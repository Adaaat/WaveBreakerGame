import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/components/BlackSlime.dart';
import 'package:fluttergame/components/background_tile.dart';
import 'package:fluttergame/components/checkpoint.dart';
import 'package:fluttergame/components/chicken.dart';
import 'package:fluttergame/components/collision_block.dart';
import 'package:fluttergame/components/fruit.dart';
import 'package:fluttergame/components/pistol.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/saw.dart';
import 'package:fluttergame/components/sword.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'package:flame/experimental.dart' as exp;
import '../WaveManager.dart';
import 'Chameleon.dart';
import 'Portal.dart';
import 'Skeleton.dart';
import 'Slime.dart';

class Level extends World with HasGameRef<Fluttergame>{

  final String levelName;
  final Player player;
  final Sword sword;
  final Pistol pistol;
  Level({
    required this.sword,
    required this.levelName,
    required this.player,
    required this.pistol
  });

  late TiledComponent level;

  List<CollisionBlock> collisionBlocks = [];

  @override
  FutureOr<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    level.priority = -1;
    add(level);

// 1. Calculate the exact pixel width and height of your Tiled map
    final mapWidth = level.tileMap.map.width * 16.0;
    final mapHeight = level.tileMap.map.height * 16.0;

    game.cam.setBounds(
      exp.Rectangle.fromLTWH(0, 0, mapWidth, mapHeight),
    );
    final worldBackground = SpriteComponent(
      sprite: await game.loadSprite('NewBackgroundpng.png'),
      size: Vector2(mapWidth, mapHeight),
      position: Vector2(0, 0),
      priority: -2,
      paint: Paint()..filterQuality = FilterQuality.none,
    );

    add(worldBackground);
    // ----------------------------

    // Initialisiere collisionBlocks VOR den Gegnern!
    _addCollisions();

    // Reset Wave Manager
    game.waveManager.portals.clear();
    game.waveManager.waveInProgress = false;
    game.waveManager.enemiesAlive = 0;

    _spawningObjects(); // Platziert Player, statische Gegner, etc.

    // Portale aus Tiled lesen
    final spawnLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    if (spawnLayer != null) {
      for (final object in spawnLayer.objects) {
        if (object.class_ == 'Portal') {
          final portal = Portal(
            enemyType: object.properties.getValue('type') ?? 'Chicken',
            position: Vector2(object.x, object.y),
          );
          add(portal);
        }
      }
    }
    return super.onLoad();
  }

  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');

    if (backgroundLayer != null) {
      final backgroundColor =
      backgroundLayer.properties.getValue('BackgroundColor');

      final backgroundTile = BackgroundTile(
        color: backgroundColor ?? 'Gray',
        position: Vector2(0, 0),
      );


      game.cam.backdrop = backgroundTile;
    }
  }

  void _spawningObjects(){
    final spawnPointsLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    if(spawnPointsLayer != null){
      for(final spawnPoint in spawnPointsLayer.objects){
        switch(spawnPoint.class_){
          case 'Player':
            player.position =  Vector2(spawnPoint.x, spawnPoint.y);
            player.scale.x = 1; // rechts schauen
            add(player);
            add(sword);
            add(pistol);
            break;
          case 'Fruit':
            final fruit = Fruit(
                fruit: spawnPoint.name,
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height)

            );
            add(fruit);
            break;
          case 'Saw':
            final isVertical = spawnPoint.properties.getValue('isVertical');
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final saw =Saw(
                isVertical: isVertical,
                offNeg: offNeg,
                offPos: offPos,
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height)
            );
            add(saw);
            break;
          case 'Portal':
            final portal = Portal(
              enemyType: spawnPoint.properties.getValue('type') ?? 'slime',
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );

            add(portal);

            game.waveManager.portals.add(portal);

            break;
          case 'Checkpoint':
            final checkpoint = Checkpoint(
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height)
            );
            add(checkpoint);
            break;
          case 'Chicken':
            final offNeg  = spawnPoint.properties.getValue('offNeg');
            final offPos  = spawnPoint.properties.getValue('offPos');
            final chicken = Chicken(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg,
              offPos: offPos,
            );
            add(chicken);
            break;
          case 'Slime':
            final slime = Slime(
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );
            add(slime);
            break;
          case 'BlackSlime':
            final slime = BlackSlime(
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );
            add(slime);
            break;
          case 'Chameleon':
            final chameleon = Chameleon(
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );
            add(chameleon);
            break;

          default:

        }
      }
    }
  }

  void _addCollisions(){
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');

    if(collisionsLayer != null){
      for(final collision in collisionsLayer.objects){
        switch(collision.class_){

          case 'Plattform':
            final platform = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
              isPlatform: true,
            );
            collisionBlocks.add(platform);
            add(platform);
            break;

          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            collisionBlocks.add(block);
            add(block);
        }
      }
    }
    player.collisionBlocks = collisionBlocks;
  }

  /// Clears any enemies left over from an interrupted wave (e.g. after Game Over).
  void removeAllEnemies() {
    children.whereType<Slime>().toList().forEach((e) => e.removeFromParent());
    children.whereType<Chameleon>().toList().forEach((e) => e.removeFromParent());
    children.whereType<BlackSlime>().toList().forEach((e) => e.removeFromParent());
    children.whereType<Chicken>().toList().forEach((e) => e.removeFromParent());
  }

  void removeLevel(){
    // Entferne alle hinzugefügten Level-Komponenten
    remove(level);

    // Entferne alle Kollisionen
    for (final block in collisionBlocks) {
      remove(block);
    }
    collisionBlocks.clear();

    // Entferne den Spieler (falls er Teil des Levels ist)
    if (parent?.children.contains(player) == true) {
      remove(player);
    }

    // Entferne andere hinzugefügte Objekte (optional, falls nötig)
    final objectsToRemove = children.where((c) => c is Fruit || c is Saw || c is Checkpoint).toList();
    for (final object in objectsToRemove) {
      remove(object);
    }
  }
}