import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'controllers/portfolio_controller.dart';
import 'controllers/auth_controller.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(baseUrl: 'http://localhost:8787/');

  // Register controllers globally
  Get.put(AuthController(apiClient: apiClient));
  Get.put(PortfolioController(apiClient: apiClient));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Asset Master',
      debugShowCheckedModeBanner: false,
      theme: TDTheme.defaultData().systemThemeDataLight,
      themeMode: ThemeMode.light,
      home: Obx(() {
        final auth = Get.find<AuthController>();
        if (!auth.isInitialized.value) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        return auth.isAuthenticated ? const DashboardView() : const LoginView();
      }),
    );
  }
}
