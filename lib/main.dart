import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:politician_life/game_phase.dart';
import 'package:politician_life/party.dart';
import 'package:politician_life/politician_game.dart';
import 'package:politician_life/profession.dart';
import 'package:lottie/lottie.dart';
import 'package:politician_life/profession_service.dart';

final PoliticianGame game = PoliticianGame();

Color partyToColor(Party party) {
  switch (party) {
    case Party.blue:
      return Colors.blue.shade300;
    case Party.green:
      return Colors.green.shade400;
    case Party.white:
      return Colors.grey.shade300;
    case Party.independent:
      return Colors.white70;
  }
}

String partyToString(Party party) {
  switch (party) {
    case Party.blue: return '藍黨';
    case Party.green: return '綠黨';
    case Party.white: return '白黨';
    case Party.independent: return '無黨籍';
  }
}

String formatLargeNumber(int number) {
  if (number >= 1000000000) { // 十億 (Billion)
    return '${(number / 1000000000).toStringAsFixed(2)} B';
  } else if (number >= 1000000) { // 百萬 (Million)
    return '${(number / 1000000).toStringAsFixed(2)} M';
  } else if (number >= 1000) { // 千 (Kilo)
    return '${(number / 1000).toStringAsFixed(1)} K';
  } else {
    return number.toString();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await ProfessionService.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansTC',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF5F5DC),
            foregroundColor: Colors.black87,
            textStyle: const TextStyle(
                fontFamily: 'NotoSansTC', fontWeight: FontWeight.bold, fontSize: 16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          'GameUI': (context, game) {
            return GameUI(game: game as PoliticianGame);
          },
        },
        initialActiveOverlays: const ['GameUI'],
      ),
    );
  }
}

class GameUI extends StatefulWidget {
  final PoliticianGame game;
  const GameUI({super.key, required this.game});

  @override
  State<GameUI> createState() => _GameUIState();
}

class _GameUIState extends State<GameUI> with WidgetsBindingObserver {
  final TextEditingController _nameController = TextEditingController();
// 【新增】initState 方法
  @override
  void initState() {
    super.initState();
    // 將這個 class 註冊為一個 App 狀態觀測員
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 當 Widget 被銷毀時，取消註冊，並釋放控制器資源
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('App Lifecycle State changed to: $state'); // 加上日誌方便未來除錯

    switch (state) {
      case AppLifecycleState.resumed:
      // App 回到前景，恢復音樂
        game.audioManager.resumeBgm();
        break;
      case AppLifecycleState.inactive:
      // App 進入非活動狀態 (例如有電話打進來)，暫停音樂
        game.audioManager.pauseBgm();
        break;
      case AppLifecycleState.paused:
      // App 進入背景，暫停音樂
        game.audioManager.pauseBgm();
        break;
      case AppLifecycleState.detached:
      // App 被銷毀前，暫停音樂 (這個狀態不一定會觸發，但補上更完整)
        game.audioManager.pauseBgm();
        break;
    // 為了應對 Flutter 未來可能新增的狀態 (例如 hidden)，我們補上一個 default 處理
      default:
        game.audioManager.pauseBgm();
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.game,
      builder: (context, child) {
        Widget currentView;
        switch (widget.game.currentPhase) {
          case GamePhase.prologue:
            currentView = buildPrologueView();
            break;
          case GamePhase.characterCreation:
            currentView = buildCharacterCreationView();
            break;
          case GamePhase.loading:
            currentView = const CircularProgressIndicator(color: Colors.white);
            break;
          case GamePhase.event:
          case GamePhase.campaigning:
            currentView = buildEventView();
            break;
          case GamePhase.newsReport:
            currentView = buildNewsReportView();
            break;
          case GamePhase.electionResults:
            currentView = buildElectionResultsView();
            break;
          case GamePhase.endOfDay:
            currentView = buildEndOfDayView();
            break;
        }

        final playerExists = widget.game.player != null;

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // 佈局1: 頂部狀態列 (使用 Positioned)
                if (playerExists)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: buildTopBar(),
                  ),

                // 佈局2: 底部互動區 (使用 Align)
                (widget.game.currentPhase == GamePhase.prologue || widget.game.currentPhase == GamePhase.characterCreation)
                    ? Center(child: currentView)
                    : Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: currentView,
                  ),
                ),

                // 佈局3: 中間動畫層 (使用 Center)
                if (widget.game.showAnimation && widget.game.currentAnimationPath != null)
                  Center(
                    child: IgnorePointer(
                      child: Lottie.asset(
                        widget.game.currentAnimationPath!,
                        width: 250,
                        height: 250,
                      ),
                    ),
                  ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPrologueView() {
    // 如果劇本還沒載入完成，顯示讀取中
    if (widget.game.prologuePages.isEmpty) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    // 使用 GestureDetector 來偵測整個畫面的點擊
    return GestureDetector(
      onTap: () {
        widget.game.advancePrologue();
      },
      child: Container(
        color: Colors.black.withOpacity(0.5), // 半透明黑底，讓文字更清晰
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.game.prologuePages[widget.game.currentProloguePage],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.8, // 增加行高
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '（輕觸螢幕以繼續）',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildTopBar() {
    const textShadow = [Shadow(blurRadius: 2, color: Colors.black54)];

    // 【修改】使用 Container 來設定頂部列的背景圖和樣式
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: const BoxDecoration(
        // 使用 DecorationImage 來設定背景圖
        image: DecorationImage(
          image: AssetImage('assets/images/top_bar_background.png'),
          fit: BoxFit.cover, // 填滿整個容器
        ),
        // 也可以在底部加上一點陰影，讓它更有立體感
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            // 【修改】移除 InfoRow 的 label，只保留 Icon 和 value
            child: InfoRow(
              icon: Icons.attach_money,
              label: '', // 標籤留空
              value: formatLargeNumber(widget.game.player?.money ?? 0), // 數字靠左對齊
              color: Colors.white,
            ),
          ),

          Expanded(
            flex: 5,
            child: Text(
              '第 ${widget.game.year} 年 第 ${widget.game.weekOfYear} 週 第 ${widget.game.dayOfWeek} 天',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: textShadow,
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 32),
                style: IconButton.styleFrom(
                  shadowColor: Colors.black.withOpacity(0.5),
                  elevation: 4,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => BioSheet(game: widget.game),
                  );
                },
              ),
            ),
          ),
          if (widget.game.isCandidate)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '競選活動進行中: ${widget.game.currentElection?.title ?? ""}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ... 以下所有 build...View, BioSheet, InfoRow 的程式碼都不變 ...
  Widget buildCharacterCreationView() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('請為你的角色命名：', style: TextStyle(fontSize: 22, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: '輸入名字...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('請選擇你的出身背景：', style: TextStyle(fontSize: 22, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              widget.game.selectProfession(Profession.engineer, _nameController.text.trim());
            },
            child: const Text('工程師'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              widget.game.selectProfession(Profession.businessman, _nameController.text.trim());
            },
            child: const Text('商人'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              widget.game.selectProfession(Profession.gangster, _nameController.text.trim());
            },
            child: const Text('黑道'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              widget.game.selectProfession(Profession.politicalstaffer, _nameController.text.trim());
            },
            child: const Text('政治工作者'),
          ),
        ],
      ),
    );
  }

  Widget buildEventView() {
    if (widget.game.currentEvent == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(widget.game.formattedEventDescription, style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.5), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 24),
        ...widget.game.currentEvent!.choices.map((choice) {
          // 【新增】在建立按鈕前，先判斷它是否啟用
          bool enabled = true; // 預設為啟用
          if (choice.isEnabled != null) {
            enabled = choice.isEnabled!(widget.game.player!);
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton(
              // 【核心修改】onPressed 根據 enabled 的值來決定
              // 如果 enabled 是 true，就執行動作；如果是 false，就設為 null，按鈕會自動變灰
              onPressed: enabled ? () => widget.game.makeChoice(choice) : null,

              // 我們也可以根據是否啟用，來改變按鈕的樣式
              style: ElevatedButton.styleFrom(
                // 如果按鈕被禁用，給它一個深灰色
                backgroundColor: enabled ? const Color(0xFFF5F5DC) : Colors.grey.shade800,
                foregroundColor: enabled ? Colors.black87 : Colors.grey.shade500,
              ),
              child: Text(choice.description, textAlign: TextAlign.center),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget buildElectionResultsView() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: widget.game.electionWon ? Colors.green.shade900.withOpacity(0.8) : Colors.red.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.game.electionWon ? '【勝選快報】' : '【敗選聲明】',
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white54, height: 32),
          Text(
            widget.game.electionResultMessage,
            style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.game.finalizeElection(),
            child: const Text('發表感言'),
          ),
        ],
      ),
    );
  }

  Widget buildNewsReportView() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '本週新聞週報',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Colors.white54, height: 32),

          // 【核心修改】使用 Column 和 .map 來動態產生新聞列表
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.game.currentNewsHeadlines.map((headline) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(' • ', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    Expanded(
                      child: Text(
                        headline,
                        style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => widget.game.continueAfterNews(),
            child: const Text('繼續'),
          ),
        ],
      ),
    );
  }

  Widget buildEndOfDayView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('今天結束了。', style: TextStyle(fontSize: 22, color: Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => widget.game.nextDay(),
          child: const Text('開始新的一天'),
        ),
      ],
    );
  }
}

class BioSheet extends StatelessWidget {
  final PoliticianGame game;
  const BioSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.player == null) return const SizedBox.shrink();
    final player = game.player!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/paper_texture.jpg'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Divider(color: Colors.black26, height: 24, thickness: 1),
                    InfoRow(icon: Icons.cake_outlined, label: '年齡', value: '${player.age}', color: Colors.black54),
                    InfoRow(icon: Icons.work_outline, label: '職業', value: game.professionData[player.currentProfession]?['title'] ?? '', color: Colors.black54),
                    InfoRow(
                      icon: Icons.flag_outlined,
                      label: '黨籍',
                      value: partyToString(player.affiliation),
                      color: HSLColor.fromColor(partyToColor(player.affiliation)).withLightness(0.4).toColor(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final double size;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = DefaultTextStyle.of(context).style.color ?? Colors.white;
    final textColor = color ?? defaultColor;
    final shadow = [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.6))];

    return Row(
      children: [
        Icon(icon, color: textColor, size: size, shadows: shadow),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: size, color: textColor, shadows: shadow),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            color: textColor,
            fontWeight: FontWeight.bold,
            shadows: shadow,
          ),
        ),
      ],
    );
  }
}