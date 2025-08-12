// lib/party.dart

// 根據您最初的設計，定義遊戲中的政黨
enum Party {
  blue,   // 藍黨
  green,  // 綠黨
  white,  // 白黨
  independent, // 無黨籍
}
String partyToString(Party party) {
  switch (party) {
    case Party.blue: return '藍黨';
    case Party.green: return '綠黨';
    case Party.white: return '白黨';
    case Party.independent: return '無黨籍';
  }
}