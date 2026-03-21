import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0E0E0E),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.grid_view, color: Color(0xFFAEC6FF)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const Text(
            'FileZen',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFFE7E5E5),
            ),
          ),
        ],
      ),
      actions: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _NavButton(title: 'Dashboard', isActive: true),
              const _NavButton(title: 'Explorer', isActive: false),
            const _NavButton(title: 'Organizer', isActive: false),
            const _NavButton(title: 'Reports', isActive: false),
            const SizedBox(width: 16),
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.3)),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB8mSYsY0iW8LBuXNPZp3vCPnbJQ86G8_S5NMMWDhXmLcZhFQ2qeEcfRb64Fn1LDzkq6-WtDEyIPw7cjas4Rgfu22LfAZogxMojbMlHrPnF4jneGnqE16Ybit1W4rc5q8kJBmX9dwgXSggIdOEtBRVza_y9x__Qn-E-RxErJF13dNlxzF9LfhhILTLnyYbxAZa4bEbycbW9-oQy2cSTW0JTJ8TUdUjHCIsxWA2rj4mZhYw1GagM91wc4lurEjleoi2vvQDTaBP6ubeq',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NavButton extends StatelessWidget {
  final String title;
  final bool isActive;

  const _NavButton({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (title == 'Dashboard') context.go('/');
        if (title == 'Explorer') context.go('/explorer');
        if (title == 'Organizer') context.go('/organizer');
        if (title == 'Reports') context.go('/reports');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
