import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart'; // 起動後に遷移するページ

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // アニメーション設定（2秒でフェードイン）
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3
    ),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // 表示後にメイン画面へ遷移
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E), // 濃グレー背景
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/images/splash.png', // 起動画面画像
            width: 300,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
