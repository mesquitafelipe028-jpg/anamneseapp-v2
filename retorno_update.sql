ALTER TABLE anamneses DROP CONSTRAINT IF EXISTS anamneses_mode_check;
ALTER TABLE anamneses ADD CONSTRAINT anamneses_mode_check
  CHECK (mode IN ('online','presencial','retorno'));
