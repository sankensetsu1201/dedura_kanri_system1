// lib/pages/genba/genba_edit_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenbaEditPage extends StatefulWidget {
  final String genbaId;

  const GenbaEditPage({super.key, required this.genbaId});

  @override
  State<GenbaEditPage> createState() => _GenbaEditPageState();
}

class _GenbaEditPageState extends State<GenbaEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = true;
  bool _saving = false;

  Color _selectedColor = Colors.blue;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadGenba();
  }

  Future<void> _loadGenba() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("genba_master")
          .doc(widget.genbaId)
          .get();

      final data = doc.data();
      if (data == null) return;

      _nameController.text = data["name"] ?? "";
      _addressController.text = data["address"] ?? "";
      _isActive = data["isActive"] ?? true;

      // カラー読み込み
      final colorHex = data["color"] ?? "#0000FF";
      _selectedColor = Color(
        int.parse(colorHex.replaceFirst("#", "0xff")),
      );
    } catch (e) {
      debugPrint("load genba error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGenba() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現場名を入力してください")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection("genba_master")
          .doc(widget.genbaId)
          .update({
        "name": name,
        "address": address.isEmpty ? null : address,
        "color":
            "#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0')}",
        "isActive": _isActive,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現場を更新しました")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("save genba error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("更新に失敗しました: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("カラー選択"),
        content: Wrap(
          spacing: 12,
          children: [
            Colors.red,
            Colors.green,
            Colors.blue,
            Colors.orange,
            Colors.purple,
            Colors.teal,
          ].map((col) {
            return GestureDetector(
              onTap: () => Navigator.pop(c, col),
              child: CircleAvatar(backgroundColor: col),
            );
          }).toList(),
        ),
      ),
    );

    if (color != null) {
      setState(() => _selectedColor = color);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("現場編集")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "現場名",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "住所（任意）",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // カラー選択
                Row(
                  children: [
                    const Text("カラー：", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _selectColor,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: _selectedColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 稼働中 / 終了
                SwitchListTile(
                  title: const Text("稼働中"),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? '保存中...' : '保存する'),
                    onPressed: _saving ? null : _saveGenba,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
