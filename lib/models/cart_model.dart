/// Model item keranjang (Cart).
///
/// Disimpan di memori (via CartProvider). Model ini TIDAK dikirim
/// langsung ke backend — saat checkout, data di-map ke format
/// yang diharapkan endpoint `orders` (POST).
class CartItem {
  final String productId;
  final String productName;
  final double price;
  final String imageUrl;
  final int quantity;
  final String sellerId;
  final String sellerName;
  final int stock;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    this.stock = 0,
  });

  /// Membuat salinan CartItem dengan quantity yang diubah.
  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId,
      sellerName: sellerName,
      stock: stock,
    );
  }

  /// Serialisasi ke JSON.
  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'stock': stock,
      };

  /// Parse dari JSON.
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        imageUrl: json['imageUrl']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        sellerId: json['sellerId']?.toString() ?? '',
        sellerName: json['sellerName']?.toString() ?? '',
        stock: (json['stock'] as num?)?.toInt() ?? 0,
      );

  /// Konversi ke format yang diharapkan endpoint backend `orders`.
  Map<String, dynamic> toOrderItemJson() => {
        'barang_id': productId,
        'jumlah': quantity,
      };

  @override
  String toString() =>
      'CartItem(productId: $productId, name: $productName, qty: $quantity)';
}