import 'package:flame/collisions.dart';



bool checkCollision(player, block){
  final hitbox = player.hitbox;
  final playerX = player.position.x + hitbox.offsetX; //  final playerX = player.position.x + hitbox.offsetX;
  final playerY = player.position.y + hitbox.offsetY; //  final playerY = player.position.y + hitbox.offsetY;
  final playerWidth = hitbox.width ; // final playerWidth = hitbox.width ;
  final playerHeight = hitbox.height; //  final playerHeight = hitbox.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  final fixedX = playerX;
  final fixedY = block.isPlatform ? playerY + playerHeight : playerY;



  return (// block y = top of block || mit blockHeight addiert ist es dann unten am Block (Achse geht nach unten)
      fixedY < blockY + blockHeight &&  // Oberseite player < unterseite Block
          playerY + playerHeight > blockY && // Unterseite player > oberseite Block
          fixedX < blockX + blockWidth && // player links < block rechts
          fixedX + playerWidth > blockX // player rechts > block links
  );
}


