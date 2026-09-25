-- Lana — finanzas personales. Mismo proyecto de Supabase que Nutri y Ritmo (tablas con prefijo fz_).
-- Nada se conecta al banco: todo lo captura la persona a mano.

-- Cuentas: tarjetas de crédito, préstamos/créditos y pagos fijos (renta, internet, suscripciones).
create table if not exists public.fz_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('card','loan','bill')),
  name text not null,              -- "BBVA Azul", "Crédito auto", "Netflix"
  bank text,                       -- "BBVA", "Nu", "Banamex"...
  color text,                      -- color de la tarjeta en la app
  credit_limit numeric,            -- solo tarjetas
  balance numeric not null default 0,   -- lo que se debe hoy
  cut_day int check (cut_day between 1 and 31),   -- día de corte (tarjetas)
  pay_day int check (pay_day between 1 and 31),   -- día límite de pago
  min_payment numeric,             -- pago mínimo del periodo
  no_interest_payment numeric,     -- pago para no generar intereses
  monthly_payment numeric,         -- mensualidad fija (préstamos y pagos fijos)
  payments_left int,               -- mensualidades que faltan (préstamos)
  rate numeric,                    -- tasa anual %, para estimar intereses
  plans jsonb not null default '[]',    -- compras a meses: [{name,total,months,start:'2026-05'}]
  paid_cycle text,                 -- 'YYYY-MM' del último periodo pagado
  notify boolean not null default true,
  notified_key text,               -- evita avisos repetidos: 'YYYY-MM-DD:tipo'
  archived boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists fz_accounts_user on public.fz_accounts(user_id);

-- Movimientos: gastos, ingresos y pagos a cuentas.
create table if not exists public.fz_moves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid references public.fz_accounts(id) on delete set null,
  kind text not null check (kind in ('expense','income','payment')),
  amount numeric not null check (amount >= 0),
  category text,
  note text,
  day date not null default current_date,
  created_at timestamptz not null default now()
);
create index if not exists fz_moves_user_day on public.fz_moves(user_id, day);

-- Ajustes por persona (ingreso mensual, presupuesto).
create table if not exists public.fz_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  monthly_income numeric,
  budget numeric,
  updated_at timestamptz not null default now()
);

alter table public.fz_accounts enable row level security;
alter table public.fz_moves enable row level security;
alter table public.fz_settings enable row level security;
drop policy if exists fz_accounts_own on public.fz_accounts;
create policy fz_accounts_own on public.fz_accounts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists fz_moves_own on public.fz_moves;
create policy fz_moves_own on public.fz_moves for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists fz_settings_own on public.fz_settings;
create policy fz_settings_own on public.fz_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Días antes de la fecha de pago en que se avisa (0 = el mismo día).
alter table public.fz_settings add column if not exists remind_days int[];
