import 'package:flutter/material.dart';

class SchemaDistributionList extends StatelessWidget {
  const SchemaDistributionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A), // surface-container
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2020).withValues(alpha: 0.3), // surface-container-high
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Distribution',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.filter_list, color: Color(0xFFACABAA)), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFFACABAA)), onPressed: () {}),
                  ],
                )
              ],
            ),
          ),
          // Scrollable Table Body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: Column(
                children: [
                  _buildHeaderRow(),
                  _buildTableRow(Icons.description, const Color(0xFFAEC6FF), 'Metadata_Cluster_A', 'Relational SQL', '42,019', '+4.2%', 'Optimized', const Color(0xFFAEC6FF)),
                  _buildTableRow(Icons.image, const Color(0xFFE4DFFF), 'Media_Assets_Archive', 'Object Storage', '882,110', '+12.8%', 'Syncing', const Color(0xFF2E3E45), textColor: const Color(0xFFB1C2CB)),
                  _buildTableRow(Icons.shield, const Color(0xFFACABAA), 'System_Logs_Secure', 'Encrypted Blob', '2,441,009', '0.0%', 'Locked', const Color(0xFF252626), textColor: const Color(0xFFACABAA)),
                  _buildTableRow(Icons.table_chart, const Color(0xFFAEC6FF), 'User_Preference_Store', 'KV Store', '12,402', '+1.4%', 'Optimized', const Color(0xFFAEC6FF)),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131313), // surface-container-low
              border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing 4 of 24 active schemas', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA))),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFFACABAA)), onPressed: null),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFFACABAA)), onPressed: () {}),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('SCHEMA NAME', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFFACABAA)))),
          Expanded(flex: 2, child: Text('TYPE', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFFACABAA)))),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('RECORDS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFFACABAA))))),
          Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('GROWTH', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFFACABAA))))),
          Expanded(flex: 1, child: Padding(padding: EdgeInsets.only(left: 32.0), child: Text('STATUS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Color(0xFFACABAA))))),
        ],
      ),
    );
  }

  Widget _buildTableRow(IconData icon, Color iconColor, String title, String type, String records, String growth, String status, Color statusBg, {Color? textColor}) {
    bool isPositive = growth.startsWith('+');
    Color growthColor = isPositive ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA);
    if (!isPositive && growth != '0.0%') growthColor = const Color(0xFFEE7D77); // error (simplified logic)
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(type, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(records, style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(growth, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: growthColor)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg == const Color(0xFFAEC6FF) ? statusBg.withValues(alpha: 0.1) : statusBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: textColor ?? statusBg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
