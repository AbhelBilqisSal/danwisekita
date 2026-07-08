/// Model Transaction DanWise.
///
/// Mapping ke tabel `transactions` di backend.
/// Tabel ini menyimpan record transaksi yang dibuat
/// bersamaan saat order dibuat (handleCreateOrder).
class TransactionModel {
  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final String paymentMethod;
  final String status; // 'pending', 'success', 'failed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.paymentMethod = 'qris',
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse dari JSON response backend (snake_case).
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      buyerId: json['buyer_id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? 'qris',
      status: json['status']?.toString() ?? 'pending',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Apakah transaksi ini berhasil.
  bool get isSuccess => status == 'success';

  /// Apakah transaksi ini pending.
  bool get isPending => status == 'pending';

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
      'TransactionModel(id: $id, orderId: $orderId, status: $status)';
}
