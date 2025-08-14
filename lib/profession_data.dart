// lib/profession_data.dart

import 'package:flutter/foundation.dart';

// 這個類別用來描述一個具體的 "職等"
class ProfessionRank {
  final String title; // 職稱，如 "軟體工程師", "市議員"
  final double salary;

  ProfessionRank({required this.title, required this.salary});

  factory ProfessionRank.fromJson(Map<String, dynamic> json) {
    return ProfessionRank(
      title: json['title'],
      salary: json['salary'].toDouble(),
    );
  }
}

// 這個類別用來儲存一個職業大類的 "所有資訊"
class ProfessionInfo {
  final String categoryName; // "工程師", "政客"
  final List<ProfessionRank> ranks;

  ProfessionInfo({required this.categoryName, required this.ranks});

  factory ProfessionInfo.fromJson(Map<String, dynamic> json) {
    var ranksList = json['ranks'] as List;
    List<ProfessionRank> ranksData = ranksList.map((i) => ProfessionRank.fromJson(i)).toList();

    return ProfessionInfo(
      categoryName: json['categoryName'],
      ranks: ranksData,
    );
  }
}