import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _qrisImageUrl;
  bool _hasQris = false;

  @override
  void initState() {
    super.initState();
    _loadQris();
  }

  Future<void> _loadQris() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? '';

    if (userId.isNotEmpty) {
      final result = await _apiService.getSellerQris(userId);
      if (result['success'] == true) {
        final data = result['data'];
        String? imageUrl = data['qris_image'];
        setState(() {
          _qrisImageUrl = imageUrl;
          _hasQris = imageUrl != null && imageUrl.isNotEmpty;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadQris() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image == null) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id ?? '';
    final result = await _apiService.uploadQris(image, userId);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _hasQris = true;
        _qrisImageUrl = result['data']['qris_image'];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ QRIS berhasil diupload')),
        );
      }
      _loadQris();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal upload QRIS')),
        );
      }
    }
  }

  Future<void> _deleteQris() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus QRIS'),
        content: const Text('Apakah Anda yakin ingin menghapus QRIS Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.deleteQris();
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        setState(() {
          _hasQris = false;
          _qrisImageUrl = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QRIS berhasil dihapus')),
        );
        _loadQris();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menghapus QRIS')),
        );
      }
    }
  }

  Widget _buildQrisImage() {
    if (_qrisImageUrl != null && _qrisImageUrl!.isNotEmpty) {
      if (_qrisImageUrl!.startsWith('data:image')) {
        try {
          final base64String = _qrisImageUrl!.split(',').last;
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              base64Decode(base64String),
              width: double.infinity,
              height: 240,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildEmptyQRIS();
              },
            ),
          );
        } catch (e) {
          return _buildEmptyQRIS();
        }
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _qrisImageUrl!,
            width: double.infinity,
            height: 240,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFDC2626)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildEmptyQRIS();
            },
          ),
        );
      }
    }
    return _buildEmptyQRIS();
  }

  Widget _buildEmptyQRIS() {
    return CustomPaint(
      painter:
          DashedRectPainter(color: const Color(0xFFDC2626).withOpacity(0.3)),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pilih File QRIS',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Format PNG, JPG max 2MB',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFDC2626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper QRIS active card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Metode Pembayaran QRIS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hasQris
                                    ? 'Sudah aktif & siap digunakan'
                                    : 'Belum aktif, upload foto QRIS',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _hasQris
                                ? Colors.green.shade600
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _hasQris ? 'Aktif' : 'Nonaktif',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Section title
                  const Text(
                    'Unggah QRIS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload gambar kode QRIS toko Anda agar pelanggan dapat membayar pesanan secara instan.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Upload container card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadQris,
                          child: _buildQrisImage(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _uploadQris,
                                icon: const Icon(Icons.cloud_upload_outlined,
                                    size: 20),
                                label: Text(
                                  _hasQris ? 'Ganti Foto QRIS' : 'Unggah QRIS',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            if (_hasQris) ...[
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _deleteQris,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info banners
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFDC2626).withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Kode QRIS yang Anda unggah akan secara otomatis ditampilkan di layar HP pembeli saat mereka melakukan pembayaran via QRIS.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom Painter to draw dashed border around upload container
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    // Simple dash algorithm
    double totalLength = 0.0;
    for (var metric in path.computeMetrics()) {
      totalLength += metric.length;
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = gap;
        if (distance + len < metric.length) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
