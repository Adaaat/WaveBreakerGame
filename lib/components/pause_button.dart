import 'package:flutter/material.dart';

class PauseButton extends StatefulWidget {
  final VoidCallback onPause;

  const PauseButton({required this.onPause, Key? key}) : super(key: key);

  @override
  State<PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<PauseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 12),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPause,
            child: AnimatedScale(
              scale: _pressed ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xCC211F30),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.pause_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}