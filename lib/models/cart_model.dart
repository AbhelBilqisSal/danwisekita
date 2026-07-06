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
}