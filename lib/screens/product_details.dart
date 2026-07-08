import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  final bool _isLoading = false;
  int _currentImageIndex = 0;

  String _getString(dynamic value) => value?.toString() ?? '';
  double _getDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _getInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<String> get _productImages {
    final image = widget.product['gambar']?.toString();
    if (image != null && image.isNotEmpty) {
      return [image];
    }
    return [];
  }

  Widget _buildProductImage(String imageUrl, {double height = 350}) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade50,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: double.infinity,
              height: height,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: height,
                  color: Colors.grey.shade50,
                  child: const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFDC2626)),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'Gambar tidak tersedia',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada gambar',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(_getString(product['id']));
    final cartQuantity = cartProvider.getQuantity(_getString(product['id']));
    final images = _productImages;

    final productId = _getString(product['id']);
    final productName = _getString(product['nama_barang']);
    final productPrice = _getDouble(product['harga']);
    final productStock = _getInt(product['stok']);
    final description = _getString(product['deskripsi']);
    final category = _getString(product['kategori']);
    final sellerId = _getString(product['toko_id']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Custom SliverAppBar with product image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFDC2626),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFFDC2626), size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: Color(0xFFDC2626), size: 22),
                      onPressed: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                    if (cartProvider.totalItems > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${cartProvider.totalItems}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  _buildProductImage(
                      images.isNotEmpty ? images[_currentImageIndex] : ''),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImageIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentImageIndex == index
                                    ? const Color(0xFFDC2626)
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product details body
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and price
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_formatNumber(productPrice)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stock info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: productStock > 0
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            productStock > 0
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 14,
                            color: productStock > 0
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            productStock > 0
                                ? 'Stok: $productStock tersisa'
                                : 'Stok habis',
                            style: TextStyle(
                              color: productStock > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Divider
                    Container(height: 1, color: Colors.grey.shade100),

                    // Seller info
                    const SizedBox(height: 20),
                    const Text(
                      'Informasi Penjual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.store,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Toko Official',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Online • Telkom University',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Chat',
                                style: TextStyle(
                                    color: Color(0xFFDC2626), fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.grey.shade100),

                    // Description
                    const SizedBox(height: 20),
                    const Text(
                      'Deskripsi Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isNotEmpty
                          ? description
                          : 'Tidak ada deskripsi',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.6,
                          fontSize: 14),
                    ),

                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category,
                                size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Text(
                              'Kategori: $category',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Quantity selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumlah',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: _quantity > 1
                                      ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _quantity > 1
                                          ? const Color(0xFFDC2626)
                                              .withOpacity(0.1)
                                          : Colors.grey.shade50,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(11),
                                        bottomLeft: Radius.circular(11),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 18,
                                      color: _quantity > 1
                                          ? const Color(0xFFDC2626)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Center(
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _quantity < productStock
                                      ? () {
                                          setState(() {
                                            _quantity++;
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _quantity < productStock
                                          ? const Color(0xFFDC2626)
                                              .withOpacity(0.1)
                                          : Colors.grey.shade50,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(11),
                                        bottomRight: Radius.circular(11),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 18,
                                      color: _quantity < productStock
                                          ? const Color(0xFFDC2626)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final cartItem = CartItem(
                        productId: productId,
                        productName: productName,
                        price: productPrice,
                        imageUrl: images.isNotEmpty ? images[0] : '',
                        quantity: _quantity,
                        sellerId: sellerId,
                        sellerName: 'Toko Official',
                        stock: productStock,
                      );

                      cartProvider.addToCart(cartItem);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '$_quantity $productName ditambahkan ke keranjang'),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          action: SnackBarAction(
                            label: 'Lihat',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.pushNamed(context, '/cart');
                            },
                          ),
                        ),
                      );

                      setState(() {
                        _quantity = 1;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isInCart ? Colors.orange : const Color(0xFFDC2626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isInCart
                        ? 'Tambah Lagi (${cartQuantity} di keranjang)'
                        : 'Tambah ke Keranjang',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
