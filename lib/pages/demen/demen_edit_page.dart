// lib/pages/demen/demen_edit_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemenEditPage extends StatefulWidget {
  final String docId;
  const DemenEditPage({super.key, required this.docId});

  @override
  State<DemenEditPage> createState() => _DemenEditPageState();
}

class _DemenEditPageState extends State<DemenEditPage> {
  bool _loading = true;
  bool _saving = false;

  String? _currentUid;
  bool _isAdmin = false;
  bool _canEdit = false;

  String? _selectedGenbaId;
  DateTime _selectedDate = DateTime.now();
  double _selectedDayCount = 1.0;
  double _selectedOvertime = 0;

  final TextEditingController _workController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  Map<String, String> _workerLabels = {}; // workerId -> displayName
  List<MapEntry<String, String>> _genbaList = [];

  final List<Map<String, dynamic>> _expenseItems = [];
  final List<String> _expenseTypes = ["ガソリン代", "高速代", "道具代", "残土代", "再生CR"];
  final List<String> _expenseCategories = ["カード", "経費", "立替え"];

  final Map<String, String> _selectedMembers = {};
  String? _creatorWorkerId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _currentUid = user?.uid;

      // 管理者判定
      if (_currentUid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
        if (userDoc.exists) {
          final u = userDoc.data()!;
          _isAdmin = (u['role'] == 'admin');
        }
      }

      // 出面データ取得
      final doc = await FirebaseFirestore.instance
          .collection('demen_data')
          .doc(widget.docId)
          .get();

      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = doc.data()!;

      // 編集権限
      final createdBy = data['createdBy']?.toString();
      _canEdit = _isAdmin || (createdBy == _currentUid);

      // 現場一覧
      final genbaSnap =
          await FirebaseFirestore.instance.collection('genba_master').get();
      _genbaList = genbaSnap.docs.map((d) {
        final dd = d.data();
        return MapEntry(d.id, (dd['name'] ?? d.id).toString());
      }).toList();

      // 作業員一覧
      final workerSnap =
          await FirebaseFirestore.instance.collection('worker_master').get();
      _workerLabels = {
        for (var d in workerSnap.docs)
          d.id: (d.data()['displayName'] ?? d.id).toString()
      };

      // メンバー
      final members = (data['members'] ?? []) as List;
      for (final m in members) {
        _selectedMembers[m['workerId']] = m['name'];
      }

      _creatorWorkerId = members.isNotEmpty ? members.first['workerId'] : null;

      // 現場
      _selectedGenbaId = data['genbaId'];

      // 日付
      final dateStr = data['date']?.toString();
      if (dateStr != null) {
        final parts = dateStr.split("-");
        _selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }

      // 作業内容
      _workController.text = data['work']?.toString() ?? "";

      // 出面区分
      final dayCountValue = data['dayCount'] ?? data['dayType'] ?? 1.0;
      _selectedDayCount = (dayCountValue is num)
          ? dayCountValue.toDouble()
          : double.tryParse(dayCountValue.toString()) ?? 1.0;

      // 残業
      _selectedOvertime = (data['overtime'] ?? 0).toDouble();

      // 経費
      _expenseItems.clear();
      final items = data['expenses'];
      if (items is List) {
        for (final it in items) {
          _expenseItems.add({
            "category": it['category']?.toString(),
            "type": it['type']?.toString(),
            "amount": (it['amount'] is num
                ? (it['amount'] as num).toDouble()
                : double.tryParse(it['amount']?.toString() ?? '') ?? 0.0),
          });
        }
      }

      if (_expenseItems.isEmpty) {
        _expenseItems.addAll(
          List.generate(3, (_) => {"category": null, "type": null, "amount": 0.0}),
        );
      }

      // メモ
      _memoController.text = data['memo']?.toString() ?? "";
    } catch (e) {
      debugPrint("edit load error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ⭐ 日付選択ダイアログ（未定義エラー修正）
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ⭐ メンバー選択ダイアログ（未定義エラー修正）
  Future<void> _openMemberSelectDialog() async {
    final tempSelected = Map<String, String>.from(_selectedMembers);

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text("メンバーを選択"),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView(
              children: _workerLabels.entries.map((e) {
                final id = e.key;
                final name = e.value;
                final selected = tempSelected.containsKey(id);

                return CheckboxListTile(
                  title: Text(name),
                  value: selected,
                  onChanged: (v) {
                    if (v == true) {
                      tempSelected[id] = name;
                    } else {
                      if (id == _creatorWorkerId) return;
                      tempSelected.remove(id);
                    }
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("決定")),
          ],
        );
      },
    );

    if (ok == true) {
      setState(() {
        _selectedMembers
          ..clear()
          ..addAll(tempSelected);
      });
    }
  }

  Future<void> _delete() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("削除権限がありません")));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text("削除確認"),
          content: const Text("本当に削除しますか？\nこの操作は取り消せません。"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("削除する")),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("削除しました")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("delete error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("削除に失敗しました")));
    }
  }

  Future<void> _save() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("編集権限がありません")));
      return;
    }

    if (_selectedGenbaId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("現場を選択してください")));
      return;
    }

    setState(() => _saving = true);

    final dateString =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final membersList = _selectedMembers.entries
        .map((e) => {"workerId": e.key, "name": e.value})
        .toList();

    try {
      await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .update({
        "genbaId": _selectedGenbaId,
        "members": membersList,
        "date": dateString,
        "work": _workController.text.trim(),
        "dayType": _selectedDayCount,
        "dayCount": _selectedDayCount,
        "overtime": _selectedOvertime,
        "hours": _selectedOvertime,
        "memo": _memoController.text.trim(),
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("更新しました")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("save error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("更新に失敗しました")));
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
      appBar: AppBar(
        title: const Text("出面編集"),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saving ? null : _save,
            ),
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("現場"),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGenbaId,
                    items: _genbaList
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: _canEdit ? (v) => setState(() => _selectedGenbaId = v) : null,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      sectionTitle("メンバー（複数選択）"),
                      const Spacer(),
                      if (_canEdit)
                        ElevatedButton(
                          onPressed: _openMemberSelectDialog,
                          child: const Text("メンバー追加"),
                        ),
                    ],
                  ),
                  memberList(_selectedMembers),

                  const SizedBox(height: 16),

                  sectionTitle("作業内容"),
                  TextField(
                    controller: _workController,
                    enabled: _canEdit,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 16),

                  sectionTitle("日付"),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateString(_selectedDate)),
                    onPressed: _canEdit ? _pickDate : null,
                  ),

                  const SizedBox(height: 16),

                  sectionTitle("出面区分"),
                  DropdownButtonFormField<double>(
                    initialValue: _selectedDayCount,
                    items: const [
                      DropdownMenuItem(value: 1.0, child: Text('1')),
                      DropdownMenuItem(value: 0.5, child: Text('0.5')),
                    ],
                    onChanged: _canEdit ? (v) => setState(() => _selectedDayCount = v ?? 1.0) : null,
                  ),

                  const SizedBox(height: 16),

                  sectionTitle("残業時間"),
                  DropdownButtonFormField<double>(
                    initialValue: _selectedOvertime,
                    items: List.generate(21, (i) => i * 0.5)
                        .map((v) => DropdownMenuItem(value: v, child: Text("$v 時間")))
                        .toList(),
                    onChanged: _canEdit ? (v) => setState(() => _selectedOvertime = v ?? 0) : null,
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
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: item['category'],
                                      hint: const Text('区分'),
                                      items: _expenseCategories
                                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: _canEdit ? (v) => setState(() => item['category'] = v) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: item['type'],
                                      hint: const Text('項目'),
                                      items: _expenseTypes
                                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                          .toList(),
                                      onChanged: _canEdit ? (v) => setState(() => item['type'] = v) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: TextEditingController(
                                          text: (item['amount'] ?? 0).toString()),
                                      enabled: _canEdit,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: '金額',
                                      ),
                                      onChanged: _canEdit
                                          ? (v) => item['amount'] = double.tryParse(v) ?? 0.0
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_canEdit)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _expenseItems.removeAt(i);
                                          if (_expenseItems.isEmpty) {
                                            _expenseItems.add({"category": null, "type": null, "amount": 0.0});
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  if (_canEdit)
                    Row(
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('経費行を追加'),
                          onPressed: () {
                            setState(() => _expenseItems.add({"category": null, "type": null, "amount": 0.0}));
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  sectionTitle("メモ"),
                  TextField(
                    controller: _memoController,
                    enabled: _canEdit,
                    maxLines: 2,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 24),

                                    if (_canEdit)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text("更新する"),
                        onPressed: _saving ? null : _save,
                      ),
                    ),

                  const SizedBox(height: 12),

                  if (_canEdit)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("削除する"),
                        onPressed: _delete,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String dateString(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }
}
