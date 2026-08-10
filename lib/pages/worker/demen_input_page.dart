import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemenInputPage extends StatefulWidget {
  final String? workerId;
  const DemenInputPage({Key? key, this.workerId}) : super(key: key);

  @override
  State<DemenInputPage> createState() => _DemenInputPageState();
}

class _DemenInputPageState extends State<DemenInputPage> {
  String? workerId;
  String? workerName;

  String? selectedGenbaId;
  Map<String, String> genbaNames = {};

  final _workController = TextEditingController();
  final _hoursController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGenbaMaster();

    // 今日の日付を初期セット
    final now = DateTime.now();
    final today = "${now.year}-${_two(now.month)}-${_two(now.day)}";
    _dateController.text = today;

    // widget.workerId が渡されていればそれを優先、なければ SharedPreferences から読み込む
    if (widget.workerId != null && widget.workerId!.isNotEmpty) {
      workerId = widget.workerId;
      _loadWorkerNameFromFirestore(workerId!);
    } else {
      _loadWorker();
    }
  }

  String _two(int n) => n.toString().padLeft(2, "0");

  Future<void> _loadWorker() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString("workerId");
    if (id == null) return;

    workerId = id;
    final doc = await FirebaseFirestore.instance.collection("workers").doc(workerId).get();
    if (doc.exists) {
      workerName = (doc.data()?["name"] ?? '').toString();
    }
    setState(() {});
  }

  Future<void> _loadWorkerNameFromFirestore(String id) async {
    final doc = await FirebaseFirestore.instance.collection("workers").doc(id).get();
    if (doc.exists) {
      workerName = (doc.data()?["name"] ?? '').toString();
    }
    setState(() {});
  }

  Future<void> _loadGenbaMaster() async {
    final snapshot = await FirebaseFirestore.instance.collection("genba_master").get();
    genbaNames = { for (var doc in snapshot.docs) doc.id: (doc.data()["name"] ?? '').toString() };
    setState(() {});
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      _dateController.text = "${picked.year}-${_two(picked.month)}-${_two(picked.day)}";
    }
  }

  Future<void> _saveDemen() async {
    // バリデーション
    if (workerId == null || workerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ログイン情報がありません")),
      );
      return;
    }

    if (selectedGenbaId == null ||
        _workController.text.trim().isEmpty ||
        _hoursController.text.trim().isEmpty ||
        _dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("すべての項目を入力してください")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("demen").add({
      "workerId": workerId,
      "name": workerName,
      "genbaId": selectedGenbaId,
      "genbaName": genbaNames[selectedGenbaId],
      "date": _dateController.text.trim(),
      "work": _workController.text.trim(),
      "hours": int.tryParse(_hoursController.text.trim()) ?? 0,
      "createdAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("出面を登録しました")),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _workController.dispose();
    _hoursController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = workerId != null && workerId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "出面編集" : "出面入力")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "作業員: ${workerName ?? "読み込み中"}",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),

            // 日付（手動変更可能）
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "日付（変更可能）",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // 現場選択
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "現場を選択",
                border: OutlineInputBorder(),
              ),
              initialValue: selectedGenbaId,
              items: genbaNames.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedGenbaId = v),
            ),
            const SizedBox(height: 16),

            // 作業内容
            TextField(
              controller: _workController,
              decoration: const InputDecoration(
                labelText: "作業内容",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 作業時間
            TextField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: "作業時間（h）",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // 登録ボタン
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveDemen,
                child: const Text(
                  "登録する",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
