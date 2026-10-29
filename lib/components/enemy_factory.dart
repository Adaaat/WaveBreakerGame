import 'package:flame/components.dart';
import 'package:fluttergame/components/BlackSlime.dart';
import 'package:fluttergame/components/Chameleon.dart';
import 'package:fluttergame/components/Slime.dart';
import 'package:fluttergame/components/chicken.dart';
import 'package:fluttergame/components/collision_block.dart';

class EnemyFactory {
  static PositionComponent createEnemy(String type, Vector2 position, List<CollisionBlock> blocks) {
    late PositionComponent enemy;

    switch (type.toLowerCase()) {
      case 'chicken':
        enemy = Chicken(position: position);
        break;
      case 'slime':
        enemy = Slime(position: position);
        break;
      case 'blackslime':
        enemy = BlackSlime(position: position);
        break;
      case 'chameleon':
        enemy = Chameleon(position: position);
        break;
      default:
        enemy = Chicken(position: position);
        break;
    }


    if (enemy is Slime) enemy.collisionBlocks = blocks;
    if (enemy is Chicken) enemy.collisionBlocks = blocks;
    if (enemy is Chameleon) enemy.collisionBlocks = blocks;
    if (enemy is BlackSlime) enemy.collisionBlocks = blocks;

    return enemy;
  }
}