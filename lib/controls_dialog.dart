import 'package:flutter/material.dart';

void showControlsDialog(BuildContext context, {required bool mobileControls}) {
  showDialog(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF211F30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mobileControls ? Icons.touch_app_rounded : Icons.keyboard_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  mobileControls ? 'Touch Controls' : 'Keyboard Controls',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (mobileControls) ...const [
              _ControlRow(icon: Icons.gamepad_rounded, label: 'Joystick (bottom-left)', action: 'Move left / right'),
              _ControlRow(icon: Icons.south_rounded, label: 'Joystick held down', action: 'Drop through platform'),
              _ControlRow(icon: Icons.arrow_upward_rounded, label: 'Jump button', action: 'Jump'),
              _ControlRow(icon: Icons.gps_fixed_rounded, label: '"GUN" button', action: 'Shoot (hold)'),
              _ControlRow(icon: Icons.colorize_rounded, label: '"SWORD" button', action: 'Swing sword (hold)'),
            ] else ...const [
              _ControlRow(icon: Icons.keyboard_rounded, label: 'A / D or Arrow keys', action: 'Move left / right'),
              _ControlRow(icon: Icons.keyboard_rounded, label: 'W / Space', action: 'Jump'),
              _ControlRow(icon: Icons.keyboard_rounded, label: 'S / Down arrow', action: 'Drop through platform'),
              _ControlRow(icon: Icons.keyboard_rounded, label: 'F', action: 'Swing sword'),
              _ControlRow(icon: Icons.keyboard_rounded, label: 'E', action: 'Shoot'),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE', style: TextStyle(color: Color(0xFF8F87FF), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ControlRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String action;

  const _ControlRow({required this.icon, required this.label, required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8F87FF), size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}