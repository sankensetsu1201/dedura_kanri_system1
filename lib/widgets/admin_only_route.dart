// lib/widgets/admin_only_route.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminOnlyRoute extends StatelessWidget {
  final Widget child;
  const AdminOnlyRoute({super.key, required this.child});

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final role = doc.data()?["role"] ?? "user";
    return role == "admin";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child; // 管理者だけ通す
        }

        // 一般ユーザーはホームへ強制送還
        return const Scaffold(
          body: Center(
            child: Text(
              "管理者専用ページです",
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}
