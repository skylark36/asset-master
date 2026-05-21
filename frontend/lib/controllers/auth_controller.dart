import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'portfolio_controller.dart';

class AuthController extends GetxController {
  final ApiClient apiClient;
  late final SharedPreferences _prefs;

  // Reactive states
  final currentUser = Rxn<User>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final isInitialized = false.obs;

  bool get isAuthenticated => currentUser.value != null;

  AuthController({required this.apiClient});

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  // Initialize SharedPreferences and restore session
  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _restoreSession();
    } catch (e) {
      print('[AuthController Prefs Init Error] $e');
      isInitialized.value = true;
    }
  }

  // Restore authenticated session from cache
  void _restoreSession() {
    final token = _prefs.getString('token');
    final userStr = _prefs.getString('user');

    if (token != null && userStr != null) {
      try {
        final userMap = json.decode(userStr) as Map<String, dynamic>;
        currentUser.value = User.fromJson(userMap);
        apiClient.token = token;

        // Refresh portfolios to load user portfolios
        _refreshPortfolioData();
      } catch (e) {
        print('[AuthController Session Restore Error] $e');
        logout();
      }
    }
    isInitialized.value = true;
  }

  // Log in user and cache session
  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await apiClient.login(email, password);
      final token = result['token'] as String;
      final user = result['user'] as User;

      apiClient.token = token;
      currentUser.value = user;

      await _prefs.setString('token', token);
      await _prefs.setString('user', json.encode(user.toJson()));

      // Refresh portfolio data for the logged-in user
      _refreshPortfolioData();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print('[AuthController Login Error] $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Register user and cache session
  Future<bool> register(String email, String name, String password) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await apiClient.register(email, name, password);
      final token = result['token'] as String;
      final user = result['user'] as User;

      apiClient.token = token;
      currentUser.value = user;

      await _prefs.setString('token', token);
      await _prefs.setString('user', json.encode(user.toJson()));

      // Refresh portfolio data for the registered user
      _refreshPortfolioData();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      print('[AuthController Register Error] $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear session and wipe cache
  Future<void> logout() async {
    isLoading.value = true;
    try {
      apiClient.token = null;
      currentUser.value = null;
      await _prefs.remove('token');
      await _prefs.remove('user');

      // Clear portfolio controller data so no old holdings remain visible
      _clearPortfolioData();
    } catch (e) {
      print('[AuthController Logout Error] $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Trigger reloading portfolios
  void _refreshPortfolioData() {
    if (Get.isRegistered<PortfolioController>()) {
      final portfolioCtrl = Get.find<PortfolioController>();
      portfolioCtrl.selectedPortfolio.value = null;
      portfolioCtrl.assets.clear();
      portfolioCtrl.valuation.value = null;
      portfolioCtrl.loadPortfolios();
    }
  }

  // Clear data upon logout
  void _clearPortfolioData() {
    if (Get.isRegistered<PortfolioController>()) {
      final portfolioCtrl = Get.find<PortfolioController>();
      portfolioCtrl.selectedPortfolio.value = null;
      portfolioCtrl.assets.clear();
      portfolioCtrl.valuation.value = null;
      portfolioCtrl.portfolios.clear();
    }
  }
}
