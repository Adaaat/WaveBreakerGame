import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttergame/components/checkpoint.dart';
import 'package:fluttergame/components/chicken.dart';
import 'package:fluttergame/components/collision_block.dart';
import 'package:fluttergame/components/custom_hitbox.dart';
import 'package:fluttergame/components/fruit.dart';
import 'package:fluttergame/components/saw.dart';
import 'package:fluttergame/components/sword.dart';
import 'package:fluttergame/components/utils.dart';
import 'package:fluttergame/WaveBreaker.dart';


enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  disappearing,
  swing,
}


class Player extends SpriteAnimationGroupComponent with HasGameRef<Fluttergame>, KeyboardHandler, CollisionCallbacks{ // a lot of Animations. Sonst auch ohne group

  String character;
  int hp;
  Player({
    super.position,
    this.character = 'Ninja Frog',
    this.hp = 200
  }) ;

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;
  late final SpriteAnimation swingAnimation;

  final double stepTime = 0.05; // 20 fps

  final double _gravity = 9.8; // 9.8
  final double _jumpforce = 260; // 460
  final double _terminalVelocity  = 300; // irgendwann soll man nicht noch schneller fallen
  double horizontalMovement = 0;
  double movespeed = 100;
  Vector2 startingPosition = Vector2.all(0);
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool isSwingig = false;
  bool isShooting = false;
  bool reachedCheckpoint = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
      offsetX: 10,
      offsetY: 4,
      width: 14,
      height: 28
  );

  double fixedDeltaTime = 1/ 60; // 60fps
  double accumulatedTime = 0;

  late Chicken chicken;



  bool isInvincible = false; // damage cooldown; does NOT freeze movement

  bool wantsToDrop = false;
  bool isDroppingThroughPlatform = false;

  double _dropThroughTimer = 0;
  final double _dropThroughDuration = 0.25; // quarter secondf



  @override
  FutureOr<void> onLoad() { // Nur am Anfang

     debugMode = false;
    //anchor = Anchor.center;
    _loadAllAnimations();

    startingPosition = Vector2(position.x, position.y);;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height)
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) { // Jeden Frame
    accumulatedTime += dt;

    const maxStepsPerFrame = 5;
    int steps = 0;
    while (accumulatedTime >= fixedDeltaTime && steps < maxStepsPerFrame) {
      if (!gotHit && !reachedCheckpoint) {

        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _updateDropThrough(fixedDeltaTime);

        if (isFacingRight) {
          game.sword.position = position + Vector2(-12, -26);
          if (velocity.y > 0) {
            game.pistol.position = position + Vector2(19, 26);
          } else {
            game.pistol.position = position + Vector2(20, 22);
          }
        } else {
          // subtract sword/pistol width to compensate for the box no longer shifting
          game.sword.position = position + Vector2(44 - game.sword.width, -26);
          if (velocity.y > 0) {
            game.pistol.position = position + Vector2(13 - game.pistol.width, 26);
          } else {
            game.pistol.position = position + Vector2(13 - game.pistol.width, 23);
          }
        }
        game.sword.isFacingRight = isFacingRight;
        game.pistol.isFacingRight = isFacingRight;

        // _swingCheck();
        _checkHorizontalCollisions(); // vor gravity checken
        _applyGravity(fixedDeltaTime);
        _checkVerticalColissions();
      }
      accumulatedTime -= fixedDeltaTime;
      steps++;
    }
    if (steps == maxStepsPerFrame) {
      accumulatedTime = 0; // drop the backlog instead of trying to fully catch up
    }

    super.update(dt);
  }


  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;

    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);

    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);



    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(PhysicalKeyboardKey.space);

    isSwingig = keysPressed.contains(LogicalKeyboardKey.keyF);
    isShooting = keysPressed.contains(LogicalKeyboardKey.keyE);

    wantsToDrop =
        keysPressed.contains(LogicalKeyboardKey.keyS) ||
            keysPressed.contains(LogicalKeyboardKey.arrowDown);

    return super.onKeyEvent(event, keysPressed);
  }


  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if(!reachedCheckpoint){
      if(other is Fruit){
        other.collidedWithPlayer();
      }
      if( other is Saw){
        _instantDeath();
      }
      if(other is Chicken && !other.gotStomped ){
        other.collidedWithPlayer();
      }
      if( other is Checkpoint){
        _reachedCheckpoint();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimations() {
   // idleAnimation = _spriteAnimation('Idle', 11);
    idleAnimation =  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/MyChar/idleBig.png') ,
      SpriteAnimationData.sequenced(
        amount: 9,   //Anzahl an Images in der Animation
        stepTime: stepTime*2 ,
        textureSize: Vector2(32, 34),
      ),
    );

   // runningAnimation = _spriteAnimation('Run', 12);
    runningAnimation =  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/MyChar/runBig.png') ,
      SpriteAnimationData.sequenced(
        amount: 8,   //Anzahl an Images in der Animation
        stepTime: stepTime *3,
        textureSize: Vector2(32, 36),
      ),
    );

 //   jumpingAnimation = _spriteAnimation('Jump', 1);
    jumpingAnimation =  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/MyChar/jump2.png') ,
      SpriteAnimationData.sequenced(
        amount: 1,   //Anzahl an Images in der Animation
        stepTime: stepTime *3,
        textureSize: Vector2(32, 36),
      ),
    );

//    fallingAnimation = _spriteAnimation('Fall', 1);
    fallingAnimation =  SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/MyChar/jump3.png') ,
      SpriteAnimationData.sequenced(
        amount: 1,   //Anzahl an Images in der Animation
        stepTime: stepTime *3,
        textureSize: Vector2(32, 36),
      ),
    );

    swingAnimation = SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/MyChar/swing.png') ,
      SpriteAnimationData.sequenced(
        amount: 10,   //Anzahl an Images in der Animation
        stepTime: stepTime*3 ,
        textureSize: Vector2(100, 64),
      ),
    )..loop=false;

    hitAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/MyChar/hit_white.png'),
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 0.1, // Vielleicht ein bisschen länger anzeigen lassen
        textureSize: Vector2(32, 32), // Deine Spieler-Maße
        loop: false,
      ),
    );

    //hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Desappearing', 7);


    //List of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
      PlayerState.swing: swingAnimation,
    };

    //Set current animation
    current = PlayerState.idle;
   }

  SpriteAnimation _spriteAnimation(String state, int amount){
    // Sequence heißt, dass die Sprite in einer Zeile abgebildet sind
    return SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$character/$state (32x32).png') ,
      SpriteAnimationData.sequenced(
        amount: amount,   //Anzahl an Images in der Animation
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );

  }
  SpriteAnimation _specialSpriteAnimation(String state, int amount){
    // Sequence heißt, dass die Sprite in einer Zeile abgebildet sind
    return SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$state (96x96).png') ,
      SpriteAnimationData.sequenced(
        amount: amount,   //Anzahl an Images in der Animation
        stepTime: stepTime,
        textureSize: Vector2.all(96),
        loop: false,
      ),
    );

  }



  void _updatePlayerState(){
    PlayerState playerState = PlayerState.idle;
    if (isSwingig && !game.pistol.visible) {
      _swingCheck();
    } else if (isShooting && !game.sword.visible) {
      _shoot();
    }
   //   playerState = PlayerState.swing;

    if(velocity.x < 0 && isFacingRight){
      isFacingRight = false;
    } else if (velocity.x > 0 && !isFacingRight){
      isFacingRight = true;
    }

    // Check if moving, set running
    if(velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    // Check if falling, set falling
    if(velocity.y > 0) playerState = PlayerState.falling;

    // Check if jumping, set jumping
    if(velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _updatePlayerMovement(double dt){
    if(hasJumped && isOnGround){
      _playerJump(dt);
    }

    if(velocity.y > _gravity){
      isOnGround = false;
    }
    velocity.x = horizontalMovement * movespeed;
    position.x += velocity.x * dt; // dt "deltaTime" notwendig, damit immer gleich schnell bewegt unabhängig von fps
  }

  void _updateDropThrough(double dt) {
    if (wantsToDrop &&
        isOnGround &&
        !isDroppingThroughPlatform) {

      isDroppingThroughPlatform = true;
      _dropThroughTimer = _dropThroughDuration;

      isOnGround = false;
    }

    if (isDroppingThroughPlatform) {
      _dropThroughTimer -= dt;

      if (_dropThroughTimer <= 0) {
        isDroppingThroughPlatform = false;
      }
    }
  }

  void _playerJump(double dt){
    if(game.playSounds){
      FlameAudio.play('jump.wav', volume: game.soundVolume);
    }
    velocity.y = -_jumpforce;
    position.y += velocity.y * dt;

    isOnGround = false;
    hasJumped = false;
  }



  void _checkHorizontalCollisions(){
    for(final block in collisionBlocks){
      if(!block.isPlatform){
        if(checkCollision(this, block)){
          if(velocity.x > 0){ //rechts
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if(velocity.x < 0){ // links
            velocity.x = 0;
            position.x = block.x + block.width - hitbox.offsetX;
            break;
          }

        }
      }
    }
  }


  void _applyGravity(double dt){
    velocity.y +=  _gravity; //man fällt immer schneller
    velocity.y = velocity.y.clamp(-_jumpforce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalColissions(){
    for(final block in collisionBlocks){
      if (block.isPlatform) {

        if (isDroppingThroughPlatform) {
          continue;
        }

        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      }else{
        if(checkCollision(this, block)){
          if(velocity.y > 0){ // unten
            velocity.y = 0;
            position.y =block.y - hitbox.height - hitbox.offsetY; //ohne fällt man wie treibsand
            isOnGround = true; // jumpen nur wenn on Ground
            break;
          }
          if(velocity.y < 0){ // oben
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  void _respawn() async {
    gotHit = true;
    const canMoveDuration = Duration(milliseconds: 400);

    isFacingRight = true;
    game.sword.isFacingRight = true;
    game.pistol.isFacingRight = true;

    position = startingPosition - Vector2.all(96 - 64);
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    game.stats.currentHp = game.stats.maxHp;

    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
  }

  _reachedCheckpoint() async{
    reachedCheckpoint = true;

    if(game.playSounds){
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }

    if(isFacingRight){
      position = position - Vector2.all(32);
      game.sword.isFacingRight = true;
      game.pistol.isFacingRight = true;
    }else {
      position = position + Vector2(32,-32);
      game.sword.isFacingRight = false;
      game.pistol.isFacingRight = false;

    }
    current = PlayerState.disappearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640); // Player wird aus dem  Bild gebracht

    const waitToChangeDuration =  Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
    const reachedCheckpointDuration = Duration(milliseconds: 50 * 7);

  }

  void collidedWithEnemy(int damage){
    _takeHit(damage);
  }

  void _instantDeath() async {
    if (gotHit) return;
    gotHit = true;

    if (game.playSounds) {
      FlameAudio.play('hit.wav', volume: game.soundVolume);
    }
    current = PlayerState.hit;
    game.stats.currentHp = 0;
    game.stats.loseLife();

    await animationTicker?.completed;
    animationTicker?.reset();

    _respawn();
  }

  void _takeHit(int damage) async {
    if (gotHit || isInvincible) return;
    isInvincible = true;

    if (game.playSounds) {
      FlameAudio.play('hit.wav', volume: game.soundVolume);
    }

    final bool lostLife = game.stats.takeDamage(damage);

    if (lostLife) {
      gotHit = true;
      current = PlayerState.hit;
      await animationTicker?.completed;
      animationTicker?.reset();
      _respawn();
      isInvincible = false;
    } else {
      _flashInvincibility();
    }
  }

  void _flashInvincibility() async {
    const blinkCount = 5;
    const blinkDuration = Duration(milliseconds: 100);

    for (int i = 0; i < blinkCount; i++) {
      opacity = 0.3;
      await Future.delayed(blinkDuration);
      opacity = 1.0;
      await Future.delayed(blinkDuration);
    }
    isInvincible = false;
  }

  void aoeAttack(){

  }

  int counter = 0;



  void _swingCheck() async {

    if(isSwingig) {
      game.sword.swing();
      game.sword.position = position +  Vector2(-17,-26 );
     // velocity = Vector2.zero();
    }

      /*   if (!isSwingig || swingInProgress) {
      return;
    }

    swingInProgress = true; // Blockiert erneutes Ausführen
    final Vector2 currentPos = position.clone();
    print('Vor Swing: $currentPos');

    velocity = Vector2.zero();
    current = PlayerState.swing;

    // Position anpassen und Schwert anzeigen
   // position.y += 30;
    //position.x -= 10;

    game.sword.position = position +  Vector2(-17,-26 );
 //   game.sword.position = position + Vector2(10, 0);
    game.sword.visible = true;

    animationTicker?.reset();
    if (animationTicker != null) {
      await animationTicker!.completed;
    }
    animationTicker?.reset();

    // Nach der Animation Position und Status zurücksetzen
    position.setFrom(currentPos);
    game.sword.visible = false;
    isSwingig = false;
    swingInProgress = false; // Freigeben für nächsten Swing

    print('Nach Swing: $currentPos');*/
    }

  void _shoot() {
    if(isShooting) {
      game.pistol.shoot();
      game.sword.position = position +  Vector2(-17,-26 );
      // velocity = Vector2.zero();
    }
  }

  bool isFacingRight = true;

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