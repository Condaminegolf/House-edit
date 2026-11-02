-- THE HOUSE EDIT · Shared database
-- Run this once in a NEW Supabase project's SQL Editor. Do not run against an
-- existing project unless you have reviewed the schema and taken a backup.
-- Requires Supabase Auth (email sign-in), Realtime, and Storage.

create schema if not exists house_private;

create table if not exists public.house_projects (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) between 1 and 80),
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.house_members (
  project_id uuid not null references public.house_projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','partner','designer')),
  display_name text not null check(length(display_name) between 1 and 60),
  joined_at timestamptz not null default now(),
  primary key (project_id, user_id),
  unique (project_id, role),
  unique (user_id) -- MVP: one home project per account
);

create table if not exists public.house_invitations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.house_projects(id) on delete cascade,
  role text not null check(role in ('partner','designer')),
  code text not null unique,
  used_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (project_id, role)
);

create table if not exists public.house_rooms (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.house_projects(id) on delete cascade,
  name text not null check(length(name) between 1 and 60),
  emoji text not null default '🏡',
  sort_order integer not null default 0,
  unique(id, project_id)
);

create table if not exists public.house_decisions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.house_projects(id) on delete cascade,
  room_id uuid not null,
  title text not null check(length(title) between 1 and 110),
  notes text not null default '',
  status text not null default 'open' check(status in ('open','approved','ordered','installed')),
  winner_option_id uuid,
  created_at timestamptz not null default now(),
  foreign key(room_id,project_id) references public.house_rooms(id,project_id) on delete cascade
);

create table if not exists public.house_options (
  id uuid primary key default gen_random_uuid(),
  decision_id uuid not null references public.house_decisions(id) on delete cascade,
  title text not null check(length(title) between 1 and 110),
  notes text not null default '',
  price numeric(12,2) check(price >= 0),
  source_url text not null default '',
  image_url text not null default '',
  image_path text not null default '',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.house_votes (
  option_id uuid not null references public.house_options(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  choice text not null check(choice in ('love','maybe','pass')),
  updated_at timestamptz not null default now(),
  primary key(option_id,user_id)
);

create table if not exists public.house_comments (
  id uuid primary key default gen_random_uuid(),
  option_id uuid not null references public.house_options(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check(length(body) between 1 and 600),
  created_at timestamptz not null default now()
);

create index if not exists house_decisions_project_idx on public.house_decisions(project_id);
create index if not exists house_options_decision_idx on public.house_options(decision_id);
create index if not exists house_comments_option_idx on public.house_comments(option_id);

-- Private membership predicates. SECURITY DEFINER is needed only to avoid
-- recursive RLS when reading house_members. Functions use auth.uid(), never a
-- user ID supplied by the browser, and have a fixed safe search_path.
create or replace function house_private.is_member(p_project uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(
    select 1 from public.house_members m
    where m.project_id = p_project and m.user_id = auth.uid()
  );
$$;

create or replace function house_private.is_owner(p_project uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(
    select 1 from public.house_members m
    where m.project_id = p_project and m.user_id = auth.uid() and m.role='owner'
  );
$$;

create or replace function house_private.is_homeowner(p_project uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(
    select 1 from public.house_members m
    where m.project_id = p_project and m.user_id = auth.uid() and m.role in ('owner','partner')
  );
$$;

create or replace function house_private.can_see_decision(p_decision uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(
    select 1 from public.house_decisions d join public.house_members m
      on m.project_id = d.project_id
    where d.id = p_decision and m.user_id = auth.uid()
  );
$$;

create or replace function house_private.can_see_option(p_option uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(
    select 1 from public.house_options o
      join public.house_decisions d on d.id=o.decision_id
      join public.house_members m on m.project_id=d.project_id
    where o.id=p_option and m.user_id = auth.uid()
  );
$$;

create or replace function house_private.can_access_image(p_filename text)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(
    select 1 from public.house_members m
    where m.project_id::text=split_part(p_filename,'/',1)
      and m.user_id = auth.uid()
  );
$$;

-- RLS is mandatory: frontend uses the public publishable key, never a secret.
alter table public.house_projects enable row level security;
alter table public.house_members enable row level security;
alter table public.house_invitations enable row level security;
alter table public.house_rooms enable row level security;
alter table public.house_decisions enable row level security;
alter table public.house_options enable row level security;
alter table public.house_votes enable row level security;
alter table public.house_comments enable row level security;

create policy "read member project" on public.house_projects for select to authenticated
using(house_private.is_member(id));
create policy "read project members" on public.house_members for select to authenticated
using(house_private.is_member(project_id));
create policy "owner reads private invites" on public.house_invitations for select to authenticated
using(house_private.is_owner(project_id));

create policy "members read rooms" on public.house_rooms for select to authenticated
using(house_private.is_member(project_id));
create policy "members add rooms" on public.house_rooms for insert to authenticated
with check(house_private.is_member(project_id));

create policy "members read decisions" on public.house_decisions for select to authenticated
using(house_private.is_member(project_id));
create policy "members add decisions" on public.house_decisions for insert to authenticated
with check(house_private.is_member(project_id) and status='open' and winner_option_id is null);

create policy "members read options" on public.house_options for select to authenticated
using(house_private.can_see_decision(decision_id));
create policy "members add options" on public.house_options for insert to authenticated
with check(created_by=auth.uid() and house_private.can_see_decision(decision_id)
  and exists(select 1 from public.house_decisions d where d.id=decision_id and d.status='open'));

create policy "members read votes" on public.house_votes for select to authenticated
using(house_private.can_see_option(option_id));
create policy "own vote insert" on public.house_votes for insert to authenticated
with check(user_id=auth.uid() and house_private.can_see_option(option_id)
  and exists(select 1 from public.house_options o join public.house_decisions d on d.id=o.decision_id
    where o.id=option_id and d.status='open'));
create policy "own vote update" on public.house_votes for update to authenticated
using(user_id=auth.uid() and house_private.can_see_option(option_id))
with check(user_id=auth.uid() and house_private.can_see_option(option_id)
  and exists(select 1 from public.house_options o join public.house_decisions d on d.id=o.decision_id
    where o.id=option_id and d.status='open'));
create policy "own vote delete" on public.house_votes for delete to authenticated
using(user_id=auth.uid() and house_private.can_see_option(option_id));

create policy "members read comments" on public.house_comments for select to authenticated
using(house_private.can_see_option(option_id));
create policy "own comment insert" on public.house_comments for insert to authenticated
with check(user_id=auth.uid() and house_private.can_see_option(option_id));

-- Remove default public grants; re-add ONLY operations actually supported.
revoke all on public.house_projects,public.house_members,public.house_invitations,
  public.house_rooms,public.house_decisions,public.house_options,public.house_votes,
  public.house_comments from anon,authenticated,public;
grant select on public.house_projects,public.house_members,public.house_invitations to authenticated;
grant select,insert on public.house_rooms,public.house_decisions,public.house_options,public.house_comments to authenticated;
grant select,insert,update,delete on public.house_votes to authenticated;

-- Invite creation and redemption require elevated inserts into memberships;
-- functions are the ONLY routes and are explicitly limited to authenticated.
create or replace function public.house_create_project(p_name text,p_display_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid();v_project uuid;v_role text;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  if length(trim(coalesce(p_name,''))) not between 1 and 80 or
     length(trim(coalesce(p_display_name,''))) not between 1 and 60 then
    raise exception 'Provide a project name and your name';
  end if;
  if exists(select 1 from public.house_members where user_id=v_user) then
    raise exception 'You already belong to a home';
  end if;
  insert into public.house_projects(name,owner_id) values(trim(p_name),v_user) returning id into v_project;
  insert into public.house_members(project_id,user_id,role,display_name)
    values(v_project,v_user,'owner',trim(p_display_name));
  foreach v_role in array array['partner','designer'] loop
    insert into public.house_invitations(project_id,role,code)
      values(v_project,v_role,substr(replace(gen_random_uuid()::text,'-',''),1,24));
  end loop;
  insert into public.house_rooms(project_id,name,emoji,sort_order) values
    (v_project,'Kitchen','🍽️',0),(v_project,'Bathroom','🛁',1),
    (v_project,'Living Room','🛋️',2),(v_project,'Bedroom','🛏️',3),
    (v_project,'Laundry','🧺',4),(v_project,'Outdoor','🌿',5),
    (v_project,'Whole House','🏠',6);
  return v_project;
end;$$;

create or replace function public.house_join_project(p_invitation_code text,p_display_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid();v_inv public.house_invitations%rowtype;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  if length(trim(coalesce(p_display_name,''))) not between 1 and 60 then
    raise exception 'Provide your name';
  end if;
  if exists(select 1 from public.house_members where user_id=v_user) then
    raise exception 'You already belong to a home';
  end if;
  select * into v_inv from public.house_invitations
    where code=lower(trim(p_invitation_code)) for update;
  if not found or v_inv.used_by is not null then
    raise exception 'Invalid or already-used invitation code';
  end if;
  insert into public.house_members(project_id,user_id,role,display_name)
    values(v_inv.project_id,v_user,v_inv.role,trim(p_display_name));
  update public.house_invitations set used_by=v_user where id=v_inv.id;
  return v_inv.project_id;
end;$$;

create or replace function public.house_approve_option(p_option_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_project uuid;v_decision uuid;v_status text;v_yes int;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select d.project_id,d.id,d.status into v_project,v_decision,v_status
    from public.house_options o join public.house_decisions d on d.id=o.decision_id
    where o.id=p_option_id for update of d;
  if v_project is null or v_status<>'open' or not house_private.is_homeowner(v_project) then
    raise exception 'You cannot approve this option';
  end if;
  select count(*) into v_yes
    from public.house_members m join public.house_votes v
      on v.user_id=m.user_id and v.option_id=p_option_id
    where m.project_id=v_project and m.role in ('owner','partner') and v.choice in ('love','maybe');
  if v_yes<>2 then raise exception 'Both homeowners must vote Love or Maybe first'; end if;
  update public.house_decisions set status='approved',winner_option_id=p_option_id where id=v_decision;
end;$$;

create or replace function public.house_set_status(p_decision_id uuid,p_status text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_project uuid;v_old text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select project_id,status into v_project,v_old from public.house_decisions
    where id=p_decision_id for update;
  if v_project is null or not house_private.is_homeowner(v_project) then
    raise exception 'Only homeowners can change the selection status';
  end if;
  if p_status='open' and v_old<>'open' then
    update public.house_decisions set status='open',winner_option_id=null where id=p_decision_id;
  elsif v_old='approved' and p_status='ordered' then
    update public.house_decisions set status='ordered' where id=p_decision_id;
  elsif v_old='ordered' and p_status='installed' then
    update public.house_decisions set status='installed' where id=p_decision_id;
  else
    raise exception 'Invalid status transition';
  end if;
end;$$;

revoke all on function public.house_create_project(text,text),
  public.house_join_project(text,text),
  public.house_approve_option(uuid),
  public.house_set_status(uuid,text) from public,anon;
grant execute on function public.house_create_project(text,text),
  public.house_join_project(text,text),
  public.house_approve_option(uuid),
  public.house_set_status(uuid,text) to authenticated;

revoke all on schema house_private from public,anon;
grant usage on schema house_private to authenticated;
grant execute on all functions in schema house_private to authenticated;

-- Private photo bucket: 6 MB image uploads, only members may read or upload.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('house-option-images','house-option-images',false,6291456,
  array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false,file_size_limit=6291456,
  allowed_mime_types=array['image/jpeg','image/png','image/webp'];

create policy "House members read private photos" on storage.objects
for select to authenticated
using(bucket_id='house-option-images' and house_private.can_access_image(name));
create policy "House members upload private photos" on storage.objects
for insert to authenticated
with check(bucket_id='house-option-images' and house_private.can_access_image(name));

-- Turn on Realtime publication for the collaborative tables (first setup).
-- Avoid duplicating publication membership on reruns.
do $$ declare t text;begin
  foreach t in array array['house_rooms','house_decisions','house_options','house_votes','house_comments','house_members'] loop
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
      execute format('alter publication supabase_realtime add table public.%I',t);
    end if;
  end loop;
end;$$;
