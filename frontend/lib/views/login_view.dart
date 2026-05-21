import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../controllers/auth_controller.dart';
import 'register_view.dart';
import 'dashboard_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();

  String _emailError = '';
  String _passwordError = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = '';
      _passwordError = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;
    if (email.isEmpty) {
      _emailError = 'Please enter your email';
      hasError = true;
    } else if (!GetUtils.isEmail(email)) {
      _emailError = 'Please enter a valid email';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }
    
    FocusScope.of(context).unfocus();
    final success = await _authController.login(email, password);
    if (success) {
      Get.offAll(() => const DashboardView(), transition: Transition.fadeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgColorPage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.bgColorContainer,
              borderRadius: BorderRadius.circular(theme.radiusMap['medium'] ?? 8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.brandNormalColor,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Asset Master',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.textColorPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Edge-native wealth management',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: theme.textColorPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter details to sync your edge portfolio',
                    style: TextStyle(
                      color: theme.textColorPlaceholder,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Input
                  TDInput(
                    controller: _emailController,
                    inputType: TextInputType.emailAddress,
                    leftIcon: Icon(Icons.email_outlined, color: theme.textColorSecondary, size: 16),
                    hintText: 'Email Address',
                    additionInfo: _emailError.isNotEmpty ? _emailError : '',
                    additionInfoColor: theme.errorNormalColor,
                    showBottomDivider: true,
                    backgroundColor: Colors.transparent,
                    textStyle: TextStyle(color: theme.textColorPrimary, fontSize: 12),
                    hintTextStyle: TextStyle(color: theme.textColorPlaceholder, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Password Input
                  TDInput(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    leftIcon: Icon(Icons.lock_outlined, color: theme.textColorSecondary, size: 16),
                    hintText: 'Password',
                    additionInfo: _passwordError.isNotEmpty ? _passwordError : '',
                    additionInfoColor: theme.errorNormalColor,
                    showBottomDivider: true,
                    backgroundColor: Colors.transparent,
                    textStyle: TextStyle(color: theme.textColorPrimary, fontSize: 12),
                    hintTextStyle: TextStyle(color: theme.textColorPlaceholder, fontSize: 12),
                    needClear: false,
                    rightWidget: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: theme.textColorSecondary,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // API Error Message
                  Obx(() {
                    final err = _authController.errorMessage.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.errorColor1,
                          borderRadius: BorderRadius.circular(theme.radiusMap['default'] ?? 6),
                          border: Border.all(color: theme.errorColor3),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, color: theme.errorNormalColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                err,
                                style: TextStyle(color: theme.errorNormalColor, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Submit Button
                  Obx(() {
                    final loading = _authController.isLoading.value;
                    return TDButton(
                      onTap: loading ? null : _handleLogin,
                      size: TDButtonSize.medium,
                      type: TDButtonType.fill,
                      theme: TDButtonTheme.primary,
                      isBlock: true,
                      text: 'Sign In',
                      iconWidget: loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                    );
                  }),
                  const SizedBox(height: 16),

                  // Redirect to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: theme.textColorSecondary, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => const RegisterView(), transition: Transition.rightToLeft);
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.brandNormalColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
