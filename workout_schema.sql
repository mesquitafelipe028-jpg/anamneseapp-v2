CREATE TABLE IF NOT EXISTS workout_prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  professional_id uuid NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  title text NOT NULL,
  content text NOT NULL,
  type text DEFAULT 'musculacao' CHECK (type IN ('musculacao','cardio','funcional','pilates','yoga','outro')),
  status text DEFAULT 'ativa' CHECK (status IN ('ativa','pausada','encerrada')),
  valid_from date DEFAULT CURRENT_DATE,
  valid_until date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE workout_prescriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prof_own" ON workout_prescriptions FOR ALL USING (
  professional_id IN (SELECT id FROM professionals WHERE user_id = auth.uid())
);
CREATE INDEX IF NOT EXISTS wp_client_idx ON workout_prescriptions(client_id);
CREATE INDEX IF NOT EXISTS wp_prof_idx ON workout_prescriptions(professional_id);
