import 'package:cloud_firestore/cloud_firestore.dart';

class DemenCrudService {
  final _db = FirebaseFirestore.instance;

  // ★ 出面データのコレクション名
  final String collection = "demen_data";

  // ------------------------------------------------------------
  // ■ 出面データを追加（登録）
  // ------------------------------------------------------------
  Future<void> addDemen({
    required String genbaId,
    required String workerId,
    required String date,
    required double overtime,
  }) async {
    await _db.collection(collection).add({
      "genbaId": genbaId,
      "workerId": workerId,
      "date": date,
      "overtime": overtime,
      "createdAt": DateTime.now(),
    });
  }

  // ------------------------------------------------------------
  // ■ 出面データを更新（編集）
  // ------------------------------------------------------------
  Future<void> updateDemen({
    required String docId,
    required String genbaId,
    required String workerId,
    required String date,
    required double overtime,
  }) async {
    await _db.collection(collection).doc(docId).update({
      "genbaId": genbaId,
      "workerId": workerId,
      "date": date,
      "overtime": overtime,
    });
  }

  // ------------------------------------------------------------
  // ■ 出面データを削除
  // ------------------------------------------------------------
  Future<void> deleteDemen(String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  // ------------------------------------------------------------
  // ■ 出面一覧（リアルタイム）
  // ------------------------------------------------------------
  Stream<QuerySnapshot> getDemenStream() {
    return _db
        .collection(collection)
        .orderBy("date", descending: true)
        .snapshots();
  }

  // ------------------------------------------------------------
  // ■ 今月の出面一覧（リアルタイム）
  // ------------------------------------------------------------
  Stream<QuerySnapshot> getMonthDemenStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    return _db
        .collection(collection)
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .where("createdAt", isLessThan: end)
        .snapshots();
  }
}
