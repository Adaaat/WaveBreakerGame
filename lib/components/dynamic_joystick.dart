import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/cupertino.dart' show Color, Paint;
import 'package:fluttergame/WaveBreaker.dart';


class DynamicJoystick extends PositionComponent
    with DragCallbacks, HasGameRef<Fluttergame> {
  DynamicJoystick() : super(priority: 10);

  CircleComponent? _background;
  CircleComponent? _knob;

  bool _active = false;
  Vector2 _origin = Vector2.zero();
  Vector2 _knobOffset = Vector2.zero();

  final double _backgroundRadius = 70;
  final double _knobRadius = 30;
  final double _radius = 60; // how far the knob can travel from the touch point
  final double _deadzone = 0.3; // fraction of radius before movement registers

  @override
  Future<void> onLoad() async {
    onGameResize(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x < size.x / 2;
  }

  @override
  void onDragStart(DragStartEvent event) {

    if (_active || _background != null || _knob != null) {
      _reset();
    }

    _active = true;
    _origin = event.localPosition.clone();
    _knobOffset = Vector2.zero();

    _background = CircleComponent(
      radius: _backgroundRadius,
      anchor: Anchor.center,
      position: _origin,
      paint: Paint()..color = const Color(0x66FFFFFF),
    );
    _knob = CircleComponent(
      radius: _knobRadius,
      anchor: Anchor.center,
      position: _origin,
      paint: Paint()..color = const Color(0xCCFFFFFF),
    );

    addAll([_background!, _knob!]);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_active || _knob == null) return;

    _knobOffset += event.localDelta;
    if (_knobOffset.length > _radius) {
      _knobOffset = _knobOffset.normalized() * _radius;
    }
    _knob!.position = _origin + _knobOffset;

    final normalized = _knobOffset / _radius; // roughly -1..1 on each axis

    if (normalized.x < -_deadzone) {
      game.player.horizontalMovement = -1;
    } else if (normalized.x > _deadzone) {
      game.player.horizontalMovement = 1;
    } else {
      game.player.horizontalMovement = 0;
    }

    game.player.wantsToDrop = normalized.y > 0.5;
  }

  @override
  void onDragEnd(DragEndEvent event) => _reset();

  @override
  void onDragCancel(DragCancelEvent event) => _reset();

  void _reset() {
    _active = false;
    _knobOffset = Vector2.zero();

    _background?.removeFromParent();
    _knob?.removeFromParent();
    _background = null;
    _knob = null;

    game.player.horizontalMovement = 0;
    game.player.wantsToDrop = false;
  }
}