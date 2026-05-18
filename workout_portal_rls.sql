-- Permite que o portal (anon) leia prescrições pelo client_id
-- O filtro por client_id é feito no JS, igual ao padrão das outras tabelas do portal
DROP POLICY IF EXISTS "wp_portal_select" ON workout_prescriptions;
CREATE POLICY "wp_portal_select" ON workout_prescriptions
  FOR SELECT USING (true);
