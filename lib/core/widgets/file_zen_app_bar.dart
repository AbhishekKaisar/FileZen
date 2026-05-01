import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FileZenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FileZenAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0E0E0E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.grid_view, color: Color(0xFFAEC6FF)),
        tooltip: 'Dashboard',
        onPressed: () => context.go('/'),
      ),
      title: const Text(
        'FileZen',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: const [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
