import 'package:dio/dio.dart';
import '../models/portfolio.dart';
import '../models/asset.dart';
import '../models/valuation.dart';
import '../models/user.dart';
import '../models/trend_data.dart';

class ApiClient {
  final Dio _dio;
  String? token;

  // Make base URL configurable, default to wrangler dev port
  ApiClient({String baseUrl = 'http://localhost:8087'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    // Add logging interceptor for easy local dev troubleshooting
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('[API Request] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '[API Response] ${response.statusCode} for ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('[API Error] ${e.message} for ${e.requestOptions.uri}');
          return handler.next(e);
        },
      ),
    );
  }

  // Login standard session
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          final String resToken = data['token'] as String;
          final User user = User.fromJson(data['user'] as Map<String, dynamic>);
          return {'token': resToken, 'user': user};
        }
      }
      throw Exception(response.data?['error'] ?? 'Login failed');
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ?? e.message ?? 'Unknown network error';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Register new edge user account
  Future<Map<String, dynamic>> register(
    String email,
    String name,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'email': email.trim(),
          'name': name.trim(),
          'password': password,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          final String resToken = data['token'] as String;
          final User user = User.fromJson(data['user'] as Map<String, dynamic>);
          return {'token': resToken, 'user': user};
        }
      }
      throw Exception(response.data?['error'] ?? 'Registration failed');
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ?? e.message ?? 'Unknown network error';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to register account: $e');
    }
  }

  // Fetch portfolios
  Future<List<Portfolio>> getPortfolios() async {
    try {
      final response = await _dio.get('/api/portfolios');
      if (response.statusCode == 200 && response.data != null) {
        final List portfoliosJson = response.data['portfolios'] as List? ?? [];
        return portfoliosJson
            .map((p) => Portfolio.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load portfolios: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception fetching portfolios: $e');
    }
  }

  // Create portfolio
  Future<Portfolio> createPortfolio(
    String name,
    String description, {
    String currency = 'USD',
  }) async {
    try {
      final response = await _dio.post(
        '/api/portfolios',
        data: {'name': name, 'description': description, 'currency': currency},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return Portfolio.fromJson(
          response.data['portfolio'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to create portfolio: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception creating portfolio: $e');
    }
  }

  // Update portfolio (e.g. currency)
  Future<Portfolio> updatePortfolio(
    String portfolioId, {
    String? name,
    String? description,
    String? currency,
  }) async {
    try {
      final response = await _dio.put(
        '/api/portfolios/$portfolioId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (currency != null) 'currency': currency,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return Portfolio.fromJson(
          response.data['portfolio'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to update portfolio: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception updating portfolio: $e');
    }
  }

  // Fetch assets for portfolio
  Future<List<Asset>> getAssets(String portfolioId, {String? broker}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (broker != null && broker != 'All') {
        queryParams['broker'] = broker;
      }
      final response = await _dio.get(
        '/api/portfolios/$portfolioId/assets',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data != null) {
        final List assetsJson = response.data['assets'] as List? ?? [];
        return assetsJson
            .map((a) => Asset.fromJson(a as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load assets: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception fetching assets: $e');
    }
  }

  // Add asset holding
  Future<Asset> addAsset({
    required String portfolioId,
    required String symbol,
    required String name,
    required double quantity,
    required double purchasePrice,
    required String broker,
    int? purchaseDate,
  }) async {
    try {
      final response = await _dio.post(
        '/api/assets',
        data: {
          'portfolio_id': portfolioId,
          'symbol': symbol,
          'name': name,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'purchase_date':
              purchaseDate ?? DateTime.now().millisecondsSinceEpoch,
          'broker': broker,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return Asset.fromJson(response.data['asset'] as Map<String, dynamic>);
      }
      throw Exception('Failed to add asset: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception adding asset: $e');
    }
  }

  // Edit asset holding
  Future<Asset> editAsset({
    required String assetId,
    required String symbol,
    required String name,
    required double quantity,
    required double purchasePrice,
    required String broker,
    int? purchaseDate,
  }) async {
    try {
      final response = await _dio.put(
        '/api/assets/$assetId',
        data: {
          'symbol': symbol,
          'name': name,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'purchase_date':
              purchaseDate ?? DateTime.now().millisecondsSinceEpoch,
          'broker': broker,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return Asset.fromJson(response.data['asset'] as Map<String, dynamic>);
      }
      throw Exception('Failed to edit asset: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception editing asset: $e');
    }
  }

  // Delete asset holding
  Future<bool> deleteAsset(String assetId) async {
    try {
      final response = await _dio.delete('/api/assets/$assetId');
      if (response.statusCode == 200) {
        return response.data['success'] as bool? ?? false;
      }
      throw Exception('Failed to delete asset: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception deleting asset: $e');
    }
  }

  // Get portfolio valuation
  Future<PortfolioValuation> getValuation(
    String portfolioId, {
    String? broker,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (broker != null && broker != 'All') {
        queryParams['broker'] = broker;
      }
      final response = await _dio.get(
        '/api/portfolios/$portfolioId/valuation',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data != null) {
        return PortfolioValuation.fromJson(
          response.data['valuation'] as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to load portfolio valuation: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Dio Exception fetching valuation: $e');
    }
  }

  // Get portfolio historical trend data
  Future<List<TrendDataPoint>> getTrendData(String portfolioId) async {
    try {
      final response = await _dio.get('/api/portfolios/$portfolioId/trend');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['trend'] as List? ?? [];
        return list
            .map(
              (item) => TrendDataPoint.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      throw Exception('Failed to load portfolio trend: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception fetching portfolio trend: $e');
    }
  }

  // Search assets using Yahoo Finance Autocomplete via the edge backend
  Future<List<Map<String, dynamic>>> searchAssets(String query) async {
    try {
      final response = await _dio.get(
        '/api/stocks/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200 && response.data != null) {
        final List results = response.data['results'] as List? ?? [];
        return results
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      throw Exception('Failed to search assets: ${response.statusCode}');
    } catch (e) {
      throw Exception('Dio Exception searching assets: $e');
    }
  }

  // Fetch live price for a single symbol
  Future<double?> getLivePrice(String symbol) async {
    try {
      final response = await _dio.get(
        '/api/stocks',
        queryParameters: {'symbols': symbol},
      );
      if (response.statusCode == 200 && response.data != null) {
        final prices = response.data['prices'] as Map?;
        final data = prices?[symbol.toUpperCase()] as Map?;
        if (data != null) {
          return (data['price'] as num?)?.toDouble();
        }
      }
      return null;
    } catch (e) {
      print('[ApiClient Live Price Error] $e');
      return null;
    }
  }
}
