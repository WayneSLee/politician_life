// lib/game_phase.dart

enum GamePhase {
  prologue,
  characterCreation,
  loading,
  event,      // 事件階段：等待玩家做選擇
  campaigning,
  electionResults,
  awaitingInauguration,
  newsReport,
  endOfDay,   // 日結階段：顯示總結，等待玩家按下一天
}