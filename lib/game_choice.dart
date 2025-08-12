// lib/game_choice.dart

import 'package:politician_life/player.dart';

// 定義一個「遊戲選項」的藍圖
class GameChoice {
  // 選項的描述文字，會顯示在按鈕上
  final String description;

  // 關鍵！這是一個「函數」，代表選擇此選項後會發生的事。
  // 它會接收一個 Player 物件作為參數，以便修改玩家的數值。
  final Function(Player) onSelect;

  GameChoice({
    required this.description,
    required this.onSelect,
  });
}