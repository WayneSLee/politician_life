// lib/game_event.dart

import 'package:politician_life/game_choice.dart';
import 'package:politician_life/player.dart'; // 引入 Player

// 定義一個「遊戲事件」的藍圖
class GameEvent {
  final String description;
  final List<GameChoice> choices;

  // 【新增這個屬性】
  // 一個可選的函數，用來判斷此事件是否能被觸發。
  // 如果這個屬性是 null，代表此事件是通用事件，隨時可以觸發。
  final bool Function(Player player)? canTrigger;

  GameEvent({
    required this.description,
    required this.choices,
    this.canTrigger, // 在構造函數中也加入它
  });
}