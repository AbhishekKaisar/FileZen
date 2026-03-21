import 'package:flutter/material.dart';

class TemporalLogicPicker extends StatefulWidget {
  const TemporalLogicPicker({super.key});

  @override
  State<TemporalLogicPicker> createState() => _TemporalLogicPickerState();
}

class _TemporalLogicPickerState extends State<TemporalLogicPicker> {
  double _inactivityDays = 90;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A), // surface-container
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFAEC6FF), width: 4)), // primary
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temporal Logic',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Archive or move files based on age and activity.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFFACABAA),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              _buildCreationWindow(),
              _buildInactivitySlider(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCreationWindow() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CREATION WINDOW',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Color(0xFFAEC6FF), // primary
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131313), // surface-container-low
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Jan 01, 2024', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white)),
                      Icon(Icons.calendar_today, size: 16, color: Color(0xFFACABAA)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFFACABAA)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131313),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Present', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white)),
                      Icon(Icons.event, size: 16, color: Color(0xFFACABAA)),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInactivitySlider() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INACTIVITY THRESHOLD',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Color(0xFFAEC6FF),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFAEC6FF),
                    inactiveTrackColor: const Color(0xFF2E3E45), // secondary-container
                    thumbColor: const Color(0xFFAEC6FF),
                    overlayColor: const Color(0xFFAEC6FF).withValues(alpha: 0.2),
                    trackHeight: 4.0,
                  ),
                  child: Slider(
                    value: _inactivityDays,
                    min: 0,
                    max: 365,
                    divisions: 365,
                    onChanged: (value) {
                      setState(() {
                        _inactivityDays = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2020), // surface-container-high
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_inactivityDays.toInt()} Days',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFAEC6FF),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
