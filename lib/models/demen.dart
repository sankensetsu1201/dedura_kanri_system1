class Demen {
  String id;          // FirestoreのID
  String workerId;    // 作業員のID
  String hostId;      // ホストのID
  String workerName;  // 作業員名
  String siteName;    // 現場名
  DateTime date;      // 日付
  double hours;       // 時間
  String note;        // 備考
  DateTime createdAt; // 送信日時

  Demen({
    required this.id,
    required this.workerId,
    required this.hostId,
    required this.workerName,
    required this.siteName,
    required this.date,
    required this.hours,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'hostId': hostId,
      'workerName': workerName,
      'siteName': siteName,
      'date': date.toIso8601String(),
      'hours': hours,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
