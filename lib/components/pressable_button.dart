import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/WaveBreaker.dart';


abstract class PressableButton extends PositionComponent
    with TapCallbacks, HasGameRef<Fluttergame> {
  PressableButton({
    required Vector2 size,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
    this.normalColor = const Color(0xFF3E8E41),
    this.pressedColor = const Color(0xFF2C6630),
    this.disabledColor = const Color(0xFF555555),
    int priority = 20,
  }) : super(size: size, position: position, anchor: anchor, priority: priority);

  final Color normalColor;
  final Color pressedColor;
  final Color disabledColor;

  late final RectangleComponent background;

  bool get isEnabled => true;

  void onPressed() {}

  @override
  Future<void> onLoad() async {
    background = RectangleComponent(
      size: size,
      paint: Paint()..color = normalColor,
    );
    add(background);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isEnabled) {
      background.paint.color = disabledColor;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isEnabled) return;
    background.paint.color = pressedColor;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isEnabled) return;
    background.paint.color = normalColor;
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (!isEnabled) return;
    background.paint.color = normalColor;
  }
}