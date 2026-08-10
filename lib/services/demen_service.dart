import 'package:cloud_firestore/cloud_firestore.dart';

class DemenService {
  final _db = FirebaseFirestore.instance;

  // ★ 出面登録
  Future<void> addDemen({
    required String workerId,
    required String genbaId,
    required String date,
    required int hours,
  }) async {
    await _db.collection("demen").add({
      "workerId": workerId,
      "genbaId": genbaId,
      "date": date,
      "hours": hours,
      "createdAt": DateTime.now(),
    });
  }

  // ★ 今日の出面数（リアルタイムはホーム画面側で処理）
  Future<int> getTodayDemen() async {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    final snapshot = await _db
        .collection("demen")
        .where("date", isEqualTo: todayStr)
        .get();

    return snapshot.size;
  }

  // ★ 今月の出面数
  Future<int> getMonthDemen() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final snapshot = await _db
        .collection("demen")
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .where("createdAt", isLessThan: end)
        .get();

    return snapshot.size;
  }

  // ★ 今月の出面一覧（リアルタイム）
  Stream<QuerySnapshot> getMonthDemenStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    return _db
        .collection("demen")
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .where("createdAt", isLessThan: end)
        .snapshots();
  }

  // ★ 出面一覧（リアルタイム）
  Stream<QuerySnapshot> getDemenStream() {
    return _db.collection("demen").orderBy("createdAt", descending: true).snapshots();
  }
}
