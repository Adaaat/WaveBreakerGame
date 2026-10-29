import 'package:flutter/material.dart';
import 'menu_widgets.dart';


class GameOverScreen extends StatelessWidget {
  final VoidCallback onRestart;

  const GameOverScreen({required this.onRestart, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC000000),
      child: Center(
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
              const Icon(Icons.heart_broken_rounded, color: Color(0xFFFF5555), size: 40),
              const SizedBox(height: 12),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 28),
              GameMenuButton(
                label: 'RESTART',
                icon: Icons.refresh_rounded,
                color: const Color(0xFF3E8E41),
                onTap: onRestart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}