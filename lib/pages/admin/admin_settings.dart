// lib/pages/admin/admin_settings.dart
import 'package:flutter/material.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理設定')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 管理者情報
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                title: const Text('管理者情報'),
                subtitle: const Text('管理者アカウントや権限の設定'),
                onTap: () {
                  Navigator.pushNamed(context, '/admin/user_list');
                },
              ),
            ),
            const SizedBox(height: 12),

            // Firestore ルール確認
            Card(
              child: ListTile(
                leading: const Icon(Icons.security, color: Colors.redAccent),
                title: const Text('Firestore セキュリティルール'),
                subtitle: const Text('読み書き権限やセキュリティルールの確認'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Firestore ルールについて"),
                      content: const Text(
                        "Firestore のセキュリティルールは Firebase Console から確認できます。\n"
                        "このアプリでは管理者権限を持つユーザーのみがデータを編集できます。",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("閉じる"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // アプリ設定
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_applications, color: Colors.green),
                title: const Text('アプリ設定'),
                subtitle: const Text('アプリ全体の設定（表示設定・通知など）'),
                onTap: () {
                  // 今後の拡張用
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("この機能はまだ実装されていません")),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'ここは管理設定のプレースホルダです。\n必要な設定項目を追加してください。',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
