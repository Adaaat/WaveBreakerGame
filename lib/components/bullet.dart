import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:fluttergame/components/Chameleon.dart';
import 'package:fluttergame/components/BlackSlime.dart';
import 'package:fluttergame/components/pistol.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/utils.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'Slime.dart';
import 'chicken.dart';
import 'collision_block.dart';
import 'custom_hitbox.dart';

class Bullet extends SpriteAnimationComponent with CollisionCallbacks, HasGameRef<Fluttergame> {
  Bullet({super.position, super.size});

  late List<CollisionBlock> collisionBlocks = [];
  late Player player;

  final double stepTime = 0.05;

  Vector2 velocity = Vector2.zero();
  double horizontalMovement = 0;
  double movespeed = 450;

  late Vector2 oldPosition;

  final hitbox = CustomHitbox(offsetX: 0, offsetY: 0, width: 2, height: 2);

  @override
  FutureOr<void> onLoad() {
    player = game.player;
    collisionBlocks = player.collisionBlocks;

    position = game.pistol.position;
    oldPosition = position.clone();

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
      collisionType: CollisionType.passive,
    ));

    horizontalMovement = player.isFacingRight ? 1 : -1;


    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/MyChar/bullet.png'),
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: stepTime * 20,
        textureSize: Vector2.all(2),
      ),
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    oldPosition = position.clone();

    velocity.x = horizontalMovement * movespeed;
    position.x += velocity.x * dt;

    _checkHorizontalCollisions();
    _checkVerticalCollisions();
    _sweptEnemyCheck();

    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player || other is Pistol) {
      super.onCollision(intersectionPoints, other);
      return;
    }

    _damageIfEnemy(other);
    removeFromParent();

    super.onCollision(intersectionPoints, other);
  }

  bool _damageIfEnemy(PositionComponent other) {
    final damage = game.stats.scaledDamage;
    if (other is Chicken) {
      other.bulletCollision(this);
      return true;
    }
    if (other is Slime) {
      other.takeDamage(damage);
      return true;
    }
    if (other is BlackSlime) {
      other.takeDamage(damage);
      return true;
    }
    if (other is Chameleon) {
      other.takeDamage(damage);
      return true;
    }
    return false;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block)) {
        removeFromParent();
        return;
      }
    }
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (checkCollision(this, block)) {
        removeFromParent();
        return;
      }
    }
  }


  void _sweptEnemyCheck() {
    final p0 = oldPosition;
    final p1 = position;

    final enemies = <PositionComponent>[
      ...game.descendants().whereType<Chicken>(),
      ...game.descendants().whereType<Slime>(),
      ...game.descendants().whereType<BlackSlime>(),
      ...game.descendants().whereType<Chameleon>(),
    ];

    for (final enemy in enemies) {
      final rect = enemy.toAbsoluteRect();
      if (_segmentIntersectsRect(p0, p1, rect)) {
        _damageIfEnemy(enemy);
        removeFromParent();
        return;
      }
    }
  }

  bool _segmentIntersectsRect(Vector2 p0, Vector2 p1, Rect r) {
    double t0 = 0.0, t1 = 1.0;
    final dx = p1.x - p0.x;
    final dy = p1.y - p0.y;

    bool clip(double p, double q) {
      if (p == 0) return q >= 0;
      final t = q / p;
      if (p < 0) {
        if (t > t1) return false;
        if (t > t0) t0 = t;
      } else {
        if (t < t0) return false;
        if (t < t1) t1 = t;
      }
      return true;
    }

    if (!clip(-dx, p0.x - r.left)) return false;
    if (!clip(dx, r.right - p0.x)) return false;
    if (!clip(-dy, p0.y - r.top)) return false;
    if (!clip(dy, r.bottom - p0.y)) return false;

    return t0 <= t1;
  }
}