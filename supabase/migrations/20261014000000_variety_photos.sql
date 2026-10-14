-- Exam Duel v2: question variety, solo practice from the shared bank,
-- an automatic question import from the Open Trivia Database, and
-- profile photos in rooms.
--
-- Run after 20261009000000_init.sql. Safe to run more than once.
-- Afterwards run supabase/seed.sql again: it only adds new questions
-- (this release adds the Bible category and 130 more questions).

-- ---------------------------------------------------------------------------
-- 1. Question bank: usage counts, OpenTDB as a source, fast duplicate checks
-- ---------------------------------------------------------------------------
alter table public.questions add column if not exists times_used int not null default 0;

alter table public.questions drop constraint if exists questions_source_check;
alter table public.questions
  add constraint questions_source_check check (source in ('curated', 'ai', 'opentdb'));

create index if not exists questions_stem_md5_idx on public.questions (md5(lower(stem)));
create index if not exists questions_pool_idx on public.questions (category) where batch_id is null;

-- Which questions each player has already had in online rooms.
-- Read only by functions (no policies).
create table if not exists public.user_seen_questions (
  user_id uuid not null,
  question_id uuid not null references public.questions (id) on delete cascade,
  seen_at timestamptz not null default now(),
  primary key (user_id, question_id)
);
alter table public.user_seen_questions enable row level security;

-- Remember which bank question each room slot came from.
alter table public.room_question_keys add column if not exists question_id uuid;

-- ---------------------------------------------------------------------------
-- 2. start_game: questions nobody in the room has seen come first
-- ---------------------------------------------------------------------------
create or replace function public.start_game(p_room uuid)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
  cnt int;
  cats text[];
  batch uuid;
  n int;
begin
  select * into r from public.rooms where id = p_room for update;
  if not found or r.host_id <> uid then
    raise exception 'only the host can start' using errcode = '42501';
  end if;
  if r.status not in ('lobby', 'finished') then
    raise exception 'game already running' using errcode = 'P0001';
  end if;

  cnt := coalesce((r.settings ->> 'count')::int, 10);
  select coalesce(array_agg(x), '{}') into cats
    from jsonb_array_elements_text(coalesce(r.settings -> 'categories', '[]'::jsonb)) x;
  batch := nullif(r.settings ->> 'ai_batch', '')::uuid;

  delete from public.room_questions where room_id = r.id;
  delete from public.room_question_keys where room_id = r.id;
  delete from public.room_answers where room_id = r.id;

  with seen as (
    -- How many players in this room have already had each question.
    select s.question_id, count(*)::int as n, max(s.seen_at) as last_seen
    from public.user_seen_questions s
    join public.room_players p on p.user_id = s.user_id and p.room_id = r.id
    group by s.question_id
  ), chosen as (
    -- AI batch first (once), then the bank: questions nobody here has had,
    -- then the ones seen longest ago, then the least used, then random.
    select q.id, q.category, q.stem, q.options, q.correct_index,
           (q.batch_id is null) as curated, random() as shuffle
    from public.questions q
    left join seen on seen.question_id = q.id
    where (batch is not null and q.batch_id = batch)
       or (q.batch_id is null and q.source <> 'ai' and (cardinality(cats) = 0 or q.category = any (cats)))
    order by (q.batch_id is null), coalesce(seen.n, 0), seen.last_seen nulls first, q.times_used / 3, random()
    limit cnt
  ), picked as (
    select c.*, (row_number() over (order by c.curated, c.shuffle) - 1)::int as rn
    from chosen c
  ), ins as (
    insert into public.room_questions (room_id, idx, category, stem, options)
    select r.id, rn, category, stem, options from picked
    returning idx
  )
  insert into public.room_question_keys (room_id, idx, correct_index, question_id)
  select r.id, rn, correct_index, id from picked;

  select count(*) into n from public.room_questions where room_id = r.id;
  if n = 0 then
    raise exception 'no questions available for these categories' using errcode = 'P0001';
  end if;

  -- Remember the picks so the next game (and other rooms) get new ones.
  insert into public.user_seen_questions (user_id, question_id)
  select p.user_id, k.question_id
  from public.room_players p
  join public.room_question_keys k on k.room_id = p.room_id
  where p.room_id = r.id and k.question_id is not null
  on conflict (user_id, question_id) do update set seen_at = now();

  update public.questions q
  set times_used = q.times_used + 1
  from public.room_question_keys k
  where k.room_id = r.id and k.question_id = q.id;

  update public.room_players
  set score = 0, streak = 0, answered_index = -1, last_correct = false, last_points = 0
  where room_id = r.id;

  update public.rooms
  set status = 'question',
      current_index = 0,
      question_count = n,
      phase_started_at = now(),
      settings = settings - 'ai_batch'   -- an AI batch is used for one game only
  where id = r.id
  returning * into r;
  return r;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Solo practice: random bank questions, with answers (solo is scored on
--    the phone). The curated questions already ship inside the app and the
--    OpenTDB ones are public, so this reveals nothing secret.
-- ---------------------------------------------------------------------------
create or replace function public.practice_questions(
  p_count int default 30,
  p_categories text[] default '{}',
  p_exclude text[] default '{}'
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', q.id,
           'c', q.category,
           'q', q.stem,
           'a', q.options ->> q.correct_index::int,
           'w', (select jsonb_agg(o.v order by o.i)
                 from jsonb_array_elements_text(q.options) with ordinality as o (v, i)
                 where o.i - 1 <> q.correct_index)
         )), '[]'::jsonb)
  from (
    select x.*
    from public.questions x
    where x.batch_id is null
      and x.source <> 'ai'
      and (coalesce(cardinality(p_categories), 0) = 0 or x.category = any (p_categories))
      and not (x.id::text = any (coalesce(p_exclude[1:500], '{}')))
    order by random()
    limit greatest(1, least(coalesce(p_count, 30), 50))
  ) q;
$$;

-- ---------------------------------------------------------------------------
-- 4. Automatic import from the Open Trivia Database (opentdb.com, CC BY-SA 4.0)
--    50 questions per call, mapped to our categories, duplicates skipped.
--    Needs the `http` extension; pg_cron runs it every 10 minutes until the
--    bank holds 6,000 imported questions.
-- ---------------------------------------------------------------------------
create or replace function public.import_opentdb(p_category int default null)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cats int[] := array[9, 10, 11, 12, 14, 15, 17, 18, 19, 21, 22, 23, 27, 30];
  v_cat int;
  v_target text;
  v_status int;
  v_content text;
  v_body jsonb;
  v_item jsonb;
  v_stem text;
  v_correct text;
  v_wrong text[];
  v_pos int;
  v_opts text[];
  v_added int := 0;
begin
  if (select count(*) from public.questions where source = 'opentdb') >= 6000 then
    return 0;
  end if;

  v_cat := coalesce(p_category, v_cats[1 + floor(random() * array_length(v_cats, 1))::int]);
  v_target := case v_cat
    when 9 then 'random'          -- General Knowledge
    when 10 then 'entertainment'  -- Books
    when 11 then 'entertainment'  -- Film
    when 12 then 'entertainment'  -- Music
    when 14 then 'entertainment'  -- Television
    when 15 then 'tech'           -- Video Games
    when 17 then 'science'        -- Science & Nature
    when 18 then 'tech'           -- Computers
    when 19 then 'science'        -- Mathematics
    when 21 then 'sports'
    when 22 then 'geography'
    when 23 then 'history'
    when 27 then 'science'        -- Animals
    when 30 then 'tech'           -- Gadgets
    else 'random'
  end;

  -- Network and parsing problems end the call quietly; cron tries again later.
  begin
    begin
      perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '10000');
    exception when others then null;
    end;
    select h.status, h.content into v_status, v_content
    from extensions.http_get(
      'https://opentdb.com/api.php?amount=50&type=multiple&encode=base64&category=' || v_cat
    ) h;
    if v_status <> 200 then
      return 0;
    end if;
    v_body := v_content::jsonb;
  exception when others then
    raise warning 'import_opentdb: %', sqlerrm;
    return 0;
  end;

  if coalesce((v_body ->> 'response_code')::int, -1) <> 0 then
    return 0;
  end if;

  for v_item in select value from jsonb_array_elements(coalesce(v_body -> 'results', '[]'::jsonb)) loop
    begin
      v_stem := btrim(convert_from(decode(v_item ->> 'question', 'base64'), 'UTF8'));
      v_correct := btrim(convert_from(decode(v_item ->> 'correct_answer', 'base64'), 'UTF8'));
      select array_agg(btrim(convert_from(decode(w, 'base64'), 'UTF8')))
        into v_wrong
        from jsonb_array_elements_text(v_item -> 'incorrect_answers') w;
    exception when others then
      continue; -- skip anything that isn't clean base64 text
    end;

    continue when v_wrong is null or array_length(v_wrong, 1) <> 3;
    continue when v_stem = '' or char_length(v_stem) > 300 or v_correct = '' or char_length(v_correct) > 120;
    continue when v_correct = any (v_wrong);
    continue when exists (select 1 from public.questions x where md5(lower(x.stem)) = md5(lower(v_stem)));

    v_pos := floor(random() * 4)::int;  -- 0..3
    v_opts := v_wrong[1:v_pos] || v_correct || v_wrong[v_pos + 1:3];
    insert into public.questions (category, stem, options, correct_index, source)
    values (v_target, v_stem, to_jsonb(v_opts), v_pos, 'opentdb');
    v_added := v_added + 1;
  end loop;

  return v_added;
end $$;

-- ---------------------------------------------------------------------------
-- 5. Profile photos in rooms
-- ---------------------------------------------------------------------------
alter table public.room_players add column if not exists has_photo boolean not null default false;

create table if not exists public.room_player_photos (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null,
  photo text not null check (char_length(photo) <= 300000),  -- base64 JPEG/PNG, about 256 px
  primary key (room_id, user_id)
);
alter table public.room_player_photos enable row level security;

drop policy if exists "members read photos" on public.room_player_photos;
create policy "members read photos" on public.room_player_photos
  for select to authenticated using (public.is_room_member(room_id));

-- Sets (or, with an empty string, removes) your photo in a room you're in.
create or replace function public.set_room_photo(p_room uuid, p_photo text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
begin
  if not exists (select 1 from public.room_players where room_id = p_room and user_id = uid) then
    raise exception 'not in this room' using errcode = '42501';
  end if;

  if p_photo is null or p_photo = '' then
    delete from public.room_player_photos where room_id = p_room and user_id = uid;
    update public.room_players set has_photo = false where room_id = p_room and user_id = uid;
    return;
  end if;

  if char_length(p_photo) > 300000 or p_photo !~ '^[A-Za-z0-9+/]+={0,2}$' then
    raise exception 'photo is too large or not an image' using errcode = '22023';
  end if;

  insert into public.room_player_photos (room_id, user_id, photo)
  values (p_room, uid, p_photo)
  on conflict (room_id, user_id) do update set photo = excluded.photo;

  -- Flipping this flag streams a player update, so others fetch the photo.
  update public.room_players set has_photo = true where room_id = p_room and user_id = uid;
end $$;

-- ---------------------------------------------------------------------------
-- 6. Permissions
-- ---------------------------------------------------------------------------
revoke all on function public.import_opentdb(int) from public, anon, authenticated;
revoke all on function public.practice_questions(int, text[], text[]) from public;
revoke all on function public.set_room_photo(uuid, text) from public, anon;

grant execute on function public.practice_questions(int, text[], text[]) to anon, authenticated;
grant execute on function public.set_room_photo(uuid, text) to authenticated;
grant execute on function public.start_game(uuid) to authenticated;
grant select on public.room_player_photos to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Extensions and schedules (skipped quietly where not available)
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    create extension if not exists http with schema extensions;
  exception when others then
    raise notice 'http extension not enabled (%). Enable it under Database > Extensions to import questions.', sqlerrm;
  end;

  begin
    create extension if not exists pg_cron with schema pg_catalog;
  exception when others then
    raise notice 'pg_cron not enabled (%). Enable it under Database > Extensions for automatic imports.', sqlerrm;
  end;

  begin
    perform cron.schedule('exam-duel-import-questions', '*/10 * * * *', 'select public.import_opentdb()');
    perform cron.schedule(
      'exam-duel-cleanup',
      '17 3 * * *',
      $job$select public.cleanup_rooms(); delete from public.user_seen_questions where seen_at < now() - interval '120 days'$job$
    );
  exception when others then
    raise notice 'Could not schedule jobs (%).', sqlerrm;
  end;
end $$;

-- First import right away, so new questions are ready without waiting.
do $$
begin
  perform public.import_opentdb();
exception when others then
  raise notice 'First import skipped (%).', sqlerrm;
end $$;
