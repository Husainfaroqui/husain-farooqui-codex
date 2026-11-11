-- Husain CodeLab platform schema. Run this in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'client' check (role in ('admin','client')),
  created_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  project_code text unique not null default ('HCL-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))),
  name text not null,
  description text not null default '',
  client_id uuid references public.profiles(id) on delete set null,
  status text not null default 'Pending' check (status in ('Pending','In Progress','Review','Completed','On Hold')),
  progress integer not null default 0 check (progress between 0 and 100),
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.milestones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  is_complete boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.project_tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  is_complete boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.project_updates (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'client')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.milestones enable row level security;
alter table public.project_tasks enable row level security;
alter table public.project_updates enable row level security;

drop policy if exists "profiles read own or admin" on public.profiles;
create policy "profiles read own or admin" on public.profiles for select
using (id = auth.uid() or public.is_admin());

drop policy if exists "admin update profiles" on public.profiles;
create policy "admin update profiles" on public.profiles for update
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins manage projects clients read own" on public.projects;
create policy "admins manage projects clients read own" on public.projects for all
using (public.is_admin() or client_id = auth.uid())
with check (public.is_admin());

drop policy if exists "project members read milestones" on public.milestones;
create policy "project members read milestones" on public.milestones for select
using (public.is_admin() or exists(select 1 from public.projects p where p.id=project_id and p.client_id=auth.uid()));
drop policy if exists "admins manage milestones" on public.milestones;
create policy "admins manage milestones" on public.milestones for all
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "project members read tasks" on public.project_tasks;
create policy "project members read tasks" on public.project_tasks for select
using (public.is_admin() or exists(select 1 from public.projects p where p.id=project_id and p.client_id=auth.uid()));
drop policy if exists "admins manage tasks" on public.project_tasks;
create policy "admins manage tasks" on public.project_tasks for all
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "project members read updates" on public.project_updates;
create policy "project members read updates" on public.project_updates for select
using (public.is_admin() or exists(select 1 from public.projects p where p.id=project_id and p.client_id=auth.uid()));
drop policy if exists "admins manage updates" on public.project_updates;
create policy "admins manage updates" on public.project_updates for all
using (public.is_admin()) with check (public.is_admin());

grant usage on schema public to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.projects to authenticated;
grant select, insert, update, delete on public.milestones to authenticated;
grant select, insert, update, delete on public.project_tasks to authenticated;
grant select, insert, update, delete on public.project_updates to authenticated;

-- After creating your own account in the app, promote ONLY that account:
-- update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';
