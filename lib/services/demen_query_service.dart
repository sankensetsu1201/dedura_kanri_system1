// lib/services/demen_query_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DemenQueryService {
  final String collectionName;
  DemenQueryService({this.collectionName = 'demen_data'});

  /// 現場ごとの経費合計を取得（genbaId が null の場合は全件集計）
  Future<double> sumExpenseByGenba({String? genbaId}) async {
    Query q = FirebaseFirestore.instance.collection(collectionName);
    if (genbaId != null && genbaId.isNotEmpty) {
      q = q.where('genbaId', isEqualTo: genbaId);
    }
    final snap = await q.get();
    double sum = 0;
    for (final doc in snap.docs) {
      final raw = doc.data();
      // doc.data() は Object? 型なので Map にキャストして扱う
      if (raw is Map<String, dynamic>) {
        final v = raw['expense'];
        if (v is num) {
          sum += v.toDouble();
        } else if (v is String) {
          sum += double.tryParse(v) ?? 0;
        }
      } else {
        // safety: raw が Map でない場合は無視
        continue;
      }
    }
    return sum;
  }

  /// 今月の出面数（createdAt ベース）
  Future<int> countThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final snap = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.size;
  }

  /// 今月の出面を取得（createdAt ベース）
  Future<List<QueryDocumentSnapshot>> fetchThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final snap = await FirebaseFirestore.instance
        .collection(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }
}
