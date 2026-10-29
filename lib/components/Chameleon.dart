import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/collision_block.dart';
import 'package:fluttergame/WaveBreaker.dart';
import '../WaveManager.dart';
import 'custom_hitbox.dart';

enum ChameleonState { idle, run, attack, hit }

class Chameleon extends SpriteAnimationGroupComponent
    with HasGameRef<Fluttergame>, CollisionCallbacks {

  Chameleon({super.position});

  bool _wasMirrored = false;
  List<CollisionBlock> collisionBlocks = [];

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runAnimation;
  late final SpriteAnimation attackAnimation;
  late final SpriteAnimation hitAnimation;

  final double wanderChangeInterval = 2.0;
  double _wanderTimer = 0;
  int _wanderDirection = 0; // -1, 0, or 1
  final Random _random = Random();


  final double stepTime = 0.05;
  int hp = 3;
  double moveSpeed = 45;
  int attackDamage = 1;
  Vector2 velocity = Vector2.zero();

  final double _gravity = 9.8;
  final double _terminalVelocity = 300;
  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  late Player player;
  bool isHit = false;
  bool isDead = false;
  bool isAttacking = false;

  final double attackRange = 58.0;

  static const bool _artFacesRight = false;

  bool _isFacingRight = true;

  bool get isFacingRight => _isFacingRight;

  set isFacingRight(bool value) {
    if (value == _isFacingRight) return;

    final oldOffsetX = _offsetXFor(_isFacingRight);
    _isFacingRight = value;
    final newOffsetX = _offsetXFor(_isFacingRight);

    position.x += oldOffsetX - newOffsetX;

    // THIS LINE IS CRITICAL TO PREVENT HITBOX TELEPORTING
    hitboxComponent.position = Vector2(newOffsetX, hitbox.offsetY);
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
      offsetX: 45,
      offsetY: 9,
      width: 24,
      height: 26
  );




  @override
  FutureOr<void> onLoad() {
//debugMode=true;
    player = game.player;
    final int wave = game.waveManager.currentWave;
    hp = (3 + ((wave - 1) ~/ 2));
    moveSpeed = (45.0 + ((wave - 1) * 1.5)).clamp(45.0,67.0);
    attackDamage = 1 + ((wave - 1) ~/ 3);

    _loadAllAnimations();

    _wasMirrored = _mirrored; // sync initial state so no phantom jump on frame 1

    hitboxComponent = RectangleHitbox(
      position: Vector2(_currentOffsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    );
    add(hitboxComponent);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || (hp <= 0 && isHit)) return;



    accumulatedTime += dt;
    while (accumulatedTime >= fixedDeltaTime) {
      if (!isHit && !isAttacking) {
        _updateMovement(fixedDeltaTime);
      }
      _checkHorizontalCollisions();
      _applyGravity(fixedDeltaTime);
      _checkVerticalCollisions();
      accumulatedTime -= fixedDeltaTime;
    }
  }

  void _syncFacingOffset() {
    if (_mirrored != _wasMirrored) {
      final oldOffsetX = _wasMirrored
          ? (width - hitbox.offsetX - hitbox.width)
          : hitbox.offsetX;
      final newOffsetX = _currentOffsetX;

      position.x += oldOffsetX - newOffsetX;

      _wasMirrored = _mirrored;
    }
  }

  void _updateMovement(double dt) {
    velocity.x = 0;

    final double dx = (player.position.x + player.width / 2) - _bodyCenterX;
    final double dy = (player.position.y + player.height / 2) - _bodyCenterY;

    final bool playerIsAbove = dy < -5.0;

    final bool playerInFront = (dx > 0) == isFacingRight;

    const double frontDetectionRange = 220.0;
    const double backDetectionRange = 50.0;

    final bool similarHeight = dy.abs() < 50;

    if (dx.abs() <= attackRange && dy.abs() < 30) {
      if (!playerIsAbove) {
        isFacingRight = dx > 0;
      }
      _attack(dx > 0 ? 1 : -1);
      return;
    }

    bool detected = false;
    if (playerInFront) {
      detected = dx.abs() <= frontDetectionRange && similarHeight;
    } else {
      detected = dx.abs() <= backDetectionRange && similarHeight;
    }

    if (detected) {
      final double direction = dx > 0 ? 1 : -1;
      velocity.x = direction * moveSpeed;

      if (!playerIsAbove) {
        isFacingRight = direction > 0;
      }

      current = ChameleonState.run;
    } else {
      _updateWander(dt);
    }

    position.x += velocity.x * dt;
  }

  void _updateWander(double dt) {
    _wanderTimer -= dt;
    if (_wanderTimer <= 0) {
      _wanderTimer = wanderChangeInterval + _random.nextDouble() * wanderChangeInterval;
      final roll = _random.nextDouble();
      if (roll < 0.4) {
        _wanderDirection = 0; // 40% chance to stand still
      } else if (roll < 0.7) {
        _wanderDirection = -1; // 30% chance to walk left
      } else {
        _wanderDirection = 1; // 30% chance to walk right
      }
    }

    velocity.x = _wanderDirection * (moveSpeed * 0.5);

    if (_wanderDirection != 0) {
      isFacingRight = _wanderDirection > 0;
      current = ChameleonState.run;
    } else {
      current = ChameleonState.idle;
    }
  }
  void _attack(double targetDirection) async {
    isAttacking = true;
    velocity.x = 0;
    current = ChameleonState.attack;

    await Future.delayed(const Duration(milliseconds: 250));

    final dx = (player.position.x + player.width / 2) - _bodyCenterX;
    final dy = (player.position.y + player.height / 2) - _bodyCenterY;
    final bool playerOnFacingSide = (dx > 0) == isFacingRight;

    if (dx.abs() <= attackRange && dy.abs() < 25 && playerOnFacingSide) {
      player.collidedWithEnemy(attackDamage);
    }

    await animationTicker?.completed;
    animationTicker?.reset();
    isAttacking = false;

    current = ChameleonState.idle;
  }

  void takeDamage(int damage) async {
    if (isHit || hp <= 0) return;

    hp -= damage;
    print("Chameleon HP: $hp");

    isHit = true;
    isAttacking = false;
    velocity.x = 0;

    current = ChameleonState.hit;

    await animationTicker?.completed;

    if (hp <= 0) {
      print("Chameleon died!");

      isDead = true;

      game.waveManager.enemyDefeated();

      print("Removing from parent...");
      removeFromParent();

      print("removeFromParent() called");
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
          break;
        }
        if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width - _currentOffsetX;
          break;
        }
      }
    }
  }


  void _checkVerticalCollisions() {
    for (final block in collisionBlocks){
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
    final bodyX = position.x + _currentOffsetX;
    final bodyY = position.y + hitbox.offsetY;
    final bodyWidth = hitbox.width;
    final bodyHeight = hitbox.height;

    final blockX = block.x;
    final blockY = block.y;
    final blockWidth = block.width;
    final blockHeight = block.height;

    return (bodyY < blockY + blockHeight &&
        bodyY + bodyHeight > blockY &&
        bodyX < blockX + blockWidth &&
        bodyX + bodyWidth > blockX);
  }


  final double _bounceHeight = 260; // to match your other enemies (Chicken's _bounceHeight)

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player && !isHit && hp > 0) {
      _handlePlayerCollision(other);
    }
    super.onCollisionStart(intersectionPoints, other);
  }


  void _handlePlayerCollision(Player player) async {
    final bool isStomp = player.velocity.y > 0 &&
        (player.y + player.height) <= (position.y + hitbox.offsetY + hitbox.height * 0.5);

    if (isStomp) {
      if (game.playSounds) {
        FlameAudio.play('bounce.wac', volume: game.soundVolume);
      }
      player.velocity.y = -_bounceHeight;
      takeDamage((game.stats.scaledDamage/2).ceil());
    } else {
      player.collidedWithEnemy(attackDamage);
    }
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle (84x38)', 13);
    runAnimation = _spriteAnimation('Run (84x38)', 8);
    attackAnimation = _spriteAnimation('Attack (84x38)', 10, loop: false);
    hitAnimation = _spriteAnimation('Hit (84x38)', 5, loop: false);

    animations = {
      ChameleonState.idle: idleAnimation,
      ChameleonState.run: runAnimation,
      ChameleonState.attack: attackAnimation,
      ChameleonState.hit: hitAnimation,
    };

    current = ChameleonState.idle;
  }

  SpriteAnimation _spriteAnimation(String name, int amount, {bool loop = true}) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Chameleon/$name.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2(84, 38),
        loop: loop,
      ),
    );
  }

  double get _bodyCenterX => position.x + _currentOffsetX + hitbox.width / 2;
  double get _bodyCenterY => position.y + hitbox.offsetY + hitbox.height / 2;

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