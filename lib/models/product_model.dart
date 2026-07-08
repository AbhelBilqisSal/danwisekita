/// Model Product DanWise.
///
/// Mapping langsung ke tabel `products` di backend.
/// Backend mengembalikan field dalam snake_case.
class ProductModel {
  final String id;
  final String tokoId; // Changed from sellerId to tokoId to match Laravel relation
  final String name; // maps to nama_barang
  final String description; // maps to deskripsi
  final double price; // maps to harga
  final int stock; // maps to stok
  final String category; // maps to kategori
  final String? mainImage; // maps to gambar
  final String? images; // Disimpan sebagai string (comma-separated atau JSON)
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.tokoId,
    required this.name,
    this.description = '',
    required this.price,
    this.stock = 0,
    this.category = '',
    this.mainImage,
    this.images,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse dari JSON response backend (snake_case).
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      tokoId: json['toko_id']?.toString() ??
          json['tokoId']?.toString() ??
          json['seller_id']?.toString() ??
          '',
      name: json['nama_barang']?.toString() ?? json['name']?.toString() ?? '',
      description: json['deskripsi']?.toString() ?? json['description']?.toString() ?? '',
      price: _parseDouble(json['harga'] ?? json['price']),
      stock: _parseInt(json['stok'] ?? json['stock']),
      category: json['kategori']?.toString() ?? json['category']?.toString() ?? '',
      mainImage: json['gambar']?.toString() ??
          json['main_image']?.toString() ??
          json['mainImage']?.toString(),
      images: json['images']?.toString(),
      isPublished: json['is_published'] == 1 ||
          json['is_published'] == true ||
          json['isPublished'] == true,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Serialisasi ke JSON (snake_case untuk dikirim ke backend).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toko_id': tokoId,
      'nama_barang': name,
      'deskripsi': description,
      'harga': price,
      'stok': stock,
      'kategori': category,
      'gambar': mainImage ?? '',
      'images': images ?? '',
      'is_published': isPublished ? 1 : 0,
    };
  }

  // ─── Helpers ───────────────────────────────────────────────

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  String toString() => 'ProductModel(id: $id, name: $name, price: $price)';
}