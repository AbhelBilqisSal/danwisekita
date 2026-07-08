/// Model Order & OrderItem DanWise.
///
/// Mapping ke tabel `orders` dan `order_items` di backend.
/// Backend mengembalikan snake_case.
class OrderModel {
  final String id;
  final String? orderNumber;
  final String buyerId;
  final String sellerId;
  final String? buyerName;
  final String? sellerName;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double shippingCost;
  final double tax;
  final double discount;
  final String status; // 'pending', 'processing', 'completed', 'rejected'
  final String? paymentStatus;
  final String paymentMethod;
  final String? shippingAddress;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    this.orderNumber,
    required this.buyerId,
    required this.sellerId,
    this.buyerName,
    this.sellerName,
    required this.items,
    required this.totalAmount,
    this.shippingCost = 0,
    this.tax = 0,
    this.discount = 0,
    required this.status,
    this.paymentStatus,
    this.paymentMethod = 'qris',
    this.shippingAddress,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse dari JSON response backend (snake_case).
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse items — backend mungkin mengembalikan 'transaksi_details' atau 'items'
    List<OrderItemModel> items = [];
    if (json['details'] is List) {
      items = (json['details'] as List)
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['transaksi_details'] is List) {
      items = (json['transaksi_details'] as List)
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['items'] is List) {
      items = (json['items'] as List)
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['barang_id'] != null) {
      // Jika response transaksi langsung berisi barang_id (satu item per transaksi)
      items.add(OrderItemModel(
        productId: json['barang_id'].toString(),
        productName: json['barang']?['nama_barang']?.toString() ?? '',
        price: _parseDouble(json['total_harga']) / _parseInt(json['jumlah']),
        quantity: _parseInt(json['jumlah']),
      ));
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ??
          json['orderNumber']?.toString(),
      buyerId: json['user_id']?.toString() ??
          json['buyer_id']?.toString() ??
          json['buyerId']?.toString() ??
          '',
      sellerId: json['toko_id']?.toString() ??
          json['seller_id']?.toString() ??
          json['sellerId']?.toString() ??
          '',
      buyerName: json['buyer_name']?.toString() ??
          json['buyerName']?.toString() ??
          (json['user'] is Map ? json['user']['name']?.toString() : null),
      sellerName: json['seller_name']?.toString() ??
          (json['toko'] is Map ? json['toko']['nama_toko']?.toString() : null),
      items: items,
      totalAmount: _parseDouble(json['total_harga'] ?? json['total_amount'] ?? json['total']),
      shippingCost: _parseDouble(json['shipping_cost'] ?? json['shippingCost']),
      tax: _parseDouble(json['tax']),
      discount: _parseDouble(json['discount']),
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString(),
      paymentMethod: json['payment_method']?.toString() ??
          json['paymentMethod']?.toString() ??
          'qris',
      shippingAddress: json['shipping_address']?.toString() ??
          json['shippingAddress']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  /// Apakah order ini sedang menunggu tindakan (belum diproses seller).
  bool get isPending =>
      status == 'pending' || status == 'paid' || status == 'menunggu_verifikasi';

  /// Apakah order ini sedang diproses seller.
  bool get isProcessing => status == 'proses';

  /// Apakah order ini sudah selesai.
  bool get isCompleted => status == 'selesai';

  /// Apakah order ini ditolak/dibatalkan.
  bool get isRejected => status == 'cancelled';

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'OrderModel(id: $id, orderNumber: $orderNumber, status: $status)';
}

/// Model item di dalam order.
/// Mapping ke tabel `order_items`.
class OrderItemModel {
  final String? id;
  final String? orderId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;
  final String? imageUrl;

  OrderItemModel({
    this.id,
    this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.subtotal = 0,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final price = _parseDouble(json['harga_satuan'] ?? json['price']);
    final quantity = _parseInt(json['jumlah'] ?? json['quantity']);

    return OrderItemModel(
      id: json['id']?.toString(),
      orderId: json['transaksi_id']?.toString() ?? json['order_id']?.toString(),
      productId: json['barang_id']?.toString() ??
          json['product_id']?.toString() ??
          json['productId']?.toString() ??
          '',
      productName: json['barang']?['nama_barang']?.toString() ?? json['product_name']?.toString() ??
          json['productName']?.toString() ??
          '',
      price: price,
      quantity: quantity,
      subtotal: _parseDouble(json['subtotal']) != 0
          ? _parseDouble(json['subtotal'])
          : price * quantity,
      imageUrl: json['barang']?['gambar']?.toString() ?? json['image_url']?.toString() ??
          json['imageUrl']?.toString(),
    );
  }

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

  @override
  String toString() =>
      'OrderItemModel(productName: $productName, qty: $quantity)';
}