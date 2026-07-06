import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/cart_model.dart';
import 'qris_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'qris';
  bool _isLoading = false;

  final double _shippingCost = 10000;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'qris',
      'name': 'QRIS',
      'icon': Icons.qr_code_scanner,
      'desc': 'Bayar dengan scan QR'
    },
    {
      'id': 'cod',
      'name': 'COD',
      'icon': Icons.attach_money,
      'desc': 'Bayar saat barang tiba'
    },
  ];

  @override
  void dispose() {
    super.dispose();
  }

  String get _buttonText {
    return _selectedPaymentMethod == 'cod'
        ? 'Pesan Sekarang'
        : 'Bayar Sekarang';
  }

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

  Future<void> _processCheckout() async {
    setState(() => _isLoading = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();

    await Future.delayed(const Duration(seconds: 2));

    final isSuccess = DateTime.now().millisecondsSinceEpoch % 20 != 0;

    setState(() => _isLoading = false);

    if (isSuccess) {
      Map<String, dynamic>? createdOrder;

      for (var item in cartProvider.items) {
        final buyerId = _toStringSafe(authService.currentUser?.id);
        final buyerName = _toStringSafe(authService.currentUser?.name);
        final sellerId = _toStringSafe(item.sellerId);
        final productId = _toStringSafe(item.productId);
        final productName = _toStringSafe(item.productName);
        final price = _toDoubleSafe(item.price);
        final quantity = _toIntSafe(item.quantity);

        final result = await apiService.createOrder({
          'buyerId': buyerId.isEmpty ? 'buyer1' : buyerId,
          'buyerName': buyerName.isEmpty ? 'Pembeli' : buyerName,
          'sellerId': sellerId.isEmpty ? '1' : sellerId,
          'items': [
            {
              'productId': productId.isEmpty ? '0' : productId,
              'productName': productName.isEmpty ? 'Produk' : productName,
              'price': price,
              'quantity': quantity,
            }
          ],
          'subtotal': price * quantity,
          'shippingCost': _shippingCost,
          'tax': 0.0,
          'total': (price * quantity) + _shippingCost,
          'paymentMethod': _selectedPaymentMethod,
          'shippingAddress': '',
        });

        if (result['success'] == true) {
          createdOrder = result['data'];
        }
      }

      cartProvider.clearCart();

      if (mounted) {
        if (_selectedPaymentMethod == 'qris') {
          final orderId = _toStringSafe(createdOrder?['id'] ??
              'order_${DateTime.now().millisecondsSinceEpoch}');
          final sellerId = cartProvider.items.isNotEmpty
              ? _toStringSafe(cartProvider.items.first.sellerId)
              : '1';

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QrisPaymentScreen(
                orderId: orderId,
                amount: cartProvider.subtotal + _shippingCost,
                sellerId: sellerId,
              ),
            ),
          );
        } else {
          _showSuccessDialog('Pesanan Berhasil!');
        }
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline,
                      size: 36, color: Colors.red.shade600),
                ),
                const SizedBox(height: 16),
                const Text('Proses Gagal!', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: const Text(
              'Proses gagal. Silakan coba lagi.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Coba Lagi',
                    style: TextStyle(color: Color(0xFFDC2626))),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rocket_launch,
                  size: 40, color: Colors.green.shade600),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Terima kasih atas\npesanan Anda!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final subtotal = cartProvider.subtotal;
    final shipping = _shippingCost;
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Rincian Pesanan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFDC2626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Daftar Produk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 20, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return _buildProductItem(item);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_outlined,
                          color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ringkasan Belanja',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Subtotal (${cartProvider.totalItems} item)',
                      'Rp ${_formatNumber(subtotal)}'),
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                      'Biaya Pengiriman', 'Rp ${_formatNumber(shipping)}'),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'Rp ${_formatNumber(total)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment, color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._paymentMethods.map((method) {
                    final isSelected = _selectedPaymentMethod == method['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method['id'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFDC2626).withOpacity(0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFDC2626)
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFDC2626).withOpacity(0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                method['icon'],
                                color: isSelected
                                    ? const Color(0xFFDC2626)
                                    : Colors.grey.shade400,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    method['desc'],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFDC2626)
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _buttonText,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildProductItem(CartItem item) {
    final productName = item.productName ?? 'Produk';
    final quantity = item.quantity;
    final price = item.price;
    final subtotal = price * quantity;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image,
                        size: 24, color: Colors.grey.shade300),
                  ),
                )
              : Icon(Icons.image, size: 24, color: Colors.grey.shade300),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$quantity x Rp ${_formatNumber(price)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Text(
          'Rp ${_formatNumber(subtotal)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFDC2626),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
