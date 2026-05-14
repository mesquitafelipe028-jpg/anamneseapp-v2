-- ═══════════════════════════════════════════════════════════════
-- AnamneseApp — Schema Multi-Profissional (Organizations)
-- Execute no Supabase → SQL Editor → New Query
-- Ordem: após schema.sql, avaliacoes_schema.sql e clients_schema.sql
-- ═══════════════════════════════════════════════════════════════

-- ── 1. ORGANIZATIONS ─────────────────────────────────────────────
create table if not exists organizations (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  slug         text unique,
  plan         text not null default 'starter' check (plan in ('starter','pro','agency')),
  owner_id     uuid references auth.users(id) on delete set null,
  created_at   timestamptz default now()
);

-- ── 2. ORGANIZATION_MEMBERS ──────────────────────────────────────
create table if not exists organization_members (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  user_id          uuid not null references auth.users(id) on delete cascade,
  role             text not null default 'member' check (role in ('owner','admin','member')),
  created_at       timestamptz default now(),
  unique (organization_id, user_id)
);

-- ── 3. ALTERA PROFESSIONALS ──────────────────────────────────────
alter table professionals
  add column if not exists organization_id uuid references organizations(id) on delete set null;

-- ── 4. ÍNDICES ───────────────────────────────────────────────────
create index if not exists idx_professionals_org    on professionals(organization_id);
create index if not exists idx_org_members_org      on organization_members(organization_id);
create index if not exists idx_org_members_user     on organization_members(user_id);

-- ── 5. RLS ───────────────────────────────────────────────────────
alter table organizations        enable row level security;
alter table organization_members enable row level security;

-- organizations: qualquer autenticado pode criar
drop policy if exists "orgs: insert authenticated" on organizations;
create policy "orgs: insert authenticated"
  on organizations for insert to authenticated
  with check (true);

-- organizations: membros da org podem ler
drop policy if exists "orgs: select members" on organizations;
create policy "orgs: select members"
  on organizations for select
  using (
    id in (
      select organization_id from organization_members
      where user_id = auth.uid()
    )
    or owner_id = auth.uid()
  );

-- organizations: owner pode atualizar
drop policy if exists "orgs: update owner" on organizations;
create policy "orgs: update owner"
  on organizations for update
  using (owner_id = auth.uid());

-- organizations: owner pode excluir
drop policy if exists "orgs: delete owner" on organizations;
create policy "orgs: delete owner"
  on organizations for delete
  using (owner_id = auth.uid());

-- organization_members: membros da mesma org podem ver os outros membros
drop policy if exists "org_members: select same org" on organization_members;
create policy "org_members: select same org"
  on organization_members for select
  using (
    organization_id in (
      select organization_id from organization_members
      where user_id = auth.uid()
    )
  );

-- organization_members: admins e owners podem adicionar membros
drop policy if exists "org_members: insert admin owner" on organization_members;
create policy "org_members: insert admin owner"
  on organization_members for insert to authenticated
  with check (
    organization_id in (
      select organization_id from organization_members
      where user_id = auth.uid()
        and role in ('owner','admin')
    )
  );

-- organization_members: admins/owners podem remover qualquer membro; membro pode sair
drop policy if exists "org_members: delete admin owner self" on organization_members;
create policy "org_members: delete admin owner self"
  on organization_members for delete
  using (
    user_id = auth.uid()
    or organization_id in (
      select organization_id from organization_members
      where user_id = auth.uid()
        and role in ('owner','admin')
    )
  );

-- ── 6. FUNÇÃO get_user_org() ─────────────────────────────────────
create or replace function get_user_org()
returns uuid
language sql
security definer
stable
as $$
  select organization_id
  from professionals
  where user_id = auth.uid()
  limit 1;
$$;

-- ── 7. VIEW org_professionals ────────────────────────────────────
create or replace view org_professionals as
  select
    p.id,
    p.name,
    p.specialty,
    p.user_id,
    p.organization_id,
    count(distinct c.id)  as total_clients,
    count(distinct a.id)  as total_anamneses
  from professionals p
  left join clients   c on c.professional_id = p.id
  left join anamneses a on a.professional_id = p.id
  where p.organization_id = get_user_org()
  group by p.id;
