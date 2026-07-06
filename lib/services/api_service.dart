import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

// ==================== HELPER FUNCTIONS ====================

String _toStringSafe(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  return value.toString();
}

double _toDoubleSafe(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toIntSafe(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _fixAllTypes(Map<String, dynamic> data) {
  final result = <String, dynamic>{};
  for (var entry in data.entries) {
    final key = entry.key;
    final value = entry.value;
    
    if (value is Map) {
      result[key] = _fixAllTypes(value as Map<String, dynamic>);
    } else if (value is List) {
      result[key] = value.map((item) {
        if (item is Map) {
          return _fixAllTypes(item as Map<String, dynamic>);
        }
        return item;
      }).toList();
    } else if (key == 'id' || key == 'user_id' || key == 'seller_id' || key == 'buyer_id' || key == 'product_id') {
      result[key] = _toStringSafe(value);
    } else if (key == 'price' || key == 'total' || key == 'total_amount' || key == 'amount' || key == 'subtotal') {
      result[key] = _toDoubleSafe(value);
    } else if (key == 'stock' || key == 'quantity' || key == 'jumlah') {
      result[key] = _toIntSafe(value);
    } else {
      result[key] = value;
    }
  }
  return result;
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/index.php';
  
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTHENTICATION ====================
  
  Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?path=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['data']['token']);
        }
        return data;
      } else {
        return {
          'success': false, 
          'message': 'Login gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final registerData = {
        'name': userData['name'],
        'email': userData['email'],
        'password': userData['password'],
        'role': userData['role'],
        'phone': userData['phone'] ?? '',
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl?path=register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['data']['token']);
        }
        return data;
      } else {
        return {
          'success': false, 
          'message': 'Registrasi gagal: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  // ==================== PRODUCTS ====================
  
  Future<List<dynamic>> getProducts({String? sellerId}) async {
    try {
      String url = '$baseUrl?path=products';
      if (sellerId != null && sellerId.isNotEmpty) {
        url += '&seller_id=$sellerId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final products = data['data'] as List? ?? [];
          return products.map((p) => _fixAllTypes(p as Map<String, dynamic>)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error getProducts: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?path=products'),
        headers: await _getHeaders(),
        body: jsonEncode(productData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal menambah produk'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl?path=product&id=$productId'),
        headers: await _getHeaders(),
        body: jsonEncode(productData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal update produk'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl?path=product&id=$productId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal hapus produk'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== ORDERS ====================
  
  Future<List<dynamic>> getOrders({String? sellerId, String? buyerId, String? status}) async {
    try {
      String url = '$baseUrl?path=orders';
      if (sellerId != null) url += '&seller_id=$sellerId';
      if (buyerId != null) url += '&buyer_id=$buyerId';
      if (status != null) url += '&status=$status';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error getOrders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final fixedData = _fixAllTypes(orderData);
      
      final items = fixedData['items'] as List? ?? [];
      final firstItem = items.isNotEmpty ? items[0] : {};
      
      final response = await http.post(
        Uri.parse('$baseUrl?path=orders'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'buyer_id': fixedData['buyerId'],
          'seller_id': fixedData['sellerId'],
          'items': fixedData['items'],
          'total': fixedData['total'],
          'shipping_cost': fixedData['shippingCost'] ?? 0,
          'tax': fixedData['tax'] ?? 0,
          'discount': fixedData['discount'] ?? 0,
          'payment_method': fixedData['paymentMethod'] ?? 'qris',
          'shipping_address': fixedData['shippingAddress'] ?? '',
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal buat order'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl?path=order/status'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'order_id': orderId,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal update status'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    return updateOrderStatus(orderId, 'processing');
  }

  Future<Map<String, dynamic>> rejectOrder(String orderId) async {
    return updateOrderStatus(orderId, 'rejected');
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    return updateOrderStatus(orderId, 'completed');
  }

  // ==================== QRIS ====================

  Future<Map<String, dynamic>> getSellerQris(String sellerId) async {
    try {
      final headers = await _getHeaders();
      headers['User-Id'] = sellerId;
      
      final response = await http.get(
        Uri.parse('$baseUrl?path=qris&seller_id=$sellerId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          String? imageUrl = data['data']['qris_image'];
          
          if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('data:image') && !imageUrl.startsWith('http')) {
            imageUrl = 'http://localhost:8000/' + imageUrl;
            data['data']['qris_image'] = imageUrl;
          }
          
          return data;
        }
        return {'success': false, 'message': data['message'] ?? 'Gagal get QRIS'};
      }
      return {'success': false, 'message': 'Gagal get QRIS: ${response.statusCode}'};
    } catch (e) {
      print('Error getSellerQris: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadQris(dynamic imageFile, String userId) async {
    try {
      if (imageFile is html.File) {
        final reader = html.FileReader();
        final completer = Completer<String>();
        
        reader.onLoadEnd.listen((_) {
          completer.complete(reader.result as String);
        });
        
        reader.onError.listen((error) {
          completer.completeError('Error reading file');
        });
        
        reader.readAsDataUrl(imageFile);
        final base64Image = await completer.future;
        
        final headers = await _getHeaders();
        headers['User-Id'] = userId;
        
        final response = await http.post(
          Uri.parse('$baseUrl?path=qris/upload'),
          headers: headers,
          body: jsonEncode({
            'qris_image': base64Image,
          }),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            return data;
          }
          return {'success': false, 'message': data['message'] ?? 'Upload QRIS gagal'};
        }
        return {'success': false, 'message': 'Upload QRIS gagal: ${response.statusCode}'};
      }
      return {'success': false, 'message': 'File format not supported'};
    } catch (e) {
      print('Error uploading QRIS: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== QRIS PAYMENT ====================

  Future<Map<String, dynamic>> getOrderPayment(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?path=payment/qris&order_id=$orderId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      print('🟢 Get order payment status: ${response.statusCode}');
      print('🟢 Get order payment response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          String? qrisImage = data['data']['seller_qris'] ?? data['data']['qris_image'] ?? null;
          if (qrisImage != null && qrisImage.isNotEmpty && !qrisImage.startsWith('data:image') && !qrisImage.startsWith('http')) {
            qrisImage = 'http://localhost:8000/' + qrisImage;
            data['data']['qris_image'] = qrisImage;
          }
          return data;
        }
        return {'success': false, 'message': data['message'] ?? 'Gagal get payment'};
      }
      return {'success': false, 'message': 'Gagal get payment: ${response.statusCode}'};
    } catch (e) {
      print('🔴 Error getOrderPayment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?path=payment/confirm&order_id=$orderId'),
        headers: await _getHeaders(),
        body: jsonEncode({'order_id': orderId}),
      ).timeout(const Duration(seconds: 10));
      
      print('🟢 Confirm payment status: ${response.statusCode}');
      print('🟢 Confirm payment response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal confirm payment: ${response.statusCode}'};
    } catch (e) {
      print('🔴 Error confirmPayment: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== PROFILE ====================
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl?path=profile'),
        headers: await _getHeaders(),
        body: jsonEncode(profileData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Gagal update profile'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== UPLOAD IMAGE (WEB COMPATIBLE) ====================
  
  // 🔧 PERBAIKAN: Upload image untuk Web menggunakan base64
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      // Baca file sebagai bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
      final headers = await _getHeaders();
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString('user_id') ?? '';
      if (userId.isEmpty) {
        final userJson = prefs.getString('user_data');
        if (userJson != null && userJson.isNotEmpty) {
          try {
            final userData = jsonDecode(userJson);
            userId = userData['id']?.toString() ?? '';
          } catch (e) {
            print('Error parsing user_data: $e');
          }
        }
      }
      headers['User-Id'] = userId;
      headers['Content-Type'] = 'application/json';
      
      print('🔵 Uploading image to: $baseUrl?path=upload');
      print('🔵 UserId: $userId');
      print('🔵 Image length: ${base64Image.length}');
      
      final response = await http.post(
        Uri.parse('$baseUrl?path=upload'),
        headers: headers,
        body: jsonEncode({
          'image': base64Image,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print('🟢 Upload image status: ${response.statusCode}');
      print('🟢 Upload image response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Image uploaded successfully!');
          return data['data']['url'];
        }
        return null;
      }
      return null;
    } catch (e) {
      print('🔴 Error uploading image: $e');
      return null;
    }
  }

  // ==================== STATS ====================
  
  Future<Map<String, dynamic>> getSellerStats(String sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?path=stats&seller_id=$sellerId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      print('Error getSellerStats: $e');
      return {};
    }
  }

  // ==================== NEARBY SELLERS ====================
  
  Future<List<dynamic>> getNearbySellers(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?path=sellers/nearby&lat=$lat&lng=$lng'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error getNearbySellers: $e');
      return [];
    }
  }
}