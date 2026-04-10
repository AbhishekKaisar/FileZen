import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/theme.dart';
import 'core/routing/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _tryInitializeSupabase();
  runApp(const FileZenApp());
}

Future<void> _tryInitializeSupabase() async {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    return;
  }
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

class FileZenApp extends StatelessWidget {
  const FileZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FileZen',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
