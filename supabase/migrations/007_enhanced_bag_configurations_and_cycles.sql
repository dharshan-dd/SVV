-- ============================================
-- ENHANCED BAG CONFIGURATION & COLLECTION CYCLES
-- ============================================

-- Enhance bag_configurations with schedule and amount rules
ALTER TABLE public.bag_configurations
ADD COLUMN IF NOT EXISTS frequency_type TEXT DEFAULT 'weekly' CHECK (frequency_type IN ('daily', 'weekly', 'monthly')),
ADD COLUMN IF NOT EXISTS days_of_week INTEGER[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS monthly_rule TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS expected_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS sunday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS monday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS tuesday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS wednesday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS thursday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS friday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS saturday_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS end_date DATE DEFAULT '2099-12-31';

-- Collection cycles table
CREATE TABLE IF NOT EXISTS public.collection_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bag_configuration_id UUID NOT NULL REFERENCES public.bag_configurations(id) ON DELETE CASCADE,
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    expected_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    collected_amount DECIMAL(14,2) DEFAULT 0.00,
    pending_amount DECIMAL(14,2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'partially_collected', 'collected', 'missed', 'cancelled')),
    previous_cycle_id UUID REFERENCES public.collection_cycles(id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(bag_configuration_id, scheduled_date)
);

-- Daily collection entries enhancement
ALTER TABLE public.daily_collection_entries
ADD COLUMN IF NOT EXISTS bag_configuration_id UUID REFERENCES public.bag_configurations(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS collection_cycle_id UUID REFERENCES public.collection_cycles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS expected_amount DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS previous_pending DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS total_due DECIMAL(14,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Indexes for collection cycles
CREATE INDEX IF NOT EXISTS idx_collection_cycles_bag_config ON public.collection_cycles(bag_configuration_id);
CREATE INDEX IF NOT EXISTS idx_collection_cycles_bag ON public.collection_cycles(bag_id);
CREATE INDEX IF NOT EXISTS idx_collection_cycles_scheduled_date ON public.collection_cycles(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_collection_cycles_status ON public.collection_cycles(status);
CREATE INDEX IF NOT EXISTS idx_collection_cycles_previous ON public.collection_cycles(previous_cycle_id);
CREATE INDEX IF NOT EXISTS idx_collection_cycles_unique_cycle ON public.collection_cycles(bag_configuration_id, scheduled_date);

-- Indexes for enhanced daily entries
CREATE INDEX IF NOT EXISTS idx_daily_entries_bag_config ON public.daily_collection_entries(bag_configuration_id);
CREATE INDEX IF NOT EXISTS idx_daily_entries_cycle ON public.daily_collection_entries(collection_cycle_id);
CREATE INDEX IF NOT EXISTS idx_daily_entries_deleted ON public.daily_collection_entries(is_deleted);

-- Enable RLS on collection_cycles
ALTER TABLE public.collection_cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read collection_cycles for all" ON public.collection_cycles
    FOR SELECT USING (true);

CREATE POLICY "Allow insert collection_cycles for all" ON public.collection_cycles
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update collection_cycles for all" ON public.collection_cycles
    FOR UPDATE USING (true);

CREATE POLICY "Allow delete collection_cycles for all" ON public.collection_cycles
    FOR DELETE USING (true);

-- Trigger for collection_cycles timestamp
CREATE TRIGGER handle_collection_cycles_updated_at BEFORE UPDATE ON public.collection_cycles
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ============================================
-- DATABASE FUNCTIONS FOR COLLECTION LOGIC
-- ============================================

-- Function to get previous cycle for a bag
CREATE OR REPLACE FUNCTION public.get_previous_cycle(p_bag_id UUID, p_scheduled_date DATE)
RETURNS TABLE (
    id UUID,
    scheduled_date DATE,
    expected_amount DECIMAL,
    collected_amount DECIMAL,
    pending_amount DECIMAL,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.scheduled_date,
        c.expected_amount,
        c.collected_amount,
        c.pending_amount,
        c.status
    FROM public.collection_cycles c
    WHERE c.bag_id = p_bag_id
    AND c.scheduled_date < p_scheduled_date
    AND c.is_active = TRUE
    ORDER BY c.scheduled_date DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate pending amount from previous cycles
CREATE OR REPLACE FUNCTION public.calculate_pending_from_previous(p_bag_id UUID, p_scheduled_date DATE)
RETURNS DECIMAL AS $$
DECLARE
    total_pending DECIMAL(14,2) := 0.00;
BEGIN
    SELECT COALESCE(SUM(c.pending_amount), 0.00)
    INTO total_pending
    FROM public.collection_cycles c
    WHERE c.bag_id = p_bag_id
    AND c.scheduled_date < p_scheduled_date
    AND c.is_active = TRUE
    AND c.status IN ('pending', 'partially_collected');

    RETURN total_pending;
END;
$$ LANGUAGE plpgsql;

-- Function to generate collection cycles for a bag configuration
CREATE OR REPLACE FUNCTION public.generate_collection_cycles(
    p_bag_configuration_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS void AS $$
DECLARE
    config RECORD;
    current_date DATE;
    days_array INTEGER[];
    day_of_week INTEGER;
    expected_amount DECIMAL(14,2);
    prev_cycle_id UUID;
BEGIN
    SELECT * INTO config FROM public.bag_configurations WHERE id = p_bag_configuration_id;
    IF NOT FOUND THEN
        RETURN;
    END IF;

    days_array := config.days_of_week;

    current_date := p_start_date;

    WHILE current_date <= p_end_date LOOP
        day_of_week := EXTRACT(DOW FROM current_date);

        IF day_of_week = ANY(days_array) THEN
            expected_amount := CASE day_of_week
                WHEN 0 THEN config.sunday_amount
                WHEN 1 THEN config.monday_amount
                WHEN 2 THEN config.tuesday_amount
                WHEN 3 THEN config.wednesday_amount
                WHEN 4 THEN config.thursday_amount
                WHEN 5 THEN config.friday_amount
                WHEN 6 THEN config.saturday_amount
                ELSE 0.00
            END;

            IF expected_amount > 0 THEN
                SELECT id INTO prev_cycle_id
                FROM public.collection_cycles
                WHERE bag_configuration_id = p_bag_configuration_id
                AND scheduled_date < current_date
                AND is_active = TRUE
                ORDER BY scheduled_date DESC
                LIMIT 1;

                INSERT INTO public.collection_cycles (
                    bag_configuration_id,
                    bag_id,
                    scheduled_date,
                    expected_amount,
                    previous_cycle_id
                ) VALUES (
                    p_bag_configuration_id,
                    config.bag_id,
                    current_date,
                    expected_amount,
                    prev_cycle_id
                )
                ON CONFLICT DO NOTHING;
            END IF;
        END IF;

        current_date := current_date + INTERVAL '1 day';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to get or create current cycle for a bag on a given date
CREATE OR REPLACE FUNCTION public.get_or_create_current_cycle(
    p_bag_configuration_id UUID,
    p_bag_id UUID,
    p_scheduled_date DATE
)
RETURNS TABLE (
    id UUID,
    bag_configuration_id UUID,
    bag_id UUID,
    scheduled_date DATE,
    expected_amount DECIMAL,
    collected_amount DECIMAL,
    pending_amount DECIMAL,
    status TEXT,
    previous_cycle_id UUID,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    config RECORD;
    current_cycle RECORD;
    day_of_week INTEGER;
    expected_amount DECIMAL(14,2);
    prev_cycle_id UUID;
BEGIN
    SELECT * INTO config FROM public.bag_configurations WHERE id = p_bag_configuration_id;
    IF NOT FOUND THEN
        RETURN;
    END IF;

    day_of_week := EXTRACT(DOW FROM p_scheduled_date);

    IF NOT (day_of_week = ANY(config.days_of_week)) THEN
        RETURN;
    END IF;

    expected_amount := CASE day_of_week
        WHEN 0 THEN config.sunday_amount
        WHEN 1 THEN config.monday_amount
        WHEN 2 THEN config.tuesday_amount
        WHEN 3 THEN config.wednesday_amount
        WHEN 4 THEN config.thursday_amount
        WHEN 5 THEN config.friday_amount
        WHEN 6 THEN config.saturday_amount
        ELSE 0.00
    END;

    IF expected_amount <= 0 THEN
        RETURN;
    END IF;

    SELECT * INTO current_cycle
    FROM public.collection_cycles
    WHERE bag_configuration_id = p_bag_configuration_id
    AND scheduled_date = p_scheduled_date
    AND is_active = TRUE
    LIMIT 1;

    IF FOUND THEN
        RETURN QUERY SELECT * FROM current_cycle;
        RETURN;
    END IF;

    SELECT id INTO prev_cycle_id
    FROM public.collection_cycles
    WHERE bag_configuration_id = p_bag_configuration_id
    AND scheduled_date < p_scheduled_date
    AND is_active = TRUE
    ORDER BY scheduled_date DESC
    LIMIT 1;

    INSERT INTO public.collection_cycles (
        bag_configuration_id,
        bag_id,
        scheduled_date,
        expected_amount,
        previous_cycle_id
    ) VALUES (
        p_bag_configuration_id,
        p_bag_id,
        p_scheduled_date,
        expected_amount,
        prev_cycle_id
    )
    RETURNING * INTO current_cycle;

    RETURN QUERY SELECT * FROM current_cycle;
END;
$$ LANGUAGE plpgsql;

-- Function to recalculate pending amounts after a collection is updated
CREATE OR REPLACE FUNCTION public.recalculate_future_pendings(p_cycle_id UUID)
RETURNS void AS $$
DECLARE
    current_cycle RECORD;
    next_cycle RECORD;
    total_pending DECIMAL(14,2);
BEGIN
    SELECT * INTO current_cycle FROM public.collection_cycles WHERE id = p_cycle_id;
    IF NOT FOUND THEN
        RETURN;
    END IF;

    IF current_cycle.status = 'cancelled' THEN
        total_pending := current_cycle.expected_amount;
    ELSE
        total_pending := current_cycle.expected_amount - COALESCE(current_cycle.collected_amount, 0.00);
    END IF;

    UPDATE public.collection_cycles
    SET pending_amount = total_pending
    WHERE id = p_cycle_id;

    FOR next_cycle IN
        SELECT * FROM public.collection_cycles
        WHERE previous_cycle_id = p_cycle_id
        AND is_active = TRUE
        ORDER BY scheduled_date ASC
    LOOP
        SELECT COALESCE(SUM(c.pending_amount), 0.00)
        INTO total_pending
        FROM public.collection_cycles c
        WHERE c.bag_id = next_cycle.bag_id
        AND c.scheduled_date < next_cycle.scheduled_date
        AND c.is_active = TRUE
        AND c.status IN ('pending', 'partially_collected', 'missed')
        AND c.id != next_cycle.id;

        UPDATE public.collection_cycles
        SET pending_amount = total_pending
        WHERE id = next_cycle.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_previous_cycle(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_pending_from_previous(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_collection_cycles(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_current_cycle(UUID, UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.recalculate_future_pendings(UUID) TO authenticated;
