import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'core/routing/router.dart';

void main() {
  runApp(const FileZenApp());
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
