// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isAdmin = false;
  bool _loadingRole = true;
  String todayText = "";
  double monthlyCount = 0;

  // ★ 今日の出面データ
  Map<String, dynamic>? todayDemen;

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadMonthlyCount();
    _loadRoleFromFirestore();
    _loadTodayDemen(); // ★ 今日の出面を読み込む
  }

  Future<void> _loadTodayDemen() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final snap = await FirebaseFirestore.instance
        .collection("demen")
        .doc(uid)
        .collection("days")
        .doc(today)
        .get();

    if (snap.exists) {
      setState(() => todayDemen = snap.data());
    }
  }

  Future<void> _loadRoleFromFirestore() async {
    setState(() => _loadingRole = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            isAdmin = false;
            _loadingRole = false;
          });
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = (doc.data()?['role'] as String?) ?? 'worker';

      if (!mounted) return;
      setState(() {
        isAdmin = role == 'admin';
        _loadingRole = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isAdmin = false;
        _loadingRole = false;
      });
    }
  }

  void _loadToday() {
    final now = DateTime.now();
    todayText = DateFormat("yyyy年MM月dd日 (EEE)", "ja_JP").format(now);
  }

  Future<void> _loadMonthlyCount() async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final snap = await FirebaseFirestore.instance
          .collection("demen_data")
          .get();

      double total = 0;

      for (final doc in snap.docs) {
        final data = doc.data();

        DateTime? date;
        if (data["date"] is Timestamp) {
          date = (data["date"] as Timestamp).toDate();
        } else if (data["date"] is String) {
          date = DateTime.tryParse(data["date"]);
        }

        if (date == null) continue;

        if (date.isAfter(firstDay.subtract(const Duration(days: 1))) &&
            date.isBefore(lastDay.add(const Duration(days: 1)))) {
          final dayCount = (data["dayCount"] ?? 1).toDouble();
          total += dayCount;
        }
      }

      if (!mounted) return;
      setState(() {
        monthlyCount = total;
      });
    } catch (e) {
      debugPrint("loadMonthlyCount error: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {}
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  String _formatDayCount(double count) {
    return count == count.roundToDouble()
        ? count.toInt().toString()
        : count.toString();
  }

  Color _colorWithOpacity(Color color, double opacity) {
    final a = (opacity * 255).round().clamp(0, 255);
    return Color.fromARGB(a, color.r.round(), color.g.round(), color.b.round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ホーム"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todayText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(
              "今月の出面日数： ${_formatDayCount(monthlyCount)} 日",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),

            // ★ 今日の出面カード（追加）
            if (todayDemen != null)
              Card(
                color: Colors.green.withOpacity(0.15),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(
                        todayDemen!["color"].replaceFirst("#", "0xff"),
                      ),
                    ),
                  ),
                  title: Text(
                    "今日の出面：${todayDemen!["genbaName"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text("登録済み"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              )
            else
              Card(
                color: Colors.orange.withOpacity(0.15),
                child: ListTile(
                  title: const Text(
                    "今日の出面：未入力",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.warning, color: Colors.orange),
                  onTap: () => Navigator.pushNamed(context, "/demen_add"),
                ),
              ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _circleMenu(
                    icon: Icons.list,
                    label: "出面一覧",
                    onTap: () => Navigator.pushNamed(context, "/demen_list"),
                  ),
                  _circleMenu(
                    icon: Icons.add,
                    label: "出面追加",
                    onTap: () => Navigator.pushNamed(context, "/demen_add"),
                  ),

                  _circleMenu(
                    icon: Icons.bar_chart,
                    label: "出面集計",
                    onTap: () => Navigator.pushNamed(context, "/demen_summary"),
                    color: Colors.blueAccent,
                  ),

                  if (isAdmin)
                    _circleMenu(
                      icon: Icons.person,
                      label: "作業員一覧",
                      onTap: () => Navigator.pushNamed(context, "/admin/user_list"),
                    ),

                  if (isAdmin)
                    _circleMenu(
                      icon: Icons.assessment,
                      label: "月次現場集計",
                      onTap: () => Navigator.pushNamed(context, "/genba_summary_month"),
                      color: Colors.deepPurple,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            if (!_loadingRole && isAdmin)
              ExpansionTile(
                title: const Text(
                  "管理者メニュー",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                children: [
                  _adminDashboard(),
                ],
              ),
          ],
        ),
      ),
    );
  }

Widget _circleMenu({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color color = Colors.orange,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () {},
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _colorWithOpacity(color, 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}

  Widget _adminDashboard() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.dashboard, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('管理者ダッシュボード',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 12),
              _adminCardRow(),
              const SizedBox(height: 12),
             
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminCardRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildCard(
            icon: Icons.add_business,
            title: '現場追加',
            subtitle: '新しい現場を登録',
            color: Colors.redAccent,
            onTap: () => Navigator.pushNamed(context, "/admin/genba/add"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            icon: Icons.list_alt,
            title: '現場一覧',
            subtitle: '現場の編集・削除',
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, "/admin/genba/list"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCard(
            icon: Icons.people,
            title: 'ユーザー管理',
            subtitle: 'ユーザー一覧・権限',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, "/admin/user_list"),
          ),
        ),
      ],
    );
  }

  
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _colorWithOpacity(color, 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
