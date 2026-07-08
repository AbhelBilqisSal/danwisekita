import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';

/// Service untuk mengelola order / pesanan.
///
/// Digunakan oleh:
/// - **Buyer**: Membuat order (checkout) dan melihat riwayat pesanan.
/// - **Seller**: Melihat pesanan masuk dan mengelola status pesanan.
class OrderService {
  final ApiClient _client = ApiClient();

  // ═══════════════════════════════════════════════════════════
  // BUYER FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  /// Checkout: membuat order (transaksi) baru dari item keranjang.
  ///
  /// Keranjang di app ini murni lokal (tidak disinkronkan ke keranjang
  /// server), jadi checkout memakai endpoint `buyer/checkout/direct`
  /// satu per item — ini juga otomatis mengelompokkan transaksi per toko
  /// karena `toko_id` diturunkan dari `barang_id` di backend.
  ///
  /// Mengembalikan `{'success', 'message', 'data': {'transactions': [...]}}`.
  Future<Map<String, dynamic>> checkout({
    required List<CartItem> cartItems,
  }) async {
    try {
      final transactions = <dynamic>[];

      for (final item in cartItems) {
        final result = await _client.post(
          'buyer/checkout/direct',
          body: {
            'barang_id': item.productId,
            'jumlah': item.quantity,
          },
        );

        if (result['success'] != true) {
          return result;
        }
        transactions.add(result['data']?['transaction']);
      }

      return {
        'success': true,
        'message': 'Checkout berhasil',
        'data': {'transactions': transactions},
      };
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal membuat pesanan: $e');
    }
  }

  /// Fetch riwayat pesanan buyer yang sedang login.
  Future<List<OrderModel>> getBuyerOrders(String buyerId,
      {String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final result = await _client.get('buyer/transactions',
          queryParams: queryParams.isNotEmpty ? queryParams : null);

      if (result['success'] == true && result['data'] is Map) {
        final transactions = (result['data'] as Map)['transactions'];
        if (transactions is List) {
          return transactions
              .map((json) =>
                  OrderModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat pesanan: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SELLER FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  /// Fetch pesanan masuk untuk toko milik seller yang sedang login.
  ///
  /// Bisa difilter berdasarkan [status]:
  /// 'pending', 'menunggu_verifikasi', 'paid', 'proses', 'selesai', 'cancelled'.
  Future<List<OrderModel>> getSellerOrders(String sellerId,
      {String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final result = await _client.get('seller/orders',
          queryParams: queryParams.isNotEmpty ? queryParams : null);

      if (result['success'] == true && result['data'] is List) {
        return (result['data'] as List)
            .map(
                (json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat pesanan seller: $e');
    }
  }

  /// Seller menerima pesanan (status → proses).
  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      return await _client.post('seller/orders/$orderId/accept');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menerima pesanan: $e');
    }
  }

  /// Seller menolak pesanan (status → cancelled).
  Future<Map<String, dynamic>> rejectOrder(String orderId) async {
    try {
      return await _client.post('seller/orders/$orderId/reject');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menolak pesanan: $e');
    }
  }

  /// Seller menyelesaikan pesanan (status → selesai).
  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    try {
      return await _client.post('seller/orders/$orderId/complete');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menyelesaikan pesanan: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PAYMENT FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  /// Get detail pembayaran QRIS untuk order tertentu.
  Future<Map<String, dynamic>> getOrderPayment(String orderId) async {
    try {
      return await _client.get('buyer/transactions/$orderId/payment');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat info pembayaran: $e');
    }
  }

  /// Konfirmasi pembayaran untuk order tertentu.
  Future<Map<String, dynamic>> confirmPayment(String orderId) async {
    try {
      return await _client.post('buyer/transactions/$orderId/confirm-payment');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal konfirmasi pembayaran: $e');
    }
  }
}
