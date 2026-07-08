import '../models/product_model.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';

/// Service untuk mengelola produk (barang).
///
/// Digunakan oleh:
/// - **Buyer**: Fetch daftar produk yang dipublish.
/// - **Seller**: CRUD produk milik toko sendiri.
///
/// Semua method melempar [ApiException] jika terjadi error
/// (timeout, 401, dll). Tangkap di UI/provider layer.
class ProductService {
  final ApiClient _client = ApiClient();

  // ─── Buyer: Get Products ──────────────────────────────────

  /// Fetch semua produk yang dipublish (is_published = 1).
  ///
  /// Jika [sellerId] diberikan (id toko), hanya produk dari toko tersebut.
  /// Mengembalikan list [ProductModel].
  Future<List<ProductModel>> getProducts({String? sellerId}) async {
    try {
      final endpoint = (sellerId != null && sellerId.isNotEmpty)
          ? 'buyer/products/store/$sellerId'
          : 'buyer/products';

      final result = await _client.get(endpoint);

      if (result['success'] == true && result['data'] is Map) {
        final barangs = (result['data'] as Map)['barangs'];
        if (barangs is List) {
          return barangs
              .map((json) =>
                  ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } on ApiException {
      rethrow; // Biar ditangani di layer atas
    } catch (e) {
      throw ApiException(message: 'Gagal memuat produk: $e');
    }
  }

  /// Fetch produk milik toko sendiri (seller yang sedang login).
  Future<List<ProductModel>> getMyProducts() async {
    try {
      final result = await _client.get('seller/products');

      if (result['success'] == true && result['data'] is List) {
        return (result['data'] as List)
            .map((json) =>
                ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal memuat produk: $e');
    }
  }

  // ─── Seller: Create Product ───────────────────────────────

  /// Tambah produk baru ke toko milik seller yang sedang login.
  ///
  /// [productData] harus berisi: nama_barang, harga.
  /// Opsional: deskripsi, stok, kategori, gambar, is_published.
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      final result = await _client.post('seller/products', body: productData);
      return result;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal menambah produk: $e');
    }
  }

  // ─── Seller: Update Product ───────────────────────────────

  /// Update produk berdasarkan [productId].
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      final result = await _client.put(
        'seller/products/$productId',
        body: productData,
      );
      return result;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal update produk: $e');
    }
  }

  // ─── Seller: Delete Product ───────────────────────────────

  /// Hapus produk berdasarkan [productId].
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final result = await _client.delete(
        'seller/products/$productId',
      );
      return result;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal hapus produk: $e');
    }
  }
}
