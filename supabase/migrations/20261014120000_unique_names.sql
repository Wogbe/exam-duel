-- Exam Duel v0.2.1: tell players apart in a room.
--
-- Two friends called "Kofi" could both join the same room, pick the same
-- avatar colour, and look identical to everyone else. Now the server gives
-- the second one "Kofi 2" and a colour nobody in the room is using.
--
-- Run after 20261014000000_variety_photos.sql. Safe to run more than once.

-- ---------------------------------------------------------------------------
-- Helpers (internal: no client may call them)
-- ---------------------------------------------------------------------------

-- A nickname nobody else in this room is using. Numbers the duplicates:
-- "Kofi", "Kofi 2", "Kofi 3"… and always fits the 20-character column.
create or replace function public._unique_nickname(p_room uuid, p_name text, p_uid uuid)
returns text
language plpgsql
stable
set search_path = public
as $$
declare
  base text := left(nullif(btrim(coalesce(p_name, '')), ''), 20);
  candidate text;
  n int := 1;
  suffix text;
begin
  if base is null then
    base := 'Player';
  end if;
  candidate := base;
  -- A room holds at most 12 players, so this cannot run away.
  while n < 30 and exists (
    select 1 from public.room_players
    where room_id = p_room
      and user_id is distinct from p_uid
      and lower(nickname) = lower(candidate)
  ) loop
    n := n + 1;
    suffix := ' ' || n;
    candidate := left(base, 20 - length(suffix)) || suffix;
  end loop;
  return candidate;
end $$;

-- The colour they asked for, or the next free one. Falls back to their choice
-- once all 8 colours are taken (9 players or more).
create or replace function public._free_avatar(p_room uuid, p_want int, p_uid uuid)
returns int
language plpgsql
stable
set search_path = public
as $$
declare
  want int := coalesce(p_want, 0);
  taken int[];
  i int;
begin
  if want < 0 or want > 7 then
    want := 0;
  end if;
  select coalesce(array_agg(avatar), '{}') into taken
  from public.room_players
  where room_id = p_room and user_id is distinct from p_uid;

  for i in 0..7 loop
    if not (((want + i) % 8) = any (taken)) then
      return (want + i) % 8;
    end if;
  end loop;
  return want;
end $$;

-- ---------------------------------------------------------------------------
-- join_room: every player in a room gets their own name and colour
-- ---------------------------------------------------------------------------
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
  -- Both helpers skip your own row, so reconnecting never bumps your number.
  if exists (select 1 from public.room_players where room_id = r.id and user_id = uid) then
    update public.room_players
    set nickname = public._unique_nickname(r.id, p_nickname, uid),
        avatar = public._free_avatar(r.id, p_avatar, uid)
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
  values (
    r.id,
    uid,
    public._unique_nickname(r.id, p_nickname, uid),
    public._free_avatar(r.id, p_avatar, uid)
  );
  return r;
end $$;

-- ---------------------------------------------------------------------------
-- Permissions
-- ---------------------------------------------------------------------------
revoke all on function public._unique_nickname(uuid, text, uuid) from public, anon, authenticated;
revoke all on function public._free_avatar(uuid, int, uuid) from public, anon, authenticated;
grant execute on function public.join_room(text, text, int) to authenticated;
