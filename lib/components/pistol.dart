import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:fluttergame/components/bullet.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'custom_hitbox.dart';

enum State{
  pistol,
  noPistol,
}

class Pistol extends SpriteAnimationGroupComponent with HasGameRef<Fluttergame>{
  Pistol({super.position , super.size, this.visible = false});

  late Player player;
  bool visible;
  final double stepTime = 0.05;
  bool isShot = false;

  late final SpriteAnimation pistolAnimation;
  late final SpriteAnimation noPistolAnimation;


  @override
  FutureOr<void> onLoad() {
    debugMode = false;
    player = game.player;
    position = player.position + Vector2(-14,-26 );


    _loadAllAnimations();


    return super.onLoad();
  }

  void update(double dt) {
    if (visible) {
      shootBullet();
    }else{
      current =State.noPistol;
    }
    super.update(dt);

  }

  void _loadAllAnimations() {
    pistolAnimation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/MyChar/pistolTry2.png'),
        SpriteAnimationData.sequenced(
            amount: 1,
            stepTime: stepTime* 7,
            textureSize: Vector2(17, 13),
            loop: false
        )
    );


    // runningAnimation = _spriteAnimation('Run', 12);
    noPistolAnimation =  SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/MyChar/noPistol.png'),
        SpriteAnimationData.sequenced(
            amount: 1,
            stepTime: stepTime,
            textureSize: Vector2(17, 13),
            loop: false
        )
    );

    animations = {
      State.pistol: pistolAnimation,
      State.noPistol: noPistolAnimation
    };
    current = State.noPistol;
  }

  void shoot(){
    visible = true;
  }

  int bulletCounter = 0;

  Future<void> shootBullet() async {

    if (bulletCounter == 0){
      if (!game.stats.useBullet()) {
        // out of ammo — cancel the shot attempt silently
        visible = false;
        current = State.noPistol;
        return;
      }

      bulletCounter = 1;
      current = State.pistol;
      isShot = false;

      Bullet bullet = Bullet();
      game.currentLevel.add((bullet));

      await animationTicker?.completed;
      animationTicker?.reset();
      visible = false;
      current= State.noPistol;

      bulletCounter = 0;
    }
  }

  bool isFacingRight = true;

  @override
  void render(Canvas canvas) {
    if (!isFacingRight) {
      canvas.save();
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

}