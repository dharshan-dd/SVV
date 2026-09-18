import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:microfinance_app/main.dart';
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

