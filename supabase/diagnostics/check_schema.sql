-- ============================================
-- DIAGNOSTIC: Check current table schemas
-- ============================================

-- Check regions table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'regions'
ORDER BY ordinal_position;

-- Check daily_collection_entries table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'daily_collection_entries'
ORDER BY ordinal_position;

-- Check RLS policies on regions
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'regions';

-- Check if regions table has any data
SELECT COUNT(*) as region_count FROM public.regions;
