import 'package:politician_life/profession.dart';
import 'package:politician_life/npc.dart';
import 'package:politician_life/party.dart';

// 這是一個 class (類別)，你可以把它想像成一個藍圖，
// 用來描述一個「玩家」物件應該包含哪些資料。
class Player {
  final String name;
  // 玩家的核心資源
  int money;      // 金錢
  int fame;       // 名聲
  int age;        // 年齡
  Profession currentProfession; // 玩家當前的職業
  Map<String, Npc> relationships;
  Party affiliation;

  // 政治光譜 [-100, 100]
  int politicalSpectrum; // 政治光譜 (經濟)
  int socialSpectrum;    // 社會光譜 (社會)

  // 構造函數 (Constructor)
  // 當我們創建一個新的 Player 物件時，這個函數會被呼叫，
  // 用來設定初始值。
  Player({
    required this.name,
    required this.money,
    required this.fame,
    required this.age,
    required this.politicalSpectrum,
    required this.socialSpectrum,
    required this.currentProfession,
  }) : relationships = {},
       affiliation = Party.independent;

  // 我們可以加上一些方便的方法(method)，例如增加名聲
  void gainFame(int amount) {
    fame += amount;
    print('名聲改變了 $amount！現在的名聲是 $fame'); // 把文字改得更通用
  }

  // 或是花錢
  void spendMoney(int amount) {
    money -= amount;
    print('花費了 $amount 元！剩餘金錢是 $money');
  }

  // 【新增這個方法】
  // 專門用來增加金錢
  void gainMoney(int amount) {
    money += amount;
    print('獲得了 $amount 元！剩餘金錢是 $money');
  }

  void ageUp() {
    // 遊戲中的一年可能是 365 天，我們先簡化成 4 天等於 1 歲
    // 這裡的邏輯可以很複雜，我們先簡單處理
    // 假設每過一天，年齡就增加 0.25 (只是示意)
    // 為了簡單，我們先改成每回合就老一歲
    age += 1;
    print('時間流逝，玩家現在 ${age} 歲');
  }
}