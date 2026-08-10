// lib/pages/genba/genba_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenbaListPage extends StatefulWidget {
  const GenbaListPage({super.key});

  @override
  State<GenbaListPage> createState() => _GenbaListPageState();
}

class _GenbaListPageState extends State<GenbaListPage> {
  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> genbaList = [];

  @override
  void initState() {
    super.initState();
    _loadGenba();
  }

  Future<void> _loadGenba() async {
    setState(() => _loading = true);

    final snap = await FirebaseFirestore.instance
        .collection("genba_master")
        .orderBy("name")
        .get();

    setState(() {
      genbaList = snap.docs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("現場一覧")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: genbaList.length,
              itemBuilder: (context, i) {
                final d = genbaList[i];
                final data = d.data();

                final name = data["name"] ?? "名称不明";
                final colorHex = data["color"] ?? "#999999";
                final isActive = data["isActive"] ?? true;

                final color = Color(
                  int.parse(colorHex.replaceFirst("#", "0xff")),
                );

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: color),
                    title: Text(name),
                    subtitle: Text(isActive ? "稼働中" : "終了"),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        "/admin/genba_month",
                        arguments: d.id,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
