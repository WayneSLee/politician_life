// 定義選舉的狀態
enum ElectionStatus {
  upcoming,   // 即將到來
  campaigning, // 競選中
  finished,   // 已結束
}

// 定義一場選舉的藍圖
class Election {
  final String title; // 例如："第 23 屆市議員選舉"
  ElectionStatus status;

  Election({
    required this.title,
    this.status = ElectionStatus.upcoming,
  });
}