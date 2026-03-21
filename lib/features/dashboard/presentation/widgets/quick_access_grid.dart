import 'package:flutter/material.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.speed, color: Color(0xFFAEC6FF)), // primary
            SizedBox(width: 12),
            Text(
              'Quick Access',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _buildCard(
              title: 'Recent',
              subtitle: 'Continue where you left off with your latest activity.',
              icon: Icons.history,
              iconColor: const Color(0xFFAEC6FF),
              iconBgColor: const Color(0xFFAEC6FF).withValues(alpha: 0.1),
              backgroundIcon: Icons.schedule,
              content: Column(
                children: [
                  _buildListItem(Icons.description, 'Q4_Financial_Report.pdf', const Color(0xFFAEC6FF), true),
                  const SizedBox(height: 12),
                  _buildListItem(Icons.image, 'Architecture_Mockup_v2.png', const Color(0xFFACABAA), false),
                ],
              ),
            ),
            _buildCard(
              title: 'Starred',
              subtitle: 'Your most important files, pinned for instant retrieval.',
              icon: Icons.star,
              iconColor: const Color(0xFFE4DFFF), // tertiary
              iconBgColor: const Color(0xFFE4DFFF).withValues(alpha: 0.1),
              backgroundIcon: Icons.star_border,
              content: Row(
                children: [
                  _buildChip('Legal Docs'),
                  const SizedBox(width: 8),
                  _buildChip('Project Zen'),
                ],
              ),
            ),
            _buildCard(
              title: 'Shared',
              subtitle: 'Collaborate seamlessly on team folders and links.',
              icon: Icons.share,
              iconColor: const Color(0xFF8FA0AA), // secondary
              iconBgColor: const Color(0xFF2E3E45), // secondary-container
              backgroundIcon: Icons.group,
              content: Row(
                children: [
                  _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuCcRdt7j875Wniif9U-uJRXmsSpV7L2N9QnH0MTcecBVRhsRbuL4iXr_dyldJkWlSkAhkDASJ8rZaJ2k9cQwowecZbUKFytq0CVMVSf9kbd_2N4vEquQRnBJoCY2bjMyhtRMTOQpQYxTYxjQvoLKMpDAjsBVDtX57VEXfmbL4wGpSTfmRhH7EBhUl3d8LHoUYcAhgWXtIgpcGifr8FuTn7IzjZROeTvAUgyEf1l1cSYozoyAFveOLavfwFNJ9Lf6v-X_heFZpaIbLA-'),
                  Transform.translate(
                    offset: const Offset(-10, 0),
                    child: _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuCdTdx3U88l7sphZyWM7Urg7DwwclKFrqmtb8suDfIQXTl265U33SEAfMQetRTC_O9DhcUH1I91HBsSHr-AKUsPVaozkxM9LeN845W3af8nZqJsHoHZLTRy1PyDxwn1RmKzJ8qjr7LSghT_ek89c2IxwMsg2GeEqKV9qLGKgutgsg098DvHsCH_R8sICyOKTh8QrqfgJxvX8vPZ7nkqnt7PlBTU0WejqGCgf2TL2-ttf9Bzed49lhTJBggOCZ1hbxo7cnoiYbpI3YI4'),
                  ),
                  Transform.translate(
                    offset: const Offset(-20, 0),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF252626),
                        border: Border.all(color: const Color(0xFF0E0E0E), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '+4',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFACABAA)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required IconData backgroundIcon,
    required Widget content,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A), // surface-container
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Icon(
              backgroundIcon,
              size: 160,
              color: Colors.white.withValues(alpha: 0.02),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFACABAA),
                ),
              ),
              const SizedBox(height: 24),
              content,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, String label, Color iconColor, bool isPrimary) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: isPrimary ? Colors.white : const Color(0xFFACABAA),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2020), // surface-container-high
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0E0E0E), width: 2),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
