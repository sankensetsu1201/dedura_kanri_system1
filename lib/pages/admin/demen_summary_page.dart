import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemenSummaryPage extends StatefulWidget {
  const DemenSummaryPage({super.key});

  @override
  State<DemenSummaryPage> createState() => _DemenSummaryPageState();
}

class _DemenSummaryPageState extends State<DemenSummaryPage> {
  String? myWorkerId;
  String? selectedWorkerId;
  bool isAdmin = false;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  bool loading = true;

  // 月次
  double monthlyDays = 0;
  double monthlyOvertime = 0;
  int monthlyExpense = 0;

  Map<String, double> monthlyGenbaDays = {};
  Map<String, List<Map<String, dynamic>>> monthlyGenbaExpenses = {};

  // ★ Firestore に合わせて displayName を使う
  List<Map<String, String>> workers = [];

  // 現場色
  Map<String, String> genbaColors = {};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();

    myWorkerId = userDoc.data()?["workerId"];
    isAdmin = userDoc.data()?["role"] == "admin";

    if (isAdmin) {
      await _loadWorkers();
      selectedWorkerId = myWorkerId;
    } else {
      selectedWorkerId = myWorkerId;
    }

    await _loadGenbaColors();
    await _loadMonthlySummary();

    setState(() {});
  }

  // ---------------------------------------------------
  // 現場色
  // ---------------------------------------------------
  Future<void> _loadGenbaColors() async {
    final snap =
        await FirebaseFirestore.instance.collection("genba_master").get();

    genbaColors = {
      for (final d in snap.docs)
        d.data()["name"]: (d.data()["color"] ?? "#CCCCCC")
    };
  }

  // ---------------------------------------------------
  // 作業員一覧（displayName 対応）
  // ---------------------------------------------------
  Future<void> _loadWorkers() async {
    final snap =
        await FirebaseFirestore.instance.collection("worker_master").get();

    workers = snap.docs.map((d) {
      return {
        "id": d.id as String,
        "name": d["displayName"] as String,   // ★ displayName を使う
      };
    }).toList();

    // ★ 初期値セット（null のまま描画しないように）
    if (workers.isNotEmpty && selectedWorkerId == null) {
      selectedWorkerId = workers.first["id"];
    }
  }

  // ---------------------------------------------------
  // 月次集計
  // ---------------------------------------------------
  Future<void> _loadMonthlySummary() async {
    setState(() => loading = true);

    final start = DateTime(selectedYear, selectedMonth, 1);
    final end = DateTime(selectedYear, selectedMonth + 1, 1);

    final snap = await FirebaseFirestore.instance
        .collection("demen_data")
        .where("workerId", isEqualTo: selectedWorkerId)
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .where("createdAt", isLessThan: end)
        .get();

    double days = 0;
    double overtime = 0;
    int expense = 0;

    Map<String, double> genbaDays = {};
    Map<String, List<Map<String, dynamic>>> genbaExpenses = {};

    for (final doc in snap.docs) {
      final data = doc.data();

      days += (data["dayCount"] ?? 1).toDouble();
      overtime += (data["overtime"] ?? 0).toDouble();

      final genba = data["genbaName"] ?? "不明";
      genbaDays[genba] = (genbaDays[genba] ?? 0) + (data["dayCount"] ?? 1);

      final expenseList = (data["expenses"] ?? []) as List;
      for (final item in expenseList) {
        final amount = (item["amount"] ?? 0) as num;
        expense += amount.toInt();

        genbaExpenses.putIfAbsent(genba, () => []);
        genbaExpenses[genba]!.add({
          "category": item["category"] ?? "",
          "type": item["type"] ?? "",
          "amount": amount.toInt(),
        });
      }
    }

    monthlyDays = days;
    monthlyOvertime = overtime;
    monthlyExpense = expense;
    monthlyGenbaDays = genbaDays;
    monthlyGenbaExpenses = genbaExpenses;

    setState(() => loading = false);
  }

  // ---------------------------------------------------
  // 色変換
  // ---------------------------------------------------
  Color genbaColor(String genbaName) {
    final hex = genbaColors[genbaName];

    if (hex != null && hex.startsWith("#")) {
      try {
        return Color(int.parse(hex.replaceFirst("#", "0xff")))
            .withValues(alpha: 0.25);
      } catch (_) {}
    }

    final hash = genbaName.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);

    return Color.fromARGB(255, r, g, b).withValues(alpha: 0.25);
  }

  // ---------------------------------------------------
  // UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("月次出面集計")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAdmin) _buildWorkerSelector(),

          const SizedBox(height: 20),

          _buildMonthSelector(),
          const SizedBox(height: 20),

          _buildMonthlyCard(),
          const SizedBox(height: 20),

          _buildGenbaDaysCard(),
          const SizedBox(height: 20),

          _buildGenbaExpenseCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // UI 部品
  // ---------------------------------------------------

  Widget _buildWorkerSelector() {
    if (selectedWorkerId == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        const Text("作業員："),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: selectedWorkerId,
          items: workers
              .map((w) => DropdownMenuItem<String>(
                    value: w["id"]!,
                    child: Text(w["name"]!),   // ★ displayName が入る
                  ))
              .toList(),
          onChanged: (v) {
            selectedWorkerId = v;
            _loadMonthlySummary();
          },
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        const Text("年月："),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: selectedYear,
          items: List.generate(5, (i) => DateTime.now().year - 2 + i)
              .map((y) => DropdownMenuItem(value: y, child: Text("$y年")))
              .toList(),
          onChanged: (y) {
            selectedYear = y!;
            _loadMonthlySummary();
          },
        ),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: selectedMonth,
          items: List.generate(12, (i) => i + 1)
              .map((m) => DropdownMenuItem(value: m, child: Text("$m月")))
              .toList(),
          onChanged: (m) {
            selectedMonth = m!;
            _loadMonthlySummary();
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("月次集計", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("出面：${monthlyDays.toStringAsFixed(1)}日"),
            Text("残業：${monthlyOvertime.toStringAsFixed(1)}h"),
            Text("経費：${monthlyExpense}円"),
          ],
        ),
      ),
    );
  }

  Widget _buildGenbaDaysCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("現場別出面日数", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (final e in monthlyGenbaDays.entries)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: genbaColor(e.key),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("${e.key}: ${e.value.toStringAsFixed(1)}日"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenbaExpenseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("現場別経費", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (final e in monthlyGenbaExpenses.entries) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: genbaColor(e.key),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    for (final item in e.value)
                      Text("・${item["category"]} / ${item["type"]}: ${item["amount"]}円"),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
