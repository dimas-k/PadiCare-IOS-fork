import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/prediction_model.dart';
import '../models/chat_model.dart';
import '../models/history_model.dart';

class ApiService {
  // ====== KONFIGURASI BASE URL API ======
  // Aktifkan SALAH SATU baseUrl di bawah sesuai kebutuhan.
  //
  // 1) PRODUCTION (Railway) — default:
  // static const String baseUrl =
  //     'https://server-padi-disease-detection-ai-production.up.railway.app';
  //
  // 2) TESTING LOKAL — HP fisik (HP & laptop harus satu WiFi), ganti IP laptopmu:
  //    (cek IP dengan `ipconfig` di Windows / `ifconfig` di Mac/Linux)
  // static const String baseUrl = 'https://rice-disease.petanitech.com';
  //
  // 3) TESTING LOKAL — Emulator Android:
  static const String baseUrl = 'http://192.168.100.39:8000';

  static const Duration timeoutDuration = Duration(seconds: 60);

  // User management
  static String? _userId;
  static String? _deviceId;
  static Map<String, String>? _deviceInfo;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Initialize user session
  Future<void> initializeSession() async {
    await _getUserId();
    await _getDeviceInfo();
    print('🚀 Session initialized - User ID: $_userId');
  }

  // Get or generate user ID (perbaikan: gunakan device_id sebagai identifier utama)
  Future<String> _getUserId() async {
    if (_userId != null) return _userId!;

    await _getDeviceInfo(); // Pastikan device info sudah loaded

    // Gunakan device_id sebagai user ID
    if (_deviceId != null && _deviceId!.isNotEmpty && _deviceId != 'unknown') {
      _userId = _deviceId;
    } else {
      // Fallback: generate random string jika device_id tidak tersedia
      _userId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    print('📱 Using user ID: $_userId');
    return _userId!;
  }

  // Mungkin perlu mengubah timeout untuk check server status
  Future<bool> checkServerStatus() async {
    try {
      print('🔍 Checking server status...');

      // Coba request ke endpoint apapun yang pasti ada di server Anda
      // Misalnya gunakan '/' atau endpoint lain yang Anda tahu pasti ada
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(Duration(seconds: 5));

      print('✅ Server status check: ${response.statusCode}');

      // Jika response code antara 200-299, server dianggap aktif
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ Server status check failed: $e');
      return false;
    }
  }

  // Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;

    final deviceInfo = DeviceInfoPlugin();
    final prefs = await SharedPreferences.getInstance();

    try {
      // Coba load dari cache dulu
      final cachedInfo = prefs.getString('device_info');
      if (cachedInfo != null) {
        _deviceInfo = Map<String, String>.from(jsonDecode(cachedInfo));
        _deviceId = _deviceInfo!['device_id'];
        return _deviceInfo!;
      }

      Map<String, String> info = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
        info = {
          'platform': 'Android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'sdk': androidInfo.version.sdkInt.toString(),
          'device_id': _deviceId!,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? const Uuid().v4();
        info = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
          'device': iosInfo.utsname.machine,
          'device_id': _deviceId!,
        };
      } else {
        // Fallback untuk platform lain
        _deviceId = const Uuid().v4();
        info = {'platform': Platform.operatingSystem, 'device_id': _deviceId!};
      }

      // Add app info
      info['app_version'] = '1.0.0';
      info['build_number'] = '1';
      info['timestamp'] = DateTime.now().toIso8601String();

      _deviceInfo = info;

      // Cache device info
      await prefs.setString('device_info', jsonEncode(info));
      print('📱 Device info cached: ${info['platform']} ${info['model']}');
    } catch (e) {
      print('⚠️ Error getting device info: $e');
      // Fallback device info yang lebih robust
      _deviceId = prefs.getString('fallback_device_id') ?? const Uuid().v4();
      await prefs.setString('fallback_device_id', _deviceId!);

      _deviceInfo = {
        'platform': Platform.operatingSystem,
        'app_version': '1.0.0',
        'device_id': _deviceId!,
        'error': 'device_info_error',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    return _deviceInfo!;
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      print('🌐 Network status: ${isConnected ? "Connected" : "Disconnected"}');
      return isConnected;
    } catch (e) {
      print('⚠️ Connectivity check failed: $e');
      return true; // Assume connected if check fails
    }
  }

  // Generic HTTP request with error handling
  Future<http.Response?> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    bool requiresAuth = true,
  }) async {
    if (!await _checkConnectivity()) {
      throw Exception('Tidak ada koneksi internet');
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    print('🔗 Making request to: $uri');

    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (requiresAuth) {
      try {
        final userId = await _getUserId();
        final deviceInfo = await _getDeviceInfo();
        requestHeaders.addAll({
          'X-User-ID': userId,
          'X-Device-Info': jsonEncode(deviceInfo),
        });
        print('🔐 Added auth headers for user: $userId');
      } catch (e) {
        print('⚠️ Error adding auth headers: $e');
      }
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: requestHeaders)
              .timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: requestHeaders, body: body)
              .timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: requestHeaders, body: body)
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: requestHeaders)
              .timeout(timeoutDuration);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print(
        '📡 ${method.toUpperCase()} $endpoint - Status: ${response.statusCode}',
      );

      // Log response body untuk debugging (hanya sebagian)
      if (response.body.isNotEmpty) {
        final bodyPreview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        print('📄 Response preview: $bodyPreview');
      }

      return response;
    } catch (e) {
      print('❌ Request failed ($method $endpoint): $e');
      rethrow;
    }
  }

  // Ambil data sensor terkini (untuk peringatan data historis di UI)
  Future<Map<String, dynamic>?> fetchSensor() async {
    try {
      final response =
          await _makeRequest('GET', '/sensor', requiresAuth: false);
      if (response != null && response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('⚠️ fetchSensor error: $e');
    }
    return null;
  }

  // Predict image with PostgreSQL integration
  Future<PredictionResult?> predictImage(File imageFile,
      {Map<String, dynamic>? manualSensor}) async {
    try {
      print('📤 Starting image prediction...');
      print('📁 Image file: ${imageFile.path}');
      print('📊 Image size: ${await imageFile.length()} bytes');

      await initializeSession();

      final userId = await _getUserId();
      final deviceInfo = await _getDeviceInfo();

      final uri = Uri.parse('$baseUrl/predict');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'X-User-ID': userId,
        'X-Device-Info': jsonEncode(deviceInfo),
      });

      // Add image file dengan validasi
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: http_parser.MediaType.parse('image/jpeg'),
      );
      request.files.add(multipartFile);

      // ✅ IoT sensor integration — kirim data sensor real-time ke LLM
      request.fields['use_sensor'] = 'true';

      // 🧪 Input sensor MANUAL (opsional) dari pengguna — diprioritaskan backend
      if (manualSensor != null && manualSensor.isNotEmpty) {
        request.fields['manual_sensor'] = jsonEncode(manualSensor);
        print('🧪 manual_sensor dikirim: ${request.fields['manual_sensor']}');
      }

      print('🔄 Uploading image (${multipartFile.length} bytes)...');
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          print('✅ Prediction successful');
          print('🎯 Predicted class: ${jsonData['predicted_class']}');
          print('📊 Confidence: ${jsonData['confidence_percentage']}%');

          final result = PredictionResult.fromJson(jsonData);

          // Save prediction ID for chat context
          if (jsonData['prediction_id'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'current_prediction_id',
              jsonData['prediction_id'],
            );
            print('💾 Saved prediction ID: ${jsonData['prediction_id']}');
          }

          // Show database save status
          final savedToDb = jsonData['saved_to_database'] ?? false;
          print(
            savedToDb
                ? '✅ Prediction saved to PostgreSQL'
                : '⚠️ Prediction not saved to database',
          );

          if (jsonData['database_error'] != null) {
            print('❌ Database error: ${jsonData['database_error']}');
          }

          return result;
        } catch (jsonError) {
          print('❌ JSON parsing error: $jsonError');
          print('📄 Raw response: ${response.body}');
          return null;
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        print('📄 Error response: ${response.body}');

        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          print('🔍 Error details: ${errorData['error']}');
          if (errorData['details'] != null) {
            print('🔍 Error details: ${errorData['details']}');
          }
        } catch (e) {
          print('📄 Raw error response: ${response.body}');
        }

        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Prediction error: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  // Chat with expert
  Future<ChatResponse?> chatWithExpert(
    String question,
    String diseaseContext, {
    String? predictionId,
    Map<String, dynamic>? manualSensor,
  }) async {
    try {
      print('💬 Starting chat request...');
      print(
        '💬 Question: ${question.substring(0, question.length > 50 ? 50 : question.length)}...',
      );
      print('🦠 Disease context: $diseaseContext');

      await initializeSession();

      // Get current prediction ID if not provided
      if (predictionId == null) {
        final prefs = await SharedPreferences.getInstance();
        predictionId = prefs.getString('current_prediction_id');
        print('💾 Using stored prediction ID: $predictionId');
      }

      final userId = await _getUserId();

      final uri = Uri.parse('$baseUrl/chat');
      final requestBody = {
        'question': question,
        'disease_context': diseaseContext,
        // Chat memakai data sensor yang sama dengan analisa:
        // manual (bila diisi) > ThingsBoard (historis).
        'use_sensor': 'true',
        if (predictionId != null) 'prediction_id': predictionId,
        if (manualSensor != null && manualSensor.isNotEmpty)
          'manual_sensor': jsonEncode(manualSensor),
      };

      print('📤 Sending chat request...');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'X-User-ID': userId,
            },
            body: requestBody,
          )
          .timeout(timeoutDuration);

      print('📥 Chat response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          print('✅ Chat response received');
          return ChatResponse.fromJson(jsonData);
        } catch (jsonError) {
          print('❌ Chat JSON parsing error: $jsonError');
          print('📄 Raw chat response: ${response.body}');
          return null;
        }
      } else {
        print('❌ Chat error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Chat request error: $e');
      return null;
    }
  }

  // Get user history
  Future<HistoryResponse?> getUserHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print(
        '📊 Getting SIMPLIFIED user history (limit: $limit, offset: $offset)...',
      );
      await initializeSession();

      final deviceInfo = await _getDeviceInfo();
      final deviceId = deviceInfo['device_id'] ?? await _getUserId();

      final encodedDeviceId = Uri.encodeComponent(deviceId);

      final response = await _makeRequest(
        'GET',
        '/history/$encodedDeviceId?limit=$limit&offset=$offset',
      );

      if (response?.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response!.body);

          if (jsonData is! Map<String, dynamic>) {
            print('❌ JSON is not Map<String, dynamic>');
            return null;
          }

          print('✅ Received SIMPLIFIED response from server');
          print('📊 Response keys: ${jsonData.keys.toList()}');

          final historyResponse = HistoryResponse.fromJson(jsonData);
          print('✅ SIMPLIFIED HistoryResponse parsed successfully');
          print('📊 History items: ${historyResponse.history.length}');
          print('📊 Pagination total: ${historyResponse.pagination.total}');

          return historyResponse;
        } catch (modelParseError) {
          print('❌ SIMPLIFIED HistoryResponse parsing error: $modelParseError');
          return null;
        }
      } else {
        print('❌ History API error: ${response?.statusCode}');
        print('❌ Response body: ${response?.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Get SIMPLIFIED history error: $e');
      print('🔍 StackTrace: $stackTrace');
      return null;
    }
  }

  // Add method untuk get image URL
  Future<String?> getImageUrl(String predictionId) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/prediction/$predictionId/image',
      );

      if (response?.statusCode == 200) {
        final jsonData = jsonDecode(response!.body);
        return jsonData['image_url'];
      }
      return null;
    } catch (e) {
      print('❌ Get image URL error: $e');
      return null;
    }
  }

  // Add method untuk delete history item
  Future<bool> deleteHistoryItem(String predictionId) async {
    try {
      print('🗑️ Deleting history item: $predictionId');
      await initializeSession();

      final response = await _makeRequest(
        'DELETE',
        '/history/item/$predictionId',
      );

      if (response?.statusCode == 200) {
        final jsonData = jsonDecode(response!.body);
        print('✅ History item deleted successfully');
        return jsonData['success'] ?? false;
      } else {
        print('❌ Delete failed: ${response?.statusCode} - ${response?.body}');
        return false;
      }
    } catch (e) {
      print('❌ Delete history error: $e');
      return false;
    }
  }

  // Tambahkan method debug untuk test
  Future<Map<String, dynamic>?> debugUserData() async {
    try {
      await initializeSession();
      final deviceInfo = await _getDeviceInfo();
      final deviceId = deviceInfo['device_id'] ?? await _getUserId();
      final encodedDeviceId = Uri.encodeComponent(deviceId);

      final response = await _makeRequest(
        'GET',
        '/debug/user/$encodedDeviceId',
      );

      if (response?.statusCode == 200) {
        return jsonDecode(response!.body);
      }
      return null;
    } catch (e) {
      print('❌ Debug user data error: $e');
      return null;
    }
  }

  // Test server connection (perbaikan: tambah database test)
  Future<Map<String, dynamic>?> testConnection() async {
    try {
      print('🔍 Testing server connection...');

      // Test basic health endpoint
      final healthResponse = await _makeRequest(
        'GET',
        '/health',
        requiresAuth: false,
      );

      if (healthResponse?.statusCode == 200) {
        final healthData = jsonDecode(healthResponse!.body);
        print('✅ Server health check passed');

        // Test database connection
        try {
          final dbResponse = await _makeRequest(
            'GET',
            '/db-test',
            requiresAuth: false,
          );

          if (dbResponse?.statusCode == 200) {
            final dbData = jsonDecode(dbResponse!.body);
            print('✅ Database connection test passed');

            return {
              'server_status': healthData,
              'database_status': dbData,
              'overall_status': 'healthy',
            };
          } else {
            print('⚠️ Database connection test failed');
            return {
              'server_status': healthData,
              'database_status': {
                'status': 'error',
                'message': 'Connection failed',
              },
              'overall_status': 'degraded',
            };
          }
        } catch (dbError) {
          print('⚠️ Database test error: $dbError');
          return {
            'server_status': healthData,
            'database_status': {
              'status': 'error',
              'message': dbError.toString(),
            },
            'overall_status': 'degraded',
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return {
        'server_status': {'status': 'error', 'message': e.toString()},
        'database_status': {'status': 'unknown'},
        'overall_status': 'error',
      };
    }
  }

  // Clear user session (for logout/reset)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('current_prediction_id');
    await prefs.remove('device_info');
    await prefs.remove('fallback_device_id');

    _userId = null;
    _deviceId = null;
    _deviceInfo = null;

    print('🗑️ User session cleared');
  }

  // Get current user ID (for UI display)
  Future<String?> getCurrentUserId() async {
    try {
      return await _getUserId();
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  // Debug method untuk testing
  Future<Map<String, dynamic>> getDebugInfo() async {
    await initializeSession();

    return {
      'user_id': _userId,
      'device_id': _deviceId,
      'device_info': _deviceInfo,
      'base_url': baseUrl,
      'connectivity': await _checkConnectivity(),
    };
  }
}