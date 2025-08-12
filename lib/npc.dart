import 'package:politician_life/profession.dart';
import 'package:politician_life/party.dart';

// 定義一個 NPC 的藍圖
class Npc {
  final String name;          // NPC 的名字
  final Profession profession;  // NPC 的職業
  int relationship;
  final Party affiliation;


  Npc({
    required this.name,
    required this.profession,
    this.relationship = 0, // 初始關係為 0
    required this.affiliation,
  });
}