import 'dart:ui';
import 'package:flutter/material.dart';
import 'menu_widgets.dart';

class PauseMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;
  final VoidCallback onSave;
  final bool canSave;

  const PauseMenu({
    Key? key,
    required this.onResume,
    required this.onQuit,
    required this.onSave,
    required this.canSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: const Color(0x99000000)),
          ),
        ),
        Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF211F30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x22FFFFFF)),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'PAUSED',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 28),
                GameMenuButton(
                  label: 'RESUME',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF3E8E41),
                  onTap: onResume,
                ),
                const SizedBox(height: 14),
                GameMenuButton(
                  label: canSave ? 'SAVE' : 'SAVE (mid-wave)',
                  icon: Icons.save_rounded,
                  color: canSave ? const Color(0xFF5B4FE8) : const Color(0xFF4A4A55),
                  onTap: canSave ? onSave : () {},
                ),
                const SizedBox(height: 14),
                GameMenuButton(
                  label: 'QUIT',
                  icon: Icons.exit_to_app_rounded,
                  color: const Color(0xFFB4453A),
                  onTap: onQuit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}