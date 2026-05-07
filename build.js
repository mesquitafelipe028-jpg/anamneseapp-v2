#!/usr/bin/env node
// Build script: gera config.js a partir de config.template.js + env vars do Vercel
// Rodado automaticamente pelo Vercel antes do deploy (buildCommand em vercel.json)
// Uso local: node build.js (requer SUPABASE_URL e SUPABASE_ANON no ambiente)

const fs = require('fs');
const path = require('path');

const url  = process.env.SUPABASE_URL;
const anon = process.env.SUPABASE_ANON;

if (!url || !anon) {
  console.warn('[build] SUPABASE_URL ou SUPABASE_ANON não definidas.');
  console.warn('[build] Pulando geração de config.js — usando arquivo local existente.');
  process.exit(0);
}

const tplPath = path.join(__dirname, 'config.template.js');
const outPath = path.join(__dirname, 'config.js');

let tpl = fs.readFileSync(tplPath, 'utf8');
tpl = tpl
  .replace('__SUPABASE_URL__',  url)
  .replace('__SUPABASE_ANON__', anon);

fs.writeFileSync(outPath, tpl);
console.log('[build] config.js gerado com sucesso a partir das variáveis de ambiente.');
