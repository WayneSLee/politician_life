// lib/game_choice.dart

import 'package:politician_life/player.dart';

// 定義一個「遊戲選項」的藍圖
class GameChoice {
  final String description;
  final Function(Player) onSelect;
  final bool Function(Player player)? isEnabled;

  GameChoice({
    required this.description,
    required this.onSelect,
    this.isEnabled,
  });
}