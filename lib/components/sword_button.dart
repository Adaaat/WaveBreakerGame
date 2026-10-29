import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/WaveBreaker.dart';

class SwordButton extends PositionComponent with TapCallbacks, HasGameRef<Fluttergame> {
  SwordButton() : super(size: Vector2(60, 60), anchor: Anchor.bottomRight, priority: 10);

  late final CircleComponent circle;

  @override
  Future<void> onLoad() async {
    circle = CircleComponent(
      radius: size.x / 2,
      paint: Paint()..color = const Color(0x993E8E41),
    );
    add(circle);
    add(TextComponent(
      text: 'SWORD',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    ));
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 24 - 64 - 16 - 60 - 16, size.y - 24);
  }

  @override
  void onTapDown(TapDownEvent event) {
    circle.paint.color = const Color(0xCC3E8E41);
    game.player.isSwingig = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    circle.paint.color = const Color(0x993E8E41);
    game.player.isSwingig = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    circle.paint.color = const Color(0x993E8E41);
    game.player.isSwingig = false;
  }
}