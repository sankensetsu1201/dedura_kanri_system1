// lib/pages/admin/admin_security_page.dart
import 'package:flutter/material.dart';

class AdminSecurityPage extends StatelessWidget {
  const AdminSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    const ruleExample = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // users コレクション
    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow write: if request.auth != null && request.auth.uid == uid;
    }

    // worker_master（管理者のみ）
    match /worker_master/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin';
    }

    // genba_master（管理者のみ）
    match /genba_master/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.role == 'admin';
    }

    // demen_data（一般ユーザーは自分の出面のみ編集可能）
    match /demen_data/{docId} {
      allow read: if request.auth != null;

      allow write: if request.auth != null &&
        (
          // 管理者は全て編集可能
          request.auth.token.role == 'admin' ||

          // 一般ユーザーは createdBy が自分の uid の場合のみ編集可能
          request.resource.data.createdBy == request.auth.uid
        );
    }
  }
}
''';

    return Scaffold(
      appBar: AppBar(title: const Text("Firestore セキュリティルール（管理者用）")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Firestore セキュリティルールとは？",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Firestore のセキュリティルールは、データの読み書きを誰ができるかを制御する仕組みです。\n"
              "このページでは、あなたのアプリに最適なルール例を紹介します。\n"
              "実際の設定は Firebase Console → Firestore → ルール から行ってください。",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),
            const Text(
              "推奨ルール（あなたのアプリ用）",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  ruleExample,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: "monospace",
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "説明",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const Text(
              "・users：ログインユーザー本人のみ読み書き可能\n"
              "・worker_master：管理者のみ編集可能\n"
              "・genba_master：管理者のみ編集可能\n"
              "・demen_data：管理者は全て編集可能、一般ユーザーは自分が作成した出面のみ編集可能\n",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 24),
            const Text(
              "注意点",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const Text(
              "・Firebase Authentication のカスタムクレーム（role: admin）を使う場合、Cloud Functions で設定が必要です。\n"
              "・セキュリティルールは必ずテストしてから公開してください。\n"
              "・誤ったルールはデータが読み込めなくなる原因になります。",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 32),
            Center(
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Firestore Console を開く"),
                onPressed: () {
                  // 実際にはブラウザを開けないので説明だけ
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ブラウザで Firebase Console を開いてください"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
