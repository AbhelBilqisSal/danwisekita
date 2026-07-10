import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';

/// Service untuk mengelola fitur khusus Seller.
///
/// Mencakup:
/// - Statistik dashboard seller.
/// - Upload QRIS.
/// - Get QRIS seller.
/// - Upload gambar profil.
class SellerService {
  final ApiClient _client = ApiClient();

  // ─── Seller Stats ─────────────────────────────────────────

  /// Fetch statistik dashboard toko milik seller yang sedang login.
  ///
  /// Response berisi: totalOrders, pendingOrders, completedOrders,
  /// todayIncome, totalProducts, averageRating.
  Future<Map<String, dynamic>> getSellerStats(String sellerId) async {
    try {
      final result = await _client.get('seller/dashboard');

      if (result['success'] == true) {
        return result['data'] as Map<String, dynamic>? ?? {};
      }
      return {};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat statistik: $e');
    }
  }

  // ─── QRIS Management ─────────────────────────────────────

  /// Get gambar QRIS milik toko sendiri (seller yang sedang login).
  Future<Map<String, dynamic>> getSellerQris(String sellerId) async {
    try {
      return await _client.get('seller/qris');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat QRIS: $e');
    }
  }

  /// Upload/ganti gambar QRIS milik toko sendiri.
  ///
  /// [imageFile] — file gambar QRIS yang sudah dipilih via ImagePicker.
  Future<Map<String, dynamic>> uploadQris(
      XFile imageFile, String userId) async {
    try {
      // Baca file sebagai bytes lalu encode ke base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/png;base64,${base64Encode(bytes)}';

      final result = await _client.post(
        'seller/qris',
        body: {'qris_image': base64Image},
        extraHeaders: {'User-Id': userId},
        timeout: const Duration(seconds: 30),
      );

      return result;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal upload QRIS: $e');
    }
  }

  /// Hapus gambar QRIS milik toko sendiri.
  Future<Map<String, dynamic>> deleteQris() async {
    try {
      return await _client.delete('seller/qris');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menghapus QRIS: $e');
    }
  }

  // ─── Image Upload ─────────────────────────────────────────

  /// Upload gambar profil/produk generik.
  ///
  /// Mengembalikan URL gambar yang tersimpan di server, atau null jika gagal.
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final result = await _client.post(
        'upload',
        body: {'image': base64Image},
        extraHeaders: {'User-Id': userId},
        timeout: const Duration(seconds: 30),
      );

      if (result['success'] == true) {
        return result['data']?['url']?.toString();
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal upload gambar: $e');
    }
  }

  // ─── Nearby Sellers ───────────────────────────────────────

  /// Get toko terdekat berdasarkan koordinat.
  ///
  /// Mengembalikan list raw toko (field: id, nama_toko, alamat, distance,
  /// latitude, longitude, barangs, dst — lihat BuyerTokoController).
  Future<List<dynamic>> getNearbySellers(double lat, double lng) async {
    try {
      final result = await _client.get(
        'buyer/tokos/nearby',
        queryParams: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'radius': '50',
        },
      );

      if (result['success'] == true && result['data'] is Map) {
        final tokos = (result['data'] as Map)['tokos'];
        if (tokos is List) return tokos;
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat toko terdekat: $e');
    }
  }
}
