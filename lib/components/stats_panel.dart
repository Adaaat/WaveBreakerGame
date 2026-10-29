import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/WaveBreaker.dart';
import 'pressable_button.dart';

class StatsButton extends PressableButton {
  StatsButton()
      : super(
    size: Vector2(110, 30),
    anchor: Anchor.topRight,
    normalColor: const Color(0xFF3355AA),
    pressedColor: const Color(0xFF25407D),
  );

  late TextComponent label;
  bool panelOpen = false;
  late StatsPanel panel;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    label = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
    add(label);
    panel = StatsPanel();
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Sits just below levelText (y:104), clear of the pause button.
    position = Vector2(size.x - 16, 136);
  }

  @override
  void update(double dt) {
    super.update(dt);
    label.text = 'Stats: ${game.stats.statPoints}';
  }

  @override
  void onPressed() {
    panelOpen = !panelOpen;
    if (panelOpen) {
      game.add(panel);
    } else {
      panel.removeFromParent();
    }
  }
}

class StatsPanel extends PositionComponent with HasGameRef<Fluttergame> {
  StatsPanel() : super(size: Vector2(200, 140), anchor: Anchor.topRight, priority: 25);

  late TextComponent hpText;
  late TextComponent dmgText;
  late TextComponent spdText;
  late TextComponent pointsText;

  TextPaint get _style => TextPaint(
    style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
  );

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(size: size, paint: Paint()..color = const Color(0xEE1B1B2E)));

    pointsText = TextComponent(text: '', position: Vector2(10, 8), textRenderer: _style);
    hpText = TextComponent(text: '', position: Vector2(10, 40), textRenderer: _style);
    dmgText = TextComponent(text: '', position: Vector2(10, 72), textRenderer: _style);
    spdText = TextComponent(text: '', position: Vector2(10, 104), textRenderer: _style);

    addAll([pointsText, hpText, dmgText, spdText]);

    add(_StatSpendButton(
      label: '+ HP',
      buttonPosition: Vector2(140, 38),
      onTap: () => game.stats.spendPointOnHp(),
    ));
    add(_StatSpendButton(
      label: '+ DMG',
      buttonPosition: Vector2(140, 70),
      onTap: () => game.stats.spendPointOnDamage(),
    ));
    add(_StatSpendButton(
      label: '+ SPD',
      buttonPosition: Vector2(140, 102),
      onTap: () => game.stats.spendPointOnSpeed(),
    ));

    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    position = Vector2(newSize.x - 16, 174);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final s = game.stats;
    pointsText.text = 'Points available: ${s.statPoints}';
    hpText.text = 'HP: ${s.maxHp}';
    dmgText.text = 'DMG x${s.damageMultiplier.toStringAsFixed(2)}';
    spdText.text = 'SPD x${s.speedMultiplier.toStringAsFixed(2)}';
  }
}

class _StatSpendButton extends PressableButton {
  final String label;
  final VoidCallback onTap;

  _StatSpendButton({required this.label, required Vector2 buttonPosition, required this.onTap})
      : super(size: Vector2(50, 26), position: buttonPosition);

  @override
  bool get isEnabled => game.stats.statPoints > 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(
      text: label,
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12)),
    ));
  }

  @override
  void onPressed() => onTap();
}