import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart'; // 引入 services
import 'dart:convert';
import 'package:politician_life/event_manager.dart';
import 'package:politician_life/game_event.dart';
import 'package:politician_life/game_phase.dart';
import 'package:politician_life/game_choice.dart';
import 'package:politician_life/npc.dart';
import 'package:politician_life/player.dart';
import 'package:politician_life/profession.dart';
import 'package:politician_life/party.dart';
import 'package:politician_life/audio_manager.dart';
import 'package:politician_life/election.dart';

class PoliticianGame extends FlameGame with ChangeNotifier {
  Player? player;
  late EventManager eventManager;
  GameEvent? currentEvent;
  late GamePhase currentPhase;
  bool isLoading = false;
  bool showAnimation = false;
  String? currentAnimationPath;
  Timer? _animationTimer;
  late final AudioManager audioManager;
  Election? currentElection;
  bool isCandidate = false; // 玩家是否為候選人
  int dayOfWeek = 1;  // 1週5天
  int weekOfYear = 1; // 1年12週
  int year = 1;       // 第幾年
  bool electionWon = false;
  String electionResultMessage = '';

  Map<String, dynamic> _newsData = {};
  List<String> currentNewsHeadlines = [];

  int socialAtmosphere = 0;
  int economyIndex = 20;

  List<String> prologuePages = [];
  int currentProloguePage = 0;

  @override
  Color backgroundColor() {
    return const Color(0x00000000);
  }

  @override
  Future<void> onLoad() async {
    audioManager = AudioManager();
    await _loadNewsData();
    await _loadPrologue();
    currentPhase = GamePhase.prologue;
  }
  @override
  void onRemove() {
    // 【新增】當遊戲被移除時，釋放音訊資源
    audioManager.dispose();
    super.onRemove();
  }

  Future<void> _loadNewsData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/story/news.json');
      _newsData = jsonDecode(jsonString);
    } catch (e) {
      print('讀取新聞檔案時發生錯誤: $e');
    }
  }

  // 【新增】產生新聞週報內容的方法
  void generateNewsReport() {
    if (_newsData.isEmpty) {
      currentNewsHeadlines = ['新聞系統錯誤...'];
      return;
    }

    List<String> report = [];
    final random = Random();

    // 1. 根據經濟景氣挑選一則新聞
    final economyNews = _newsData['economy'];
    if (economyIndex > 30) {
      report.add(economyNews['good'][random.nextInt(economyNews['good'].length)]);
    } else if (economyIndex < -30) {
      report.add(economyNews['bad'][random.nextInt(economyNews['bad'].length)]);
    } else {
      report.add(economyNews['neutral'][random.nextInt(economyNews['neutral'].length)]);
    }

    // 2. 根據社會氛圍挑選一則新聞
    final socialNews = _newsData['social'];
    if (socialAtmosphere > 30) {
      report.add(socialNews['good'][random.nextInt(socialNews['good'].length)]);
    } else if (socialAtmosphere < -30) {
      report.add(socialNews['bad'][random.nextInt(socialNews['bad'].length)]);
    } else {
      report.add(socialNews['neutral'][random.nextInt(socialNews['neutral'].length)]);
    }

    // 3. 隨機挑選一則趣聞
    final fillerNews = _newsData['filler'] as List;
    report.add(fillerNews[random.nextInt(fillerNews.length)]);

    currentNewsHeadlines = report;
  }

  Future<void> _loadPrologue() async {
    try {
      final jsonString = await rootBundle.loadString('assets/story/prologue.json');
      final List<dynamic> pages = jsonDecode(jsonString);
      prologuePages = pages.map((page) => page.toString()).toList();
    } catch (e) {
      print('讀取序章檔案時發生錯誤: $e');
      prologuePages = ['序章讀取失敗...'];
    }
  }

  // 【新增】推進序章劇情的方法
  void advancePrologue() {
    // 如果還有下一頁
    if (currentProloguePage < prologuePages.length - 1) {
      currentProloguePage++;
    } else {
      // 如果已經是最後一頁，就進入創角階段
      currentPhase = GamePhase.characterCreation;
    }
    notifyListeners();
  }

  void selectProfession(Profession profession, String playerName) {
    if (isLoading) return;
    isLoading = true;
    currentPhase = GamePhase.loading;
    notifyListeners();
    _initializePlayerAndEvents(profession, playerName);
  }

  Future<void> _initializePlayerAndEvents(Profession profession, String playerName) async {
    player = Player(
      name: playerName,
      money: 500000,
      fame: 10,
      age: 23,
      politicalSpectrum: 5,
      socialSpectrum: -10,
      currentProfession: profession,
    );

    // ... 生成初始 NPC 的邏輯 ...
    String colleagueName = '王前輩';
    final parties = [Party.blue, Party.green, Party.white];
    final randomParty = parties[Random().nextInt(parties.length)];
    final colleague = Npc(name: colleagueName, profession: profession, relationship: 10, affiliation: randomParty);
    player!.relationships[colleagueName] = colleague;

    eventManager = EventManager(player: player!, game: this);
    await eventManager.loadEvents();

    if (year <= 4) {
      scheduleNextElection();
    }

    triggerNewEvent();
    isLoading = false;
    currentPhase = GamePhase.event;
    audioManager.playMainBgm();
    notifyListeners();
  }

  void scheduleNextElection() {
    // 假設選舉每 4 年一次
    currentElection = Election(title: '第 ${ (year ~/ 4) + 1 } 屆里長選舉');
    print('新的選舉已安排在 4 年後: ${currentElection!.title}');
  }

  void calculateElectionResults() {
    if (player == null) return;

    // 這是一個非常基礎的計票公式，未來可以擴充得更複雜
    // 基礎勝率 30%
    double winChance = 0.3;

    // 名聲越高，勝率越高 (每 100 點名聲增加 10% 勝率)
    winChance += (player!.fame / 1000);

    // 金錢越多，勝率越高 (每 100 萬金錢增加 5% 勝率)
    winChance += (player!.money / 20000000);

    // 確保勝率不會超過 95%
    if (winChance > 0.95) winChance = 0.95;

    print('玩家最終勝率為: $winChance');

    // 根據勝率進行一次隨機判定
    if (Random().nextDouble() < winChance) {
      electionWon = true;
      electionResultMessage = '恭喜！您成功當選，開啟了您政治生涯的新篇章！';

      // 1. 設定待就職資訊
      player!.pendingProfession = Profession.electedrepresentative; // 假設選上後是政客
      player!.pendingRankIndex = 0; // 假設是第一個職等 "里長"

      // 2. 設定就職日 (例如：2週後)
      int inaugurationWeek = weekOfYear + 2;
      int inaugurationYear = year;
      if (inaugurationWeek > 12) {
        inaugurationWeek -= 12;
        inaugurationYear++;
      }
      player!.inaugurationDate = {
        'year': inaugurationYear,
        'week': inaugurationWeek,
        'day': 1 // 從週一開始
      };

      // 3. 進入等待就職階段
      currentPhase = GamePhase.awaitingInauguration;
    } else {
      electionWon = false;
      electionResultMessage = '可惜... 您以些微的差距落敗。但這次的挑戰讓更多人認識了您，下次再來！';
      player!.gainFame(20); // 敗選也能增加一些名聲
      currentPhase = GamePhase.electionResults;
    }
  }

  void finalizeElection() {
    isCandidate = false;
    currentElection = null; // 清除本次選舉

    // 重新安排下一次選舉
    if (!electionWon) {
      scheduleNextElection();
    }

    // 觸發一個新的日常事件，回歸正常生活
    triggerNewEvent();
    currentPhase = GamePhase.event;
    notifyListeners();
  }

  void playAnimation(String path, {int seconds = 2}) {
    _animationTimer?.cancel();
    currentAnimationPath = path;
    showAnimation = true;
    notifyListeners();
    _animationTimer = Timer(Duration(seconds: seconds), () {
      showAnimation = false;
      currentAnimationPath = null;
      notifyListeners();
    });
  }

  void triggerNewEvent() {
    currentEvent = eventManager.getRandomEvent();
  }

  void _performInauguration() {
    print("就職日到來！");
    if (player == null || player!.pendingProfession == null) return;

    // 1. 正式更新玩家職業
    player!.setJob(player!.pendingProfession!, player!.pendingRankIndex!);
    player!.gainFame(100); // 在就職時才給予大量名聲

    // 2. 清理待就職狀態
    player!.pendingProfession = null;
    player!.pendingRankIndex = null;
    player!.inaugurationDate = null;
    isCandidate = false;

    // 3. 重新安排下一次選舉
    scheduleNextElection();

    // 4. 顯示一個慶祝動畫或事件，然後回到正常事件循環
    playAnimation('assets/animations/celebration.json'); // 假設您有這個動畫
    triggerNewEvent();
    currentPhase = GamePhase.event;
  }

  void nextDay() {
    if (player == null) return;
    if (currentPhase == GamePhase.awaitingInauguration) {
      final date = player!.inaugurationDate!;
      if (year == date['year'] && weekOfYear == date['week'] && dayOfWeek == date['day']) {
        _performInauguration();
        // 就職日當天完成就職即可，不用再往下執行 nextDay 的其他邏輯
        notifyListeners();
        return;
      }
    }
    print('--- Day Start: Year $year, Week $weekOfYear, Day $dayOfWeek ---');

    // 領薪水
    final job = professionData[player!.currentProfession];
    player!.gainMoney(player!.currentSalary);

    // 日期推進W
    dayOfWeek++;

    // 檢查是否為選舉日
    if (year % 4 == 0 && weekOfYear == 12 && dayOfWeek > 5 && isCandidate) {
      calculateElectionResults();
      notifyListeners();
      return;
    }

    // 檢查是否過完一週
    if (dayOfWeek > 5) {
      dayOfWeek = 1;
      weekOfYear++;
      generateNewsReport();
      currentPhase = GamePhase.newsReport;
    } else {
      // 【核心修正】即使還沒過完一週，也要觸發新事件並設定階段
      triggerNewEvent();
      currentPhase = GamePhase.event;
    }

    // 檢查是否過完一年
    if (weekOfYear > 12) {
      weekOfYear = 1;
      year++;
      player!.ageUp();

      if (year % 4 == 1 && year > 1) {
        scheduleNextElection();
      }
    }

    // 印出選舉狀態以供除錯
    if (currentElection != null) {
      print('Current Election Status: ${currentElection!.status.toString()}');
    } else {
      print('Current Election Status: null (No upcoming election)');
    }
    print('----------------------------------------------------');

    notifyListeners();
  }


  // 處理玩家的選擇
  void makeChoice(GameChoice choice) {
    if (player == null) return;
    choice.onSelect(player!);
    currentPhase = GamePhase.endOfDay;
    notifyListeners();
  }

  // 處理新聞看完後的「繼續」按鈕
  void continueAfterNews() {
    triggerNewEvent();
    currentPhase = GamePhase.event;
    notifyListeners();
  }

  // 【已修正空安全問題的 Getter】
  String get formattedEventDescription {
    if (currentEvent == null || player == null) return '';
    String description = currentEvent!.description;

    if (description.contains('{NPC_NAME}')) {
      Npc? inviter;
      try {
        // .firstWhere 如果找不到會拋出錯誤，所以我們用 try-catch 來捕捉
        inviter = player!.relationships.values.firstWhere(
              (npc) => npc.affiliation != Party.independent && npc.relationship > 20,
        );
      } catch (e) {
        // 如果找不到符合條件的 NPC，inviter 就會是 null
        inviter = null;
      }

      // 【關鍵】在確定 inviter 不是 null 之後，才使用它的屬性
      if (inviter != null) {
        description = description.replaceAll('{NPC_NAME}', inviter.name);
        description = description.replaceAll('{PARTY_NAME}', partyToString(inviter.affiliation));
      } else {
        // 如果真的找不到，給一個預設的描述，避免樣板文字出現
        description = description.replaceAll('{NPC_NAME}', '一位神秘的前輩');
        description = description.replaceAll('{PARTY_NAME}', '一個秘密組織');
      }
    }

    if (description.contains('{ELECTION_TITLE}')) {
      if (currentElection != null) {
        description = description.replaceAll('{ELECTION_TITLE}', currentElection!.title);
      } else {
        description = description.replaceAll('{ELECTION_TITLE}', '即將到來的選舉');
      }
    }

    return description;
  }
}