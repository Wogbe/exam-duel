// Edge function: Eve writes fresh trivia on any topic the host types.
// Deploy:  supabase functions deploy generate-questions
// Secrets: supabase secrets set ANTHROPIC_API_KEY=sk-ant-...  (ANTHROPIC_MODEL optional)
import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-haiku-4-5";
const MAX_PER_HOUR = 120; // questions per user per hour

type Q = { stem: string; options: string[]; answer: number };

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });
}

function valid(q: Q): boolean {
  if (typeof q?.stem !== "string" || q.stem.length < 8 || q.stem.length > 200) return false;
  if (!Array.isArray(q.options) || q.options.length !== 4) return false;
  if (q.options.some((o) => typeof o !== "string" || o.trim().length === 0 || o.length > 80)) return false;
  if (new Set(q.options.map((o) => o.trim().toLowerCase())).size !== 4) return false;
  return Number.isInteger(q.answer) && q.answer >= 0 && q.answer <= 3;
}

function shuffle(q: Q): Q {
  const correct = q.options[q.answer];
  const opts = [...q.options];
  for (let i = opts.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [opts[i], opts[j]] = [opts[j], opts[i]];
  }
  return { stem: q.stem.trim(), options: opts.map((o) => o.trim()), answer: opts.indexOf(correct) };
}

async function askClaude(topic: string, count: number): Promise<Q[]> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 4000,
      system:
        "You write multiple-choice trivia for a party game played by friends in Ghana. " +
        "Only include facts you are certain are true and that will not change soon. " +
        "Each question has exactly one correct option and three plausible wrong options. " +
        "Keep questions under 120 characters and options under 40. Mix easy, medium and hard. " +
        "Keep everything friendly and suitable for teenagers. No trick questions.",
      messages: [{ role: "user", content: `Write ${count} trivia questions about: ${topic}` }],
      tools: [{
        name: "save_questions",
        description: "Save the trivia questions.",
        input_schema: {
          type: "object",
          properties: {
            questions: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  stem: { type: "string" },
                  options: { type: "array", items: { type: "string" }, minItems: 4, maxItems: 4 },
                  answer: { type: "integer", description: "Index 0-3 of the correct option" },
                },
                required: ["stem", "options", "answer"],
              },
            },
          },
          required: ["questions"],
        },
      }],
      tool_choice: { type: "tool", name: "save_questions" },
    }),
  });
  if (!res.ok) throw new Error(`Claude API ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const block = (data.content ?? []).find((b: { type: string }) => b.type === "tool_use");
  return (block?.input?.questions ?? []) as Q[];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const auth = req.headers.get("Authorization") ?? "";
  // User-scoped client: RPCs run as the caller, so host checks apply.
  const asUser = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: auth } } });
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: { user } } = await asUser.auth.getUser();
  if (!user) return json({ error: "Sign in first" }, 401);

  let body: { room_id?: string; topic?: string; count?: number };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Bad JSON" }, 400);
  }
  const topic = (body.topic ?? "").trim().slice(0, 80);
  const count = Math.max(3, Math.min(Number(body.count) || 10, 20));
  if (!body.room_id || topic.length < 2) return json({ error: "room_id and topic are required" }, 400);

  const since = new Date(Date.now() - 3600_000).toISOString();
  const { count: recent } = await admin.from("questions").select("id", { count: "exact", head: true })
    .eq("created_by", user.id).gte("created_at", since);
  if ((recent ?? 0) + count > MAX_PER_HOUR) return json({ error: "Eve needs a break. Try again later." }, 429);

  let qs: Q[];
  try {
    qs = (await askClaude(topic, count)).filter(valid).map(shuffle);
  } catch (e) {
    console.error(e);
    return json({ error: "Eve couldn't write questions right now." }, 502);
  }
  if (qs.length === 0) return json({ error: "No usable questions. Try a different topic." }, 422);

  const batchId = crypto.randomUUID();
  const { error: insErr } = await admin.from("questions").insert(qs.map((q) => ({
    category: "ai",
    stem: q.stem,
    options: q.options,
    correct_index: q.answer,
    source: "ai",
    batch_id: batchId,
    created_by: user.id,
  })));
  if (insErr) return json({ error: insErr.message }, 500);

  const { error: rpcErr } = await asUser.rpc("attach_ai_batch", { p_room: body.room_id, p_batch: batchId });
  if (rpcErr) return json({ error: rpcErr.message }, 403);

  return json({ batch_id: batchId, count: qs.length, topic });
});
