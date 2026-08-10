import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemenInputPage extends StatefulWidget {
  const DemenInputPage({super.key});

  @override
  State<DemenInputPage> createState() => _DemenInputPageState();
}

class _DemenInputPageState extends State<DemenInputPage> {
  String? selectedGenbaId;
  String? selectedGenbaName;
  String? selectedGenbaColor;

  final TextEditingController _workController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> genbaList = [];

  @override
  void initState() {
    super.initState();
    _loadGenbaList();
    _loadLastGenba();
  }

  Future<void> _loadGenbaList() async {
    final snap = await FirebaseFirestore.instance
        .collection("genba_master")
        .where("isActive", isEqualTo: true)
        .orderBy("name")
        .get();

    genbaList = snap.docs;
    setState(() => _loading = false);
  }

  Future<void> _loadLastGenba() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final lastGenba = userDoc.data()?["lastGenba"];
    if (lastGenba != null) {
      setState(() {
        selectedGenbaId = lastGenba;
      });
    }
  }

  Future<void> _saveDemen() async {
    if (selectedGenbaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現場を選択してください")),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = DateTime.now();
    final todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final genbaData = genbaList.firstWhere((d) => d.id == selectedGenbaId).data();

    await FirebaseFirestore.instance
        .collection("demen")
        .doc(uid)
        .collection("days")
        .doc(todayKey)
        .set({
      "genbaId": selectedGenbaId,
      "genbaName": genbaData["name"],
      "color": genbaData["color"],
      "work": _workController.text.trim(),
      "memo": _memoController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    // ★ 前回の現場を保存
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({"lastGenba": selectedGenbaId});

    // ★ 完了カード
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("出面を登録しました"),
        content: Text("現場：${genbaData["name"]}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("出面入力")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ★ 現場選択（カラーカード）
            Expanded(
              child: ListView.builder(
                itemCount: genbaList.length,
                itemBuilder: (context, i) {
                  final d = genbaList[i];
                  final data = d.data();
                  final color = Color(
                    int.parse(data["color"].replaceFirst("#", "0xff")),
                  );

                  final selected = selectedGenbaId == d.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedGenbaId = d.id;
                        selectedGenbaName = data["name"];
                        selectedGenbaColor = data["color"];
                      });
                    },
                    child: Card(
                      color: selected ? color.withOpacity(0.2) : null,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color),
                        title: Text(
                          data["name"],
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _workController,
              decoration: const InputDecoration(
                labelText: "作業内容",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: "備考（任意）",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveDemen,
                child: const Text("保存する"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
