-- AnamneseApp — Mobilidade e expansão de Força
-- Novos campos em assessment_strength
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS prancha_seg integer;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS salto_horizontal_cm numeric;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS barra_fixa_reps integer;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS barra_isometrica_seg integer;
ALTER TABLE assessment_strength ADD COLUMN IF NOT EXISTS core_antirotacao jsonb default null;

-- Nova tabela assessment_mobility
CREATE TABLE IF NOT EXISTS assessment_mobility (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id uuid NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  overhead_squat_resultado text,
  overhead_squat_obs jsonb default '{}',
  mobilidade_ombro_d text,
  mobilidade_ombro_e text,
  toe_touch text,
  elevacao_perna_d text,
  elevacao_perna_e text,
  tornozelo_resultado text,
  observacoes_gerais text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_assessment_mobility_assessment_id ON assessment_mobility(assessment_id);

ALTER TABLE assessment_mobility ENABLE ROW LEVEL SECURITY;

CREATE POLICY "professionals_own_mobility" ON assessment_mobility
  FOR ALL USING (
    assessment_id IN (
      SELECT id FROM assessments WHERE professional_id = auth.uid()
    )
  );
