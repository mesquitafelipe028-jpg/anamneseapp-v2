-- ============================================================
--  avaliacoes_schema.sql
--  Supabase — Módulo de Avaliação Física
-- ============================================================

-- ── 1. ASSESSMENTS ──────────────────────────────────────────
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

-- Migração: renomeia mode → modality para quem rodou o schema antigo
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'assessments' AND column_name = 'mode'
  ) THEN
    ALTER TABLE assessments RENAME COLUMN mode TO modality;
  END IF;
END $$;

-- Garante que modality exista (criação do zero sem a tabela)
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

-- ── 2. BIOMETRICS ────────────────────────────────────────────
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

CREATE INDEX IF NOT EXISTS idx_biometrics_assessment
  ON assessment_biometrics (assessment_id);

-- ── 3. CIRCUMFERENCES ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assessment_circumferences (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id   uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  pescoco_cm      numeric(5,1),
  ombro_cm        numeric(5,1),
  torax_cm        numeric(5,1),
  cintura_cm      numeric(5,1),
  abdomen_cm      numeric(5,1),
  quadril_cm      numeric(5,1),
  braco_d_cm      numeric(5,1),
  braco_e_cm      numeric(5,1),
  antebraco_d_cm  numeric(5,1),
  antebraco_e_cm  numeric(5,1),
  coxa_d_cm       numeric(5,1),
  coxa_e_cm       numeric(5,1),
  panturrilha_d_cm numeric(5,1),
  panturrilha_e_cm numeric(5,1),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_circumferences_assessment
  ON assessment_circumferences (assessment_id);

-- ── 4. SKINFOLDS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assessment_skinfolds (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id        uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  protocolo            text NOT NULL DEFAULT 'jackson_pollock_7',
  triceps_mm           numeric(5,1),
  subescapular_mm      numeric(5,1),
  peitoral_mm          numeric(5,1),
  axilar_mm            numeric(5,1),
  suprailiaca_mm       numeric(5,1),
  abdominal_mm         numeric(5,1),
  coxa_mm              numeric(5,1),
  soma_dobras          numeric(7,1),
  percentual_gordura   numeric(5,2),
  densidade_corporal   numeric(8,5),
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_skinfolds_assessment
  ON assessment_skinfolds (assessment_id);

-- ── 5. POSTURE ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assessment_posture (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id       uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  foto_anterior_url   text,
  foto_posterior_url  text,
  foto_lateral_d_url  text,
  foto_lateral_e_url  text,
  desvios             jsonb NOT NULL DEFAULT '[]'::jsonb,
  observacoes         text,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_posture_assessment
  ON assessment_posture (assessment_id);

-- ── 6. VO2 ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assessment_vo2 (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id        uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  protocolo            text,
  fc_repouso           integer,
  fc_maxima_estimada   integer,
  resultado_bruto      numeric(8,3),
  vo2max_estimado      numeric(6,2),
  classificacao        text,
  observacoes          text,
  created_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vo2_assessment
  ON assessment_vo2 (assessment_id);

-- ── 7. STRENGTH ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS assessment_strength (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id            uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  preensao_d_kg            numeric(5,1),
  preensao_e_kg            numeric(5,1),
  flexao_repeticoes        integer,
  abdominal_repeticoes     integer,
  agachamento_repeticoes   integer,
  rm_estimado_supino       numeric(6,1),
  rm_estimado_leg          numeric(6,1),
  observacoes              text,
  created_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_strength_assessment
  ON assessment_strength (assessment_id);

-- ============================================================
--  RLS
-- ============================================================

ALTER TABLE assessments               ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_biometrics     ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_circumferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_skinfolds      ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_posture        ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_vo2            ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_strength       ENABLE ROW LEVEL SECURITY;

-- ── assessments ──────────────────────────────────────────────
DROP POLICY IF EXISTS "assessments_select" ON assessments;
CREATE POLICY "assessments_select" ON assessments
  FOR SELECT USING (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "assessments_insert" ON assessments;
CREATE POLICY "assessments_insert" ON assessments
  FOR INSERT WITH CHECK (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "assessments_update" ON assessments;
CREATE POLICY "assessments_update" ON assessments
  FOR UPDATE USING (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "assessments_delete" ON assessments;
CREATE POLICY "assessments_delete" ON assessments
  FOR DELETE USING (
    professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
  );

-- ── assessment_biometrics ────────────────────────────────────
DROP POLICY IF EXISTS "biometrics_select" ON assessment_biometrics;
CREATE POLICY "biometrics_select" ON assessment_biometrics FOR SELECT USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "biometrics_insert" ON assessment_biometrics;
CREATE POLICY "biometrics_insert" ON assessment_biometrics FOR INSERT WITH CHECK (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "biometrics_update" ON assessment_biometrics;
CREATE POLICY "biometrics_update" ON assessment_biometrics FOR UPDATE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "biometrics_delete" ON assessment_biometrics;
CREATE POLICY "biometrics_delete" ON assessment_biometrics FOR DELETE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);

-- ── assessment_circumferences ────────────────────────────────
DROP POLICY IF EXISTS "circumferences_select" ON assessment_circumferences;
CREATE POLICY "circumferences_select" ON assessment_circumferences FOR SELECT USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "circumferences_insert" ON assessment_circumferences;
CREATE POLICY "circumferences_insert" ON assessment_circumferences FOR INSERT WITH CHECK (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "circumferences_update" ON assessment_circumferences;
CREATE POLICY "circumferences_update" ON assessment_circumferences FOR UPDATE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "circumferences_delete" ON assessment_circumferences;
CREATE POLICY "circumferences_delete" ON assessment_circumferences FOR DELETE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);

-- ── assessment_skinfolds ─────────────────────────────────────
DROP POLICY IF EXISTS "skinfolds_select" ON assessment_skinfolds;
CREATE POLICY "skinfolds_select" ON assessment_skinfolds FOR SELECT USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "skinfolds_insert" ON assessment_skinfolds;
CREATE POLICY "skinfolds_insert" ON assessment_skinfolds FOR INSERT WITH CHECK (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "skinfolds_update" ON assessment_skinfolds;
CREATE POLICY "skinfolds_update" ON assessment_skinfolds FOR UPDATE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "skinfolds_delete" ON assessment_skinfolds;
CREATE POLICY "skinfolds_delete" ON assessment_skinfolds FOR DELETE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);

-- ── assessment_posture ───────────────────────────────────────
DROP POLICY IF EXISTS "posture_select" ON assessment_posture;
CREATE POLICY "posture_select" ON assessment_posture FOR SELECT USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "posture_insert_public" ON assessment_posture;
CREATE POLICY "posture_insert_public" ON assessment_posture
  FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "posture_update" ON assessment_posture;
CREATE POLICY "posture_update" ON assessment_posture FOR UPDATE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "posture_delete" ON assessment_posture;
CREATE POLICY "posture_delete" ON assessment_posture FOR DELETE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);

-- ── assessment_vo2 ───────────────────────────────────────────
DROP POLICY IF EXISTS "vo2_select" ON assessment_vo2;
CREATE POLICY "vo2_select" ON assessment_vo2 FOR SELECT USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "vo2_insert" ON assessment_vo2;
CREATE POLICY "vo2_insert" ON assessment_vo2 FOR INSERT WITH CHECK (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "vo2_update" ON assessment_vo2;
CREATE POLICY "vo2_update" ON assessment_vo2 FOR UPDATE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "vo2_delete" ON assessment_vo2;
CREATE POLICY "vo2_delete" ON assessment_vo2 FOR DELETE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);

-- ── assessment_strength ──────────────────────────────────────
DROP POLICY IF EXISTS "strength_select" ON assessment_strength;
CREATE POLICY "strength_select" ON assessment_strength FOR SELECT USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "strength_insert" ON assessment_strength;
CREATE POLICY "strength_insert" ON assessment_strength FOR INSERT WITH CHECK (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "strength_update" ON assessment_strength;
CREATE POLICY "strength_update" ON assessment_strength FOR UPDATE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
DROP POLICY IF EXISTS "strength_delete" ON assessment_strength;
CREATE POLICY "strength_delete" ON assessment_strength FOR DELETE USING (
  assessment_id IN (SELECT id FROM assessments WHERE professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid()))
);
