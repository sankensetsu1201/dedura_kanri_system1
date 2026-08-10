// lib/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _workerIdController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  bool _loading = false;

  // ---------------------------------------------------------
  // メールログイン
  // ---------------------------------------------------------
  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack("メールとパスワードを入力してください");
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!doc.exists) {
        _showSnack("ユーザー情報が見つかりません");
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack("ログインエラー: ${e.message}");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------
  // IDログイン（スマホ）
  // ---------------------------------------------------------
  Future<void> _loginWithWorkerId() async {
    final workerId = _workerIdController.text.trim();

    if (workerId.isEmpty) {
      _showSnack("作業員IDを入力してください");
      return;
    }

    setState(() => _loading = true);

    try {
      final q = await FirebaseFirestore.instance
          .collection("users")
          .where("workerId", isEqualTo: workerId)
          .limit(1)
          .get();

      if (q.docs.isEmpty) {
        _showSnack("作業員IDが見つかりません");
        return;
      }

      await FirebaseAuth.instance.signInAnonymously();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showSnack("IDログインエラー: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------
  // 顔認証ログイン
  // ---------------------------------------------------------
  Future<void> _loginWithFaceId() async {
    try {
      final isAvailable = await auth.canCheckBiometrics;
      if (!isAvailable) {
        _showSnack("顔認証が利用できません");
        return;
      }

      final didAuth = await auth.authenticate(
        localizedReason: "顔認証でログインします",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuth) {
        _showSnack("顔認証に失敗しました");
        return;
      }

      const detectedWorkerId = "001";
      _workerIdController.text = detectedWorkerId;

      await _loginWithWorkerId();
    } catch (e) {
      _showSnack("顔認証エラー: $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ★ ロゴ（必ず assets に入れる）
              Image.asset(
                "assets/logo.png",
                width: 120,
              ),
              const SizedBox(height: 20),

              const Text(
                "出面管理システム",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // ---------------------------------------------------------
              // メールログインカード
              // ---------------------------------------------------------
              _loginCard(
                title: "メールログイン",
                child: Column(
                  children: [
                    _inputField(
                      controller: _emailController,
                      label: "メールアドレス",
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: _passwordController,
                      label: "パスワード",
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
                    _roundedButton(
                      text: "メールでログイン",
                      onTap: _loading ? null : _loginWithEmail,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ---------------------------------------------------------
              // IDログインカード
              // ---------------------------------------------------------
              _loginCard(
                title: "作業員IDログイン",
                child: Column(
                  children: [
                    _inputField(
                      controller: _workerIdController,
                      label: "作業員ID（3桁）",
                    ),
                    const SizedBox(height: 24),
                    _roundedButton(
                      text: "IDでログイン",
                      onTap: _loading ? null : _loginWithWorkerId,
                    ),
                    const SizedBox(height: 16),
                    _roundedButton(
                      text: "顔認証でログイン",
                      onTap: _loading ? null : _loginWithFaceId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 共通UI部品
  // ---------------------------------------------------------
  Widget _loginCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12), // ← 改善ポイント
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.orange), // ← 改善ポイント
        ),
      ),
    );
  }

  Widget _roundedButton({
    required String text,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.orange, // ← 改善ポイント
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
