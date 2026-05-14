-- AnamneseApp — Atualização de protocolos expandidos
-- Adiciona coluna para salvar inputs detalhados de qualquer protocolo
alter table assessment_skinfolds add column if not exists protocolo_detalhes jsonb default null;
alter table assessment_vo2       add column if not exists protocolo_detalhes jsonb default null;
