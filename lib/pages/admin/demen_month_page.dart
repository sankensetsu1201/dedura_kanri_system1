import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemenMonthPage extends StatefulWidget {
  const DemenMonthPage({super.key});

  @override
  State<DemenMonthPage> createState() => _DemenMonthPageState();
}

class _DemenMonthPageState extends State<DemenMonthPage> {
  String selectedMonth = "";
  Map<String, String> genbaNames = {};

  @override
  void initState() {
    super.initState();
    _loadGenbaMaster();
  }

  Future<void> _loadGenbaMaster() async {
    final snap =
        await FirebaseFirestore.instance.collection("genba_master").get();

    genbaNames = {
      for (var doc in snap.docs) doc.id: doc["name"],
    };

    setState(() {});
  }

  Future<Map<String, dynamic>> _loadMonthData() async {
    if (selectedMonth.isEmpty) return {};

    final snap = await FirebaseFirestore.instance.collection("demen").get();

    final data = <String, Map<String, Map<String, dynamic>>>{};

    for (var doc in snap.docs) {
      final d = doc.data();

      if (d["date"] == null) continue;
      if (!d["date"].startsWith(selectedMonth)) continue;

      final genbaId = d["genbaId"];
      final workerId = d["workerId"];
      final name = d["name"];
      final days = (d["days"] ?? 1.0).toDouble();      // ← 入力した日数
      final overtime = (d["overtime"] ?? 0.0).toDouble(); // ← 入力した残業

      data.putIfAbsent(genbaId, () => {});
      data[genbaId]!.putIfAbsent(workerId, () {
        return {
          "name": name,
          "days": 0.0,
          "overtime": 0.0,
        };
      });

      // 日数加算（複数件でも合計される）
      data[genbaId]![workerId]!["days"] += days;

      // 残業加算
      data[genbaId]![workerId]!["overtime"] += overtime;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("月次集計")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "月を入力（例：2024-07）",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => selectedMonth = v.trim()),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: FutureBuilder(
                future: _loadMonthData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: Text("月を入力してください"));
                  }

                  final data = snapshot.data as Map<String, dynamic>;
                  if (data.isEmpty) {
                    return const Center(child: Text("該当データがありません"));
                  }

                  return ListView(
                    children: data.entries.map((genbaEntry) {
                      final genbaId = genbaEntry.key;
                      final workers = genbaEntry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                genbaNames[genbaId] ?? "不明な現場",
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),

                              ...workers.entries.map((w) {
                                final info = w.value;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    "${info['name']}： 日数 ${info['days']}日 / 残業 ${info['overtime']}h",
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
