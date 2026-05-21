import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asset_master_frontend/controllers/portfolio_controller.dart';
import 'package:asset_master_frontend/services/api_client.dart';
import 'package:asset_master_frontend/models/trend_data.dart';
import 'package:asset_master_frontend/models/portfolio.dart';
import 'package:asset_master_frontend/models/asset.dart';
import 'package:asset_master_frontend/models/valuation.dart';

// Simple Mock API client to avoid real network requests during tests
class MockApiClient extends ApiClient {
  bool getTrendCalled = false;
  String? queriedPortfolioId;

  @override
  Future<List<TrendDataPoint>> getTrendData(String portfolioId) async {
    getTrendCalled = true;
    queriedPortfolioId = portfolioId;
    return [
      TrendDataPoint(date: '2026-05-18', value: 10000.0),
      TrendDataPoint(date: '2026-05-19', value: 12000.0),
    ];
  }

  @override
  Future<List<Portfolio>> getPortfolios() async {
    return [
      Portfolio(
        id: 'test-port',
        userId: 'test-user',
        name: 'Test Portfolio',
        description: 'Test Desc',
        currency: 'USD',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
  }

  @override
  Future<List<Asset>> getAssets(String portfolioId, {String? broker}) async {
    return [];
  }

  @override
  Future<PortfolioValuation> getValuation(String portfolioId, {String? broker}) async {
    return PortfolioValuation.empty(portfolioId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Trend Data & Controller Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TrendDataPoint parses from JSON correctly', () {
      final json = {'date': '2026-05-19', 'value': 23450.67};
      final point = TrendDataPoint.fromJson(json);

      expect(point.date, '2026-05-19');
      expect(point.value, 23450.67);

      final backToMap = point.toJson();
      expect(backToMap['date'], '2026-05-19');
      expect(backToMap['value'], 23450.67);
    });

    test('PortfolioController loads trend data on portfolio details fetch', () async {
      final mockApi = MockApiClient();
      final controller = PortfolioController(apiClient: mockApi);

      // Trigger initialization
      controller.onInit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockApi.getTrendCalled, isTrue);
      expect(mockApi.queriedPortfolioId, 'test-port');
      
      expect(controller.trendData.length, 2);
      expect(controller.trendData[0].date, '2026-05-18');
      expect(controller.trendData[0].value, 10000.0);
      expect(controller.trendData[1].date, '2026-05-19');
      expect(controller.trendData[1].value, 12000.0);
    });
  });
}
