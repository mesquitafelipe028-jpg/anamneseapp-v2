-- ═══════════════════════════════════════════════════════════════
-- AnamneseApp — Portal do Cliente (token de acesso)
-- Execute no Supabase → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════════

-- ── 1. COLUNAS DE TOKEN ──────────────────────────────────────────
alter table clients add column if not exists portal_token            text;
alter table clients add column if not exists portal_token_expires_at timestamptz;

-- Índice para busca rápida por token
create index if not exists idx_clients_portal_token on clients(portal_token);

-- ── 2. RLS PORTAL ────────────────────────────────────────────────
-- NOTA DE SEGURANÇA: estas policies permitem leitura pública de linhas
-- cujo portal_token é válido. Em produção, substituir por Supabase Edge Function
-- que valida o token server-side e retorna os dados sem expor RLS.

-- clients: leitura pública quando token válido e não expirado
drop policy if exists "clients: portal token read" on clients;
create policy "clients: portal token read"
  on clients for select
  using (
    portal_token is not null
    and portal_token_expires_at > now()
  );

-- assessments: leitura via portal (client tem token válido)
drop policy if exists "assessments: portal read" on assessments;
create policy "assessments: portal read"
  on assessments for select
  using (
    client_id in (
      select id from clients
      where portal_token is not null
        and portal_token_expires_at > now()
    )
  );

-- assessment_biometrics
drop policy if exists "assessment_biometrics: portal read" on assessment_biometrics;
create policy "assessment_biometrics: portal read"
  on assessment_biometrics for select
  using (
    assessment_id in (
      select a.id from assessments a
      join clients c on c.id = a.client_id
      where c.portal_token is not null and c.portal_token_expires_at > now()
    )
  );

-- assessment_circumferences
drop policy if exists "assessment_circumferences: portal read" on assessment_circumferences;
create policy "assessment_circumferences: portal read"
  on assessment_circumferences for select
  using (
    assessment_id in (
      select a.id from assessments a
      join clients c on c.id = a.client_id
      where c.portal_token is not null and c.portal_token_expires_at > now()
    )
  );

-- assessment_skinfolds
drop policy if exists "assessment_skinfolds: portal read" on assessment_skinfolds;
create policy "assessment_skinfolds: portal read"
  on assessment_skinfolds for select
  using (
    assessment_id in (
      select a.id from assessments a
      join clients c on c.id = a.client_id
      where c.portal_token is not null and c.portal_token_expires_at > now()
    )
  );

-- assessment_vo2
drop policy if exists "assessment_vo2: portal read" on assessment_vo2;
create policy "assessment_vo2: portal read"
  on assessment_vo2 for select
  using (
    assessment_id in (
      select a.id from assessments a
      join clients c on c.id = a.client_id
      where c.portal_token is not null and c.portal_token_expires_at > now()
    )
  );

-- assessment_strength
drop policy if exists "assessment_strength: portal read" on assessment_strength;
create policy "assessment_strength: portal read"
  on assessment_strength for select
  using (
    assessment_id in (
      select a.id from assessments a
      join clients c on c.id = a.client_id
      where c.portal_token is not null and c.portal_token_expires_at > now()
    )
  );

-- anamneses: leitura via portal
drop policy if exists "anamneses: portal read" on anamneses;
create policy "anamneses: portal read"
  on anamneses for select
  using (
    client_id in (
      select id from clients
      where portal_token is not null
        and portal_token_expires_at > now()
    )
  );

-- client_goals: leitura via portal
drop policy if exists "goals: portal read" on client_goals;
create policy "goals: portal read"
  on client_goals for select
  using (
    client_id in (
      select id from clients
      where portal_token is not null
        and portal_token_expires_at > now()
    )
  );
