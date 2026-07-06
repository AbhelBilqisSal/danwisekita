import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');
      
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email, password, role);
      
      if (result['success'] == true) {
        _token = result['data']['token'];
        _currentUser = UserModel.fromJson(result['data']['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.register(userData);
      
      if (result['success'] == true) {
        _token = result['data']['token'];
        _currentUser = UserModel.fromJson(result['data']['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registrasi gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_data');
      
      _currentUser = null;
      _token = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error logging out: $e');
    }
  }

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
      
      final result = await _apiService.updateProfile(dataWithId);
      
      if (result['success'] == true) {
        final Map<String, dynamic> mergedData = {
          ..._currentUser!.toJson(),
          ...profileData,
        };
        if (profileData.containsKey('profile_picture')) {
          mergedData['profilePicture'] = profileData['profile_picture'];
        }
        if (profileData.containsKey('store_name')) {
          mergedData['storeName'] = profileData['store_name'];
        }
        if (profileData.containsKey('qris_image')) {
          mergedData['qrisImage'] = profileData['qris_image'];
        }
        
        final updatedUser = UserModel.fromJson(mergedData);
        _currentUser = updatedUser;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Update profil gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}