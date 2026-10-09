-- Exam Duel: multiplayer trivia rooms.
-- Clients never write tables directly. Every change goes through the
-- security-definer functions below, so scoring and timing stay on the server.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Question bank
-- ---------------------------------------------------------------------------
create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  stem text not null,
  options jsonb not null,            -- array of 4 strings
  correct_index smallint not null check (correct_index between 0 and 3),
  source text not null default 'curated' check (source in ('curated', 'ai')),
  batch_id uuid,                     -- set for AI-generated batches
  created_by uuid,
  created_at timestamptz not null default now(),
  constraint options_are_four check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) = 4)
);
create index if not exists questions_category_idx on public.questions (category) where source = 'curated';
create index if not exists questions_batch_idx on public.questions (batch_id);
alter table public.questions enable row level security;
-- No policies: the bank (and its answers) is readable only through functions.

-- ---------------------------------------------------------------------------
-- Rooms
-- ---------------------------------------------------------------------------
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  host_id uuid not null,
  status text not null default 'lobby' check (status in ('lobby', 'question', 'reveal', 'finished')),
  settings jsonb not null default '{}'::jsonb,
  current_index int not null default -1,
  question_count int not null default 0,
  phase_started_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.room_players (
  room_id uuid not null references public.rooms (id) on delete cascade,
  user_id uuid not null,
  nickname text not null check (char_length(nickname) between 1 and 20),
  avatar smallint not null default 0,
  score int not null default 0,
  streak int not null default 0,
  answered_index int not null default -1,
  last_correct boolean not null default false,
  last_points int not null default 0,
  is_host boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

-- Questions for one game, copied from the bank. The answer lives in a
-- separate table nobody can read; it is copied to revealed_index at reveal.
create table if not exists public.room_questions (
  room_id uuid not null references public.rooms (id) on delete cascade,
  idx int not null,
  category text not null,
  stem text not null,
  options jsonb not null,
  revealed_index smallint,
  primary key (room_id, idx)
);

create table if not exists public.room_question_keys (
  room_id uuid not null references public.rooms (id) on delete cascade,
  idx int not null,
  correct_index smallint not null,
  primary key (room_id, idx)
);

create table if not exists public.room_answers (
  room_id uuid not null references public.rooms (id) on delete cascade,
  idx int not null,
  user_id uuid not null,
  choice smallint,
  correct boolean not null,
  points int not null,
  ms_taken int not null,
  created_at timestamptz not null default now(),
  primary key (room_id, idx, user_id)
);

alter table public.rooms enable row level security;
alter table public.room_players enable row level security;
alter table public.room_questions enable row level security;
alter table public.room_question_keys enable row level security;
alter table public.room_answers enable row level security;

-- Membership check. Security definer avoids recursive RLS on room_players.
create or replace function public.is_room_member(p_room uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.room_players
    where room_id = p_room and user_id = auth.uid()
  );
$$;

drop policy if exists "members read room" on public.rooms;
create policy "members read room" on public.rooms
  for select to authenticated using (public.is_room_member(id));

drop policy if exists "members read players" on public.room_players;
create policy "members read players" on public.room_players
  for select to authenticated using (public.is_room_member(room_id));

-- Players only see a question once the room has reached it.
drop policy if exists "members read reached questions" on public.room_questions;
create policy "members read reached questions" on public.room_questions
  for select to authenticated using (
    public.is_room_member(room_id)
    and idx <= (select r.current_index from public.rooms r where r.id = room_id)
  );

drop policy if exists "own answers" on public.room_answers;
create policy "own answers" on public.room_answers
  for select to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function public.server_now()
returns timestamptz language sql stable as $$ select now() $$;

create or replace function public._touch_room()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists rooms_touch on public.rooms;
create trigger rooms_touch before update on public.rooms
  for each row execute function public._touch_room();

create or replace function public._new_room_code()
returns text
language plpgsql
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; -- no 0/O, 1/I/L
  c text;
begin
  loop
    c := '';
    for i in 1..5 loop
      c := c || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.rooms where code = c);
  end loop;
  return c;
end $$;

create or replace function public._require_user()
returns uuid
language plpgsql
as $$
declare uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  return uid;
end $$;

create or replace function public._clean_settings(p jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  cnt int := coalesce((p ->> 'count')::int, 10);
  secs int := coalesce((p ->> 'seconds')::int, 15);
  cats jsonb := coalesce(p -> 'categories', '[]'::jsonb);
begin
  cnt := greatest(3, least(cnt, 30));
  secs := greatest(5, least(secs, 60));
  if jsonb_typeof(cats) <> 'array' then cats := '[]'::jsonb; end if;
  return jsonb_strip_nulls(jsonb_build_object(
    'count', cnt,
    'seconds', secs,
    'categories', cats,
    'topic', left(p ->> 'topic', 80),
    'ai_batch', p ->> 'ai_batch'
  ));
end $$;

-- ---------------------------------------------------------------------------
-- Room lifecycle
-- ---------------------------------------------------------------------------
create or replace function public.create_room(p_nickname text, p_avatar int, p_settings jsonb)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
begin
  insert into public.rooms (code, host_id, settings)
  values (public._new_room_code(), uid, public._clean_settings(p_settings))
  returning * into r;

  insert into public.room_players (room_id, user_id, nickname, avatar, is_host)
  values (r.id, uid, left(trim(p_nickname), 20), coalesce(p_avatar, 0), true);
  return r;
end $$;

create or replace function public.join_room(p_code text, p_nickname text, p_avatar int)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
  n int;
begin
  select * into r from public.rooms where code = upper(trim(p_code));
  if not found then
    raise exception 'room not found' using errcode = 'P0002';
  end if;

  -- Rejoining your own seat is always allowed (e.g. after a reconnect).
  if exists (select 1 from public.room_players where room_id = r.id and user_id = uid) then
    update public.room_players set nickname = left(trim(p_nickname), 20), avatar = coalesce(p_avatar, 0)
    where room_id = r.id and user_id = uid;
    return r;
  end if;

  if r.status not in ('lobby', 'finished') then
    raise exception 'game already started' using errcode = 'P0001';
  end if;
  select count(*) into n from public.room_players where room_id = r.id;
  if n >= 12 then
    raise exception 'room is full' using errcode = 'P0001';
  end if;

  insert into public.room_players (room_id, user_id, nickname, avatar)
  values (r.id, uid, left(trim(p_nickname), 20), coalesce(p_avatar, 0));
  return r;
end $$;

create or replace function public.leave_room(p_room uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  next_host uuid;
begin
  delete from public.room_players where room_id = p_room and user_id = uid;
  if not exists (select 1 from public.room_players where room_id = p_room) then
    delete from public.rooms where id = p_room;
    return;
  end if;
  -- Hand the host role to the earliest remaining player.
  if (select host_id from public.rooms where id = p_room) = uid then
    select user_id into next_host from public.room_players
    where room_id = p_room order by joined_at limit 1;
    update public.rooms set host_id = next_host where id = p_room;
    update public.room_players set is_host = (user_id = next_host) where room_id = p_room;
  end if;
end $$;

create or replace function public.update_room_settings(p_room uuid, p_settings jsonb)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
begin
  update public.rooms set settings = public._clean_settings(p_settings)
  where id = p_room and host_id = uid and status in ('lobby', 'finished')
  returning * into r;
  if not found then
    raise exception 'only the host can change settings before the game' using errcode = '42501';
  end if;
  return r;
end $$;

-- Picks questions and starts round 1. Also used for rematches.
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

  with chosen as (
    -- AI batch first (once), then curated questions to fill up.
    select q.category, q.stem, q.options, q.correct_index,
           (q.batch_id is null) as curated, random() as shuffle
    from public.questions q
    where (batch is not null and q.batch_id = batch)
       or (q.source = 'curated' and (cardinality(cats) = 0 or q.category = any (cats)))
    order by (q.batch_id is null), random()
    limit cnt
  ), picked as (
    select c.*, (row_number() over (order by c.curated, c.shuffle) - 1)::int as rn
    from chosen c
  ), ins as (
    insert into public.room_questions (room_id, idx, category, stem, options)
    select r.id, rn, category, stem, options from picked
    returning idx
  )
  insert into public.room_question_keys (room_id, idx, correct_index)
  select r.id, rn, correct_index from picked;

  select count(*) into n from public.room_questions where room_id = r.id;
  if n = 0 then
    raise exception 'no questions available for these categories' using errcode = 'P0001';
  end if;

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

-- Internal: reveal the current answer. Caller must hold the room row lock.
create or replace function public._reveal(p_room uuid, p_idx int)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.room_questions q
  set revealed_index = k.correct_index
  from public.room_question_keys k
  where q.room_id = p_room and q.idx = p_idx and k.room_id = q.room_id and k.idx = q.idx;

  -- Players who did not answer lose their streak and score nothing.
  update public.room_players
  set streak = 0, last_correct = false, last_points = 0
  where room_id = p_room and answered_index < p_idx;

  update public.rooms
  set status = 'reveal', phase_started_at = now()
  where id = p_room;
end $$;

-- Scores an answer with server time. Reveals early once everyone answered.
create or replace function public.submit_answer(p_room uuid, p_idx int, p_choice int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
  p public.room_players;
  key smallint;
  limit_ms int;
  elapsed_ms int;
  ok boolean;
  pts int := 0;
  new_streak int;
  pending int;
begin
  select * into r from public.rooms where id = p_room for update;
  if not found then
    raise exception 'room not found' using errcode = 'P0002';
  end if;
  select * into p from public.room_players where room_id = p_room and user_id = uid for update;
  if not found then
    raise exception 'not in this room' using errcode = '42501';
  end if;
  if r.status <> 'question' or r.current_index <> p_idx or p.answered_index >= p_idx then
    return jsonb_build_object('accepted', false);
  end if;

  limit_ms := coalesce((r.settings ->> 'seconds')::int, 15) * 1000;
  elapsed_ms := greatest(0, (extract(epoch from (now() - r.phase_started_at)) * 1000)::int);
  if elapsed_ms > limit_ms + 1500 then  -- small grace for network lag
    return jsonb_build_object('accepted', false, 'late', true);
  end if;

  select correct_index into key from public.room_question_keys where room_id = p_room and idx = p_idx;
  ok := p_choice is not null and p_choice = key;

  if ok then
    new_streak := p.streak + 1;
    -- 500 for being right, up to 500 more for speed, +10% per streak step (max +50%).
    pts := (500 + round(500 * greatest(0, 1 - elapsed_ms::numeric / limit_ms)))::int;
    pts := (pts * (1 + least(new_streak - 1, 5) * 0.1))::int;
  else
    new_streak := 0;
  end if;

  insert into public.room_answers (room_id, idx, user_id, choice, correct, points, ms_taken)
  values (p_room, p_idx, uid, p_choice, ok, pts, elapsed_ms);

  update public.room_players
  set score = score + pts,
      streak = new_streak,
      answered_index = p_idx,
      last_correct = ok,
      last_points = pts
  where room_id = p_room and user_id = uid;

  select count(*) into pending from public.room_players
  where room_id = p_room and answered_index < p_idx;
  if pending = 0 then
    perform public._reveal(p_room, p_idx);
  end if;

  return jsonb_build_object('accepted', true, 'correct', ok, 'points', pts, 'streak', new_streak);
end $$;

-- Any member may call this once the timer has run out. Idempotent.
create or replace function public.reveal_question(p_room uuid, p_idx int)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.rooms;
begin
  if not public.is_room_member(p_room) then
    raise exception 'not in this room' using errcode = '42501';
  end if;
  select * into r from public.rooms where id = p_room for update;
  if r.status = 'question' and r.current_index = p_idx
     and now() >= r.phase_started_at + make_interval(secs => coalesce((r.settings ->> 'seconds')::int, 15)) then
    perform public._reveal(p_room, p_idx);
  end if;
  select * into r from public.rooms where id = p_room;
  return r;
end $$;

-- Host moves on after the reveal. Others may call after 12 s (host gone).
create or replace function public.next_question(p_room uuid, p_idx int)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
begin
  if not public.is_room_member(p_room) then
    raise exception 'not in this room' using errcode = '42501';
  end if;
  select * into r from public.rooms where id = p_room for update;
  if r.status <> 'reveal' or r.current_index <> p_idx then
    return r;
  end if;
  if r.host_id <> uid and now() < r.phase_started_at + interval '12 seconds' then
    return r;
  end if;

  if r.current_index + 1 >= r.question_count then
    update public.rooms set status = 'finished', phase_started_at = now()
    where id = p_room returning * into r;
  else
    update public.rooms
    set status = 'question', current_index = current_index + 1, phase_started_at = now()
    where id = p_room returning * into r;
  end if;
  return r;
end $$;

-- Lets the AI edge function attach a generated batch to a room.
create or replace function public.attach_ai_batch(p_room uuid, p_batch uuid)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := public._require_user();
  r public.rooms;
begin
  update public.rooms set settings = settings || jsonb_build_object('ai_batch', p_batch::text)
  where id = p_room and host_id = uid and status in ('lobby', 'finished')
  returning * into r;
  if not found then
    raise exception 'only the host can add questions before the game' using errcode = '42501';
  end if;
  return r;
end $$;

-- Rooms older than a day are cleaned up. Schedule with pg_cron if you like:
--   select cron.schedule('cleanup-rooms', '0 3 * * *', 'select public.cleanup_rooms()');
create or replace function public.cleanup_rooms()
returns int
language sql
security definer
set search_path = public
as $$
  with d as (delete from public.rooms where updated_at < now() - interval '1 day' returning 1)
  select count(*)::int from d;
$$;

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------
revoke all on function public._reveal(uuid, int) from public, anon, authenticated;
revoke all on function public._new_room_code() from public, anon, authenticated;
revoke all on function public.cleanup_rooms() from public, anon, authenticated;

grant select on public.rooms, public.room_players, public.room_questions, public.room_answers to authenticated;
grant execute on function
  public.server_now(),
  public.is_room_member(uuid),
  public.create_room(text, int, jsonb),
  public.join_room(text, text, int),
  public.leave_room(uuid),
  public.update_room_settings(uuid, jsonb),
  public.start_game(uuid),
  public.submit_answer(uuid, int, int),
  public.reveal_question(uuid, int),
  public.next_question(uuid, int),
  public.attach_ai_batch(uuid, uuid)
to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime: clients subscribe to room and player changes.
-- ---------------------------------------------------------------------------
alter table public.rooms replica identity full;
alter table public.room_players replica identity full;
do $$
begin
  begin
    alter publication supabase_realtime add table public.rooms;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.room_players;
  exception when duplicate_object then null;
  end;
end $$;
