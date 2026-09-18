-- ============================================
-- DAY BRANCH ASSIGNMENTS
-- ============================================

CREATE TABLE IF NOT EXISTS public.day_branch_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    branch_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(day_of_week, branch_id)
);

ALTER TABLE public.day_branch_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all day_branch_assignments" ON public.day_branch_assignments FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_day_branch_assignments_day ON public.day_branch_assignments(day_of_week);
CREATE INDEX IF NOT EXISTS idx_day_branch_assignments_branch ON public.day_branch_assignments(branch_id);

CREATE TRIGGER handle_day_branch_assignments_updated_at BEFORE UPDATE ON public.day_branch_assignments
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
