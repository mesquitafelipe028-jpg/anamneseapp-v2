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

O projeto usa um build script (`build.js`) que gera `config.js` automaticamente durante o deploy, injetando as chaves Supabase a partir das variáveis de ambiente do Vercel.

### 1. Configurar variáveis de ambiente no Vercel

No painel do Vercel, acesse seu projeto → **Settings → Environment Variables** e adicione:

| Variável | Valor | Ambientes |
|---|---|---|
| `SUPABASE_URL` | `https://seu-projeto.supabase.co` | Production, Preview, Development |
| `SUPABASE_ANON` | `sua-anon-key` | Production, Preview, Development |

### 2. Deploy

O `vercel.json` já configura `"buildCommand": "node build.js"`. A cada deploy, o Vercel:

1. Roda `node build.js`
2. O script lê `SUPABASE_URL` e `SUPABASE_ANON` do ambiente
3. Gera `config.js` a partir de `config.template.js`
4. Serve os arquivos estáticos (incluindo o `config.js` gerado)

```bash
# Deploy via Vercel CLI
npm i -g vercel
vercel login
vercel --prod
```

### Rotas configuradas (vercel.json)

| URL | Arquivo |
|---|---|
| `/` | index.html |
| `/dashboard` | dashboard.html |
| `/anamnese` | anamnese.html |
| `/avaliacao` | avaliacao.html |

## Estrutura de arquivos

```
├── index.html            — Landing page e auto-redirect
├── dashboard.html        — Painel do profissional (SPA)
├── anamnese.html         — Formulário de anamnese (público)
├── avaliacao.html        — Avaliação física (6 módulos)
├── sw.js                 — Service Worker (PWA cache)
├── manifest.json         — Metadados PWA
├── icon.svg              — Ícone da aplicação
├── build.js              — Build script: gera config.js a partir de env vars
├── config.template.js    — Template de config (placeholders __SUPABASE_URL__ etc.)
├── config.example.js     — Exemplo de config para dev local
├── config.js             — Gerado pelo build (gitignored — não commitar)
├── vercel.json           — Rotas + buildCommand
├── schema.sql            — Schema principal (executar primeiro)
├── avaliacoes_schema.sql — Schema de avaliações (executar segundo)
└── clients_schema.sql    — Schema de clientes (executar terceiro)
```

## Tecnologias

- HTML + CSS + JavaScript puro (sem framework)
- [Supabase](https://supabase.com) — autenticação, banco de dados PostgreSQL, storage
- [jsPDF](https://github.com/parallax/jsPDF) — geração de PDF no browser
- Vercel — hosting estático com rotas customizadas e build script
- PWA — Service Worker, manifest, installable
