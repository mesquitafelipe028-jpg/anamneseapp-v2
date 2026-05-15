-- ═══════════════════════════════════════════════════════════════
-- AnamneseApp — Execução completa de todos os schemas
-- Cole no Supabase SQL Editor e execute de uma vez.
-- Ordem importa: cada schema depende do anterior.
-- ═══════════════════════════════════════════════════════════════

-- ── 1. SCHEMA PRINCIPAL ──────────────────────────────────────────
-- professionals, anamneses, form_templates

\i schema.sql

-- ── 2. AVALIAÇÕES ────────────────────────────────────────────────
-- assessments + 7 subtabelas (biometrics, circumferences, skinfolds,
-- posture, vo2, strength, mobility setup básico)

\i avaliacoes_schema.sql

-- ── 3. CLIENTES ──────────────────────────────────────────────────
-- clients, clients_summary view

\i clients_schema.sql

-- ── 4. METAS ─────────────────────────────────────────────────────
-- client_goals, goal_checkins, trigger de progresso

\i goals_schema.sql

-- ── 5. ORGANIZAÇÕES ──────────────────────────────────────────────
-- organizations, organization_members, get_user_org()

\i organizations_schema.sql

-- ── 6. PORTAL DO CLIENTE ─────────────────────────────────────────
-- portal_token + portal_token_expires_at em clients + RLS público

\i portal_schema.sql

-- ── 7. MOBILIDADE E FORÇA (expansão) ─────────────────────────────
-- assessment_mobility (CREATE TABLE)
-- + novas colunas em assessment_strength

\i mobility_strength_update.sql

-- ── 8. PROTOCOLO DETALHES ────────────────────────────────────────
-- protocolo_detalhes jsonb em assessment_skinfolds e assessment_vo2

\i protocols_update.sql

-- ═══════════════════════════════════════════════════════════════
-- Todos os schemas executados com sucesso.
-- ═══════════════════════════════════════════════════════════════
