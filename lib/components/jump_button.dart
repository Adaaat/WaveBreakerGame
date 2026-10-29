import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:fluttergame/WaveBreaker.dart';


class JumpButton extends PositionComponent with TapCallbacks, HasGameRef<Fluttergame> {
  JumpButton() : super(size: Vector2(64, 64), anchor: Anchor.bottomRight, priority: 10);

  late final CircleComponent circle;

  final Color _normalColor = const Color(0x99C2793C);
  final Color _pressedColor = const Color(0xCCC2793C);

  @override
  Future<void> onLoad() async {
    circle = CircleComponent(
      radius: size.x / 2,
      paint: Paint()..color = _normalColor,
    );
    add(circle);

    add(
      _UpArrow()
        ..size = Vector2(30, 30)
        ..anchor = Anchor.center
        ..position = size / 2,
    );

    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 24, size.y - 24);
  }

  @override
  void onTapDown(TapDownEvent event) {
    circle.paint.color = _pressedColor;
    game.player.hasJumped = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    circle.paint.color = _normalColor;
    game.player.hasJumped = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    circle.paint.color = _normalColor;
    game.player.hasJumped = false;
  }
}


class _UpArrow extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    final w = size.x;
    final h = size.y;

    final path = Path()
      ..moveTo(w * 0.5, 0) // tip
      ..lineTo(w, h * 0.55) // right wing
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w * 0.68, h) // stem bottom-right
      ..lineTo(w * 0.32, h) // stem bottom-left
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(0, h * 0.55) // left wing
      ..close();

    canvas.drawPath(path, paint);
  }
}