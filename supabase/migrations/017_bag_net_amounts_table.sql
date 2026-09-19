-- ============================================
-- Create a dedicated table for tracking extra net amounts per bag per day
-- This avoids schema issues with generated columns or missing columns
-- ============================================

CREATE TABLE IF NOT EXISTS public.bag_net_amounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    amount DECIMAL(14,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(bag_id, entry_date)
);

CREATE INDEX IF NOT EXISTS idx_bag_net_amounts_bag ON public.bag_net_amounts(bag_id);
CREATE INDEX IF NOT EXISTS idx_bag_net_amounts_date ON public.bag_net_amounts(entry_date);

ALTER TABLE public.bag_net_amounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all bag_net_amounts" ON public.bag_net_amounts FOR ALL USING (true);

CREATE TRIGGER handle_bag_net_amounts_updated_at BEFORE UPDATE ON public.bag_net_amounts
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Function to get all extra net amounts for a bag on or before a date
CREATE OR REPLACE FUNCTION public.get_bag_extra_net_amounts(
    p_bag_id UUID,
    p_on_or_before_date DATE
)
RETURNS TABLE (
    entry_date DATE,
    amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT n.entry_date, n.amount
    FROM public.bag_net_amounts n
    WHERE n.bag_id = p_bag_id
      AND n.entry_date <= p_on_or_before_date
    ORDER BY n.entry_date;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_bag_extra_net_amounts(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bag_extra_net_amounts(UUID, DATE) TO anon;
