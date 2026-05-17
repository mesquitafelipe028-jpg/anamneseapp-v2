CREATE TABLE IF NOT EXISTS consultation_checklists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id uuid REFERENCES assessments(id) ON DELETE CASCADE,
  client_id uuid REFERENCES clients(id) ON DELETE CASCADE,
  professional_id uuid NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  items jsonb NOT NULL DEFAULT '[]',
  notes text,
  consultation_date date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE consultation_checklists ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prof_own_chk" ON consultation_checklists FOR ALL USING (
  professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
);
CREATE INDEX IF NOT EXISTS chk_asm_idx ON consultation_checklists(assessment_id);
CREATE INDEX IF NOT EXISTS chk_cli_idx ON consultation_checklists(client_id);
