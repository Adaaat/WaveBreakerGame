import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'controls_dialog.dart';
import 'game_save_manager.dart';
import 'menu_widgets.dart';

class MainMenu extends StatefulWidget {

  final void Function(bool mobileControls, Map<String, dynamic>? loadData) onStartGame;

  const MainMenu({Key? key, required this.onStartGame}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _hasSave = false;
  bool _checkingSave = true;
  late bool _mobileControls;

  @override
  void initState() {
    super.initState();
    // Reasonable default: touch controls on Android/iOS, keyboard elsewhere.
    _mobileControls = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    _checkForSave();
  }

  Future<void> _checkForSave() async {
    final hasSave = await GameSaveManager.hasSingleSave();
    if (!mounted) return;
    setState(() {
      _hasSave = hasSave;
      _checkingSave = false;
    });
  }

  Future<void> _continueGame() async {
    final data = await GameSaveManager.loadSingleGame();
    widget.onStartGame(_mobileControls, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF211F30), Color(0xFF14131F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              left: -60,
              child: _GlowBlob(color: Color(0x335B4FE8), size: 260),
            ),
            const Positioned(
              bottom: -100,
              right: -60,
              child: _GlowBlob(color: Color(0x333E8E41), size: 300),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF8F87FF), Color(0xFF5B4FE8)],
                    ).createShader(bounds),
                    child: const Text(
                      'WAVE BREAKER',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Survive the waves.',
                    style: TextStyle(fontSize: 15, color: Color(0x99FFFFFF), letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 36),

                  // --- Control scheme toggle ---
                  _ControlToggle(
                    mobileControls: _mobileControls,
                    onChanged: (value) => setState(() => _mobileControls = value),
                  ),
                  const SizedBox(height: 28),

                  GameMenuButton(
                    label: 'START GAME',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF3E8E41),
                    onTap: () => widget.onStartGame(_mobileControls, null),
                  ),
                  const SizedBox(height: 14),
                  if (!_checkingSave && _hasSave)
                    GameMenuButton(
                      label: 'CONTINUE',
                      icon: Icons.history_rounded,
                      color: const Color(0xFF5B4FE8),
                      onTap: _continueGame,
                    ),
                  if (!_checkingSave && _hasSave) const SizedBox(height: 14),
                  GameMenuButton(
                    label: 'HOW TO PLAY',
                    icon: Icons.help_outline_rounded,
                    color: const Color(0xFF3355AA),
                    onTap: () => showControlsDialog(context, mobileControls: _mobileControls),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlToggle extends StatelessWidget {
  final bool mobileControls;
  final ValueChanged<bool> onChanged;

  const _ControlToggle({required this.mobileControls, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'PC',
            icon: Icons.keyboard_rounded,
            selected: !mobileControls,
            onTap: () => onChanged(false),
          ),
          _ToggleOption(
            label: 'Mobile',
            icon: Icons.touch_app_rounded,
            selected: mobileControls,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5B4FE8) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : const Color(0x99FFFFFF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0x99FFFFFF),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}