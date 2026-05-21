import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../controllers/auth_controller.dart';
import 'dashboard_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = Get.find<AuthController>();

  String _nameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _nameError = '';
      _emailError = '';
      _passwordError = '';
      _confirmPasswordError = '';
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;
    if (name.isEmpty) {
      _nameError = 'Please enter your full name';
      hasError = true;
    } else if (name.length < 2) {
      _nameError = 'Name must be at least 2 characters';
      hasError = true;
    }

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

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      hasError = true;
    } else if (confirmPassword != password) {
      _confirmPasswordError = 'Passwords do not match';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    FocusScope.of(context).unfocus();
    final success = await _authController.register(email, name, password);
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
                          'Create account to build your premium ledger',
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
                    'Get Started',
                    style: TextStyle(
                      color: theme.textColorPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register to securely manage assets',
                    style: TextStyle(
                      color: theme.textColorPlaceholder,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Input
                  TDInput(
                    controller: _nameController,
                    inputType: TextInputType.name,
                    leftIcon: Icon(Icons.person_outline_rounded, color: theme.textColorSecondary, size: 16),
                    hintText: 'Full Name',
                    additionInfo: _nameError.isNotEmpty ? _nameError : '',
                    additionInfoColor: theme.errorNormalColor,
                    showBottomDivider: true,
                    backgroundColor: Colors.transparent,
                    textStyle: TextStyle(color: theme.textColorPrimary, fontSize: 12),
                    hintTextStyle: TextStyle(color: theme.textColorPlaceholder, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

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

                  // Confirm Password Input
                  TDInput(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    leftIcon: Icon(Icons.lock_clock_outlined, color: theme.textColorSecondary, size: 16),
                    hintText: 'Confirm Password',
                    additionInfo: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : '',
                    additionInfoColor: theme.errorNormalColor,
                    showBottomDivider: true,
                    backgroundColor: Colors.transparent,
                    textStyle: TextStyle(color: theme.textColorPrimary, fontSize: 12),
                    hintTextStyle: TextStyle(color: theme.textColorPlaceholder, fontSize: 12),
                    needClear: false,
                    rightWidget: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: theme.textColorSecondary,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

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
                      onTap: loading ? null : _handleRegister,
                      size: TDButtonSize.medium,
                      type: TDButtonType.fill,
                      theme: TDButtonTheme.primary,
                      isBlock: true,
                      text: 'Sign Up',
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

                  // Redirect to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: theme.textColorSecondary, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: Text(
                          'Sign In',
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
