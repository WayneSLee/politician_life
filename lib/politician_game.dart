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


  // 【新增】日曆系統變數
  int dayOfWeek = 1;  // 1週5天
  int weekOfYear = 1; // 1年12週
  int year = 1;       // 第幾年

  Map<String, dynamic> _newsData = {};
  List<String> currentNewsHeadlines = [];

  final Map<Profession, Map<String, dynamic>> professionData = {
    Profession.engineer: {'title': '工程師', 'salary': 1500},
    Profession.businessman: {'title': '商人', 'salary': 2500},
    Profession.gangster: {'title': '黑道', 'salary': 3000},
    Profession.politician: {'title': '政治幕僚', 'salary': 1200},
  };

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

    triggerNewEvent();
    isLoading = false;
    currentPhase = GamePhase.event;
    audioManager.playMainBgm();
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

  void nextDay() {
    if (player == null) return;

    final job = professionData[player!.currentProfession];
    if (job != null) {
      player!.gainMoney(job['salary'] as int);
    }

    dayOfWeek++;

    if (dayOfWeek > 5) {
      dayOfWeek = 1;
      weekOfYear++;
      // 【修改】在進入新聞階段前，先產生新聞內容
      generateNewsReport();
      currentPhase = GamePhase.newsReport;
    } else {
      triggerNewEvent();
      currentPhase = GamePhase.event;
    }

    if (weekOfYear > 12) {
      weekOfYear = 1;
      year++;
      player!.ageUp();
    }

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

    return description;
  }
}