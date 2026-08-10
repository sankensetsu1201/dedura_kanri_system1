import 'package:flutter/material.dart';

class SanKenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SanKenAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
        ),
      ),
      title: Text(title),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
