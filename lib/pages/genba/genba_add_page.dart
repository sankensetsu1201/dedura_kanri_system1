// lib/pages/genba/genba_add_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenbaAddPage extends StatefulWidget {
  const GenbaAddPage({super.key});

  @override
  State<GenbaAddPage> createState() => _GenbaAddPageState();
}

class _GenbaAddPageState extends State<GenbaAddPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  // ★ 現場カラー（デフォルトは青）
  Color _selectedColor = Colors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _addGenba() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現場名を入力してください")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('genba_master').add({
        'name': name,
        'address': address.isEmpty ? null : address,
        'color': "#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0')}", // ★ 新仕様
        'isActive': true, // ★ 新規現場は必ず稼働中
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("現場を作成しました")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("作成に失敗しました: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              onTap: () => Navigator.pop(c, col), // ★ 修正済み
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
    return Scaffold(
      appBar: AppBar(title: const Text("現場追加")),
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

                // ★ カラー選択
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

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? '追加中...' : '追加する'),
                    onPressed: _isLoading ? null : _addGenba,
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
