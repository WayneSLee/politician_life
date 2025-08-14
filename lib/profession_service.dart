// lib/profession_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:politician_life/profession.dart';
import 'package:politician_life/profession_data.dart'; // 引入我們剛才建立的類別

class ProfessionService {
  // 使用 Map 將 enum 與其詳細資料關聯起來
  static final Map<Profession, ProfessionInfo> _professionData = {};

  // 遊戲啟動時必須呼叫此方法來載入資料
  static Future<void> load() async {
    final jsonString = await rootBundle.loadString('assets/data/professions.json'); // 假設你的資料檔路徑
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    jsonMap.forEach((key, value) {
      // 將 JSON 的 key (字串) 轉換為 Profession enum
      final professionEnum = Profession.values.firstWhere(
            (e) => e.toString() == 'Profession.$key',
        orElse: () => throw Exception('Profession enum for $key not found'),
      );

      _professionData[professionEnum] = ProfessionInfo.fromJson(value);
    });
  }

  // 提供一個靜態方法，讓外部可以方便地取得職業資訊
  static ProfessionInfo getInfo(Profession profession) {
    return _professionData[profession]!;
  }
}