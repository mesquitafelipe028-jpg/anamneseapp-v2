-- ============================================================
--  clients_schema.sql
--  Supabase — Módulo de Clientes
--  Cole este SQL no Supabase > SQL Editor > New Query
-- ============================================================

-- ── 1. CLIENTS ───────────────────────────────────────────────
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

-- Reutiliza a função de updated_at criada em avaliacoes_schema.sql
CREATE OR REPLACE FUNCTION _set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_clients_updated_at ON clients;
CREATE TRIGGER trg_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION _set_updated_at();

-- ── 2. RLS ───────────────────────────────────────────────────
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clients_select" ON clients
  FOR SELECT USING (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

CREATE POLICY "clients_insert" ON clients
  FOR INSERT WITH CHECK (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

CREATE POLICY "clients_update" ON clients
  FOR UPDATE USING (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

CREATE POLICY "clients_delete" ON clients
  FOR DELETE USING (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

-- ── 3. ÍNDICE ────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_clients_professional
  ON clients (professional_id);

-- ── 4. COLUNAS client_id NAS TABELAS EXISTENTES ──────────────
ALTER TABLE anamneses
  ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES clients(id) ON DELETE SET NULL;

ALTER TABLE assessments
  ADD COLUMN IF NOT EXISTS client_id uuid REFERENCES clients(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_anamneses_client
  ON anamneses (client_id);

CREATE INDEX IF NOT EXISTS idx_assessments_client
  ON assessments (client_id);

-- Policy de update via client_id (complementa a policy existente em schema.sql)
CREATE POLICY "anamneses_update_via_client" ON anamneses
  FOR UPDATE USING (
    client_id IN (
      SELECT id FROM clients
      WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
    )
  );

-- ── 5. VIEW clients_summary ──────────────────────────────────
CREATE OR REPLACE VIEW clients_summary AS
SELECT
  c.id,
  c.professional_id,
  c.name,
  c.phone,
  c.sex,
  c.dob,
  c.created_at,
  COUNT(DISTINCT a.id)  AS total_anamneses,
  COUNT(DISTINCT av.id) AS total_avaliacoes,
  MAX(a.created_at)     AS ultima_anamnese,
  MAX(av.created_at)    AS ultima_avaliacao
FROM clients c
LEFT JOIN anamneses   a  ON a.client_id  = c.id
LEFT JOIN assessments av ON av.client_id = c.id
GROUP BY c.id;
