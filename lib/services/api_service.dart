import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../utils/constants.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';
import 'product_service.dart';
import 'order_service.dart';
import 'seller_service.dart';

/// Facade Service untuk backward compatibility.
///
/// **DEPRECATED**: File ini tetap dipertahankan agar screen-screen
/// yang sudah ada tidak langsung rusak. Untuk kode baru, gunakan
/// service yang lebih spesifik:
/// - [AuthService] → login, register, logout
/// - [ProductService] → CRUD produk
/// - [OrderService] → checkout, pesanan masuk seller
/// - [SellerService] → stats, QRIS, upload gambar
///
/// Secara internal, class ini mendelegasikan ke service-service
/// tersebut di atas.
class ApiService {
  static final String baseUrl = AppConstants.baseUrl;

  final ApiClient _client = ApiClient();
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final SellerService _sellerService = SellerService();

  // ==================== AUTHENTICATION ====================

  Future<Map<String, dynamic>> login(
      String email, String password, String role) async {
    try {
      final result = await _client.post(
        'login',
        body: {'email': email, 'password': password},
        includeAuth: false,
      );

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          AppConstants.keyAuthToken,
          result['data']['token'],
        );
      }
      return result;
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final result = await _client.post(
        'register',
        body: {
          'name': userData['name'],
          'email': userData['email'],
          'password': userData['password'],
          'role': userData['role'] ?? 'buyer',
          'phone': userData['phone'] ?? '',
        },
        includeAuth: false,
      );

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          AppConstants.keyAuthToken,
          result['data']['token'],
        );
      }
      return result;
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke server gagal: $e'};
    }
  }

  // ==================== PRODUCTS ====================

  Future<List<dynamic>> getProducts({String? sellerId}) async {
    try {
      final products = await _productService.getProducts(sellerId: sellerId);
      // Kembalikan sebagai List<Map> agar compatible dengan kode lama
      return products.map((p) => p.toJson()).toList();
    } on ApiException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Produk milik toko sendiri (seller yang sedang login).
  Future<List<dynamic>> getMyProducts() async {
    try {
      final products = await _productService.getMyProducts();
      return products.map((p) => p.toJson()).toList();
    } on ApiException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      return await _productService.createProduct(productData);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      return await _productService.updateProduct(productId, productData);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      return await _productService.deleteProduct(productId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== ORDERS ====================

  Future<List<dynamic>> getOrders({
    String? sellerId,
    String? buyerId,
    String? status,
  }) async {
    try {
      List<OrderModel> orders;
      if (sellerId != null) {
        orders = await _orderService.getSellerOrders(sellerId, status: status);
      } else if (buyerId != null) {
        orders = await _orderService.getBuyerOrders(buyerId, status: status);
      } else {
        orders = [];
      }
      // Kembalikan raw data agar compatible dengan kode lama
      return orders.map((o) => {
            'id': o.id,
            'order_number': o.orderNumber,
            'buyer_id': o.buyerId,
            'seller_id': o.sellerId,
            'buyer_name': o.buyerName,
            'seller_name': o.sellerName,
            'total_amount': o.totalAmount,
            'status': o.status,
            'created_at': o.createdAt?.toIso8601String(),
            'items': o.items
                .map((i) => {
                      'product_id': i.productId,
                      'product_name': i.productName,
                      'price': i.price,
                      'quantity': i.quantity,
                      'subtotal': i.subtotal,
                    })
                .toList(),
          }).toList();
    } on ApiException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Checkout semua item keranjang lokal menjadi transaksi di backend.
  Future<Map<String, dynamic>> checkout(List<CartItem> cartItems) async {
    try {
      return await _orderService.checkout(cartItems: cartItems);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      return await _orderService.acceptOrder(orderId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectOrder(String orderId) async {
    try {
      return await _orderService.rejectOrder(orderId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    try {
      return await _orderService.completeOrder(orderId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== QRIS ====================

  Future<Map<String, dynamic>> getSellerQris(String sellerId) async {
    try {
      return await _sellerService.getSellerQris(sellerId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadQris(
      dynamic imageFile, String userId) async {
    try {
      if (imageFile is XFile) {
        return await _sellerService.uploadQris(imageFile, userId);
      }
      return {'success': false, 'message': 'Format file tidak didukung'};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteQris() async {
    try {
      return await _sellerService.deleteQris();
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== PAYMENT ====================

  Future<Map<String, dynamic>> getOrderPayment(String orderId) async {
    try {
      return await _orderService.getOrderPayment(orderId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String orderId) async {
    try {
      return await _orderService.confirmPayment(orderId);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== PROFILE ====================

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      return await _client.put('profile', body: profileData);
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== UPLOAD IMAGE ====================

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString(AppConstants.keyUserId) ?? '';

      if (userId.isEmpty) {
        final userJson = prefs.getString(AppConstants.keyUserData);
        if (userJson != null && userJson.isNotEmpty) {
          try {
            final userData = jsonDecode(userJson);
            userId = userData['id']?.toString() ?? '';
          } catch (_) {}
        }
      }

      return await _sellerService.uploadProfileImage(imageFile, userId);
    } on ApiException {
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== STATS ====================

  Future<Map<String, dynamic>> getSellerStats(String sellerId) async {
    try {
      return await _sellerService.getSellerStats(sellerId);
    } on ApiException {
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== NEARBY SELLERS ====================

  Future<List<dynamic>> getNearbySellers(double lat, double lng) async {
    try {
      return await _sellerService.getNearbySellers(lat, lng);
    } on ApiException {
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== CHAT ====================

  Future<List<dynamic>> getConversations(String userId) async {
    try {
      final result = await _client.get(
        'chat/conversations',
        queryParams: {'user_id': userId},
      );
      return result['data'] ?? [];
    } on ApiException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMessages(String userId, String otherUserId) async {
    try {
      final result = await _client.get(
        'chat/messages',
        queryParams: {'user_id': userId, 'other_user_id': otherUserId},
      );
      return result['data'] ?? [];
    } on ApiException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(String senderId, String receiverId, String message, {String? image}) async {
    try {
      return await _client.post(
        'chat/send',
        body: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': message,
          'image': image,
        },
      );
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markAsRead(String userId, String otherUserId) async {
    try {
      return await _client.put(
        'chat/read',
        body: {
          'user_id': userId,
          'other_user_id': otherUserId,
        },
      );
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}