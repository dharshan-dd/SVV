#!/bin/bash
# Deployment script - run to build and deploy to Vercel
set -e

echo " Running tests..."
flutter test

echo "Building web..."
flutter build web --dart-define=supabase_url=$SUPABASE_URL --dart-define=supabase_anon_key=$SUPABASE_ANON_KEY

echo "Deploying to Vercel..."
npx vercel --prod --token=$VERCEL_TOKEN

echo "Done! App deployed at $(npx vercel ls --prod --token=$VERCEL_TOKEN | head -1)"
