-- SIPANDAI: initial multi-tenant schema
-- Jalankan di Supabase SQL Editor pada proyek baru.
-- RLS adalah batas keamanan utama; jangan menonaktifkannya di produksi.

create extension if not exists pgcrypto;

create type public.school_role as enum ('school_admin', 'principal', 'teacher');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  npsn_or_ns text,
  level text not null default 'MI/SD' check (level in ('MI','SD','MI/SD')),
  address text,
  district text,
  province text,
  phone text,
  email text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.school_memberships (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.school_role not null default 'teacher',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, user_id)
);

create table public.academic_years (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null, -- contoh: 2026/2027
  starts_on date,
  ends_on date,
  is_current boolean not null default false,
  created_at timestamptz not null default now(),
  unique (school_id, name),
  check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  academic_year_id uuid references public.academic_years(id) on delete set null,
  name text not null, -- contoh: Kelas 4A
  grade_level smallint check (grade_level between 1 and 6),
  phase text check (phase in ('A','B','C')),
  homeroom_teacher_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (school_id, academic_year_id, name)
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_number text,
  full_name text not null,
  birth_date date,
  gender text check (gender in ('L','P')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, student_number)
);

create table public.class_members (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  joined_at date not null default current_date,
  unique (class_id, student_id)
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references public.schools(id) on delete cascade,
  name text not null,
  code text,
  is_system boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.learning_outcomes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  academic_year_id uuid references public.academic_years(id) on delete set null,
  curriculum_name text not null,
  phase text not null check (phase in ('A','B','C')),
  grade_range text,
  subject_id uuid references public.subjects(id) on delete set null,
  subject_name text not null,
  element_name text not null,
  cp_text text not null,
  source_name text,
  source_url text,
  version_label text,
  status text not null default 'draft' check (status in ('draft','verified','archived')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.cp_analyses (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  learning_outcome_id uuid not null references public.learning_outcomes(id) on delete cascade,
  analysis_json jsonb not null default '{}'::jsonb,
  notes text,
  status text not null default 'draft' check (status in ('draft','reviewed','approved')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.learning_objectives (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  learning_outcome_id uuid not null references public.learning_outcomes(id) on delete cascade,
  cp_analysis_id uuid references public.cp_analyses(id) on delete set null,
  code text,
  sequence_no integer not null default 1,
  objective_text text not null,
  material_scope text,
  estimated_periods numeric(6,2),
  status text not null default 'draft' check (status in ('draft','reviewed','approved')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.learning_paths (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  learning_outcome_id uuid not null references public.learning_outcomes(id) on delete cascade,
  name text not null default 'ATP',
  description text,
  status text not null default 'draft' check (status in ('draft','reviewed','approved')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.learning_path_items (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  learning_path_id uuid not null references public.learning_paths(id) on delete cascade,
  learning_objective_id uuid not null references public.learning_objectives(id) on delete cascade,
  sequence_no integer not null,
  allocated_periods numeric(6,2),
  notes text,
  unique (learning_path_id, sequence_no),
  unique (learning_path_id, learning_objective_id)
);

create table public.generated_documents (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  document_type text not null,
  title text not null,
  academic_year_id uuid references public.academic_years(id) on delete set null,
  class_id uuid references public.classes(id) on delete set null,
  subject_id uuid references public.subjects(id) on delete set null,
  source_learning_outcome_id uuid references public.learning_outcomes(id) on delete set null,
  source_learning_path_id uuid references public.learning_paths(id) on delete set null,
  content_json jsonb not null default '{}'::jsonb,
  version_no integer not null default 1,
  status text not null default 'draft' check (status in ('draft','review','approved','archived')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_memberships_user on public.school_memberships(user_id, school_id);
create index idx_classes_school on public.classes(school_id);
create index idx_students_school on public.students(school_id);
create index idx_cp_school_phase on public.learning_outcomes(school_id, phase);
create index idx_docs_school_type on public.generated_documents(school_id, document_type);

-- Helper functions: SECURITY DEFINER avoids recursive RLS policy evaluation.
create or replace function public.is_platform_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.platform_admins pa
    where pa.user_id = (select auth.uid())
  );
$$;

create or replace function public.is_school_member(target_school_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select public.is_platform_admin() or exists (
    select 1 from public.school_memberships sm
    where sm.school_id = target_school_id
      and sm.user_id = (select auth.uid())
      and sm.is_active = true
  );
$$;

create or replace function public.has_school_role(target_school_id uuid, allowed_roles public.school_role[])
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select public.is_platform_admin() or exists (
    select 1 from public.school_memberships sm
    where sm.school_id = target_school_id
      and sm.user_id = (select auth.uid())
      and sm.is_active = true
      and sm.role = any(allowed_roles)
  );
$$;

-- Create profile automatically for new Auth users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.platform_admins enable row level security;
alter table public.schools enable row level security;
alter table public.school_memberships enable row level security;
alter table public.academic_years enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.class_members enable row level security;
alter table public.subjects enable row level security;
alter table public.learning_outcomes enable row level security;
alter table public.cp_analyses enable row level security;
alter table public.learning_objectives enable row level security;
alter table public.learning_paths enable row level security;
alter table public.learning_path_items enable row level security;
alter table public.generated_documents enable row level security;

-- Profiles: users may read/update only their own profile.
create policy "profile_select_own" on public.profiles
for select to authenticated using (id = (select auth.uid()) or public.is_platform_admin());
create policy "profile_update_own" on public.profiles
for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- Platform admins: visible only to platform admins.
create policy "platform_admins_select" on public.platform_admins
for select to authenticated using (public.is_platform_admin());

-- Schools: members can read their school; platform admin can manage all.
create policy "schools_select_member" on public.schools
for select to authenticated using (public.is_school_member(id));
create policy "schools_insert_platform" on public.schools
for insert to authenticated with check (public.is_platform_admin());
create policy "schools_update_admin" on public.schools
for update to authenticated using (public.has_school_role(id, array['school_admin']::public.school_role[]))
with check (public.has_school_role(id, array['school_admin']::public.school_role[]));
create policy "schools_delete_platform" on public.schools
for delete to authenticated using (public.is_platform_admin());

-- Memberships: members can view membership list within their school.
create policy "memberships_select_school" on public.school_memberships
for select to authenticated using (public.is_school_member(school_id));
create policy "memberships_insert_admin" on public.school_memberships
for insert to authenticated with check (
  public.is_platform_admin()
  or public.has_school_role(school_id, array['school_admin']::public.school_role[])
);
create policy "memberships_update_admin" on public.school_memberships
for update to authenticated using (
  public.is_platform_admin()
  or public.has_school_role(school_id, array['school_admin']::public.school_role[])
) with check (
  public.is_platform_admin()
  or public.has_school_role(school_id, array['school_admin']::public.school_role[])
);
create policy "memberships_delete_admin" on public.school_memberships
for delete to authenticated using (
  public.is_platform_admin()
  or public.has_school_role(school_id, array['school_admin']::public.school_role[])
);

-- Tenant tables: member read; admin write for school setup; members may create their own academic work.
create policy "academic_years_select" on public.academic_years
for select to authenticated using (public.is_school_member(school_id));
create policy "academic_years_write" on public.academic_years
for all to authenticated using (public.has_school_role(school_id, array['school_admin']::public.school_role[]))
with check (public.has_school_role(school_id, array['school_admin']::public.school_role[]));

create policy "classes_select" on public.classes
for select to authenticated using (public.is_school_member(school_id));
create policy "classes_write" on public.classes
for all to authenticated using (public.has_school_role(school_id, array['school_admin','principal']::public.school_role[]))
with check (public.has_school_role(school_id, array['school_admin','principal']::public.school_role[]));

create policy "students_select" on public.students
for select to authenticated using (public.is_school_member(school_id));
create policy "students_write" on public.students
for all to authenticated using (public.has_school_role(school_id, array['school_admin']::public.school_role[]))
with check (public.has_school_role(school_id, array['school_admin']::public.school_role[]));

create policy "class_members_select" on public.class_members
for select to authenticated using (public.is_school_member(school_id));
create policy "class_members_write" on public.class_members
for all to authenticated using (public.has_school_role(school_id, array['school_admin','principal']::public.school_role[]))
with check (public.has_school_role(school_id, array['school_admin','principal']::public.school_role[]));

-- Subjects may be global system subjects (school_id NULL) or tenant-specific.
create policy "subjects_select" on public.subjects
for select to authenticated using (school_id is null or public.is_school_member(school_id));
create policy "subjects_write" on public.subjects
for all to authenticated using (
  school_id is not null and public.has_school_role(school_id, array['school_admin']::public.school_role[])
) with check (
  school_id is not null and public.has_school_role(school_id, array['school_admin']::public.school_role[])
);

-- Curriculum work: teachers and above may create/update within their school.
create policy "cp_select" on public.learning_outcomes
for select to authenticated using (public.is_school_member(school_id));
create policy "cp_write" on public.learning_outcomes
for all to authenticated using (public.is_school_member(school_id))
with check (public.is_school_member(school_id));

create policy "cp_analysis_select" on public.cp_analyses
for select to authenticated using (public.is_school_member(school_id));
create policy "cp_analysis_write" on public.cp_analyses
for all to authenticated using (public.is_school_member(school_id))
with check (public.is_school_member(school_id));

create policy "tp_select" on public.learning_objectives
for select to authenticated using (public.is_school_member(school_id));
create policy "tp_write" on public.learning_objectives
for all to authenticated using (public.is_school_member(school_id))
with check (public.is_school_member(school_id));

create policy "atp_select" on public.learning_paths
for select to authenticated using (public.is_school_member(school_id));
create policy "atp_write" on public.learning_paths
for all to authenticated using (public.is_school_member(school_id))
with check (public.is_school_member(school_id));

create policy "atp_items_select" on public.learning_path_items
for select to authenticated using (public.is_school_member(school_id));
create policy "atp_items_write" on public.learning_path_items
for all to authenticated using (public.is_school_member(school_id))
with check (public.is_school_member(school_id));

create policy "documents_select" on public.generated_documents
for select to authenticated using (public.is_school_member(school_id));
create policy "documents_write" on public.generated_documents
for all to authenticated using (public.is_school_member(school_id))
with check (public.is_school_member(school_id));

-- Important: before production, tighten teacher write permissions by assigning
-- documents/classes to a teacher and checking ownership/assignment at row level.
-- Also add audit logging, storage policies, rate limits, and tested invite flows.
