// lib/pages/admin/genba_manage_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../genba/genba_edit_page.dart';

class GenbaManagePage extends StatelessWidget {
  const GenbaManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("現場管理")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("genba_master")
            .orderBy("name")
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final active = data["isActive"] ?? true;

              final colorHex = data["color"] ?? "#CCCCCC";
              final color = Color(
                int.parse(colorHex.replaceFirst("#", "0xff")),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: color),
                  title: Text(
                    data["name"],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Text(active ? "稼働中" : "終了済み"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 編集ボタン
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: "編集",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GenbaEditPage(genbaId: d.id),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 4),

                      // 終了 or 再開ボタン
                      if (active)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection("genba_master")
                                .doc(d.id)
                                .update({"isActive": false});
                          },
                          child: const Text("終了"),
                        )
                      else
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection("genba_master")
                                .doc(d.id)
                                .update({"isActive": true});
                          },
                          child: const Text("再開"),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
