import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/api_exception.dart';

/// Base API Client untuk DanWise.
///
/// Fitur utama:
/// - Otomatis menyisipkan Bearer Token di setiap header request.
/// - Otomatis menangani timeout dan error 401 (Unauthorized).
/// - Menyediakan method GET, POST, PUT, DELETE yang sudah
///   ter-*wrap* dengan error handling yang konsisten.
///
/// Semua service (AuthService, ProductService, dll.)
/// memanggil method dari class ini.
class ApiClient {
  // Singleton agar semua service berbagi satu instance.
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String _baseUrl = AppConstants.baseUrl;

  // ─── Header Builder ────────────────────────────────────────

  /// Membangun header standar JSON + Bearer Token.
  /// Jika [includeAuth] false, token tidak disertakan
  /// (digunakan untuk login/register).
  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAuthToken);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Menambah header custom (misal User-Id) di atas header standar.
  Future<Map<String, String>> _buildHeadersWithExtra({
    bool includeAuth = true,
    Map<String, String>? extra,
  }) async {
    final headers = await _buildHeaders(includeAuth: includeAuth);
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  // ─── HTTP Methods ──────────────────────────────────────────

  /// HTTP GET request.
  ///
  /// [path] — endpoint API (misal 'products').
  /// [queryParams] — parameter query tambahan.
  /// [extraHeaders] — header tambahan (misal 'User-Id').
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
  }) async {
    try {
      // Bangun URL dengan standard REST (Laravel)
      var uriString = '$_baseUrl/$path';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = Uri(queryParameters: queryParams).query;
        uriString += '?$query';
      }
      
      final uri = Uri.parse(uriString);
      final headers = await _buildHeadersWithExtra(
        includeAuth: includeAuth,
        extra: extraHeaders,
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(AppConstants.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi timeout. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Koneksi ke server gagal: $e');
    }
  }

  /// HTTP POST request.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    try {
      var uriString = '$_baseUrl/$path';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = Uri(queryParameters: queryParams).query;
        uriString += '?$query';
      }

      final uri = Uri.parse(uriString);
      final headers = await _buildHeadersWithExtra(
        includeAuth: includeAuth,
        extra: extraHeaders,
      );

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout ?? AppConstants.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi timeout. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Koneksi ke server gagal: $e');
    }
  }

  /// HTTP PUT request.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
  }) async {
    try {
      var uriString = '$_baseUrl/$path';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = Uri(queryParameters: queryParams).query;
        uriString += '?$query';
      }

      final uri = Uri.parse(uriString);
      final headers = await _buildHeadersWithExtra(
        includeAuth: includeAuth,
        extra: extraHeaders,
      );

      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(AppConstants.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi timeout. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Koneksi ke server gagal: $e');
    }
  }

  /// HTTP DELETE request.
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    bool includeAuth = true,
  }) async {
    try {
      var uriString = '$_baseUrl/$path';
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = Uri(queryParameters: queryParams).query;
        uriString += '?$query';
      }

      final uri = Uri.parse(uriString);
      final headers = await _buildHeadersWithExtra(
        includeAuth: includeAuth,
        extra: extraHeaders,
      );

      final response = await http
          .delete(uri, headers: headers)
          .timeout(AppConstants.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi timeout. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Koneksi ke server gagal: $e');
    }
  }

  // ─── Response Handler ──────────────────────────────────────

  /// Menangani response HTTP.
  /// - 200 → parse JSON body.
  /// - 401 → throw ApiException(isUnauthorized).
  /// - Selainnya → throw ApiException dengan pesan dari server.
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const ApiException(
        statusCode: 401,
        message: 'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw const ApiException(
          statusCode: 200,
          message: 'Format response server tidak valid.',
        );
      }
    }

    // Status code lainnya (400, 403, 404, 500, dll.)
    String message;
    try {
      final data = jsonDecode(response.body);
      message = data['message'] ?? 'Terjadi kesalahan pada server.';
    } catch (_) {
      message = 'Server error: ${response.statusCode}';
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }

  // ─── Token Management ─────────────────────────────────────

  /// Menyimpan auth token ke SharedPreferences.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, token);
  }

  /// Menghapus auth token dari SharedPreferences.
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
  }

  /// Mengambil auth token dari SharedPreferences.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAuthToken);
  }
}
