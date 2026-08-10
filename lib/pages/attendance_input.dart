import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demen_app/widgets/san_ken_appbar.dart';
import 'package:demen_app/widgets/san_ken_header.dart';

class AttendanceInputPage extends StatefulWidget {
  const AttendanceInputPage({super.key});

  @override
  State<AttendanceInputPage> createState() => _AttendanceInputPageState();
}

class _AttendanceInputPageState extends State<AttendanceInputPage> {
  String? selectedWorker;
  String? selectedSite;
  DateTime selectedDate = DateTime.now();
  double workHours = 8.0;

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const SanKenAppBar(title: "出面入力"),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SanKenHeader(),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "作業員",
              border: OutlineInputBorder(),
            ),
            initialValue: selectedWorker,
            items: const [
              DropdownMenuItem(value: "佐藤太郎", child: Text("佐藤太郎")),
              DropdownMenuItem(value: "田中一郎", child: Text("田中一郎")),
              DropdownMenuItem(value: "山本健", child: Text("山本健")),
            ],
            onChanged: (v) => setState(() => selectedWorker = v),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "現場",
              border: OutlineInputBorder(),
            ),
            initialValue: selectedSite,
            items: const [
              DropdownMenuItem(value: "A工事", child: Text("A工事")),
              DropdownMenuItem(value: "B工事", child: Text("B工事")),
              DropdownMenuItem(value: "C工事", child: Text("C工事")),
            ],
            onChanged: (v) => setState(() => selectedSite = v),
          ),

          const SizedBox(height: 20),

          ListTile(
            title: Text(
              "日付：${selectedDate.year}/${selectedDate.month}/${selectedDate.day}",
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),

          const SizedBox(height: 20),

          Text("作業時間：${workHours.toStringAsFixed(1)} 時間"),
          Slider(
            value: workHours,
            min: 0,
            max: 12,
            divisions: 24,
            label: "${workHours.toStringAsFixed(1)} 時間",
            activeColor: color.primary,
            onChanged: (v) => setState(() => workHours = v),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving ? null : _saveAttendance,
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "登録する",
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> _saveAttendance() async {
    if (selectedWorker == null || selectedSite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("作業員と現場を選択してください")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance.collection("attendance").add({
        "worker": selectedWorker,
        "site": selectedSite,
        "date": "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
        "hours": workHours,
        "createdAt": DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Firestore に保存しました")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("保存エラー: $e")),
      );
    }

    setState(() => isSaving = false);
  }
}
