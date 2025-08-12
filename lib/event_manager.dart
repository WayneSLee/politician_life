import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:politician_life/game_choice.dart';
import 'package:politician_life/game_event.dart';
import 'package:politician_life/npc.dart';
import 'package:politician_life/party.dart';
import 'package:politician_life/player.dart';
import 'package:politician_life/politician_game.dart';
import 'package:politician_life/profession.dart';

class EventManager {
  final List<GameEvent> _allEvents = [];
  final Random _random = Random();
  final Player player;
  final PoliticianGame game;

  EventManager({required this.player, required this.game});

  Future<void> loadEvents() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
    final eventFilePaths = manifestMap.keys
        .where((key) => key.startsWith('assets/events/') && key.endsWith('.json'))
        .toList();

    for (final filePath in eventFilePaths) {
      try {
        final jsonString = await rootBundle.loadString(filePath);
        final List<dynamic> jsonList = jsonDecode(jsonString);

        for (var eventData in jsonList) {
          final event = GameEvent(
            description: eventData['description'],
            canTrigger: _createTrigger(eventData['trigger']), // 使用新的觸發條件產生器
            choices: (eventData['choices'] as List).map((choiceData) {
              return GameChoice(
                description: choiceData['description'],
                onSelect: choiceData.containsKey('action_id')
                    ? _getHardcodedAction(choiceData['action_id'])
                    : _createActionFromEffects(choiceData['effects'] ?? []),
              );
            }).toList(),
          );
          _allEvents.add(event);
        }
        print('成功從 $filePath 載入事件。');
      } catch (e) {
        print('讀取或解析檔案 $filePath 時發生錯誤: $e');
      }
    }
  }

  bool Function(Player) _createTrigger(dynamic triggerData) {
    if (triggerData == null) {
      return (player) => true;
    }

    // 將 triggerData 轉為 Map<String, dynamic>
    final Map<String, dynamic> conditions = triggerData as Map<String, dynamic>;

    return (player) {
      for (final key in conditions.keys) {
        final value = conditions[key];
        bool conditionMet = false;
        switch (key) {
          case 'profession':
            final requiredProfession = Profession.values.firstWhere((e) => e.toString() == 'Profession.$value');
            if (player.currentProfession == requiredProfession) conditionMet = true;
            break;
          case 'player_fame':
            if (_checkCondition(player.fame, value)) conditionMet = true;
            break;
          case 'world_economyIndex':
            if (_checkCondition(game.economyIndex, value)) conditionMet = true;
            break;
          case 'world_socialAtmosphere':
            if (_checkCondition(game.socialAtmosphere, value)) conditionMet = true;
            break;
          case 'custom':
            if (value == 'CAN_JOIN_PARTY' && (player.affiliation == Party.independent && player.relationships.values.any((npc) => npc.affiliation != Party.independent && npc.relationship > 20))) {
              conditionMet = true;
            }
            if (value == 'HAS_NPC_WANG' && player.relationships.containsKey('王前輩')) {
              conditionMet = true;
            }
            break;
        }
        // 複合條件是 AND 邏輯，只要有一個不滿足，就直接回傳 false
        if (!conditionMet) return false;
      }
      // 所有條件都滿足
      return true;
    };
  }

  bool _checkCondition(int stat, Map<String, dynamic> condition) {
    final op = condition['operator'];
    final val = condition['value'];
    if (op == '>') return stat > val;
    if (op == '<') return stat < val;
    if (op == '==') return stat == val;
    return false;
  }

  Function(Player) _createActionFromEffects(List<dynamic> effectsData) {
    return (Player player) {
      for (var effect in effectsData) {
        final type = effect['type'];

        switch (type) {
          case 'gainFame':
          case 'gainMoney':
          case 'spendMoney':
            if (effect.containsKey('value')) {
              final value = effect['value'];
              if (value != null) {
                if (type == 'gainFame') player.gainFame((value as num).toInt());
                if (type == 'gainMoney') player.gainMoney((value as num).toInt());
                if (type == 'spendMoney') player.spendMoney((value as num).toInt());
              }
            }
            break;
          case 'changeWorldStat':
            if (effect.containsKey('value') && effect.containsKey('stat')) {
              final value = effect['value'];
              final stat = effect['stat'];
              if (value != null && stat != null) {
                if (stat == 'socialAtmosphere') game.socialAtmosphere += (value as num).toInt();
                if (stat == 'economyIndex') game.economyIndex += (value as num).toInt();
              }
            }
            break;
        // 【強化 playAnimation 的處理邏輯】
          case 'playAnimation':
          // 1. 先檢查 'path' 這個 key 是否存在，且其值不是 null
            if (effect.containsKey('path') && effect['path'] != null) {
              // 2. 將它安全地轉換成 String
              final path = effect['path'] as String;
              // 3. 才呼叫播放函式
              game.playAnimation(path);
            } else {
              // 如果 JSON 寫錯了，在 console 印出一個警告，但不要讓遊戲崩潰
              print("警告：在事件中找到 'playAnimation' 效果，但缺少 'path' 屬性。");
            }
            break;
        }
      }
    };
  }

  // 根據 action_id 回傳寫死的複雜動作
  Function(Player) _getHardcodedAction(String actionId) {
    switch (actionId) {
    // 在這裡放置所有複雜的邏輯
      case 'ACTION_CREATE_NEW_FRIEND':
        return (player) {
          const List<String> lastNames = ['陳', '林', '黃', '張', '李'];
          const List<String> firstNames = ['冠宇', '家豪', '俊傑', '雅婷', '怡君'];
          final String randomName = lastNames[_random.nextInt(lastNames.length)] + firstNames[_random.nextInt(firstNames.length)];

          if (player.relationships.containsKey(randomName)) {
            player.relationships[randomName]!.relationship += 2;
            return;
          }
          final parties = [Party.blue, Party.green, Party.white];
          final randomParty = parties[_random.nextInt(parties.length)];
          final newFriend = Npc(name: randomName, profession: player.currentProfession, relationship: 5, affiliation: randomParty);
          player.relationships[newFriend.name] = newFriend;
          player.gainFame(2);
        };
      case 'ACTION_ACCEPT_PARTY_INVITATION':
        return (player) {
          final inviter = player.relationships.values.firstWhere((npc) => npc.affiliation != Party.independent && npc.relationship > 20);
          player.affiliation = inviter.affiliation;
          player.gainFame(20);
        };
      case 'ACTION_GANGSTER_COOPERATE_CHECK':
        return (player) {
          if (_random.nextBool()) {
            player.gainFame(5); game.socialAtmosphere -= 5;
          } else {
            player.gainFame(-10); game.socialAtmosphere += 10;
          }
        };
      case 'ACTION_GANGSTER_RUN_FROM_CHECK':
        return (player) {
          if (_random.nextBool()) {
            player.gainFame(15); game.socialAtmosphere -= 15;
          } else {
            player.gainFame(-20); game.socialAtmosphere += 20;
          }
        };
      case 'ACTION_HANDLE_PETITION':
        return (player) {
          if (player.fame > 100) {
            player.gainFame(10);
          } else {
            if (game.socialAtmosphere < 20) {
              player.gainFame(-25);
            }
          }
        };
      case 'ACTION_REJECT_PETITION':
        return (player) {
          player.gainFame(-5);
          if (_random.nextBool()) {
            player.gainFame(30); game.socialAtmosphere += 10;
          }
        };
      case 'ACTION_BUSINESSMAN_GAMBLE_STOCK':
        return (player) {
          if (_random.nextBool()) {
            player.gainMoney(player.money); game.economyIndex += 10;
          } else {
            player.spendMoney(player.money ~/ 2); game.economyIndex -= 20;
          }
        };
      case 'ACTION_SMEAR_CAMPAIGN_DENY':
        return (player) {
          player.spendMoney(100000);
          if (game.socialAtmosphere < 0 && player.fame < 50) {
            player.gainFame(-20);
          } else if (game.socialAtmosphere < 0 && player.fame > 50) {
            player.gainFame(20); game.socialAtmosphere += 10;
          }
        };
      case 'ACTION_SMEAR_CAMPAIGN_IGNORE':
        return (player) {
          player.gainFame(-15); game.socialAtmosphere -= 20;
          if (game.socialAtmosphere < 0 && _random.nextBool()) {
            player.gainFame(-20);
          }
        };
      case 'ACTION_GREET_WANG':
        return (player) {
          final colleague = player.relationships['王前輩'];
          if (colleague != null) {
            colleague.relationship += 5;
          }
          player.gainFame(1);
        };
      case 'ACTION_IGNORE_WANG':
        return (player) {
          final colleague = player.relationships['王前輩'];
          if (colleague != null) {
            colleague.relationship -= 1;
          }
        };
      default:
      // 如果找不到對應的 ID，回傳一個什麼都不做的動作
        return (player) {};
    }
  }

  GameEvent getRandomEvent() {
    // 【修正】在 .where 子句中，正確處理可為 null 的 canTrigger
    final validEvents = _allEvents.where((event) {
      // 如果 canTrigger 是 null，視為可觸發 (true)
      // 如果不是 null，則執行它
      return event.canTrigger == null || event.canTrigger!(player);
    }).toList();

    if (validEvents.isEmpty) {
      return GameEvent(
        description: '今天風平浪靜，沒有特別的事情發生。',
        choices: [GameChoice(description: '繼續下一天', onSelect: (player) {})],
        canTrigger: (player) => true,
      );
    }
    return validEvents[_random.nextInt(validEvents.length)];
  }
}