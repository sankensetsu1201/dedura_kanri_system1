// lib/pages/demen/demen_add_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemenAddPage extends StatefulWidget {
  const DemenAddPage({super.key});

  @override
  State<DemenAddPage> createState() => _DemenAddPageState();
}

class _DemenAddPageState extends State<DemenAddPage> {
  String? _selectedGenbaId;
  DateTime _selectedDate = DateTime.now();
  double _selectedDayCount = 1.0;
  double _selectedOvertime = 0;
  bool _saving = false;

  final TextEditingController _workController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  Map<String, String> _workerLabels = {}; // workerId -> displayName
  List<MapEntry<String, String>> _genbaList = [];

  /// 新形式 expenses に統一
  final List<Map<String, dynamic>> _expenseItems =
      List.generate(3, (_) => {"category": null, "type": null, "amount": 0.0});

  final List<String> _expenseTypes = [
    "ガソリン代",
    "高速代",
    "道具代",
    "残土代",
    "砕石代",
    "ガラ捨て代"
  ];

  final List<String> _expenseCategories = ["カード", "経費", "立替え"];

  String? _currentUid;
  String? _myWorkerId;
  String? _myName;

  /// 選択されたメンバー（複数）
  final Map<String, String> _selectedMembers = {};

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      // 現場一覧
      final genbaSnap =
          await FirebaseFirestore.instance.collection('genba_master').get();
      _genbaList = genbaSnap.docs.map((d) {
        final data = d.data();
        return MapEntry(d.id, (data['name'] ?? d.id).toString());
      }).toList();

      // 作業員一覧
      final workerSnap =
          await FirebaseFirestore.instance.collection('worker_master').get();
      _workerLabels = {
        for (var d in workerSnap.docs)
          d.id: (d.data()['displayName'] ?? d.id).toString()
      };

      // ログインユーザー情報
      final user = FirebaseAuth.instance.currentUser;
      _currentUid = user?.uid;

      if (_currentUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .get();

        if (userDoc.exists) {
          final u = userDoc.data()!;
          _myWorkerId = u['workerId']?.toString();
        }
      }

      // 自分の名前
      if (_myWorkerId != null && _workerLabels.containsKey(_myWorkerId)) {
        _myName = _workerLabels[_myWorkerId];
      }

      // 自分をメンバーに追加
      if (_myWorkerId != null && _myName != null) {
        _selectedMembers[_myWorkerId!] = _myName!;
      }

      // 現場初期値
      if (_genbaList.isNotEmpty) {
        _selectedGenbaId = _genbaList.first.key;
      }
    } catch (e) {
      debugPrint("loadContext error: $e");
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// メンバー追加ダイアログ
  Future<void> _openMemberSelectDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("メンバーを選択"),
              content: SizedBox(
                width: 400,
                height: 400,
                child: ListView(
                  children: _workerLabels.entries.map((e) {
                    final id = e.key;
                    final name = e.value;
                    final selected = _selectedMembers.containsKey(id);

                    return CheckboxListTile(
                      title: Text(name),
                      value: selected,
                      onChanged: (v) {
                        setStateDialog(() {
                          if (v == true) {
                            _selectedMembers[id] = name;
                          } else {
                            if (id == _myWorkerId) return;
                            _selectedMembers.remove(id);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text("閉じる"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveDemen() async {
    if (_selectedGenbaId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("現場を選択してください")));
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("メンバーを選択してください")));
      return;
    }

    setState(() => _saving = true);

    final dateString =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final membersList = _selectedMembers.entries
        .map((e) => {"workerId": e.key, "name": e.value})
        .toList();

    try {
      await FirebaseFirestore.instance.collection("demen_data").add({
        "genbaId": _selectedGenbaId,
        "members": membersList,
        "date": dateString,
        "work": _workController.text.trim(),
        "dayType": _selectedDayCount,
        "dayCount": _selectedDayCount,
        "overtime": _selectedOvertime,
        "hours": _selectedOvertime,
        "memo": _memoController.text.trim(),

        // ⭐ 新形式 expenses に統一
        "expenses": _expenseItems
            .where((e) =>
                ((e['type'] as String?) != null ||
                    (e['category'] as String?) != null) &&
                (e['amount'] ?? 0) > 0)
            .map((e) => {
                  "category": e['category'],
                  "type": e['type'],
                  "amount": (e['amount'] ?? 0),
                })
            .toList(),

        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": _currentUid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("出面を追加しました")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("save error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("保存に失敗しました")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget memberList(Map<String, String> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: members.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text("・${e.value}", style: const TextStyle(fontSize: 15)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("出面追加")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          sectionTitle("現場"),
          DropdownButtonFormField<String>(
            value: _selectedGenbaId,
            items: _genbaList
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGenbaId = v),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              sectionTitle("メンバー（複数選択）"),
              const Spacer(),
              ElevatedButton(
                  onPressed: _openMemberSelectDialog,
                  child: const Text("メンバー追加")),
            ],
          ),
          memberList(_selectedMembers),

          const SizedBox(height: 16),

          sectionTitle("作業内容"),
          TextField(
            controller: _workController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), hintText: "作業内容を入力"),
          ),

          const SizedBox(height: 16),

          sectionTitle("日付"),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.calendar_today),
            label: Text(dateString(_selectedDate)),
            onPressed: _pickDate,
          ),

          const SizedBox(height: 16),

          sectionTitle("出面区分"),
          DropdownButtonFormField<double>(
            value: _selectedDayCount,
            items: const [
              DropdownMenuItem(value: 1.0, child: Text('1')),
              DropdownMenuItem(value: 0.5, child: Text('0.5')),
            ],
            onChanged: (v) => setState(() => _selectedDayCount = v ?? 1.0),
          ),

          const SizedBox(height: 16),

          sectionTitle("残業時間"),
          DropdownButtonFormField<double>(
            value: _selectedOvertime,
            items: List.generate(21, (i) => i * 0.5)
                .map((v) => DropdownMenuItem(value: v, child: Text("$v 時間")))
                .toList(),
            onChanged: (v) => setState(() => _selectedOvertime = v ?? 0),
          ),

          const SizedBox(height: 16),

          sectionTitle("経費（項目別）"),
          Column(
            children: List.generate(_expenseItems.length, (i) {
              final item = _expenseItems[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: item['category'],
                        hint: const Text('区分'),
                        items: _expenseCategories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => item['category'] = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: item['type'],
                        hint: const Text('項目'),
                        items: _expenseTypes
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => item['type'] = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '金額',
                        ),
                        onChanged: (v) =>
                            item['amount'] = double.tryParse(v) ?? 0.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _expenseItems.removeAt(i);
                          if (_expenseItems.isEmpty) {
                            _expenseItems.add(
                                {"category": null, "type": null, "amount": 0.0});
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ),

          Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('経費行を追加'),
                onPressed: () {
                  setState(() => _expenseItems
                      .add({"category": null, "type": null, "amount": 0.0}));
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          sectionTitle("メモ"),
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
              hintText: "メモ（任意）",
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text("保存する"),
              onPressed: _saving ? null : _saveDemen,
            ),
          ),
        ]),
      ),
    );
  }

  String dateString(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }
}
