import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameSaveManager {
  static const String _multiSlotKey = 'game_saves_slots';
  static const String _singleSlotKey = 'progress_save_slot';


  static Future<void> saveGameStates(List<Map<String, dynamic>> gameStates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonContent = jsonEncode(gameStates);
    await prefs.setString(_multiSlotKey, jsonContent);
  }

  static Future<List<Map<String, dynamic>>> loadGameStates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonContent = prefs.getString(_multiSlotKey);

    if (jsonContent != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(jsonContent));
    } else {
      return [];
    }
  }


  static Future<void> saveSingleGame(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonContent = jsonEncode(data);
    await prefs.setString(_singleSlotKey, jsonContent);
  }

  static Future<Map<String, dynamic>?> loadSingleGame() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonContent = prefs.getString(_singleSlotKey);

    if (jsonContent == null) return null;
    return Map<String, dynamic>.from(jsonDecode(jsonContent));
  }

  static Future<bool> hasSingleSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_singleSlotKey);
  }

  static Future<void> deleteSingleSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_singleSlotKey);
  }
}
