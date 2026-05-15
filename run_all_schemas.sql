-- ═══════════════════════════════════════════════════════════════
-- AnamneseApp — Execução completa de todos os schemas
-- Cole no Supabase SQL Editor e execute de uma vez.
-- Ordem importa: cada bloco depende do anterior.
-- ═══════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════
-- 1. SCHEMA PRINCIPAL (schema.sql)
-- professionals, anamneses, form_templates
-- ══════════════════════════════════════════════════════════════

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

create table if not exists form_templates (
  professional_id   uuid primary key references professionals(id) on delete cascade,
  online_config     jsonb not null default '[]',
  presencial_config jsonb not null default '[]',
  updated_at        timestamptz default now()
);

alter table anamneses add column if not exists status text not null default 'nova';
alter table anamneses add column if not exists notes  text;
alter table anamneses add column if not exists photos jsonb not null default '[]';
alter table form_templates add column if not exists wa_number text;

alter table anamneses drop constraint if exists anamneses_status_check;
alter table anamneses add constraint anamneses_status_check
  check (status in ('nova','lida','arquivada'));

alter table professionals enable row level security;
alter table anamneses     enable row level security;
alter table form_templates enable row level security;

create policy if not exists "professionals: own rows"
  on professionals for all using (auth.uid() = user_id);

create policy if not exists "anamneses: public insert"
  on anamneses for insert with check (true);

create policy if not exists "anamneses: professional reads own"
  on anamneses for select using (
    professional_id in (select id from professionals where user_id = auth.uid())
    or professional_id is null
  );

create policy if not exists "anamneses: professional deletes own"
  on anamneses for delete using (
    professional_id in (select id from professionals where user_id = auth.uid())
    or professional_id is null
  );

create policy if not exists "anamneses: professional updates own"
  on anamneses for update using (
    professional_id in (select id from professionals where user_id = auth.uid())
    or professional_id is null
  );

create policy if not exists "form_templates: public select"
  on form_templates for select using (true);

create policy if not exists "form_templates: owner all"
  on form_templates for all to authenticated
  using (professional_id in (select id from professionals where user_id = auth.uid()));

create index if not exists idx_anamneses_professional on anamneses(professional_id);
create index if not exists idx_anamneses_created      on anamneses(created_at desc);
create index if not exists idx_professionals_user     on professionals(user_id);


-- ══════════════════════════════════════════════════════════════
-- 2. AVALIAÇÕES (avaliacoes_schema.sql)
-- assessments + 7 subtabelas
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS assessments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id  uuid NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  patient_name     text NOT NULL,
  patient_phone    text,
  patient_dob      date,
  patient_sex      char(1) CHECK (patient_sex IN ('M','F')),
  modality         text NOT NULL DEFAULT 'presencial'
                     CHECK (modality IN ('presencial','online')),
  status           text NOT NULL DEFAULT 'em_andamento'
                     CHECK (status IN ('em_andamento','concluida')),
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assessments' AND column_name = 'mode'
  ) THEN
    ALTER TABLE assessments RENAME COLUMN mode TO modality;
  END IF;
END $$;

ALTER TABLE assessments ADD COLUMN IF NOT EXISTS
  modality text NOT NULL DEFAULT 'presencial'
    CHECK (modality IN ('presencial','online'));

CREATE OR REPLACE FUNCTION _set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_assessments_updated_at ON assessments;
CREATE TRIGGER trg_assessments_updated_at
  BEFORE UPDATE ON assessments
  FOR EACH ROW EXECUTE FUNCTION _set_updated_at();

CREATE TABLE IF NOT EXISTS assessment_biometrics (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id         uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  peso_kg               numeric(6,2),
  altura_cm             numeric(5,1),
  imc                   numeric(5,2) GENERATED ALWAYS AS (
    CASE WHEN altura_cm > 0
      THEN round((peso_kg / ((altura_cm / 100.0) ^ 2))::numeric, 2)
    ELSE NULL END
  ) STORED,
  percentual_gordura_bio numeric(5,2),
  massa_gorda_kg         numeric(6,2),
  massa_magra_kg         numeric(6,2),
  agua_corporal_pct      numeric(5,2),
  metabolismo_basal      integer,
  created_at             timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessment_circumferences (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id   uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  pescoco_cm      numeric(5,1), ombro_cm        numeric(5,1),
  torax_cm        numeric(5,1), cintura_cm      numeric(5,1),
  abdomen_cm      numeric(5,1), quadril_cm      numeric(5,1),
  braco_d_cm      numeric(5,1), braco_e_cm      numeric(5,1),
  antebraco_d_cm  numeric(5,1), antebraco_e_cm  numeric(5,1),
  coxa_d_cm       numeric(5,1), coxa_e_cm       numeric(5,1),
  panturrilha_d_cm numeric(5,1), panturrilha_e_cm numeric(5,1),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessment_skinfolds (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id        uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  protocolo            text NOT NULL DEFAULT 'jackson_pollock_7',
  triceps_mm           numeric(5,1), subescapular_mm  numeric(5,1),
  peitoral_mm          numeric(5,1), axilar_mm        numeric(5,1),
  suprailiaca_mm       numeric(5,1), abdominal_mm     numeric(5,1),
  coxa_mm              numeric(5,1), soma_dobras      numeric(7,1),
  percentual_gordura   numeric(5,2), densidade_corporal numeric(8,5),
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessment_posture (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id       uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  foto_anterior_url   text, foto_posterior_url  text,
  foto_lateral_d_url  text, foto_lateral_e_url  text,
  desvios             jsonb NOT NULL DEFAULT '[]'::jsonb,
  observacoes         text,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessment_vo2 (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id        uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  protocolo            text, fc_repouso           integer,
  fc_maxima_estimada   integer, resultado_bruto   numeric(8,3),
  vo2max_estimado      numeric(6,2), classificacao text,
  observacoes          text,
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assessment_strength (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id            uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  preensao_d_kg            numeric(5,1), preensao_e_kg          numeric(5,1),
  flexao_repeticoes        integer,      abdominal_repeticoes   integer,
  agachamento_repeticoes   integer,      rm_estimado_supino     numeric(6,1),
  rm_estimado_leg          numeric(6,1), observacoes            text,
  created_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_biometrics_assessment     ON assessment_biometrics(assessment_id);
CREATE INDEX IF NOT EXISTS idx_circumferences_assessment ON assessment_circumferences(assessment_id);
CREATE INDEX IF NOT EXISTS idx_skinfolds_assessment      ON assessment_skinfolds(assessment_id);
CREATE INDEX IF NOT EXISTS idx_posture_assessment        ON assessment_posture(assessment_id);
CREATE INDEX IF NOT EXISTS idx_vo2_assessment            ON assessment_vo2(assessment_id);
CREATE INDEX IF NOT EXISTS idx_strength_assessment       ON assessment_strength(assessment_id);

ALTER TABLE assessments               ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_biometrics     ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_circumferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_skinfolds      ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_posture        ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_vo2            ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_strength       ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "assessments_select" ON assessments;
CREATE POLICY "assessments_select" ON assessments FOR SELECT USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "assessments_insert" ON assessments;
CREATE POLICY "assessments_insert" ON assessments FOR INSERT WITH CHECK (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "assessments_update" ON assessments;
CREATE POLICY "assessments_update" ON assessments FOR UPDATE USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "assessments_delete" ON assessments;
CREATE POLICY "assessments_delete" ON assessments FOR DELETE USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "biometrics_select" ON assessment_biometrics;
CREATE POLICY "biometrics_select" ON assessment_biometrics FOR SELECT USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "biometrics_insert" ON assessment_biometrics;
CREATE POLICY "biometrics_insert" ON assessment_biometrics FOR INSERT WITH CHECK (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "biometrics_update" ON assessment_biometrics;
CREATE POLICY "biometrics_update" ON assessment_biometrics FOR UPDATE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "biometrics_delete" ON assessment_biometrics;
CREATE POLICY "biometrics_delete" ON assessment_biometrics FOR DELETE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));

DROP POLICY IF EXISTS "circumferences_select" ON assessment_circumferences;
CREATE POLICY "circumferences_select" ON assessment_circumferences FOR SELECT USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "circumferences_insert" ON assessment_circumferences;
CREATE POLICY "circumferences_insert" ON assessment_circumferences FOR INSERT WITH CHECK (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "circumferences_update" ON assessment_circumferences;
CREATE POLICY "circumferences_update" ON assessment_circumferences FOR UPDATE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "circumferences_delete" ON assessment_circumferences;
CREATE POLICY "circumferences_delete" ON assessment_circumferences FOR DELETE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));

DROP POLICY IF EXISTS "skinfolds_select" ON assessment_skinfolds;
CREATE POLICY "skinfolds_select" ON assessment_skinfolds FOR SELECT USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "skinfolds_insert" ON assessment_skinfolds;
CREATE POLICY "skinfolds_insert" ON assessment_skinfolds FOR INSERT WITH CHECK (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "skinfolds_update" ON assessment_skinfolds;
CREATE POLICY "skinfolds_update" ON assessment_skinfolds FOR UPDATE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "skinfolds_delete" ON assessment_skinfolds;
CREATE POLICY "skinfolds_delete" ON assessment_skinfolds FOR DELETE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));

DROP POLICY IF EXISTS "posture_select" ON assessment_posture;
CREATE POLICY "posture_select" ON assessment_posture FOR SELECT USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "posture_insert_public" ON assessment_posture;
CREATE POLICY "posture_insert_public" ON assessment_posture FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "posture_update" ON assessment_posture;
CREATE POLICY "posture_update" ON assessment_posture FOR UPDATE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "posture_delete" ON assessment_posture;
CREATE POLICY "posture_delete" ON assessment_posture FOR DELETE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));

DROP POLICY IF EXISTS "vo2_select" ON assessment_vo2;
CREATE POLICY "vo2_select" ON assessment_vo2 FOR SELECT USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "vo2_insert" ON assessment_vo2;
CREATE POLICY "vo2_insert" ON assessment_vo2 FOR INSERT WITH CHECK (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "vo2_update" ON assessment_vo2;
CREATE POLICY "vo2_update" ON assessment_vo2 FOR UPDATE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "vo2_delete" ON assessment_vo2;
CREATE POLICY "vo2_delete" ON assessment_vo2 FOR DELETE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));

DROP POLICY IF EXISTS "strength_select" ON assessment_strength;
CREATE POLICY "strength_select" ON assessment_strength FOR SELECT USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "strength_insert" ON assessment_strength;
CREATE POLICY "strength_insert" ON assessment_strength FOR INSERT WITH CHECK (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "strength_update" ON assessment_strength;
CREATE POLICY "strength_update" ON assessment_strength FOR UPDATE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));
DROP POLICY IF EXISTS "strength_delete" ON assessment_strength;
CREATE POLICY "strength_delete" ON assessment_strength FOR DELETE USING (assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())));


-- ══════════════════════════════════════════════════════════════
-- 3. CLIENTES (clients_schema.sql)
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS clients (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id  uuid        NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  name             text        NOT NULL,
  phone            text,
  email            text,
  dob              date,
  sex              text        CHECK (sex IN ('M','F','outro')),
  objetivo         text,
  observacoes      text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_clients_updated_at ON clients;
CREATE TRIGGER trg_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION _set_updated_at();

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clients_select" ON clients;
CREATE POLICY "clients_select" ON clients FOR SELECT USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "clients_insert" ON clients;
CREATE POLICY "clients_insert" ON clients FOR INSERT WITH CHECK (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "clients_update" ON clients;
CREATE POLICY "clients_update" ON clients FOR UPDATE USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "clients_delete" ON clients;
CREATE POLICY "clients_delete" ON clients FOR DELETE USING (professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_clients_professional ON clients(professional_id);

ALTER TABLE anamneses   ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES clients(id) ON DELETE SET NULL;
ALTER TABLE assessments ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES clients(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_anamneses_client  ON anamneses(client_id);
CREATE INDEX IF NOT EXISTS idx_assessments_client ON assessments(client_id);

DROP POLICY IF EXISTS "anamneses_update_via_client" ON anamneses;
CREATE POLICY "anamneses_update_via_client" ON anamneses FOR UPDATE USING (
  client_id IN (SELECT id FROM clients WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);

CREATE OR REPLACE VIEW clients_summary AS
SELECT
  c.id, c.professional_id, c.name, c.phone, c.sex, c.dob, c.created_at,
  COUNT(DISTINCT a.id)  AS total_anamneses,
  COUNT(DISTINCT av.id) AS total_avaliacoes,
  MAX(a.created_at)     AS ultima_anamnese,
  MAX(av.created_at)    AS ultima_avaliacao
FROM clients c
LEFT JOIN anamneses   a  ON a.client_id  = c.id
LEFT JOIN assessments av ON av.client_id = c.id
GROUP BY c.id;


-- ══════════════════════════════════════════════════════════════
-- 4. METAS (goals_schema.sql)
-- ══════════════════════════════════════════════════════════════

create table if not exists client_goals (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid not null references clients(id) on delete cascade,
  professional_id uuid not null references professionals(id) on delete cascade,
  title           text not null,
  description     text,
  category        text check (category in ('peso','gordura','circunferencia','vo2','forca','outro')),
  target_value    numeric, target_unit text, baseline_value numeric,
  current_value   numeric, deadline date,
  status          text not null default 'ativa' check (status in ('ativa','concluida','pausada','cancelada')),
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

create table if not exists goal_checkins (
  id          uuid primary key default gen_random_uuid(),
  goal_id     uuid not null references client_goals(id) on delete cascade,
  value       numeric not null,
  note        text,
  checked_at  timestamptz default now(),
  created_by  uuid references auth.users(id)
);

create index if not exists idx_goals_client       on client_goals(client_id);
create index if not exists idx_goals_professional on client_goals(professional_id);
create index if not exists idx_checkins_goal      on goal_checkins(goal_id);

drop trigger if exists trg_goals_updated_at on client_goals;
create trigger trg_goals_updated_at
  before update on client_goals
  for each row execute function _set_updated_at();

alter table client_goals  enable row level security;
alter table goal_checkins enable row level security;

drop policy if exists "goals: all for professional" on client_goals;
create policy "goals: all for professional" on client_goals for all
  using (professional_id in (select id from professionals where user_id = auth.uid()))
  with check (professional_id in (select id from professionals where user_id = auth.uid()));

drop policy if exists "checkins: all via goal" on goal_checkins;
create policy "checkins: all via goal" on goal_checkins for all
  using (goal_id in (select id from client_goals where professional_id in (select id from professionals where user_id = auth.uid())))
  with check (goal_id in (select id from client_goals where professional_id in (select id from professionals where user_id = auth.uid())));


-- ══════════════════════════════════════════════════════════════
-- 5. ORGANIZAÇÕES (organizations_schema.sql)
-- ══════════════════════════════════════════════════════════════

create table if not exists organizations (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  slug         text unique,
  plan         text not null default 'starter' check (plan in ('starter','pro','agency')),
  owner_id     uuid references auth.users(id) on delete set null,
  created_at   timestamptz default now()
);

create table if not exists organization_members (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  role             text not null default 'member' check (role in ('owner','admin','member')),
  created_at       timestamptz default now(),
  unique (organization_id, user_id)
);

alter table professionals add column if not exists organization_id uuid references organizations(id) on delete set null;

create index if not exists idx_professionals_org on professionals(organization_id);
create index if not exists idx_org_members_org   on organization_members(organization_id);
create index if not exists idx_org_members_user  on organization_members(user_id);

alter table organizations        enable row level security;
alter table organization_members enable row level security;

drop policy if exists "orgs: insert authenticated" on organizations;
create policy "orgs: insert authenticated" on organizations for insert to authenticated with check (true);
drop policy if exists "orgs: select members" on organizations;
create policy "orgs: select members" on organizations for select using (id in (select organization_id from organization_members where user_id = auth.uid()) or owner_id = auth.uid());
drop policy if exists "orgs: update owner" on organizations;
create policy "orgs: update owner" on organizations for update using (owner_id = auth.uid());
drop policy if exists "orgs: delete owner" on organizations;
create policy "orgs: delete owner" on organizations for delete using (owner_id = auth.uid());
drop policy if exists "org_members: select same org" on organization_members;
create policy "org_members: select same org" on organization_members for select using (organization_id in (select organization_id from organization_members where user_id = auth.uid()));
drop policy if exists "org_members: insert admin owner" on organization_members;
create policy "org_members: insert admin owner" on organization_members for insert to authenticated with check (organization_id in (select organization_id from organization_members where user_id = auth.uid() and role in ('owner','admin')));
drop policy if exists "org_members: delete admin owner self" on organization_members;
create policy "org_members: delete admin owner self" on organization_members for delete using (user_id = auth.uid() or organization_id in (select organization_id from organization_members where user_id = auth.uid() and role in ('owner','admin')));

create or replace function get_user_org() returns uuid language sql security definer stable as $$
  select organization_id from professionals where user_id = auth.uid() limit 1;
$$;

create or replace view org_professionals as
  select p.id, p.name, p.specialty, p.user_id, p.organization_id,
    count(distinct c.id) as total_clients, count(distinct a.id) as total_anamneses
  from professionals p
  left join clients   c on c.professional_id = p.id
  left join anamneses a on a.professional_id = p.id
  where p.organization_id = get_user_org()
  group by p.id;


-- ══════════════════════════════════════════════════════════════
-- 6. PORTAL DO CLIENTE (portal_schema.sql)
-- ══════════════════════════════════════════════════════════════

alter table clients add column if not exists portal_token            text;
alter table clients add column if not exists portal_token_expires_at timestamptz;
create index if not exists idx_clients_portal_token on clients(portal_token);

-- NOTA DE SEGURANÇA: policies abaixo permitem leitura pública via token.
-- Em produção real, substituir por Edge Function que valida server-side.
drop policy if exists "clients: portal token read" on clients;
create policy "clients: portal token read" on clients for select using (portal_token is not null and portal_token_expires_at > now());

drop policy if exists "assessments: portal read" on assessments;
create policy "assessments: portal read" on assessments for select using (client_id in (select id from clients where portal_token is not null and portal_token_expires_at > now()));

drop policy if exists "assessment_biometrics: portal read" on assessment_biometrics;
create policy "assessment_biometrics: portal read" on assessment_biometrics for select using (assessment_id in (select a.id from assessments a join clients c on c.id = a.client_id where c.portal_token is not null and c.portal_token_expires_at > now()));

drop policy if exists "assessment_circumferences: portal read" on assessment_circumferences;
create policy "assessment_circumferences: portal read" on assessment_circumferences for select using (assessment_id in (select a.id from assessments a join clients c on c.id = a.client_id where c.portal_token is not null and c.portal_token_expires_at > now()));

drop policy if exists "assessment_skinfolds: portal read" on assessment_skinfolds;
create policy "assessment_skinfolds: portal read" on assessment_skinfolds for select using (assessment_id in (select a.id from assessments a join clients c on c.id = a.client_id where c.portal_token is not null and c.portal_token_expires_at > now()));

drop policy if exists "assessment_vo2: portal read" on assessment_vo2;
create policy "assessment_vo2: portal read" on assessment_vo2 for select using (assessment_id in (select a.id from assessments a join clients c on c.id = a.client_id where c.portal_token is not null and c.portal_token_expires_at > now()));

drop policy if exists "assessment_strength: portal read" on assessment_strength;
create policy "assessment_strength: portal read" on assessment_strength for select using (assessment_id in (select a.id from assessments a join clients c on c.id = a.client_id where c.portal_token is not null and c.portal_token_expires_at > now()));

drop policy if exists "anamneses: portal read" on anamneses;
create policy "anamneses: portal read" on anamneses for select using (client_id in (select id from clients where portal_token is not null and portal_token_expires_at > now()));

drop policy if exists "goals: portal read" on client_goals;
create policy "goals: portal read" on client_goals for select using (client_id in (select id from clients where portal_token is not null and portal_token_expires_at > now()));


-- ══════════════════════════════════════════════════════════════
-- 7. MOBILIDADE E FORÇA (mobility_strength_update.sql)
-- ══════════════════════════════════════════════════════════════

ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS prancha_seg integer;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS salto_horizontal_cm numeric;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS barra_fixa_reps integer;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS barra_isometrica_seg integer;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS core_antirotacao jsonb default null;

CREATE TABLE IF NOT EXISTS assessment_mobility (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  overhead_squat_resultado text,
  overhead_squat_obs jsonb default '{}',
  mobilidade_ombro_d text, mobilidade_ombro_e text,
  toe_touch text,
  elevacao_perna_d text, elevacao_perna_e text,
  tornozelo_resultado text,
  observacoes_gerais text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assessment_mobility_assessment_id ON assessment_mobility(assessment_id);
ALTER TABLE assessment_mobility ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "professionals_own_mobility" ON assessment_mobility;
CREATE POLICY "professionals_own_mobility" ON assessment_mobility FOR ALL USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);


-- ══════════════════════════════════════════════════════════════
-- 8. PROTOCOLO DETALHES (protocols_update.sql)
-- ══════════════════════════════════════════════════════════════

alter table assessment_skinfolds add column if not exists protocolo_detalhes jsonb default null;
alter table assessment_vo2       add column if not exists protocolo_detalhes jsonb default null;


-- ═══════════════════════════════════════════════════════════════
-- Todos os schemas executados com sucesso.
-- ═══════════════════════════════════════════════════════════════
