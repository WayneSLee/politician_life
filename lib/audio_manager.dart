import 'package:audioplayers/audioplayers.dart';

// 一個專門用來管理遊戲背景音樂(BGM)的類別
class AudioManager {
  // 【修改】在創建時，直接傳入 playerId
  final AudioPlayer _backgroundPlayer = AudioPlayer(playerId: 'background_music_player');

  // 構造函數
  AudioManager() {
    // 【修改】我們不再需要 setPlayerId，因為創建時已經設定好了
    // _backgroundPlayer.setPlayerId('background_music_player');

    // 預設將播放模式設定為循環播放
    _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // 播放主流程的背景音樂
  Future<void> playMainBgm() async {
    await stopBgm();
    await _backgroundPlayer.play(AssetSource('audio/main_theme.mp3'));
  }

  // 【新增】暫停背景音樂的方法
  Future<void> pauseBgm() async {
    await _backgroundPlayer.pause();
  }

  // 【新增】恢復背景音樂播放的方法
  Future<void> resumeBgm() async {
    await _backgroundPlayer.resume();
  }


  // 未來可以新增播放序章音樂的方法
  Future<void> playPrologueBgm() async {
    await stopBgm();
    // await _backgroundPlayer.play(AssetSource('audio/prologue_theme.mp3'));
  }

  // 停止背景音樂
  Future<void> stopBgm() async {
    await _backgroundPlayer.stop();
  }

  // 釋放資源 (當遊戲關閉時可以呼叫)
  void dispose() {
    _backgroundPlayer.dispose();
  }
}