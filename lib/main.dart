import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:microfinance_app/screens/index.dart';
import 'package:microfinance_app/theme/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://hgauwydrzosafwprtsld.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnYXV3eWRyem9zYWZ3cHJ0c2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3NjE3NzEsImV4cCI6MjEwNDMzNzc3MX0.QEZE7U85JoZdu-9k8cDxlTuJlZF7B040eL_e_R40zyY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  // Read the saved theme *before* the first frame so the app never flashes
  // the wrong palette on launch.
  final initialTheme = await loadInitialThemeChoice();

  runApp(
    ProviderScope(
      overrides: [
        initialThemeChoiceProvider.overrideWithValue(initialTheme),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;
  final ValueNotifier<bool> _authLoaded = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _authLoaded.value = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authLoaded.value = true;
    });
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authLoaded,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          redirect: (context, state) {
            if (!_authLoaded.value) return null;
            final user = Supabase.instance.client.auth.currentSession?.user;
            return user == null ? '/login' : null;
          },
          builder: (context, state) => const DashboardHomeScreen(),
        ),
        GoRoute(
          path: '/daily-tracking',
          builder: (context, state) => const DailyTrackingScreen(),
        ),
        GoRoute(
          path: '/daily-entry',
          builder: (context, state) => const DailyEntryScreen(),
        ),
        GoRoute(
          path: '/collection-history',
          builder: (context, state) => const CollectionHistoryScreen(),
        ),
        GoRoute(
          path: '/bag-history',
          builder: (context, state) => const BagHistoryScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/weekly-dashboard',
          builder: (context, state) => const WeeklyDashboardScreen(),
        ),
        GoRoute(
          path: '/monthly-dashboard',
          builder: (context, state) => const MonthlyDashboardScreen(),
        ),
        GoRoute(
          path: '/gpay-dashboard',
          builder: (context, state) => const GPayDashboardScreen(),
        ),
        GoRoute(
          path: '/day-record-entry',
          builder: (context, state) => DayRecordEntryScreen(
            initialDate: state.uri.queryParameters['date'] != null
                ? DateTime.parse(state.uri.queryParameters['date']!)
                : null,
            initialRegionId: state.uri.queryParameters['regionId'],
            initialModelId: state.uri.queryParameters['modelId'],
            initialBagId: state.uri.queryParameters['bagId'],
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/plan-notes',
          builder: (context, state) => const PlanNoteScreen(),
        ),
        GoRoute(
          path: '/day-records',
          builder: (context, state) => const DayRecordsScreen(),
        ),
        GoRoute(
          path: '/branches',
          builder: (context, state) => const BranchesScreen(),
        ),
        GoRoute(
          path: '/models',
          builder: (context, state) => const ModelsScreen(),
        ),
        GoRoute(
          path: '/bags',
          builder: (context, state) => const BagsScreen(),
        ),
        GoRoute(
          path: '/schedules',
          builder: (context, state) => const SchedulesScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _authLoaded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watching this rebuilds MaterialApp whenever the user picks a theme,
    // which is what makes the selector affect the entire UI.
    final resolved = ref.watch(resolvedThemeProvider);

    return MaterialApp.router(
      title: 'SVV Finance',
      debugShowCheckedModeBanner: false,
      theme: resolved.theme,
      darkTheme: resolved.darkTheme,
      themeMode: resolved.mode,
      routerConfig: _router,
    );
  }
}
