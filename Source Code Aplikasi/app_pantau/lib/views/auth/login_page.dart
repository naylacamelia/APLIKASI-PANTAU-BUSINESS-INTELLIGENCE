import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/dataset_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../main/main_shell_page.dart';
import '../shared/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final auth = Get.find<AuthController>();
  final dataset = Get.find<DatasetController>();
  final dashboard = Get.find<DashboardController>();
  final users = Get.find<UserController>();
  final nav = Get.find<NavigationController>();

  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Login belum lengkap',
        'Masukkan email dan kata sandi terlebih dahulu.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warningSoft,
        colorText: AppColors.warning,
      );
      return;
    }

    final ok = await auth.login(email, password);

    if (!ok) {
      Get.snackbar(
        'Login gagal',
        auth.errorMessage.value ?? 'Email atau password salah.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.dangerSoft,
        colorText: AppColors.danger,
      );
      return;
    }

    nav.reset();
    await dataset.loadDatasets();
    await dashboard.loadDashboard();

    if (auth.currentRole == UserRole.superadmin) {
      await users.loadUsers();
    }

    Get.offAll(() => const MainShellPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.95),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.white.withOpacity(.72),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(.10),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LoginLogo(),
                      const SizedBox(height: 18),
                      Text(
                        'Pantau',
                        textAlign: TextAlign.center,
                        style: AppText.title.copyWith(
                          color: AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk ke akun Anda',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const _InputLabel(label: 'Email'),
                      const SizedBox(height: 8),
                      _AuthTextField(
                        controller: emailController,
                        focusNode: emailFocus,
                        hintText: 'Masukkan email Anda',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 17),
                      const _InputLabel(label: 'Kata Sandi'),
                      const SizedBox(height: 8),
                      _AuthTextField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        hintText: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 21,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Get.snackbar(
                              'Lupa kata sandi',
                              'Fitur reset password dapat dihubungkan ke Supabase Auth.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.infoSoft,
                              colorText: AppColors.info,
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Lupa Kata Sandi?',
                            style: AppText.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Obx(
                        () => _PrimaryLoginButton(
                          isLoading: auth.isLoading.value,
                          onPressed: _login,
                        ),
                      ),
                      Obx(
                        () {
                          final message = auth.errorMessage.value;

                          if (message == null || message.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: ErrorState(message: message),
                          );
                        },
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

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF6F8FC),
                Color(0xFFEAF1FF),
                Color(0xFFEAFBF7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -80,
          child: _BlurBlob(
            size: 230,
            color: AppColors.primary.withOpacity(.18),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -80,
          child: _BlurBlob(
            size: 240,
            color: AppColors.tealMint.withOpacity(.18),
          ),
        ),
        Positioned(
          top: 140,
          left: -65,
          child: _BlurBlob(
            size: 170,
            color: AppColors.success.withOpacity(.10),
          ),
        ),

      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LoginLogo extends StatelessWidget {
  const _LoginLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_pantau.png',
      width: 90,
      height: 90,
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        obscureText: obscureText,
        style: AppText.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppText.body.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 21,
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Masuk',
                      style: AppText.cardTitle.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
