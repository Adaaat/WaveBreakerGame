import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/components/jump_button.dart';
import 'package:fluttergame/components/pistol.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/level.dart';

import 'WaveManager.dart';
import 'components/dynamic_joystick.dart';
import 'components/game_hud.dart';
import 'components/game_over_overlay.dart';
import 'components/player_stats.dart';
import 'components/stats_panel.dart';
import 'components/sword.dart';
import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttergame/components/jump_button.dart';
import 'package:fluttergame/components/pistol.dart';
import 'package:fluttergame/components/player.dart';
import 'package:fluttergame/components/level.dart';

import 'WaveManager.dart';
import 'components/game_hud.dart';
import 'game_save_manager.dart';
import 'components/player_stats.dart';
import 'components/stats_panel.dart';
import 'components/shoot_button.dart';
import 'components/sword_button.dart';
import 'components/sword.dart';



class Fluttergame extends FlameGame with  HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection, TapCallbacks  {
  Fluttergame({this.pendingSaveData});

  /// If set (e.g. from "Continue" on the main menu), applied once in onLoad()
  /// to restore level/wave/stat progress before the level loads.
  Map<String, dynamic>? pendingSaveData;

  /// Set by MyApp so Fluttergame can ask for the 'GameOver' Flutter overlay
  /// without needing to reach into the widget tree itself.
  VoidCallback? onGameOver;

  late Level currentLevel;
  Color backgroundColor() => const Color(0xFF211F30);

  bool _isPaused = false;

  late WaveManager waveManager;
  late PlayerStats stats;

  late CameraComponent cam;
  Player player = Player(character: 'Mask Dude');
  Sword sword = Sword();
  Pistol pistol = Pistol();

  bool showControls = false; // mobile true | desktop false
  bool playSounds = false;
  List<String> levelNames = ['level02', 'level02'];
  int currentLevelIndex = 1;
  double soundVolume = 1.0;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    stats = PlayerStats();
    add(stats);

    waveManager = WaveManager();
    add(waveManager);

    if (pendingSaveData != null) {
      _applySaveData(pendingSaveData!);
    } else {
      // FIX: If it's a brand new game, force the stats to initialize!
      stats.fullReset();
      player.movespeed = 100 * stats.speedMultiplier;
    }

    _loadLevel();

    // --- MOVE THESE BACK HERE ---
    // Adding them directly to the game root restores their normal size
    // and layout positions!
    add(GameHud());
    add(StartWaveButton());
    add(StatsButton());

    if(showControls){
      add(DynamicJoystick());
      add(JumpButton());
      add(ShootButton());
      add(SwordButton());
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (_isPaused) return;

    final cappedDt = dt > 0.033 ? 0.033 : dt;

    // FIX: Pass cappedDt here, NOT the original dt!
    super.update(cappedDt);
  }

  void pauseGame() {
    _isPaused = true;
    pauseEngine();
  }

  void resumeGame() {
    _isPaused = false;
    resumeEngine();
  }

  void triggerGameOver() {
    pauseGame();
    onGameOver?.call();
  }

  void restartFromGameOver() {
    stats.fullReset();

    waveManager.currentWave = 1;
    waveManager.waveInProgress = false;
    waveManager.enemiesAlive = 0;
    for (final portal in waveManager.portals) {
      portal.enemiesToSpawn = 0; // stop any leftover queued spawns from the failed wave
    }

    currentLevel.removeAllEnemies(); // clear enemies left over from the failed wave

    player.position = player.startingPosition;
    player.velocity = Vector2.zero();

    resumeGame();
  }

  Future<void> saveProgress() async {
    if (waveManager.waveInProgress) return;

    final data = <String, dynamic>{
      'levelIndex': currentLevelIndex,
      'wave': waveManager.currentWave,
      'level': stats.level,
      'xp': stats.xp,
      'xpToNextLevel': stats.xpToNextLevel,
      'baseMaxHp': stats.baseMaxHp,
      'maxLives': stats.maxLives,
      'damageMultiplier': stats.damageMultiplier,
      'speedMultiplier': stats.speedMultiplier,
      'statPoints': stats.statPoints,
    };

    await GameSaveManager.saveSingleGame(data);
  }

  void _applySaveData(Map<String, dynamic> data) {
    currentLevelIndex = (data['levelIndex'] as int?) ?? currentLevelIndex;

    waveManager.currentWave = (data['wave'] as int?) ?? 1;

    stats.level = (data['level'] as int?) ?? 1;
    stats.xp = (data['xp'] as int?) ?? 0;
    stats.xpToNextLevel = (data['xpToNextLevel'] as int?) ?? 10;
    stats.baseMaxHp = (data['baseMaxHp'] as int?) ?? 5;
    stats.maxHp = stats.baseMaxHp;
    stats.currentHp = stats.maxHp;
    stats.maxLives = (data['maxLives'] as int?) ?? 3;
    stats.lives = stats.maxLives;
    stats.damageMultiplier = ((data['damageMultiplier'] as num?) ?? 1.0).toDouble();
    stats.speedMultiplier = ((data['speedMultiplier'] as num?) ?? 1.0).toDouble();
    stats.statPoints = (data['statPoints'] as int?) ?? 0;

    player.movespeed = 100 * stats.speedMultiplier;
  }

  void loadNextLevel(){
    removeWhere((component) => component is Level);

    if(currentLevelIndex < levelNames.length-1){
      currentLevelIndex++;
      _loadLevel();
    }else{
      currentLevelIndex = 0;
      _loadLevel();
    }
  }
  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      currentLevel = Level(levelName: levelNames[currentLevelIndex], player: player, sword: sword, pistol: pistol);

      cam = CameraComponent(world: currentLevel);
      cam.viewfinder.zoom = size.y / 360;
      cam.follow(player);
      cam.priority = 0;

      // Notice we deleted the background and backdrop logic here!
      addAll([cam, currentLevel]);
    });
  }


}