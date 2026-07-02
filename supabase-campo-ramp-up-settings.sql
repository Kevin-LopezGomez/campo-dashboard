-- Supabase migration for the Campo Ramp Up shared model settings.
-- Run this in the Supabase SQL Editor with table-owner privileges.
--
-- Source dashboard: 15.0 Campo Ramp Up.html
-- Stores the latest shared model state so every viewer can load the same
-- assumptions, active tab, chart series visibility, and SKU mix values.

create table if not exists public.campo_ramp_up_settings (
  id text primary key default 'shared',
  settings jsonb not null default '{}'::jsonb,
  source_file text not null default '15.0 Campo Ramp Up.html',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint campo_ramp_up_settings_id_not_blank
    check (length(trim(id)) > 0),
  constraint campo_ramp_up_settings_object
    check (jsonb_typeof(settings) = 'object')
);

insert into public.campo_ramp_up_settings (id, settings, source_file)
values ('shared', '{}'::jsonb, '15.0 Campo Ramp Up.html')
on conflict (id) do nothing;

grant select, insert, update on public.campo_ramp_up_settings
  to anon, authenticated;

alter table public.campo_ramp_up_settings enable row level security;

drop policy if exists campo_ramp_up_settings_read
  on public.campo_ramp_up_settings;

create policy campo_ramp_up_settings_read
on public.campo_ramp_up_settings
for select
to anon, authenticated
using (true);

drop policy if exists campo_ramp_up_settings_insert
  on public.campo_ramp_up_settings;

create policy campo_ramp_up_settings_insert
on public.campo_ramp_up_settings
for insert
to anon, authenticated
with check (true);

drop policy if exists campo_ramp_up_settings_update
  on public.campo_ramp_up_settings;

create policy campo_ramp_up_settings_update
on public.campo_ramp_up_settings
for update
to anon, authenticated
using (true)
with check (true);

create or replace function public.set_campo_ramp_up_settings_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_campo_ramp_up_settings_updated_at
  on public.campo_ramp_up_settings;

create trigger set_campo_ramp_up_settings_updated_at
before update on public.campo_ramp_up_settings
for each row
execute function public.set_campo_ramp_up_settings_updated_at();

comment on table public.campo_ramp_up_settings is
  'Latest shared settings payload for the Campo Ramp Up dashboard.';

comment on column public.campo_ramp_up_settings.settings is
  'Model state JSON from 15.0 Campo Ramp Up.html, including inputs, SKU mix, active screen, and chart series.';

notify pgrst, 'reload schema';
