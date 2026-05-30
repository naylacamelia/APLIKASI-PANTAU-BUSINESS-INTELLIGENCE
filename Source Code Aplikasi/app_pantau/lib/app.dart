import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/app_binding.dart';
import 'core/theme.dart';
import 'views/auth/splash_page.dart';

class PantauUmkmApp extends StatelessWidget {
  const PantauUmkmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pantau',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: AppBinding(),
      home: const SplashPage(),
    );
  }
}
