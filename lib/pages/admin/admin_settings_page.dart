// lib/pages/admin/admin_settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _clearing = false;

  Future<void> _clearLocalCache() async {
    setState(() => _clearing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _clearing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ローカルキャッシュを削除しました")),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("管理者設定")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card("アプリ情報", [
              const Text("このページでは管理者向けの設定や情報を確認できます。"),
              const SizedBox(height: 8),
              const Text("・現場マスター管理"),
              const Text("・作業員マスター管理"),
              const Text("・ユーザー管理"),
              const Text("・出面データ管理"),
              const Text("・月次集計（現場別 / 作業員別 / 全体）"),
              const Text("・Firestore セキュリティルール"),
            ]),

            _card("Firestore コレクション構造", [
              const Text("・users（ログインユーザー）"),
              const Text("・worker_master（作業員マスター）"),
              const Text("・genba_master（現場マスター）"),
              const Text("・demen_data（出面データ）"),
              const SizedBox(height: 8),
              const Text("出面データは以下の形式："),
              const Text("members: [ { workerId, name } ]"),
              const Text("expenses: [ { category, type, amount } ]"),
              const Text("dayCount, overtime, memo, work, date, genbaId"),
            ]),

            _card("管理者向け注意点", [
              const Text("・作業員や現場の削除は慎重に行ってください。"),
              const Text("・削除すると関連する出面データの整合性が崩れる可能性があります。"),
              const Text("・出面データの編集は全ユーザー分が対象です。"),
              const Text("・セキュリティルールは Firebase Console で管理してください。"),
            ]),

            _card("ローカルキャッシュ", [
              const Text("SharedPreferences に保存されている uid などを削除します。"),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: _clearing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete),
                label: const Text("ローカルキャッシュ削除"),
                onPressed: _clearing ? null : _clearLocalCache,
              ),
            ]),

            _card("今後の拡張案", [
              const Text("・バックアップ機能"),
              const Text("・CSV / Excel 出力"),
              const Text("・出面データの一括編集"),
              const Text("・管理者ログ（操作履歴）"),
              const Text("・通知設定（締め日リマインドなど）"),
            ]),
          ],
        ),
      ),
    );
  }
}
