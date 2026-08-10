// tools/backfill_worker_master.dart
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ここをプロジェクトの実際のパスに合わせてください ---
// 例1: firebase_options.dart がプロジェクトルートにある場合（推奨）
import '../lib/firebase_options.dart';

// 例2: firebase_options.dart が lib/ 配下にある場合
// import '../lib/firebase_options.dart';

// 例3: もし firebase_options.dart を別の場所に置いているなら、その相対パスを指定してください
// import '../path/to/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  print('Starting backfill: users -> worker_master');

  final usersSnap = await firestore.collection('users').get();
  print('Found ${usersSnap.docs.length} users');

  int created = 0;
  int skipped = 0;
  int noWorkerId = 0;

  for (final u in usersSnap.docs) {
    final data = u.data();
    final workerId = (data['workerId'] as String?)?.trim();
    final displayName = (data['displayName'] ?? data['name'] ?? '') as String;
    final email = (data['email'] ?? '') as String;

    if (workerId == null || workerId.isEmpty) {
      print('Skipping user ${u.id}: no workerId');
      noWorkerId++;
      continue;
    }

    final wmRef = firestore.collection('worker_master').doc(workerId);
    final wmDoc = await wmRef.get();
    if (wmDoc.exists) {
      print('worker_master exists for $workerId, skipping');
      skipped++;
      continue;
    }

    try {
      await wmRef.set({
        'workerId': workerId,
        'displayName': displayName,
        'email': email,
        'createdFromUser': u.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created worker_master for $workerId');
      created++;
    } catch (e) {
      print('Failed to create worker_master for $workerId: $e');
    }

    // レート対策
    await Future.delayed(const Duration(milliseconds: 200));
  }

  print('Backfill finished. created=$created skipped=$skipped noWorkerId=$noWorkerId');
  exit(0);
}
