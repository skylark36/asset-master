import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asset_master_frontend/controllers/portfolio_controller.dart';
import 'package:asset_master_frontend/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PortfolioController - Broker Management Tests', () {
    late ApiClient apiClient;
    late PortfolioController controller;

    setUp(() async {
      // Mock SharedPreferences initial values
      SharedPreferences.setMockInitialValues({
        'custom_brokers': ['Webull', 'Robinhood'],
      });

      apiClient = ApiClient();
      controller = PortfolioController(apiClient: apiClient);
      
      // Trigger initialization and wait for SharedPreferences to load
      controller.onInit();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('Initializes with presets and cached custom brokers', () {
      expect(controller.customBrokers, containsAll(['Webull', 'Robinhood']));
      expect(controller.availableBrokers, containsAll([
        'All',
        'IBKR',
        'Charles Schwab',
        'HSBC',
        'Webull',
        'Robinhood',
        'Other',
      ]));
    });

    test('Add custom broker updates list and persists', () async {
      controller.addCustomBroker('Fidelity');
      
      expect(controller.customBrokers, contains('Fidelity'));
      expect(controller.availableBrokers, contains('Fidelity'));

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('custom_brokers');
      expect(saved, contains('Fidelity'));
    });

    test('Add custom broker prevents duplicates case-insensitively', () {
      // Try duplicate of preset
      controller.addCustomBroker('ibkr');
      expect(controller.customBrokers, isNot(contains('ibkr')));

      // Try duplicate of existing custom
      controller.addCustomBroker('webull');
      expect(controller.customBrokers.where((b) => b.toLowerCase() == 'webull').length, 1);
    });

    test('Remove custom broker updates list and persists', () async {
      controller.removeCustomBroker('Webull');

      expect(controller.customBrokers, isNot(contains('Webull')));
      expect(controller.availableBrokers, isNot(contains('Webull')));

      // Check SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('custom_brokers');
      expect(saved, isNot(contains('Webull')));
    });
  });
}
