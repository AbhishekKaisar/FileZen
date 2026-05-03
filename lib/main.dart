import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';
import 'core/theme/theme.dart';
import 'core/routing/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env may not exist in test or CI — continue with dart-define fallback.
  }
  await _tryInitializeSupabase();
  runApp(const FileZenApp());
}

Future<void> _tryInitializeSupabase() async {
  final supabaseUrl = Env.supabaseUrl;
  final supabaseAnonKey = Env.supabaseAnonKey;
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) return;
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
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
