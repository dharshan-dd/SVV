-- ============================================
-- ADMIN USER SETUP SCRIPT
-- ============================================
-- Run this AFTER creating a user through Supabase Auth
-- (Sign up through the app or Supabase dashboard)
-- Then replace 'USER_UUID_HERE' with the actual user ID

-- Example: Create admin user role
-- First, get the user ID from auth.users table or Supabase dashboard
-- Then run:

INSERT INTO public.user_roles (user_id, role)
SELECT 'USER_UUID_HERE', 'admin'
WHERE NOT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = 'USER_UUID_HERE'
);

-- To make a user a regular agent instead:
-- INSERT INTO public.user_roles (user_id, role)
-- SELECT 'USER_UUID_HERE', 'user'
-- WHERE NOT EXISTS (
--     SELECT 1 FROM public.user_roles
--     WHERE user_id = 'USER_UUID_HERE'
-- );

-- To check existing roles:
-- SELECT u.email, r.role
-- FROM auth.users u
-- JOIN public.user_roles r ON u.id = r.user_id
-- ORDER BY u.email;
