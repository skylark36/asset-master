import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio.dart';
import '../models/asset.dart';
import '../models/valuation.dart';
import '../models/trend_data.dart';
import '../services/api_client.dart';

class PortfolioController extends GetxController {
  final ApiClient apiClient;

  PortfolioController({required this.apiClient});

  // Reactive states
  final portfolios = <Portfolio>[].obs;
  final selectedPortfolio = Rxn<Portfolio>();
  final assets = <Asset>[].obs;
  final valuation = Rxn<PortfolioValuation>();
  
  // Trend states
  final trendData = <TrendDataPoint>[].obs;
  final isTrendLoading = false.obs;
  
  // Broker states
  final selectedBroker = 'All'.obs;
  
  static const List<String> presetBrokers = [
    'IBKR',
    'Charles Schwab',
    'HSBC'
  ];
  
  final customBrokers = <String>[].obs;
  final availableBrokers = <String>[
    'All',
    ...presetBrokers,
    'Other'
  ].obs;
  
  late final SharedPreferences _prefs;
  
  final isLoading = false.obs;
  final isValuationLoading = false.obs;
  final errorMessage = RxnString();
  
  // Purchase history search state
  final purchaseHistorySearchQuery = ''.obs;

  // Feedback states
  final feedbackText = ''.obs;
  final feedbackRating = 5.obs;
  final feedbackCategory = 'Feature Request'.obs;
  final isFeedbackSubmitting = false.obs;
  final feedbackSubmittedSuccess = false.obs;
  
  // Tab navigation state (0 = Overview, 1 = Holdings)
  final activeTab = 0.obs;
  
  // Floating Action Button visibility state
  final showFab = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initPrefsAndBrokers();
    loadPortfolios();
  }

  // Load custom brokers from storage and sync list
  Future<void> _initPrefsAndBrokers() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedCustom = _prefs.getStringList('custom_brokers');
      if (savedCustom != null) {
        customBrokers.assignAll(savedCustom);
      }
      _updateAvailableBrokers();
    } catch (e) {
      print('[PortfolioController Prefs Error] $e');
    }
  }

  void _updateAvailableBrokers() {
    availableBrokers.assignAll([
      'All',
      ...presetBrokers,
      ...customBrokers,
      'Other',
    ]);
  }

  void addCustomBroker(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    // Prevent duplicates case-insensitively with presets or existing custom brokers
    final isDuplicate = presetBrokers.any((b) => b.toLowerCase() == cleanName.toLowerCase()) ||
                        customBrokers.any((b) => b.toLowerCase() == cleanName.toLowerCase());
    if (isDuplicate) return;
    
    customBrokers.add(cleanName);
    _prefs.setStringList('custom_brokers', customBrokers.toList());
    _updateAvailableBrokers();
  }

  void removeCustomBroker(String name) {
    customBrokers.remove(name);
    _prefs.setStringList('custom_brokers', customBrokers.toList());
    _updateAvailableBrokers();
  }

  // Load all portfolios for the current user (demo-user-123 is handled by backend)
  Future<void> loadPortfolios() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final list = await apiClient.getPortfolios();
      portfolios.assignAll(list);
      
      if (list.isNotEmpty) {
        // Automatically select the first portfolio if none selected yet
        if (selectedPortfolio.value == null) {
          selectPortfolio(list.first);
        } else {
          // If already selected, verify it still exists, otherwise select first
          final exists = list.any((p) => p.id == selectedPortfolio.value!.id);
          if (exists) {
            final updated = list.firstWhere((p) => p.id == selectedPortfolio.value!.id);
            selectedPortfolio.value = updated;
            loadPortfolioDetails(updated.id);
          } else {
            selectPortfolio(list.first);
          }
        }
      } else {
        // Only one portfolio is enough - auto-create default if empty
        final success = await createPortfolio('My Wealth', 'Core stock and crypto ledger', currency: 'USD');
        if (!success) {
          selectedPortfolio.value = null;
          assets.clear();
          valuation.value = null;
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to load portfolios. Is the server running?';
      print('[PortfolioController Error] $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update portfolio base currency and reload
  Future<bool> updateSelectedPortfolioCurrency(String currency) async {
    final activePort = selectedPortfolio.value;
    if (activePort == null) return false;

    isValuationLoading.value = true;
    errorMessage.value = null;
    try {
      final updated = await apiClient.updatePortfolio(activePort.id, currency: currency);
      
      // Update in portfolios list
      final index = portfolios.indexWhere((p) => p.id == activePort.id);
      if (index != -1) {
        portfolios[index] = updated;
      }
      selectedPortfolio.value = updated;
      
      // Reload assets and valuation under new base currency
      await loadPortfolioDetails(activePort.id);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update currency: $e';
      print('[PortfolioController Error updating currency] $e');
      return false;
    } finally {
      isValuationLoading.value = false;
    }
  }

  // Select a portfolio and load its details
  void selectPortfolio(Portfolio portfolio) {
    selectedPortfolio.value = portfolio;
    loadPortfolioDetails(portfolio.id);
  }

  // Load details (assets and calculated valuations) for a portfolio
  Future<void> loadPortfolioDetails(String portfolioId) async {
    isValuationLoading.value = true;
    errorMessage.value = null;
    try {
      // Run assets fetch and valuation fetch concurrently passing the selected broker filter
      final results = await Future.wait([
        apiClient.getAssets(portfolioId, broker: selectedBroker.value),
        apiClient.getValuation(portfolioId, broker: selectedBroker.value)
      ]);

      assets.assignAll(results[0] as List<Asset>);
      valuation.value = results[1] as PortfolioValuation;
    } catch (e) {
      errorMessage.value = 'Failed to fetch details for this portfolio.';
      print('[PortfolioController Error loading details] $e');
      
      // Fallback empty valuation so UI doesn't crash
      assets.clear();
      valuation.value = PortfolioValuation.empty(portfolioId);
    } finally {
      isValuationLoading.value = false;
    }

    // Load trend data separately to prevent historical price fetch warnings/errors from blocking dashboard
    loadTrendData(portfolioId);
  }

  // Load portfolio historical valuation trend
  Future<void> loadTrendData(String portfolioId) async {
    isTrendLoading.value = true;
    try {
      final list = await apiClient.getTrendData(portfolioId, broker: selectedBroker.value);
      trendData.assignAll(list);
    } catch (e) {
      print('[PortfolioController Error loading trend] $e');
      trendData.clear();
    } finally {
      isTrendLoading.value = false;
    }
  }

  // Set active broker filter and reload
  void selectBroker(String broker) {
    selectedBroker.value = broker;
    final activePort = selectedPortfolio.value;
    if (activePort != null) {
      loadPortfolioDetails(activePort.id);
    }
  }

  // Create a new portfolio
  Future<bool> createPortfolio(String name, String description, {String currency = 'USD'}) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final newPortfolio = await apiClient.createPortfolio(name, description, currency: currency);
      portfolios.add(newPortfolio);
      selectPortfolio(newPortfolio);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create portfolio: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add an asset holding to the active portfolio
  Future<bool> addAssetHolding({
    required String symbol,
    required String name,
    required double quantity,
    required double purchasePrice,
    required String broker,
    DateTime? purchaseDate,
  }) async {
    final activePort = selectedPortfolio.value;
    if (activePort == null) {
      errorMessage.value = 'No portfolio selected';
      return false;
    }

    isValuationLoading.value = true;
    try {
      await apiClient.addAsset(
        portfolioId: activePort.id,
        symbol: symbol.trim(),
        name: name.trim(),
        quantity: quantity,
        purchasePrice: purchasePrice,
        broker: broker,
        purchaseDate: purchaseDate?.millisecondsSinceEpoch,
      );
      
      // Reload assets and valuation
      await loadPortfolioDetails(activePort.id);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to add holding: $e';
      return false;
    } finally {
      isValuationLoading.value = false;
    }
  }

  // Edit an asset holding
  Future<bool> editAssetHolding({
    required String assetId,
    required String symbol,
    required String name,
    required double quantity,
    required double purchasePrice,
    required String broker,
    DateTime? purchaseDate,
  }) async {
    final activePort = selectedPortfolio.value;
    if (activePort == null) {
      errorMessage.value = 'No portfolio selected';
      return false;
    }

    isValuationLoading.value = true;
    try {
      await apiClient.editAsset(
        assetId: assetId,
        symbol: symbol.trim(),
        name: name.trim(),
        quantity: quantity,
        purchasePrice: purchasePrice,
        broker: broker,
        purchaseDate: purchaseDate?.millisecondsSinceEpoch,
      );
      
      // Reload assets and valuation
      await loadPortfolioDetails(activePort.id);
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to edit holding: $e';
      return false;
    } finally {
      isValuationLoading.value = false;
    }
  }

  // Remove an asset holding
  Future<bool> deleteAssetHolding(String assetId) async {
    final activePort = selectedPortfolio.value;
    if (activePort == null) return false;

    isValuationLoading.value = true;
    try {
      final success = await apiClient.deleteAsset(assetId);
      if (success) {
        // Refresh details
        await loadPortfolioDetails(activePort.id);
        return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to delete asset: $e';
      return false;
    } finally {
      isValuationLoading.value = false;
    }
  }

  // Refresh current data
  Future<void> refreshActivePortfolio() async {
    final activePort = selectedPortfolio.value;
    if (activePort != null) {
      await loadPortfolioDetails(activePort.id);
    } else {
      await loadPortfolios();
    }
  }

  // Search assets dynamically
  Future<List<Map<String, dynamic>>> searchAssets(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      return await apiClient.searchAssets(query);
    } catch (e) {
      print('[PortfolioController Search Error] $e');
      return [];
    }
  }

  // Get live price for a symbol
  Future<double?> getLivePrice(String symbol) async {
    return await apiClient.getLivePrice(symbol);
  }

  // Submit user feedback (simulated Edge Node API call)
  Future<void> submitFeedback() async {
    isFeedbackSubmitting.value = true;
    errorMessage.value = null;
    try {
      // Simulate real-world Cloudflare Edge network latency
      await Future.delayed(const Duration(milliseconds: 1200));
      
      feedbackSubmittedSuccess.value = true;
      feedbackText.value = '';
      feedbackRating.value = 5;
      feedbackCategory.value = 'Feature Request';
      
      // Auto-dismiss the success state after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        feedbackSubmittedSuccess.value = false;
      });
    } catch (e) {
      errorMessage.value = 'Failed to submit feedback: $e';
    } finally {
      isFeedbackSubmitting.value = false;
    }
  }
}
