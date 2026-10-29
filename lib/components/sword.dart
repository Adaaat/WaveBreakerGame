import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:fluttergame/components/chicken.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'BlackSlime.dart';
import 'Chameleon.dart';
import 'Skeleton.dart';
import 'Slime.dart';
import 'custom_hitbox.dart';

enum SwordState{
  sword,
  noSword,
}

class Sword extends SpriteAnimationGroupComponent with HasGameRef<Fluttergame>, CollisionCallbacks{
  Sword({super.position , super.size, this.visible = false});

  late Player player;
  bool visible;
  final double stepTime = 0.05;

  late final SpriteAnimation swordAnimation;
  late final SpriteAnimation noSwordAnimation;

  bool isFacingRight = true;
  late final RectangleHitbox hitboxComponent; // <-- store the reference



  final hitbox = CustomHitbox(
      offsetX: 30,
      offsetY: 50,
      width: 38,
      height: 12
  );

  @override
  FutureOr<void> onLoad() {
   // debugMode = true;
    player = game.player;
    _loadAllAnimations();
    position = player.position + Vector2(-14,-26);

    hitboxComponent = RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
        collisionType: CollisionType.passive
    );
    add(hitboxComponent);

    return super.onLoad();
  }
  void _loadAllAnimations() {

    swordAnimation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/MyChar/sword4.png'),
        SpriteAnimationData.sequenced(
            amount: 7,
            stepTime: stepTime* 1.2,
            textureSize: Vector2(100, 64),
            loop: false
        )
    );


    // runningAnimation = _spriteAnimation('Run', 12);
    noSwordAnimation =  SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/MyChar/noSword.png'),
        SpriteAnimationData.sequenced(
            amount: 1,
            stepTime: stepTime,
            textureSize: Vector2(100, 64),
            loop: false
        )
    );


    //List of all animations
    animations = {
      SwordState.sword: swordAnimation,
      SwordState.noSword: noSwordAnimation,

    };

    //Set current animation
    current = SwordState.noSword;
  }

  @override
  void update(double dt) {
    // keep hitbox mirrored to match the current facing direction
    if (isFacingRight) {
      hitboxComponent.position = Vector2(hitbox.offsetX, hitbox.offsetY);
    } else {
      hitboxComponent.position = Vector2(width - hitbox.offsetX - hitbox.width, hitbox.offsetY);
    }

    // only take part in collision checks while actually swinging
    hitboxComponent.collisionType = visible ? CollisionType.passive : CollisionType.inactive;

    if (visible) {
      swordAnimator();
    } else {
      current = SwordState.noSword;
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if(other is Chicken && visible){
      Future.delayed(const Duration(milliseconds: 50),() { other.swordCollision();});

    } else if (other is Slime && visible) { // NEU FÜR SLIME
      Future.delayed(const Duration(milliseconds: 50), () {other.takeDamage(game.stats.scaledDamage); });

    } else if (other is BlackSlime && visible) { // NEU FÜR SLIME
      Future.delayed(const Duration(milliseconds: 50), () { other.takeDamage(game.stats.scaledDamage); });
    }
    else if (other is Chameleon && visible) {
      Future.delayed(const Duration(milliseconds: 50), () { other.takeDamage(game.stats.scaledDamage); });
    }

    super.onCollision(intersectionPoints, other);
  }

  void swing()async{
    visible = true;
  }

  void swordAnimator() async{
    current =SwordState.sword;

    await animationTicker?.completed;
    animationTicker?.reset();
    visible = false;
    current= SwordState.noSword;
  }

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
