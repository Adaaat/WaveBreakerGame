import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/WaveBreaker.dart';
import 'pressable_button.dart';

class GameHud extends PositionComponent with HasGameRef<Fluttergame> {
  late TextComponent livesText;
  late TextComponent waveText;
  late TextComponent ammoText;
  late TextComponent levelText;

  final TextPaint _style = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    priority = 20;

    livesText = TextComponent(text: '', textRenderer: _style, position: Vector2(16, 16));
    ammoText = TextComponent(text: '', textRenderer: _style, position: Vector2(16, 40));
    waveText = TextComponent(text: '', textRenderer: _style, anchor: Anchor.topCenter);
    levelText = TextComponent(text: '', textRenderer: _style, anchor: Anchor.topRight);

    addAll([livesText, ammoText, waveText, levelText]);
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isMounted) {
      waveText.position = Vector2(size.x / 2, 16);
      levelText.position = Vector2(size.x - 16, 104);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final stats = game.stats;
    final wm = game.waveManager;

    livesText.text = 'Lives: ${'♥ ' * stats.lives}${'♡ ' * (stats.maxLives - stats.lives)}'
        ' (HP ${stats.currentHp}/${stats.maxHp})';
    ammoText.text = 'Ammo: ${stats.bulletsRemaining}/${stats.maxBulletsPerWave}';
    waveText.text = wm.waveInProgress
        ? 'Wave ${wm.currentWave}'
        : 'Wave ${wm.currentWave} — Ready';
    levelText.text = 'Lv ${stats.level}  (${stats.xp}/${stats.xpToNextLevel} XP)';
  }
}

class StartWaveButton extends PressableButton {
  StartWaveButton() : super(size: Vector2(150, 42), anchor: Anchor.center);

  late TextComponent label;

  @override
  bool get isEnabled => !game.waveManager.waveInProgress && game.waveManager.portals.isNotEmpty;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    label = TextComponent(
      text: 'Start Wave',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
    add(label);
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, size.y - 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    label.text = 'Start Wave ${game.waveManager.currentWave}';
  }

  @override
  void onPressed() {
    game.waveManager.startWave();
  }

  @override
  void render(Canvas canvas) {
    if (game.waveManager.waveInProgress) return;
    super.render(canvas);
  }
}