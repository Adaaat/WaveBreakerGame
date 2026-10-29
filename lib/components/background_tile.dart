import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class BackgroundTile extends ParallaxComponent {
  final String color;
  BackgroundTile({
    this.color = 'Gray',
    position,
  }) : super(
    position: position,
  );

  final double scrollSpeed = 40;

  @override
  FutureOr<void> onLoad() async {
    priority = -10;

    // size = Vector2.all(64);

    parallax = await game.loadParallax(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(40, 0),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.none,

      alignment: Alignment.bottomLeft,
    );
    return super.onLoad();
  }
}