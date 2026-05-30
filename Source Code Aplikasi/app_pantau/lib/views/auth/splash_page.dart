import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: 900),
      () => Get.off(() => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_pantau.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 26),
            Text(
              'Pantau',
              style: AppText.title.copyWith(color: Colors.white, fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'Dashboard BI untuk Retail',
              style: AppText.subtitle.copyWith(
                color: Colors.white.withOpacity(.84),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}