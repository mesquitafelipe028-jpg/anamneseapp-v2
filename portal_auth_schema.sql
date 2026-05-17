-- Adiciona colunas de autenticação ao portal do aluno
ALTER TABLE clients ADD COLUMN IF NOT EXISTS portal_email text;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS portal_password text;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS portal_session text;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS portal_session_expires timestamptz;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS portal_last_login timestamptz;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS portal_access_enabled boolean DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_clients_portal_email ON clients(portal_email);

-- Policy: portal lê dados próprios via session token (filtro no JS)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='clients' AND policyname='portal: client reads own data via session'
  ) THEN
    CREATE POLICY "portal: client reads own data via session" ON clients
      FOR SELECT USING (true);
  END IF;
END$$;
