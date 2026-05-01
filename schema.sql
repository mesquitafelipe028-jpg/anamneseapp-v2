-- ═══════════════════════════════════════════
-- AnamneseApp — Schema Supabase
-- Cole este SQL no Supabase > SQL Editor > New Query
-- ═══════════════════════════════════════════

-- 1. PROFISSIONAIS
create table if not exists professionals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade,
  name        text not null,
  specialty   text not null default 'personal',
  phone       text,
  wa_number   text,
  color       text default 'olive',
  created_at  timestamptz default now()
);

-- 2. ANAMNESES
create table if not exists anamneses (
  id              uuid primary key default gen_random_uuid(),
  professional_id uuid references professionals(id) on delete cascade,
  mode            text not null check (mode in ('online','presencial')),
  patient_name    text,
  patient_phone   text,
  data            jsonb not null default '{}',
  created_at      timestamptz default now()
);

-- 3. SEGURANÇA (Row Level Security)
alter table professionals enable row level security;
alter table anamneses     enable row level security;

-- Profissional só vê seus próprios dados
create policy "professionals: own rows"
  on professionals for all
  using (auth.uid() = user_id);

-- Anamnese: qualquer um insere (paciente), mas só o dono lê
create policy "anamneses: public insert"
  on anamneses for insert
  with check (true);

create policy "anamneses: professional reads own"
  on anamneses for select
  using (
    professional_id in (
      select id from professionals where user_id = auth.uid()
    )
  );

-- 4. ÍNDICES
create index if not exists idx_anamneses_professional on anamneses(professional_id);
create index if not exists idx_anamneses_created      on anamneses(created_at desc);
create index if not exists idx_professionals_user     on professionals(user_id);
