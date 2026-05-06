# AnamneseApp

PWA para profissionais de saúde gerenciarem fichas de anamnese digitais, clientes e avaliações físicas completas.

## Funcionalidades

- Formulário de anamnese online e presencial com campos customizáveis
- Dashboard com CRM de clientes, fichas e avaliações
- Avaliação física com 6 módulos: Biometria, Circunferências, Dobras Cutâneas, Postural, VO2 Máx, Força
- Cálculos automáticos: IMC, % gordura (JP7/JP3), VO2max (Cooper/Rockport/Harvard), 1RM Brzycki
- Geração de PDF para anamnese e avaliação
- Integração WhatsApp para envio de resultados
- PWA installável com suporte offline
- Autenticação via Supabase

## Configuração local

### 1. Criar config.js

Copie `config.example.js` para `config.js` e preencha com suas chaves do Supabase:

```bash
cp config.example.js config.js
```

Edite `config.js`:

```js
window.SUPABASE_URL  = 'https://SEU-PROJETO.supabase.co';
window.SUPABASE_ANON = 'sua-anon-key-aqui';
```

As chaves estão em: **supabase.com → seu projeto → Settings → API**

> **IMPORTANTE:** `config.js` está no `.gitignore` e nunca deve ser commitado.

### 2. Executar os schemas SQL

Execute os arquivos SQL no Supabase **nesta ordem** via SQL Editor (supabase.com → seu projeto → SQL Editor):

1. `schema.sql` — tabelas principais: `professionals`, `anamneses`, `form_templates`
2. `avaliacoes_schema.sql` — tabelas de avaliação física (7 tabelas + RLS)
3. `clients_schema.sql` — tabela `clients`, FK em anamneses/assessments, view `clients_summary`

> Execute cada arquivo separadamente e verifique se não há erros antes de prosseguir.

### 3. Configurar Supabase Storage (para fotos de avaliação)

No painel do Supabase, crie um bucket chamado `assessment-photos` com acesso público de leitura.

## Deploy no Vercel

### Configurar variáveis de ambiente

No painel do Vercel, acesse seu projeto → **Settings → Environment Variables** e adicione:

| Variável | Valor |
|---|---|
| (nenhuma) | — |

> Como o projeto usa HTML estático puro (sem Node/bundler), as credenciais ficam em `config.js`. No Vercel, faça upload manual do arquivo via **Settings → Files** ou use a Vercel CLI.

### Deploy via Vercel CLI

```bash
npm i -g vercel
vercel login
vercel --prod
```

Antes do deploy, certifique-se de que `config.js` existe localmente com as credenciais corretas — ele não está no git.

### Rotas configuradas (vercel.json)

| URL | Arquivo |
|---|---|
| `/` | index.html |
| `/dashboard` | dashboard.html |
| `/anamnese` | anamnese.html |
| `/avaliacao` | avaliacao.html |

## Estrutura de arquivos

```
├── index.html          — Landing page e auto-redirect
├── dashboard.html      — Painel do profissional (SPA)
├── anamnese.html       — Formulário de anamnese (público)
├── avaliacao.html      — Avaliação física (6 módulos)
├── sw.js               — Service Worker (PWA cache)
├── manifest.json       — Metadados PWA
├── icon.svg            — Ícone da aplicação
├── config.js           — Credenciais Supabase (NÃO commitar, criar localmente)
├── config.example.js   — Template de configuração
├── vercel.json         — Configuração de rotas
├── schema.sql          — Schema principal (executar primeiro)
├── avaliacoes_schema.sql — Schema de avaliações (executar segundo)
└── clients_schema.sql  — Schema de clientes (executar terceiro)
```

## Tecnologias

- HTML + CSS + JavaScript puro (sem framework)
- [Supabase](https://supabase.com) — autenticação, banco de dados PostgreSQL, storage
- [jsPDF](https://github.com/parallax/jsPDF) — geração de PDF no browser
- Vercel — hosting estático com rotas customizadas
- PWA — Service Worker, manifest, installable
