import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  String? workerId;
  String? workerName;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    final prefs = await SharedPreferences.getInstance();
    workerId = prefs.getString("workerId");

    if (workerId == null) return;

    // Firestoreから名前を取得
    final doc = await FirebaseFirestore.instance
        .collection("workers")
        .doc(workerId)
        .get();

    if (doc.exists) {
      workerName = doc.data()!["name"];
    }

    setState(() {});
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("workerId");

    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("作業員ホーム"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "ようこそ、${workerName ?? "読み込み中"} さん",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 出面入力
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit, size: 32),
                title: const Text("出面を入力する", style: TextStyle(fontSize: 20)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, "/demen_input"),
              ),
            ),
            const SizedBox(height: 12),

            // 今日の出面一覧
            Card(
              child: ListTile(
                leading: const Icon(Icons.today, size: 32),
                title: const Text("今日の出面を見る", style: TextStyle(fontSize: 20)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, "/demen_today"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
