import 'dart:async';
import 'dart:math';
import 'dart:ui';


import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'bullet.dart';
import 'collision_block.dart';

enum State{idle, run, hit}

class Chicken extends SpriteAnimationGroupComponent with HasGameRef<Fluttergame>, CollisionCallbacks{
  final double offNeg;
  final double offPos;
  Chicken({super.position, super.size, this.offPos = 0, this.offNeg = 0});

  static const stepTime = 0.05;
  static const tileSize = 16;
  static const runSpeed = 80;
  static const _bounceHeight = 260.0;
  final textureSize = Vector2(32, 34);

  Vector2 velocity = Vector2.zero();
  double rangeNeg = 0;
  double rangePos = 0;
  double moveDirection = 1;
  double targetDirection = -1;
  bool gotStomped = false;

  late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runAnimation;
  late final SpriteAnimation _hitAnimation;

  late final RectangleHitbox hitboxComponent;

  List<CollisionBlock> collisionBlocks = [];
  @override
  FutureOr<void> onLoad() {
 //   debugMode = true;
    player = game.player;

    hitboxComponent = RectangleHitbox(
      position: Vector2(4, 6),
      size: Vector2(24, 26),
      collisionType: CollisionType.active,
    );

    add(hitboxComponent);
    _loadAllAnimations();
    _calculateRange(); // wie weit das chicken sehen kann
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if(!gotStomped){
      _updateState();
      _movement(dt);
    }

    for (final component in game.children) {
      if (component is Bullet) {
        final oldPos = component.oldPosition;
        final newPos = component.position;
        final rect = toRect();
        if (_lineIntersectsRect(oldPos, newPos, rect)) {
          bulletCollision(component);
          component.removeFromParent();
          break;
        }
      }
    }


    super.update(dt);
  }

  void _loadAllAnimations() {
   _idleAnimation = _spriteAnimation('Idle', 13);
   _runAnimation = _spriteAnimation('Run', 14);
   _hitAnimation = _spriteAnimation('Hit', 5)..loop = false;

   animations = {
     State.idle: _idleAnimation,
     State.run: _runAnimation,
     State.hit: _hitAnimation,
   };

   current = State.idle;
  }
  
  SpriteAnimation _spriteAnimation(String state, int amount){
    return SpriteAnimation.fromFrameData(game.images.fromCache('Enemies/Chicken/$state (32x34).png'),
        SpriteAnimationData.sequenced(
            amount: amount,
            stepTime: stepTime,
            textureSize: textureSize));
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  void _movement(double dt) {
    //set velocity to 0
    velocity.x = 0;

    double playerOffset = (player.scale.x > 0) ? 0: - player.width; // je nachdem welche richtung
    double chickenOffset = (scale.x > 0) ? 0: -width; // je nachdem welche richtung

    if(playerInRange()){
      //player in Range
      targetDirection = (player.x + playerOffset < position.x + chickenOffset) ? -1 : 1; // links oder rechts
      velocity.x = targetDirection * runSpeed;
    }

    moveDirection =  lerpDouble(moveDirection, targetDirection, 0.1)?? 1; // delay

    position.x += velocity.x * dt;
  }

  bool playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0: - player.width;

    return player.x + playerOffset >= rangeNeg &&  // right from the chicken in range
      player.x + playerOffset <= rangePos && //  rechts vom chicken in range
      player.y + player.height > position.y &&// Bottom player höher als chicken oben
      player.y < position.y + height ;// top player niedriger als chicken unten
  }

  void _updateState() {
    current = (velocity.x != 0) ? State.run : State.idle;
    if((moveDirection > 0 && scale.x > 0) // move right and facing right und das Gleiche für left
        || (moveDirection < 0 && scale.x < 0)){
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async{

    if(player.velocity.y > 0 && player.y + player.height > position.y){
      if(game.playSounds){
        FlameAudio.play('bounce.wac', volume: game.soundVolume);
      }
      gotStomped = true; // bei false stirbt das chicken nicht wie bei einem Trampolin;
      current = State.hit;
      player.velocity.y = -_bounceHeight;
      await animationTicker?.completed;
      game.waveManager.enemyDefeated();
      removeFromParent();

    } else{
      player.collidedWithEnemy(1);
    }
  }

  void swordCollision() async{
    gotStomped = true; // bei false stirbt das chicken nicht wie bei einem Trampolin;
    current = State.hit;
    await animationTicker?.completed;
    game.waveManager.enemyDefeated();

    removeFromParent();
  }
  void bulletCollision( Bullet bullet) async{
    gotStomped = true; // bei false stirbt das chicken nicht wie bei einem Trampolin;
    current = State.hit;
    await animationTicker?.completed;
    game.waveManager.enemyDefeated();

    removeFromParent();
  }
    bool _lineIntersectsRect(Vector2 a, Vector2 b, Rect r) {
      final swept = Rect.fromLTRB(
        min(a.x, b.x),
        min(a.y, b.y),
        max(a.x, b.x),
        max(a.y, b.y),
      );
      return swept.overlaps(r);
    }
}