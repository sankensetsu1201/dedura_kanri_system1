import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ===== ページ =====
import 'admin_dashboard.dart';
import 'admin_settings_page.dart';
import 'worker_manage_page.dart';
import 'worker_month_page.dart';
import 'genba_manage_page.dart';
import 'genba_month_page.dart';
import 'user_manage_page.dart';
import 'user_list_page.dart';
import 'admin_demen_list_page.dart';
import 'admin_excel_viewer_page.dart';
import 'admin_import_page.dart';
import 'admin_export_page.dart';
import 'admin_backup_page.dart';
import 'admin_restore_page.dart';

/// =======================================================
///  ページ遷移アニメーション（ここが前回消えてた）
/// =======================================================
class PageTransitions {
  static Route scale(BuildContext context, Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final scale = Tween(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));
        return ScaleTransition(scale: scale, child: child);
      },
    );
  }
}

/// =======================================================
///  管理者ダッシュボード本体
/// =======================================================
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _DashboardItem("ダッシュボード", "assets/icons/dashboard.svg", Colors.blueAccent, const AdminDashboardPage()),
      _DashboardItem("アプリ設定", "assets/icons/settings.svg", Colors.blueGrey, const AdminSettingsPage()),
      _DashboardItem("作業員一覧", "assets/icons/workers.svg", Colors.tealAccent, const WorkerManagePage()),
      _DashboardItem("作業員月別", "assets/icons/calendar.svg", Colors.teal, const WorkerMonthPage()),
      _DashboardItem("現場一覧", "assets/icons/site.svg", Colors.orangeAccent, const GenbaManagePage()),
      _DashboardItem("現場月別", "assets/icons/calendar.svg", Colors.orange, const GenbaMonthPage()),
      _DashboardItem("ユーザー一覧", "assets/icons/users.svg", Colors.indigoAccent, const UserListPage()),
      _DashboardItem("ユーザー管理", "assets/icons/admin.svg", Colors.indigo, const UserManagePage()),
      _DashboardItem("出面一覧", "assets/icons/list.svg", Colors.greenAccent, const AdminDemenListPage()),
      _DashboardItem("Excelビューア", "assets/icons/excel.svg", Colors.deepPurpleAccent, const AdminExcelViewerPage()),
      _DashboardItem("データインポート", "assets/icons/upload.svg", Colors.redAccent, const AdminImportPage()),
      _DashboardItem("データエクスポート", "assets/icons/download.svg", Colors.red, const AdminExportPage()),
      _DashboardItem("バックアップ作成", "assets/icons/backup.svg", Colors.lightBlueAccent, const AdminBackupPage()),
      _DashboardItem("バックアップ復元", "assets/icons/restore.svg", Colors.lightBlue, const AdminRestorePage()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1F25),
      appBar: AppBar(
        title: const Text("管理者ダッシュボード"),
        backgroundColor: const Color(0xFF2C2F36),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          return _DashboardTile(item: items[index]);
        },
      ),
    );
  }
}

/// =======================================================
///  ダッシュボードアイテム
/// =======================================================
class _DashboardItem {
  final String title;
  final String svg;
  final Color color;
  final Widget page;

  _DashboardItem(this.title, this.svg, this.color, this.page);
}

/// =======================================================
///  タイル（アニメーション付き）
/// =======================================================
class _DashboardTile extends StatefulWidget {
  final _DashboardItem item;

  const _DashboardTile({required this.item});

  @override
  State<_DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<_DashboardTile> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1.0, end: scale),
      duration: const Duration(milliseconds: 150),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => scale = 0.95),
        onTapUp: (_) => setState(() => scale = 1.0),
        onTapCancel: () => setState(() => scale = 1.0),
        onTap: () {
          Navigator.push(
            context,
            PageTransitions.scale(context, widget.item.page), // ← アニメ遷移ここ！
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F36),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  widget.item.svg,
                  colorFilter: ColorFilter.mode(widget.item.color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
