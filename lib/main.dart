import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:fluttergame/WaveBreaker.dart';

import 'components/pause_button.dart';
import 'game_save_screen.dart';
import 'main_menu.dart';
import 'pause_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isPlaying = false;
  late Fluttergame _game;

  void _startGame(bool mobileControls, Map<String, dynamic>? loadData) {
    final game = Fluttergame(pendingSaveData: loadData);
    game.showControls = mobileControls;
    game.onGameOver = _handleGameOver;

    setState(() {
      _game = game;
      _isPlaying = true;
    });
  }

  void _handleGameOver() {
    _game.overlays.add('GameOver');
  }

  void _pauseGame() {
    _game.pauseGame();
    _game.overlays.add('PauseMenu');
  }

  void _resumeGame() {
    _game.resumeGame();
    _game.overlays.remove('PauseMenu');
  }

  Future<void> _saveGame() async {
    await _game.saveProgress();
  }

  void _restartFromGameOver() {
    _game.overlays.remove('GameOver');
    _game.restartFromGameOver();
  }

  void _quitGame() {
    setState(() {
      _game.resumeGame();
      _game.overlays.clear();
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF211F30),
          body: Center(
            child: Text(
              "Please rotate your phone to landscape to play!",
              style: TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // 3. If they are in landscape (or on PC), render the game with all your overlays!
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isPlaying
          ? GameWidget(
        game: _game,
        overlayBuilderMap: {
          'PauseMenu': (context, game) => PauseMenu(
            onResume: _resumeGame,
            onQuit: _quitGame,
            onSave: _saveGame,
            canSave: !(game as Fluttergame).waveManager.waveInProgress,
          ),
          'PauseButton': (context, game) => PauseButton(onPause: _pauseGame),
          'GameOver': (context, game) => GameOverScreen(onRestart: _restartFromGameOver),
        },
        initialActiveOverlays: const ['PauseButton'],
      )
          : MainMenu(onStartGame: _startGame),
    );
  }
}