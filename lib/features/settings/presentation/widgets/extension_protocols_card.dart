import 'package:flutter/material.dart';

class ExtensionProtocolsCard extends StatefulWidget {
  const ExtensionProtocolsCard({super.key});

  @override
  State<ExtensionProtocolsCard> createState() => _ExtensionProtocolsCardState();
}

class _ExtensionProtocolsCardState extends State<ExtensionProtocolsCard> {
  bool _visualAssets = true;
  bool _documents = false;
  bool _sourceCode = true;
  bool _archives = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131313), // surface-container-low
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extension Protocols',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Automatically categorize files based on their type.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFFACABAA),
                    ),
                  )
                ],
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFFAEC6FF), size: 30),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildItem('Visual Assets', '.jpg, .png, .svg', Icons.image, const Color(0xFFAEC6FF), _visualAssets, (v) => setState(() => _visualAssets = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildItem('Documents', '.pdf, .docx, .txt', Icons.description, const Color(0xFF8FA0AA), _documents, (v) => setState(() => _documents = v))),
                  ],
                );
              }
              return Column(
                children: [
                  _buildItem('Visual Assets', '.jpg, .png, .svg', Icons.image, const Color(0xFFAEC6FF), _visualAssets, (v) => setState(() => _visualAssets = v)),
                  const SizedBox(height: 16),
                  _buildItem('Documents', '.pdf, .docx, .txt', Icons.description, const Color(0xFF8FA0AA), _documents, (v) => setState(() => _documents = v)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildItem('Source Code', '.js, .py, .html', Icons.terminal, const Color(0xFFE4DFFF), _sourceCode, (v) => setState(() => _sourceCode = v))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildItem('Archives', '.zip, .rar, .7z', Icons.inventory_2, Colors.white, _archives, (v) => setState(() => _archives = v))),
                  ],
                );
              }
              return Column(
                children: [
                  _buildItem('Source Code', '.js, .py, .html', Icons.terminal, const Color(0xFFE4DFFF), _sourceCode, (v) => setState(() => _sourceCode = v)),
                  const SizedBox(height: 16),
                  _buildItem('Archives', '.zip, .rar, .7z', Icons.inventory_2, Colors.white, _archives, (v) => setState(() => _archives = v)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String title, String subtitle, IconData icon, Color iconColor, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E), // surface
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA)),
                )
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF003D8A), // on-primary
            activeTrackColor: const Color(0xFFAEC6FF), // primary
            inactiveTrackColor: const Color(0xFF252626), // surface-variant
          )
        ],
      ),
    );
  }
}
