import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/collision_block.dart';
import 'package:fluttergame/WaveBreaker.dart';
import 'custom_hitbox.dart';

enum SkeletonState { walk, attack, hurt, death, idle }

class Skeleton extends SpriteAnimationGroupComponent
    with HasGameRef<Fluttergame>, CollisionCallbacks {

  // super.size entfernt, damit Tiled das 96x64 Sprite nicht auf 0x0 schrumpft
  Skeleton({super.position});

  late final SpriteAnimation walkAnimation;
  late final SpriteAnimation attackAnimation;
  late final SpriteAnimation hurtAnimation;
  late final SpriteAnimation deathAnimation;
  late final SpriteAnimation idleAnimation;

  final double stepTime = 0.05;
  int hp = 3;
  double moveSpeed = 50;
  Vector2 velocity = Vector2.zero();

  final double _gravity = 9.8;
  final double _terminalVelocity = 300;

  double fixedDeltaTime = 1 / 60; // 60fps
  double accumulatedTime = 0;

  late Player player;

  bool isHit = false;
  bool isDead = false;

  // Angepasste Hitbox für das 96x64 Sprite (damit es mittig auf dem Boden steht)
  CustomHitbox hitbox = CustomHitbox(
      offsetX: 38,
      offsetY: 24,
      width: 20,
      height: 40
  );

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    print("skeleton spawned");
    player = game.player;

    _loadAllAnimations();

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (isDead) return;

    accumulatedTime += dt;

    // Fixed Timestep-Schleife (wie bei deinem Player)
    while (accumulatedTime >= fixedDeltaTime) {
      if (!isHit) {
        _updateMovement(fixedDeltaTime);
      }

      _checkHorizontalCollisions();
      _applyGravity(fixedDeltaTime);
      _checkVerticalCollisions();

      accumulatedTime -= fixedDeltaTime;
    }

    super.update(dt);
  }

  void _updateMovement(double dt) {
    double direction = 0;

    if (player.position.x > position.x) {
      direction = 1;
      if (scale.x < 0) flipHorizontallyAroundCenter();
    } else if (player.position.x < position.x) {
      direction = -1;
      if (scale.x > 0) flipHorizontallyAroundCenter();
    }

    velocity.x = direction * moveSpeed;
    position.x += velocity.x * dt;

    current = SkeletonState.walk;
  }

  void takeDamage(int damage) async {
    if (isDead || isHit) return;

    hp -= damage;
    isHit = true;
    velocity.x = 0;

    if (hp <= 0) {
      isDead = true;
      current = SkeletonState.death;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      current = SkeletonState.hurt;
      await animationTicker?.completed;
      isHit = false;
    }
    animationTicker?.reset();
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-1000.0, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkHorizontalCollisions() {
    // Greift in jedem Frame auf player.collisionBlocks zu!
    for (final block in player.collisionBlocks) {
      if (!block.isPlatform && _checkCollision(block)) {
        if (velocity.x > 0) {
          velocity.x = 0;
          position.x = block.x - hitbox.offsetX - hitbox.width;
          break;
        }
        if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
          break;
        }
      }
    }
  }

  void _checkVerticalCollisions() {
    // Greift in jedem Frame auf player.collisionBlocks zu!
    for (final block in player.collisionBlocks) {
      if (block.isPlatform) {
        if (_checkCollision(block) && velocity.y > 0) {
          velocity.y = 0;
          position.y = block.y - hitbox.height - hitbox.offsetY;
          break;
        }
      } else {
        if (_checkCollision(block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  // Eigene Hilfsfunktion für die Kollision (um utils.dart nicht anzufassen)
  bool _checkCollision(CollisionBlock block) {
    final skeletonX = position.x + hitbox.offsetX;
    final skeletonY = position.y + hitbox.offsetY;
    final skeletonWidth = hitbox.width;
    final skeletonHeight = hitbox.height;

    final blockX = block.x;
    final blockY = block.y;
    final blockWidth = block.width;
    final blockHeight = block.height;

    return (skeletonY < blockY + blockHeight &&
        skeletonY + skeletonHeight > blockY &&
        skeletonX < blockX + blockWidth &&
        skeletonX + skeletonWidth > blockX);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('skeleton_idle_strip6', 6, loop: true);
    walkAnimation = _spriteAnimation('skeleton_walk_strip8', 8, loop: true);
    attackAnimation = _spriteAnimation('skeleton_attack_strip7', 7, loop: false);
    hurtAnimation = _spriteAnimation('skeleton_hurt_strip7', 7, loop: false);
    deathAnimation = _spriteAnimation('skeleton_death_strip10', 10, loop: false);

    animations = {
      SkeletonState.idle: idleAnimation,
      SkeletonState.walk: walkAnimation,
      SkeletonState.attack: attackAnimation,
      SkeletonState.hurt: hurtAnimation,
      SkeletonState.death: deathAnimation,
    };

    current = SkeletonState.walk;
  }

  SpriteAnimation _spriteAnimation(String name, int amount, {bool loop = true}) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Skeleton/$name.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2(96, 64),
        loop: loop,
      ),
    );
  }
}