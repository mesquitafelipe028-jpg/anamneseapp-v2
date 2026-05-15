# AnamneseApp — Setup do Banco de Dados

Execute os schemas no Supabase **SQL Editor** na ordem exata abaixo.
Cada arquivo é idempotente (`IF NOT EXISTS`) — pode ser re-executado sem risco.

## Ordem de execução

| # | Arquivo | O que cria |
|---|---------|-----------|
| 1 | `schema.sql` | Tabelas `professionals`, `anamneses`, `form_templates` + RLS |
| 2 | `avaliacoes_schema.sql` | Tabela `assessments` + 7 subtabelas de avaliação física |
| 3 | `clients_schema.sql` | Tabela `clients` + view `clients_summary` |
| 4 | `goals_schema.sql` | Tabelas `client_goals`, `goal_checkins` + trigger de progresso |
| 5 | `organizations_schema.sql` | Tabelas `organizations`, `organization_members` + função `get_user_org()` |
| 6 | `portal_schema.sql` | Colunas `portal_token` e `portal_token_expires_at` em `clients` + RLS público |
| 7 | `mobility_strength_update.sql` | Tabela `assessment_mobility` + novas colunas em `assessment_strength` |
| 8 | `protocols_update.sql` | Coluna `protocolo_detalhes jsonb` em `assessment_skinfolds` e `assessment_vo2` |

## Execução rápida (todos de uma vez)

Use o arquivo `run_all_schemas.sql` que concatena tudo na ordem correta:

```
Supabase Dashboard → SQL Editor → New query → cole o conteúdo de run_all_schemas.sql → Run
```

## Variáveis de ambiente (Vercel)

Configure no painel do Vercel em **Settings → Environment Variables**:

| Variável | Valor |
|----------|-------|
| `SUPABASE_URL` | URL do projeto Supabase (`https://xxx.supabase.co`) |
| `SUPABASE_ANON` | Chave anon pública do Supabase |

O `build.js` gera `config.js` automaticamente no deploy. Sem essas variáveis o deploy falha com erro visível.

## Desenvolvimento local

Crie um `config.js` na raiz com:

```js
const _SBU  = 'https://seu-projeto.supabase.co';
const _SBA  = 'sua-anon-key';
```

O `build.js` detecta o arquivo local e pula a geração (exit 0).
