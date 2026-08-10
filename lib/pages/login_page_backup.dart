// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // ID + 生体認証
  final TextEditingController _idController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Email/Password
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwCtrl = TextEditingController();

  // UI / 状態
  late final TabController _tabController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _idController.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------
  // 生体認証ヘルパー
  // ---------------------------
  Future<bool> _checkBiometrics() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'ログインのために認証してください',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      // 生体認証が利用できない／例外時は false を返す
      return false;
    }
  }

  // ---------------------------
  // ID + 生体認証ログイン
  // ---------------------------
  Future<void> _loginWithId() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("IDを入力してください")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await _checkBiometrics();
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("認証に失敗しました")),
        );
        return;
      }

      // 生体認証成功 → ID を使ってアプリ内の認証フローへ進める
      // ここでは簡易にホームへ遷移する（実運用ではサーバ照合や Firestore 確認を行う）
      Navigator.pushReplacementNamed(context, "/home");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------
  // Email/Password ログイン
  // ---------------------------
  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _pwCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("メールアドレスとパスワードを入力してください")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // ログイン成功
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // よくあるエラーコードに対するメッセージ
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'ユーザーが見つかりません';
          break;
        case 'wrong-password':
          msg = 'パスワードが違います';
          break;
        case 'invalid-email':
          msg = 'メールアドレスの形式が不正です';
          break;
        case 'user-disabled':
          msg = 'このアカウントは無効化されています';
          break;
        default:
          msg = 'ログインに失敗しました: ${e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('エラー: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------
  // パスワードリセット
  // ---------------------------
  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("リセットするメールアドレスを入力してください")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードリセットメールを送信しました')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('送信失敗: ${e.code}')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('送信失敗: $e')));
    }
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '作業員ID'),
            Tab(text: 'メールでログイン'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---------------------------
          // タブ1: 作業員ID + 生体認証
          // ---------------------------
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "作業員ログイン",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: "作業員ID（名前＋誕生日4桁）",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _loginWithId,
                          child: _loading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('ログイン（生体認証）'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          // IDのみでログインするオプションが必要ならここに実装
                          // 例: ID を照合してログインさせる（現在は生体認証必須）
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('生体認証でのログインを推奨します')),
                          );
                        },
                        child: const Text('IDのみでログイン'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------------------------
          // タブ2: Email / Password
          // ---------------------------
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "メールでログイン",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "メールアドレス",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "パスワード",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _signInWithEmail,
                          child: _loading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('ログイン'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _sendResetEmail,
                            child: const Text('パスワードを忘れた場合'),
                          ),
                          TextButton(
                            onPressed: () {
                              // 新規登録ページがあれば遷移させる
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text('新規登録'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
