import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'enemy_factory.dart';

class Portal extends SpriteComponent with HasGameRef<Fluttergame> {
  final String enemyType;

  int enemiesToSpawn = 0;
  double spawnTimer = 0;
  double spawnInterval = 2.0;

  final Random random = Random();

  Portal({
    required this.enemyType,
    required Vector2 position,
  }) : super(
    position: position,
    size: Vector2(32, 48),
    priority: -1,
  );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('Items/Portal.png');
    return super.onLoad();
  }

  void startWave(int wave) {
    enemiesToSpawn = wave; // 1 per wave per portal
    spawnInterval = (2.5 - wave * 0.2).clamp(0.5, 2.5);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (enemiesToSpawn <= 0) return;

    spawnTimer += dt;

    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;

      _spawnEnemy();
    }
  }

  void _spawnEnemy() {
    final randomPick = random.nextInt(3);
    String type;

    if (randomPick == 0) {
      type = 'slime';
    } else if (randomPick == 1) {
      type = 'chameleon';
    } else {
      type = 'blackslime';
    }

    final spawnPos = Vector2(
      position.x,
      position.y,
    );

    final enemy = EnemyFactory.createEnemy(
      type,
      spawnPos,
      gameRef.currentLevel.collisionBlocks,
    );

    gameRef.currentLevel.add(enemy);

    enemiesToSpawn--;
    gameRef.waveManager.enemySpawned();
  }

}