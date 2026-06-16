-- Supabase migration for Board Inventory Runway user-entered scenarios.
-- Run this in the Supabase SQL Editor with table-owner privileges.
--
-- Source dashboard: 04.2 Team - Board Inventory.html
-- Stores the inputs needed to reproduce the calculated runway chart:
-- start date, starting inventory, boards per pond, broken boards/week
-- assumptions, buffer days, horizon, selected pond scenarios, and view state.

create extension if not exists pgcrypto;

create table if not exists public.board_inventory_runway_inputs (
  id uuid primary key default gen_random_uuid(),

  scenario_name text not null default 'Board Inventory Runway',
  notes text,

  start_date date not null,
  starting_inventory integer not null,
  bowed_boards integer not null default 0,
  boards_per_pond integer not null,
  max_clean_per_day integer not null default 120,
  transplant_per_day integer not null default 0,
  broken_boards_per_week_best integer not null,
  broken_boards_per_week_worst integer not null,
  buffer_days numeric(8, 2) not null default 0,
  horizon_weeks integer not null,
  selected_ponds integer[] not null default array[]::integer[],
  additional_safety_lines jsonb not null default '[]'::jsonb,

  timeline_mode text not null default 'presets',
  active_preset text not null default '1y',

  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint board_inventory_runway_starting_inventory_nonnegative
    check (starting_inventory >= 0),
  constraint board_inventory_runway_bowed_boards_nonnegative
    check (bowed_boards >= 0),
  constraint board_inventory_runway_boards_per_pond_positive
    check (boards_per_pond > 0),
  constraint board_inventory_runway_max_clean_per_day_positive
    check (max_clean_per_day > 0),
  constraint board_inventory_runway_transplant_per_day_nonnegative
    check (transplant_per_day >= 0),
  constraint board_inventory_runway_broken_best_nonnegative
    check (broken_boards_per_week_best >= 0),
  constraint board_inventory_runway_broken_worst_nonnegative
    check (broken_boards_per_week_worst >= 0),
  constraint board_inventory_runway_broken_worst_gte_best
    check (broken_boards_per_week_worst >= broken_boards_per_week_best),
  constraint board_inventory_runway_buffer_days_nonnegative
    check (buffer_days >= 0),
  constraint board_inventory_runway_horizon_weeks_min
    check (horizon_weeks >= 4),
  constraint board_inventory_runway_timeline_mode_valid
    check (timeline_mode in ('presets', 'horizon')),
  constraint board_inventory_runway_active_preset_valid
    check (active_preset in ('3m', '6m', '1y', '2y', 'all')),
  constraint board_inventory_runway_selected_ponds_valid
    check (
      selected_ponds <@ array[8, 9, 10, 11, 12, 13, 14]
      and array_position(selected_ponds, null) is null
    ),
  constraint board_inventory_runway_additional_safety_lines_array
    check (jsonb_typeof(additional_safety_lines) = 'array')
);

create index if not exists board_inventory_runway_inputs_created_at_idx
  on public.board_inventory_runway_inputs (created_at desc);

create index if not exists board_inventory_runway_inputs_created_by_idx
  on public.board_inventory_runway_inputs (created_by);

alter table public.board_inventory_runway_inputs
  add column if not exists bowed_boards integer not null default 0;

alter table public.board_inventory_runway_inputs
  add column if not exists max_clean_per_day integer not null default 120;

alter table public.board_inventory_runway_inputs
  add column if not exists transplant_per_day integer not null default 0;

alter table public.board_inventory_runway_inputs
  add column if not exists selected_ponds integer[] not null default array[]::integer[];

alter table public.board_inventory_runway_inputs
  add column if not exists additional_safety_lines jsonb not null default '[]'::jsonb;

do $$
begin
  alter table public.board_inventory_runway_inputs
    add constraint board_inventory_runway_bowed_boards_nonnegative
    check (bowed_boards >= 0);
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.board_inventory_runway_inputs
    add constraint board_inventory_runway_max_clean_per_day_positive
    check (max_clean_per_day > 0);
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.board_inventory_runway_inputs
    add constraint board_inventory_runway_transplant_per_day_nonnegative
    check (transplant_per_day >= 0);
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.board_inventory_runway_inputs
    add constraint board_inventory_runway_selected_ponds_valid
    check (
      selected_ponds <@ array[8, 9, 10, 11, 12, 13, 14]
      and array_position(selected_ponds, null) is null
    );
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter table public.board_inventory_runway_inputs
    add constraint board_inventory_runway_additional_safety_lines_array
    check (jsonb_typeof(additional_safety_lines) = 'array');
exception
  when duplicate_object then null;
end $$;

grant select, insert, update on public.board_inventory_runway_inputs
  to anon, authenticated;

alter table public.board_inventory_runway_inputs enable row level security;

drop policy if exists board_inventory_runway_inputs_read
  on public.board_inventory_runway_inputs;

create policy board_inventory_runway_inputs_read
on public.board_inventory_runway_inputs
for select
to anon, authenticated
using (true);

drop policy if exists board_inventory_runway_inputs_insert
  on public.board_inventory_runway_inputs;

create policy board_inventory_runway_inputs_insert
on public.board_inventory_runway_inputs
for insert
to anon, authenticated
with check (true);

drop policy if exists board_inventory_runway_inputs_update
  on public.board_inventory_runway_inputs;

create policy board_inventory_runway_inputs_update
on public.board_inventory_runway_inputs
for update
to anon, authenticated
using (true)
with check (true);

create or replace function public.set_board_inventory_runway_inputs_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_board_inventory_runway_inputs_updated_at
  on public.board_inventory_runway_inputs;

create trigger set_board_inventory_runway_inputs_updated_at
before update on public.board_inventory_runway_inputs
for each row
execute function public.set_board_inventory_runway_inputs_updated_at();

comment on table public.board_inventory_runway_inputs is
  'User-entered scenario inputs for the Board Inventory Runway dashboard.';

comment on column public.board_inventory_runway_inputs.selected_ponds is
  'Selected pond scenario counts from the dashboard multi-select chips.';

notify pgrst, 'reload schema';
