import 'package:flame/components.dart';
import 'package:fluttergame/WaveBreaker.dart';

class PlayerStats extends Component with HasGameRef<Fluttergame> {
  int level = 1;
  int xp = 0;
  int xpToNextLevel = 10;

  int maxLives = 3;
  int lives = 3;

  int baseMaxHp = 5;
  late int maxHp = baseMaxHp;
  late int currentHp = maxHp;

  double damageMultiplier = 1.0;
  double speedMultiplier = 1.0;

  int maxBulletsPerWave = 5;
  int bulletsRemaining = 5;

  bool isGameOver = false;

  int statPoints = 0;
  static const int pointsPerLevel = 3;

  int get scaledDamage => (1 * damageMultiplier).round();

  void gainXp(int amount) {
    if (isGameOver) return;
    xp += amount;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      _levelUp();
    }
  }

  void _levelUp() {
    level++;
    xpToNextLevel = (xpToNextLevel * 1.3).round();
    statPoints += pointsPerLevel;

    baseMaxHp += 1;
    maxHp = baseMaxHp;
    //currentHp += maxHp;
  }

  void spendPointOnHp() {
    if (statPoints <= 0) return;
    statPoints--;
    baseMaxHp += 1;
    maxHp = baseMaxHp;
    currentHp += 1;
  }

  void spendPointOnDamage() {
    if (statPoints <= 0) return;
    statPoints--;
    damageMultiplier += 0.15;
  }

  void spendPointOnSpeed() {
    if (statPoints <= 0) return;
    statPoints--;
    speedMultiplier += 0.08;
    gameRef.player.movespeed = 100 * speedMultiplier;
  }

  bool takeDamage(int amount) {
    if (isGameOver) return false;
    currentHp -= amount;
    if (currentHp <= 0) {
      currentHp = 0;
      loseLife();
      return true;
    }
    return false;
  }

  void loseLife() {
    lives--;
    if (lives <= 0) {
      lives = 0;
      isGameOver = true;
      gameRef.triggerGameOver();
    } else {
      currentHp = maxHp;
    }
  }

  void resetForNewWave() {
    bulletsRemaining = maxBulletsPerWave;

    currentHp = maxHp;
  }

  bool useBullet() {
    if (bulletsRemaining <= 0) return false;
    bulletsRemaining--;
    return true;
  }

  void fullReset() {
    level = 1;
    xp = 0;
    xpToNextLevel = 10;
    baseMaxHp = 5;
    maxHp = baseMaxHp;
    currentHp = maxHp;
    damageMultiplier = 1.0;
    speedMultiplier = 1.0;
    lives = maxLives;
    bulletsRemaining = maxBulletsPerWave;
    statPoints = 0;
    isGameOver = false;
    gameRef.player.movespeed = 100;
  }
}