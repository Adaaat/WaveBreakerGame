import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/collision_block.dart';
import 'package:fluttergame/WaveBreaker.dart';
import '../WaveManager.dart';
import 'custom_hitbox.dart';

enum SlimeState { idleRun, hit }

class Slime extends SpriteAnimationGroupComponent
    with HasGameRef<Fluttergame>, CollisionCallbacks {

  Slime({super.position});

  late final SpriteAnimation idleRunAnimation;
  late final SpriteAnimation hitAnimation;

  final double stepTime = 0.05;
  int hp = 1;
  double moveSpeed = 30;
  int attackDamage = 1;
  Vector2 velocity = Vector2.zero();

  List<CollisionBlock> collisionBlocks = [];

  final double _gravity = 9.8;
  final double _terminalVelocity = 300;

  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  late Player player;
  bool isHit = false;

  // Idle wandering while the player hasn't been noticed yet.
  final double wanderChangeInterval = 2.0;
  double _wanderTimer = 0;
  int _wanderDirection = 0; // -1, 0, or 1
  final Random _random = Random();

  // The raw artwork's neutral pose faces LEFT (matches old code: scale.x = -1 when moving right)
  static const bool _artFacesRight = false;

  bool _isFacingRight = true;
  bool get isFacingRight => _isFacingRight;
  set isFacingRight(bool value) {
    if (value == _isFacingRight) return;

    final oldOffsetX = _offsetXFor(_isFacingRight);
    _isFacingRight = value;
    final newOffsetX = _offsetXFor(_isFacingRight);

    // Keep the body's world-space position fixed; only the frame shifts.
    position.x += oldOffsetX - newOffsetX;
  }

  bool _mirroredFor(bool facingRight) => facingRight != _artFacesRight;
  double _offsetXFor(bool facingRight) {
    return _mirroredFor(facingRight)
        ? (width - hitbox.offsetX - hitbox.width)
        : hitbox.offsetX;
  }

  bool get _mirrored => _mirroredFor(isFacingRight);
  double get _currentOffsetX => _offsetXFor(isFacingRight);

  late final RectangleHitbox hitboxComponent;

  CustomHitbox hitbox = CustomHitbox(
      offsetX: 10,
      width: 25,
      offsetY: 10,
      height: 20
  );

  @override
  FutureOr<void> onLoad() {
    player = game.player;

    final int wave = game.waveManager.currentWave;
    hp = (1 + ((wave - 1) ~/ 2));
    moveSpeed = (30 + ((wave - 1) * 2.0)).clamp(45.0,75.0);
    attackDamage = 1 + ((wave - 1) ~/ 3);



    _loadAllAnimations();

    hitboxComponent = RectangleHitbox(
      position: Vector2(_currentOffsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    );
    add(hitboxComponent);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (hp <= 0 && isHit) {
      super.update(dt);
      return;
    }

    hitboxComponent.position = Vector2(_currentOffsetX, hitbox.offsetY);

    accumulatedTime += dt;
    const maxStepsPerFrame = 5;
    int steps = 0;
    while (accumulatedTime >= fixedDeltaTime && steps < maxStepsPerFrame) {
      if (!isHit) {
        _updateMovement(fixedDeltaTime);
      }
      _checkHorizontalCollisions();
      _applyGravity(fixedDeltaTime);
      _checkVerticalCollisions();
      accumulatedTime -= fixedDeltaTime;
      steps++;
    }
    if (steps == maxStepsPerFrame) {
      accumulatedTime = 0;
    }

    super.update(dt);
  }

  void _updateMovement(double dt) {
    velocity.x = 0;

    final double playerCenterX = player.position.x + player.width / 2;
    final double playerCenterY = player.position.y + player.height / 2;

    final double slimeCenterX = position.x + _currentOffsetX + hitbox.width / 2;
    final double slimeCenterY = position.y + hitbox.offsetY + hitbox.height / 2;

    final double dx = playerCenterX - slimeCenterX;
    final double dy = playerCenterY - slimeCenterY;

    const double detectionRange = 220.0;
    const double behindRange = 60.0;
    const double verticalTolerance = 150.0;
    const double stopDistance = 15.0;

    final bool playerInFront = (dx > 0) == isFacingRight;

    bool canSeePlayer = false;

    if (playerInFront) {
      canSeePlayer =
          dx.abs() <= detectionRange &&
              dy.abs() <= verticalTolerance;
    } else {
      canSeePlayer =
          dx.abs() <= behindRange &&
              dy.abs() <= verticalTolerance;
    }

    if (canSeePlayer) {
      _wanderTimer = 0; // forget wandering the moment it notices you
      final double direction = dx > 0 ? 1 : -1;

      if (dx.abs() > stopDistance) {
        velocity.x = direction * moveSpeed;
        isFacingRight = direction > 0;
      }
    } else {
      _updateWander(dt);
    }

    position.x += velocity.x * dt;
    current = SlimeState.idleRun;
  }

  void _updateWander(double dt) {
    _wanderTimer -= dt;
    if (_wanderTimer <= 0) {
      _wanderTimer = wanderChangeInterval + _random.nextDouble() * wanderChangeInterval;
      final roll = _random.nextDouble();
      if (roll < 0.4) {
        _wanderDirection = 0; // stand still for a bit
      } else if (roll < 0.7) {
        _wanderDirection = -1;
      } else {
        _wanderDirection = 1;
      }
    }

    velocity.x = _wanderDirection * (moveSpeed * 0.5); // wander slower than chase speed
    if (_wanderDirection != 0) {
      isFacingRight = _wanderDirection > 0;
    }
  }

  void takeDamage(int damage) async {
    if (isHit || hp <= 0) return;

    hp -= damage;
    isHit = true;
    velocity.x = 0;

    current = SlimeState.hit;
    await animationTicker?.completed;

    if (hp <= 0) {
      game.waveManager.enemyDefeated();
      removeFromParent();
    } else {
      isHit = false;
      animationTicker?.reset();
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-1000.0, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform && _checkCollision(block)) {
        if (velocity.x > 0) {
          velocity.x = 0;
          position.x = block.x - _currentOffsetX - hitbox.width;
          _turnAround();
          break;
        }
        if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width - _currentOffsetX;
          _turnAround();
          break;
        }
      }
    }
  }

  void _turnAround() {
    isFacingRight = !isFacingRight;
    _wanderDirection = isFacingRight ? 1 : -1;
    _wanderTimer = wanderChangeInterval; // don't immediately re-randomize back into the wall
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
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

  bool _checkCollision(CollisionBlock block) {
    final slimeX = position.x + _currentOffsetX;
    final slimeY = position.y + hitbox.offsetY;

    final slimeWidth = hitbox.width;
    final slimeHeight = hitbox.height;

    return (
        slimeY < block.y + block.height &&
            slimeY + slimeHeight > block.y &&
            slimeX < block.x + block.width &&
            slimeX + slimeWidth > block.x
    );
  }

  void _loadAllAnimations() {
    idleRunAnimation = _spriteAnimation('Idle-Run (44x30)', 10, loop: true);
    hitAnimation = _spriteAnimation('Hit (44x30)', 5, loop: false);

    animations = {
      SlimeState.idleRun: idleRunAnimation,
      SlimeState.hit: hitAnimation,
    };

    current = SlimeState.idleRun;
  }

  SpriteAnimation _spriteAnimation(String name, int amount, {bool loop = true}) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Slime/$name.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2(44, 30),
        loop: loop,
      ),
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !isHit && hp > 0) {
      player.collidedWithEnemy(attackDamage);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void render(Canvas canvas) {
    if (_mirrored) {
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