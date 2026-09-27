-- ============================================================
-- SVV Finance App — Complete Supabase Schema
-- Run this in Supabase Studio → SQL Editor
-- ============================================================

-- 0. Enable required extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- CORE TABLES
-- ============================================================

-- 1. Regions
create table if not exists public.regions (
  id         uuid primary key default uuid_generate_v4(),
  name       text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Model Types
create table if not exists public.models (
  id         uuid primary key default uuid_generate_v4(),
  name       text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. Collection Bags (Areas)
create table if not exists public.collection_bags (
  id         uuid primary key default uuid_generate_v4(),
  name       text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. Bag Configurations
create table if not exists public.bag_configurations (
  id                  uuid primary key default uuid_generate_v4(),
  entity              text not null default 'Line',
  region_id           uuid not null references public.regions(id) on delete cascade,
  model_id            uuid not null references public.models(id) on delete cascade,
  bag_id              uuid not null references public.collection_bags(id) on delete cascade,
  frequency           text not null,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  -- Enhanced schedule fields
  frequency_type      text not null default 'weekly' check (frequency_type in ('weekly', 'monthly')),
  days_of_week        int[] not null default '{}',
  monthly_rule        text not null default '',
  expected_amount     numeric not null default 0,
  sunday_amount       numeric not null default 0,
  monday_amount       numeric not null default 0,
  tuesday_amount      numeric not null default 0,
  wednesday_amount    numeric not null default 0,
  thursday_amount     numeric not null default 0,
  friday_amount       numeric not null default 0,
  saturday_amount     numeric not null default 0,
  start_date          date not null default now(),
  end_date            date not null default '2099-12-31',

  unique (region_id, model_id, bag_id, frequency)
);

-- 5. Collection Cycles
create table if not exists public.collection_cycles (
  id                     uuid primary key default uuid_generate_v4(),
  bag_configuration_id   uuid not null references public.bag_configurations(id) on delete cascade,
  bag_id                 uuid not null references public.collection_bags(id) on delete cascade,
  scheduled_date         date not null,
  expected_amount        numeric not null default 0,
  collected_amount       numeric not null default 0,
  pending_amount         numeric not null default 0,
  status                 text not null default 'pending' check (status in ('pending', 'partially_collected', 'collected', 'missed', 'cancelled')),
  previous_cycle_id      uuid references public.collection_cycles(id) on delete set null,
  is_active              boolean not null default true,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),

  unique (bag_configuration_id, scheduled_date)
);

-- 6. Daily Collection Entries
create table if not exists public.daily_collection_entries (
  id                      uuid primary key default uuid_generate_v4(),
  entry_date              date not null,
  region_id               uuid not null references public.regions(id) on delete cascade,
  model_id                uuid not null references public.models(id) on delete cascade,
  bag_id                  uuid not null references public.collection_bags(id) on delete cascade,
  bag_configuration_id    uuid references public.bag_configurations(id) on delete set null,
  collection_cycle_id     uuid references public.collection_cycles(id) on delete set null,
  expected_amount         numeric not null default 0,
  previous_pending        numeric not null default 0,
  total_due               numeric not null default 0,
  is_deleted              boolean not null default false,
  deleted_at              timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  -- Credit Breakdown
  opening_balance         numeric not null default 0,
  collection_cash         numeric not null default 0,
  collection_upi          numeric not null default 0,
  document_charges        numeric not null default 0,

  -- Debit Breakdown
  new_loan_cash           numeric not null default 0,
  new_loan_upi            numeric not null default 0,
  chit_payment            numeric not null default 0,
  misc_expenses           numeric not null default 0,

  -- Calculated Fields
  total_credit            numeric not null default 0,
  total_debit             numeric not null default 0,
  net_closing_balance     numeric not null default 0,

  unique (entry_date, region_id, model_id, bag_id)
);

-- 7. Weekly Collection Entries
create table if not exists public.weekly_collection_entries (
  id                      uuid primary key default uuid_generate_v4(),
  week_start_date         date not null,
  region_id               uuid not null references public.regions(id) on delete cascade,
  model_id                uuid not null references public.models(id) on delete cascade,
  bag_id                  uuid not null references public.collection_bags(id) on delete cascade,
  opening_balance         numeric not null default 0,
  collection_cash         numeric not null default 0,
  remaining_amount        numeric not null default 0,
  remaining_reason        text not null default '',
  document_charges        numeric not null default 0,
  adap_amount             numeric not null default 0,
  rr_gpay_amount          numeric not null default 0,
  misc_expenses           numeric not null default 0,
  additional_collection   numeric not null default 0,
  additional_deduction    numeric not null default 0,
  other_amount            numeric not null default 0,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  unique (week_start_date, region_id, model_id, bag_id)
);

-- 8. Monthly Collection Entries
create table if not exists public.monthly_collection_entries (
  id                      uuid primary key default uuid_generate_v4(),
  month_start_date        date not null,
  region_id               uuid not null references public.regions(id) on delete cascade,
  model_id                uuid not null references public.models(id) on delete cascade,
  bag_id                  uuid not null references public.collection_bags(id) on delete cascade,
  opening_balance         numeric not null default 0,
  collection_cash         numeric not null default 0,
  remaining_amount        numeric not null default 0,
  remaining_reason        text not null default '',
  document_charges        numeric not null default 0,
  adap_amount             numeric not null default 0,
  rr_gpay_amount          numeric not null default 0,
  misc_expenses           numeric not null default 0,
  additional_collection   numeric not null default 0,
  additional_deduction    numeric not null default 0,
  other_amount            numeric not null default 0,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  unique (month_start_date, region_id, model_id, bag_id)
);

-- 9. Day Branch Assignments
create table if not exists public.day_branch_assignments (
  id            uuid primary key default uuid_generate_v4(),
  day_of_week   int not null check (day_of_week between 0 and 6),
  branch_id     uuid not null references public.collection_bags(id) on delete cascade,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  unique (day_of_week, branch_id)
);

-- 10. Daily Cash Records (THE MAIN TABLE WITH ALL CALCULATED FIELDS)
create table if not exists public.daily_cash_records (
  id                       uuid primary key default uuid_generate_v4(),
  entry_date               date not null,
  region_id                uuid not null references public.regions(id) on delete cascade,
  model_id                 uuid not null references public.models(id) on delete cascade,
  bag_id                   uuid not null references public.collection_bags(id) on delete cascade,
  week_start_date          date not null,
  day_of_week              int not null check (day_of_week between 0 and 6),

  -- Input Fields
  net_amount_in_hand       numeric not null default 0,
  collected_amount         numeric not null default 0,
  remaining_amount         numeric not null default 0,
  remaining_reason         text not null default '',
  document_fees            numeric not null default 0,
  adap_amount              numeric not null default 0,
  rr_gpay_amount           numeric not null default 0,
  expense                  numeric not null default 0,
  additional_collection    numeric not null default 0,
  additional_deduction     numeric not null default 0,
  deduction_details        jsonb not null default '[]'::jsonb,
  other_amount             numeric not null default 0,
  extra_net_amount         numeric not null default 0,
  previous_final_amount    numeric not null default 0,

  -- Calculated Fields (stored for performance)
  total_amount             numeric not null default 0,
  amount_after_adap        numeric not null default 0,
  amount_after_gpay        numeric not null default 0,
  final_amount             numeric not null default 0,

  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),

  unique (entry_date, region_id, model_id, bag_id)
);

-- 11. Bag Net Amounts (for tracking net amounts per bag/date)
create table if not exists public.bag_net_amounts (
  id           uuid primary key default uuid_generate_v4(),
  bag_id       uuid not null references public.collection_bags(id) on delete cascade,
  entry_date   date not null,
  amount       numeric not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  unique (bag_id, entry_date)
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

create index if not exists idx_bag_configs_region on public.bag_configurations(region_id);
create index if not exists idx_bag_configs_model on public.bag_configurations(model_id);
create index if not exists idx_bag_configs_bag on public.bag_configurations(bag_id);
create index if not exists idx_collection_cycles_bag_config on public.collection_cycles(bag_configuration_id);
create index if not exists idx_collection_cycles_scheduled on public.collection_cycles(scheduled_date);
create index if not exists idx_daily_entries_date on public.daily_collection_entries(entry_date);
create index if not exists idx_daily_entries_region_model_bag on public.daily_collection_entries(region_id, model_id, bag_id);
create index if not exists idx_weekly_entries_week on public.weekly_collection_entries(week_start_date);
create index if not exists idx_monthly_entries_month on public.monthly_collection_entries(month_start_date);
create index if not exists idx_day_assignments_day on public.day_branch_assignments(day_of_week);
create index if not exists idx_daily_cash_entry_date on public.daily_cash_records(entry_date);
create index if not exists idx_daily_cash_region_model_bag on public.daily_cash_records(region_id, model_id, bag_id);
create index if not exists idx_daily_cash_week_start on public.daily_cash_records(week_start_date);
create index if not exists idx_bag_net_amounts_bag_date on public.bag_net_amounts(bag_id, entry_date);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.regions                   enable row level security;
alter table public.models                    enable row level security;
alter table public.collection_bags           enable row level security;
alter table public.bag_configurations        enable row level security;
alter table public.collection_cycles         enable row level security;
alter table public.daily_collection_entries  enable row level security;
alter table public.weekly_collection_entries enable row level security;
alter table public.monthly_collection_entries enable row level security;
alter table public.day_branch_assignments    enable row level security;
alter table public.daily_cash_records        enable row level security;
alter table public.bag_net_amounts           enable row level security;

-- Allow all authenticated users full access (adjust as needed for production)
create policy "authenticated_all_regions"                   on public.regions                   for all to authenticated using (true) with check (true);
create policy "authenticated_all_models"                    on public.models                    for all to authenticated using (true) with check (true);
create policy "authenticated_all_collection_bags"           on public.collection_bags           for all to authenticated using (true) with check (true);
create policy "authenticated_all_bag_configurations"        on public.bag_configurations        for all to authenticated using (true) with check (true);
create policy "authenticated_all_collection_cycles"         on public.collection_cycles         for all to authenticated using (true) with check (true);
create policy "authenticated_all_daily_collection_entries"  on public.daily_collection_entries  for all to authenticated using (true) with check (true);
create policy "authenticated_all_weekly_collection_entries" on public.weekly_collection_entries for all to authenticated using (true) with check (true);
create policy "authenticated_all_monthly_collection_entries" on public.monthly_collection_entries for all to authenticated using (true) with check (true);
create policy "authenticated_all_day_branch_assignments"    on public.day_branch_assignments    for all to authenticated using (true) with check (true);
create policy "authenticated_all_daily_cash_records"        on public.daily_cash_records        for all to authenticated using (true) with check (true);
create policy "authenticated_all_bag_net_amounts"           on public.bag_net_amounts           for all to authenticated using (true) with check (true);

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to auto-update updated_at timestamp
create or replace function public.update_updated_at_column()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- Apply triggers to tables with updated_at
create trigger update_regions_updated_at          before update on public.regions                   for each row execute function public.update_updated_at_column();
create trigger update_models_updated_at           before update on public.models                    for each row execute function public.update_updated_at_column();
create trigger update_collection_bags_updated_at  before update on public.collection_bags           for each row execute function public.update_updated_at_column();
create trigger update_bag_configs_updated_at      before update on public.bag_configurations        for each row execute function public.update_updated_at_column();
create trigger update_collection_cycles_updated_at before update on public.collection_cycles         for each row execute function public.update_updated_at_column();
create trigger update_daily_entries_updated_at    before update on public.daily_collection_entries  for each row execute function public.update_updated_at_column();
create trigger update_weekly_entries_updated_at   before update on public.weekly_collection_entries for each row execute function public.update_updated_at_column();
create trigger update_monthly_entries_updated_at  before update on public.monthly_collection_entries for each row execute function public.update_updated_at_column();
create trigger update_day_assignments_updated_at  before update on public.day_branch_assignments    for each row execute function public.update_updated_at_column();
create trigger update_daily_cash_updated_at       before update on public.daily_cash_records        for each row execute function public.update_updated_at_column();
create trigger update_bag_net_amounts_updated_at  before update on public.bag_net_amounts           for each row execute function public.update_updated_at_column();

-- ============================================================
-- RPC FUNCTION: Generate Collection Cycles
-- ============================================================

drop function if exists public.generate_collection_cycles(uuid, date, date);

create or replace function public.generate_collection_cycles(
  p_bag_configuration_id uuid,
  p_start_date date,
  p_end_date date
) returns void language plpgsql as $$
declare
  v_config record;
  v_current_date date;
  v_day_of_week int;
  v_expected_amount numeric;
begin
  -- Get the bag configuration
  select * into v_config
  from public.bag_configurations
  where id = p_bag_configuration_id;

  if not found then
    raise exception 'Bag configuration not found: %', p_bag_configuration_id;
  end if;

  v_current_date := p_start_date;

  while v_current_date <= p_end_date loop
    v_day_of_week := extract(dow from v_current_date)::int;

    -- Check if this day matches the configuration's schedule
    if v_config.frequency_type = 'weekly' then
      if v_config.days_of_week @> array[v_day_of_week] then
        v_expected_amount := v_config.getAmountForDay(v_day_of_week);
        if v_expected_amount is null then v_expected_amount := 0; end if;

        insert into public.collection_cycles (
          bag_configuration_id, bag_id, scheduled_date,
          expected_amount, previous_cycle_id
        ) values (
          p_bag_configuration_id, v_config.bag_id, v_current_date,
          v_expected_amount, null
        ) on conflict (bag_configuration_id, scheduled_date) do nothing;
      end if;
    elsif v_config.frequency_type = 'monthly' then
      -- Simple monthly: first day of month matching the rule
      if v_current_date = date_trunc('month', v_current_date)::date then
        v_expected_amount := v_config.expected_amount;

        insert into public.collection_cycles (
          bag_configuration_id, bag_id, scheduled_date,
          expected_amount, previous_cycle_id
        ) values (
          p_bag_configuration_id, v_config.bag_id, v_current_date,
          v_expected_amount, null
        ) on conflict (bag_configuration_id, scheduled_date) do nothing;
      end if;
    end if;

    v_current_date := v_current_date + interval '1 day';
  end loop;
end $$;

-- ============================================================
-- RPC FUNCTION: Get Daily Summary
-- ============================================================

drop function if exists public.get_daily_summary(date);

create or replace function public.get_daily_summary(p_date date)
returns jsonb language plpgsql as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'total_final_amount', coalesce(sum(final_amount), 0),
    'total_collected', coalesce(sum(collected_amount), 0),
    'total_expense', coalesce(sum(expense), 0),
    'total_adap_amount', coalesce(sum(adap_amount), 0),
    'total_document_fees', coalesce(sum(document_fees), 0),
    'total_remaining', coalesce(sum(remaining_amount), 0),
    'total_amount', coalesce(sum(total_amount), 0),
    'entry_count', count(*)
  ) into v_result
  from public.daily_cash_records
  where entry_date = p_date;

  return v_result;
end $$;

-- ============================================================
-- SAMPLE DATA (Optional - remove if not needed)
-- ============================================================

-- Insert sample region
insert into public.regions (id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Default Region')
on conflict (id) do nothing;

-- Insert sample model
insert into public.models (id, name) values
  ('22222222-2222-2222-2222-222222222222', 'Default Model')
on conflict (id) do nothing;

-- Insert sample bag
insert into public.collection_bags (id, name) values
  ('33333333-3333-3333-3333-333333333333', 'Default Bag')
on conflict (id) do nothing;