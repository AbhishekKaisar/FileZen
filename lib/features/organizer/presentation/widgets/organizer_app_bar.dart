import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrganizerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OrganizerAppBar({super.key});

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
              letterSpacing: -0.5,
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
              const _NavButton(title: 'Dashboard', isActive: false),
              const _NavButton(title: 'Explorer', isActive: false),
              const _NavButton(title: 'Organizer', isActive: true),
              const _NavButton(title: 'Reports', isActive: false),
              const SizedBox(width: 16),
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1F2020),
                  border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDCyhFEXQYlBFC3X5g25pxQu1bxJuUJbYo029vFjL8mV_wnBrMpYP037inuKYuOl2_h-ljm4VY6oxi9y6y-3oHK1rClPYOriaXEsmo3UoRudMfoZfnCDt4ZRrzGrO_rvOnuCHBFDq7PBx4DNy1O3Wc71w9MJ0kMOWtuHFKILyEQ5g_s_SE3PScWmeC4yH9wV41CouHdzfp0mncti2Y1ltWRHHOpJJBOpvAUEySLX0-QHsCiFa40xXngH18lc8brZJM2RCVLHjpWFrtl',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        )
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
