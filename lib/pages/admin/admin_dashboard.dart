import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理者ダッシュボード')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _menuCard(
              context,
              icon: Icons.add_business,
              title: "現場管理",
              subtitle: "現場の追加・編集・削除",
              route: "/admin/genba_manage",
              color: Colors.blue.shade100,
            ),
            _menuCard(
              context,
              icon: Icons.people,
              title: "作業員管理",
              subtitle: "作業員の登録・編集・削除",
              route: "/admin/worker_manage",
              color: Colors.green.shade100,
            ),
            _menuCard(
              context,
              icon: Icons.admin_panel_settings,
              title: "ユーザー管理",
              subtitle: "ログインユーザーの権限設定",
              route: "/admin/user_manage",
              color: Colors.orange.shade100,
            ),
            _menuCard(
              context,
              icon: Icons.list_alt,
              title: "出面一覧",
              subtitle: "全ユーザーの出面を確認・編集",
              route: "/admin/demen_list",
              color: Colors.purple.shade100,
            ),
            _menuCard(
              context,
              icon: Icons.pie_chart,
              title: "月次集計（全ユーザー）",
              subtitle: "全ユーザーの出面・経費・残業を集計",
              route: "/admin/month_summary_all",
              color: Colors.red.shade100,
            ),
            _menuCard(
              context,
              icon: Icons.settings,
              title: "アプリ設定",
              subtitle: "管理者専用の設定",
              route: "/admin/settings",
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
