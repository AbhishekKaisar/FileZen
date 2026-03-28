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
        onPressed: () {},
      ),
      title: const Text(
        'FileZen',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFACABAA)),
            onPressed: () {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFACABAA)),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF2E3E45), // secondary-container
            radius: 16,
            child: const Icon(Icons.person, color: Color(0xFFB1C2CB), size: 16),
          ),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
