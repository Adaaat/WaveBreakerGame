import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/WaveBreaker.dart';

class GameOverOverlay extends PositionComponent with TapCallbacks, HasGameRef<Fluttergame> {
  GameOverOverlay() : super(priority: 100);

  @override
  Future<void> onLoad() async {
    size = game.size;

    add(RectangleComponent(size: size, paint: Paint()..color = const Color(0xCC000000)));
    add(TextComponent(
      text: 'GAME OVER',
      anchor: Anchor.center,
      position: size / 2 - Vector2(0, 30),
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFFF5555), fontSize: 32, fontWeight: FontWeight.bold),
      ),
    ));
    add(TextComponent(
      text: 'Tap to restart',
      anchor: Anchor.center,
      position: size / 2 + Vector2(0, 20),
      textRenderer: TextPaint(style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18)),
    ));
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.restartFromGameOver();
    removeFromParent();
  }
}