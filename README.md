# Microfinance Collection & Operations Management App

A Flutter + Supabase based mobile application for microfinance collection management.

## Tech Stack

- **Frontend**: Flutter (Mobile & Web)
- **Backend & Database**: Supabase (PostgreSQL, Auth, Row Level Security)
- **State Management**: Riverpod
- **Navigation**: GoRouter

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App initialization
├── models/                   # Data models
│   ├── region.dart
│   ├── model_type.dart
│   ├── collection_bag.dart
│   ├── bag_configuration.dart
│   ├── daily_collection_entry.dart
│   └── index.dart
├── services/                 # API services
│   └── supabase_service.dart
├── providers/                # State management
│   └── app_providers.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── daily_entry_screen.dart
│   ├── admin_screen.dart
│   └── index.dart
├── widgets/                  # Reusable widgets
│   ├── numeric_input_field.dart
│   ├── amount_summary_card.dart
│   ├── custom_dropdown_field.dart
│   ├── date_picker_field.dart
│   ├── section_header.dart
│   └── index.dart
└── utils/                    # Constants and utilities
    ├── app_constants.dart
    └── index.dart
```

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.0.0)
- Supabase account

### 1. Clone and Install Dependencies

```bash
git clone <repository-url>
cd microfinance_app
flutter pub get
```

### 2. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor in your Supabase dashboard
3. Run the SQL migration file located at `supabase/migrations/001_initial_schema.sql`
4. Enable Email authentication in Supabase Auth settings
5. Create your first admin user through Supabase Auth

### 3. Configure Supabase Credentials

Get your Supabase project URL and anon key from:
- Project Settings → API → Project URL & anon key

Set them as environment variables or update `lib/app.dart`:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co
flutter run --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or edit `lib/app.dart` and replace the placeholder values.

### 4. Run the App

```bash
flutter run
```

### 5. Deploy to Vercel (Auto-Deploy)

The project is configured for automatic deployment on every push to `main`.

#### One-Time Setup

```powershell
cd your-project-directory

# 1. Add GitHub remote
git remote add origin <your-github-repo-url>

# 2. Push to main (triggers auto-deploy)
git branch -M main
git push -u origin main
```

#### GitHub Secrets (in repo Settings → Secrets)

| Secret | Value |
|---|---|
| `SUPABASE_URL` | `https://hgauwydrzosafwprtsld.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIs...QEZE7U85JoZdu-9k8cDxlTuJlZF7B040eL_e_R40zyY` |
| `VERCEL_TOKEN` | From https://vercel.com/account/settings |
| `VERCEL_ORG_ID` | From https://vercel.com/account/settings |
| `VERCEL_PROJECT_ID` | From your Vercel project settings |

#### After Setup
- Every push to `main` → tests run → web builds → deploys to Vercel
- Manual deploy: `bash deploy.sh` (requires env vars set)

#### Vercel Environment Variables (in Vercel dashboard)

Set in project settings → Environment Variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Features

### Feature 1: Dynamic Master Data & Dropdowns
- Date picker (defaults to today)
- Region dropdown (loaded from database)
- Type/Model dropdown (loaded from database)
- Area/Bag dropdown (filtered based on selections)

### Feature 2: Daily Collection Entry
- Credit section with opening balance, cash/UPI collections, document charges
- Live auto-calculation of total credit
- Debit section with new loans, chit payments, misc expenses
- Live auto-calculation of total debit
- Real-time net closing balance display
- Submit to Supabase

### Feature 3: Admin Configuration
- Add/Edit/Delete Regions
- Add/Edit/Delete Types (Models)
- Add/Edit/Delete Collection Bags
- Configure schedule mappings

### Feature 4: Financial Dashboard
- Daily, weekly, monthly summaries
- Total Cash vs UPI collections
- Total loans issued
- Net profit/operating cash flow
- P&L metrics

## Database Schema

The app uses 5 main tables:
- `regions` - Geographic regions
- `models` - Collection line types (Daily/Weekly/Monthly)
- `collection_bags` - Collection areas
- `bag_configurations` - Schedule mappings
- `daily_collection_entries` - Transaction records with auto-calculated fields

## Row Level Security

All tables have RLS policies enabled:
- Master data (regions, models, bags) - readable by all authenticated users
- Admin tables - writable by admins only
- Daily entries - users can only access their own entries
- Admins can access all entries

## License

Proprietary - SVV Finance
