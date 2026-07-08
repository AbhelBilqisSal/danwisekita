import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';

/// Service untuk autentikasi: login, register, logout.
///
/// Extends [ChangeNotifier] agar bisa langsung digunakan
/// sebagai provider di Provider/MultiProvider.
///
/// Menyimpan token dan data user ke SharedPreferences
/// agar sesi tetap tersimpan saat app di-restart.
class AuthService extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null && _token != null;
  String? get errorMessage => _errorMessage;

  // ─── Constructor ───────────────────────────────────────────

  AuthService() {
    _loadSavedUser();
  }

  // ─── Load Saved User ──────────────────────────────────────

  /// Memuat user yang tersimpan dari SharedPreferences saat app start.
  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.keyAuthToken);
      final userJson = prefs.getString(AppConstants.keyUserData);

      if (_token != null && userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthService: Error loading saved user: $e');
    }
  }

  // ─── Login ─────────────────────────────────────────────────

  /// Login user dengan email, password, dan role.
  ///
  /// Mengembalikan `true` jika berhasil, `false` jika gagal.
  /// Pesan error tersedia di [errorMessage].
  ///
  /// Response yang diharapkan dari backend:
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "user": { "id", "name", "email", "phone", "role", ... },
  ///     "token": "base64..."
  ///   }
  /// }
  /// ```
  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _client.post(
        'login',
        body: {
          'email': email,
          'password': password,
        },
        includeAuth: false, // Belum punya token saat login
      );

      if (result['success'] == true) {
        _token = result['data']['token'] as String;
        _currentUser = UserModel.fromJson(
          result['data']['user'] as Map<String, dynamic>,
        );

        // Simpan ke SharedPreferences
        await _persistUserData();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message']?.toString() ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.isTimeout
          ? 'Koneksi timeout. Pastikan server berjalan.'
          : e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Register ──────────────────────────────────────────────

  /// Registrasi user baru.
  ///
  /// [userData] harus berisi: name, email, password, role, dan opsional phone.
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _client.post(
        'register',
        body: {
          'name': userData['name'],
          'email': userData['email'],
          'password': userData['password'],
          'role': userData['role'] ?? 'buyer',
          'phone': userData['phone'] ?? '',
          if (userData['role'] == 'seller')
            'store_name': userData['storeName'] ?? userData['store_name'] ?? 'Toko ${userData['name']}',
        },
        includeAuth: false,
      );

      if (result['success'] == true) {
        // Registrasi berhasil tapi akun berstatus 'pending' — belum ada
        // token karena backend mewajibkan persetujuan admin sebelum login.
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message']?.toString() ?? 'Registrasi gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.isTimeout
          ? 'Koneksi timeout. Pastikan server berjalan.'
          : e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────

  /// Logout: hapus token & data user dari memori dan SharedPreferences.
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyAuthToken);
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserData);
      await prefs.remove(AppConstants.keyUserRole);

      _currentUser = null;
      _token = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
    }
  }

  // ─── Update Profile ───────────────────────────────────────

  /// Update profil user yang sedang login.
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dataWithId = {
        'id': _currentUser!.id,
        ...profileData,
      };

      String endpoint = 'profile';
      if (_currentUser!.role == 'buyer') {
        endpoint = 'buyer/profile';
      }

      final result = await _client.put(endpoint, body: dataWithId);

      if (result['success'] == true) {
        // Merge data profile yang baru ke currentUser
        _currentUser = _currentUser!.copyWith(
          name: profileData['name']?.toString() ?? _currentUser!.name,
          phone: profileData['phone']?.toString() ?? _currentUser!.phone,
          storeName: profileData['store_name']?.toString() ??
              _currentUser!.storeName,
          profilePicture: profileData['profile_picture']?.toString() ??
              _currentUser!.profilePicture,
          qrisImage: profileData['qris_image']?.toString() ??
              _currentUser!.qrisImage,
        );

        await _persistUserData();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message']?.toString() ?? 'Update profil gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on ApiException catch (e) {
      _errorMessage = e.isUnauthorized
          ? 'Sesi berakhir. Silakan login kembali.'
          : e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  /// Simpan data user ke SharedPreferences.
  Future<void> _persistUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(AppConstants.keyAuthToken, _token!);
    }
    if (_currentUser != null) {
      await prefs.setString(AppConstants.keyUserId, _currentUser!.id);
      await prefs.setString(AppConstants.keyUserRole, _currentUser!.role);
      await prefs.setString(
        AppConstants.keyUserData,
        jsonEncode(_currentUser!.toJson()),
      );
    }
  }

  /// Hapus pesan error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}