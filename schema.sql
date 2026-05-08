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
  status          text not null default 'nova' check (status in ('nova','lida','arquivada')),
  notes           text,
  photos          jsonb not null default '[]',
  created_at      timestamptz default now()
);

-- Migração: adiciona colunas se a tabela já existir
alter table anamneses add column if not exists status text not null default 'nova';
alter table anamneses add column if not exists notes  text;
alter table anamneses add column if not exists photos jsonb not null default '[]';
-- wa_number em form_templates permite que pacientes leiam o número do profissional sem auth
alter table form_templates add column if not exists wa_number text;

-- Migração: garante que o check constraint de status inclui 'arquivada'
-- (necessário se a tabela foi criada com versão antiga do schema)
alter table anamneses drop constraint if exists anamneses_status_check;
alter table anamneses add constraint anamneses_status_check
  check (status in ('nova','lida','arquivada'));

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
    -- fichas vinculadas ao profissional
    professional_id in (
      select id from professionals where user_id = auth.uid()
    )
    -- fichas antigas sem pid (submetidas antes do link ter ?pid=)
    or professional_id is null
  );

-- Profissional pode deletar suas próprias fichas
create policy "anamneses: professional deletes own"
  on anamneses for delete
  using (
    professional_id in (select id from professionals where user_id = auth.uid())
    or professional_id is null
  );

-- Profissional pode atualizar (status, notes, photos)
create policy "anamneses: professional updates own"
  on anamneses for update
  using (
    professional_id in (select id from professionals where user_id = auth.uid())
    or professional_id is null
  );

-- 5. STORAGE (execute no Supabase > SQL Editor)
-- insert into storage.buckets (id, name, public) values ('anamnese-photos', 'anamnese-photos', true);
-- create policy "photos: authenticated upload"
--   on storage.objects for insert to authenticated
--   with check (bucket_id = 'anamnese-photos');
-- create policy "photos: public read"
--   on storage.objects for select to public
--   using (bucket_id = 'anamnese-photos');
-- create policy "photos: owner delete"
--   on storage.objects for delete to authenticated
--   using (bucket_id = 'anamnese-photos' and auth.uid()::text = (storage.foldername(name))[1]);

-- 4. FORM TEMPLATES (configuração do formulário por profissional)
create table if not exists form_templates (
  professional_id   uuid primary key references professionals(id) on delete cascade,
  online_config     jsonb not null default '[]',
  presencial_config jsonb not null default '[]',
  updated_at        timestamptz default now()
);
alter table form_templates enable row level security;
-- Pacientes lêem para montar o formulário (sem autenticação)
create policy "form_templates: public select"
  on form_templates for select using (true);
-- Só o dono escreve
create policy "form_templates: owner all"
  on form_templates for all to authenticated
  using (professional_id in (select id from professionals where user_id = auth.uid()));

-- 5. ÍNDICES
create index if not exists idx_anamneses_professional on anamneses(professional_id);
create index if not exists idx_anamneses_created      on anamneses(created_at desc);
create index if not exists idx_professionals_user     on professionals(user_id);
