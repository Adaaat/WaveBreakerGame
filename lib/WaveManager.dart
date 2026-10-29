import 'package:flame/components.dart';
import 'package:fluttergame/WaveBreaker.dart';
import 'components/Portal.dart';

class WaveManager extends Component with HasGameRef<Fluttergame> {
  int currentWave = 1;
  int enemiesAlive = 0;

  List<Portal> portals = [];

  bool waveInProgress = false;

  void startWave() {
    if (waveInProgress || portals.isEmpty) return;

    waveInProgress = true;
    enemiesAlive = 0;

    gameRef.stats.resetForNewWave();

    for (final portal in portals) {
      portal.startWave(currentWave);
    }
  }

  void enemySpawned() {
    enemiesAlive++;
  }

  void enemyDefeated({int xp = 5}) {
    enemiesAlive--;
    gameRef.stats.gainXp(xp);

    if (enemiesAlive <= 0 && _allPortalsFinished()) {
      waveInProgress = false;
      currentWave++;
      gameRef.saveProgress(); // safe now — no wave is active
    }
  }

  bool _allPortalsFinished() {
    return portals.every((p) => p.enemiesToSpawn <= 0);
  }
}