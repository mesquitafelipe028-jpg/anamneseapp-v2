-- ═══════════════════════════════════════════════════════════════
-- AnamneseApp — Schema de Metas dos Clientes
-- Execute no Supabase → SQL Editor → New Query
-- Ordem: após clients_schema.sql
-- ═══════════════════════════════════════════════════════════════

-- ── 1. CLIENT_GOALS ──────────────────────────────────────────────
create table if not exists client_goals (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid not null references clients(id) on delete cascade,
  professional_id uuid not null references professionals(id) on delete cascade,
  title           text not null,
  description     text,
  category        text check (category in ('peso','gordura','circunferencia','vo2','forca','outro')),
  target_value    numeric,
  target_unit     text,
  baseline_value  numeric,
  current_value   numeric,
  deadline        date,
  status          text not null default 'ativa' check (status in ('ativa','concluida','pausada','cancelada')),
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- ── 2. GOAL_CHECKINS ─────────────────────────────────────────────
create table if not exists goal_checkins (
  id          uuid primary key default gen_random_uuid(),
  goal_id     uuid not null references client_goals(id) on delete cascade,
  value       numeric not null,
  note        text,
  checked_at  timestamptz default now(),
  created_by  uuid references auth.users(id)
);

-- ── 3. ÍNDICES ───────────────────────────────────────────────────
create index if not exists idx_goals_client       on client_goals(client_id);
create index if not exists idx_goals_professional on client_goals(professional_id);
create index if not exists idx_checkins_goal      on goal_checkins(goal_id);

-- ── 4. TRIGGER updated_at ────────────────────────────────────────
create or replace function _set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists trg_goals_updated_at on client_goals;
create trigger trg_goals_updated_at
  before update on client_goals
  for each row execute function _set_updated_at();

-- ── 5. RLS ───────────────────────────────────────────────────────
alter table client_goals  enable row level security;
alter table goal_checkins enable row level security;

-- client_goals: todas as operações para o profissional dono
drop policy if exists "goals: all for professional" on client_goals;
create policy "goals: all for professional"
  on client_goals for all
  using (
    professional_id in (
      select id from professionals where user_id = auth.uid()
    )
  )
  with check (
    professional_id in (
      select id from professionals where user_id = auth.uid()
    )
  );

-- goal_checkins: acesso via goal → professional
drop policy if exists "checkins: all via goal" on goal_checkins;
create policy "checkins: all via goal"
  on goal_checkins for all
  using (
    goal_id in (
      select id from client_goals
      where professional_id in (
        select id from professionals where user_id = auth.uid()
      )
    )
  )
  with check (
    goal_id in (
      select id from client_goals
      where professional_id in (
        select id from professionals where user_id = auth.uid()
      )
    )
  );
