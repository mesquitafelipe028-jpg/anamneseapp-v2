#!/usr/bin/env node
// Build script: gera config.js a partir de config.template.js + env vars do Vercel
// Rodado automaticamente pelo Vercel antes do deploy (buildCommand em vercel.json)
// Uso local: node build.js (requer SUPABASE_URL e SUPABASE_ANON no ambiente)

const fs = require('fs');
const path = require('path');

const url  = process.env.SUPABASE_URL;
const anon = process.env.SUPABASE_ANON;

if (!url || !anon) {
  if (fs.existsSync(path.join(__dirname, 'config.js'))) {
    console.warn('[build] Usando config.js local existente (env vars não definidas).');
    process.exit(0);
  }
  console.error('[build] ERRO: SUPABASE_URL e SUPABASE_ANON são obrigatórias no Vercel.');
  console.error('[build] Configure as variáveis de ambiente no painel do Vercel.');
  process.exit(1);
}

const tplPath = path.join(__dirname, 'config.template.js');
const outPath = path.join(__dirname, 'config.js');

let tpl = fs.readFileSync(tplPath, 'utf8');
tpl = tpl
  .replace('__SUPABASE_URL__',  url)
  .replace('__SUPABASE_ANON__', anon);

fs.writeFileSync(outPath, tpl);
console.log('[build] config.js gerado com sucesso a partir das variáveis de ambiente.');
