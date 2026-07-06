import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';

class QrisPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String sellerId;

  const QrisPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.sellerId,
  });

  @override
  State<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends State<QrisPaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isPaid = false;
  String? _qrisImageUrl;
  Timer? _statusTimer;
  String? _orderNumber;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPayment() async {
    setState(() => _isLoading = true);
    
    final result = await _apiService.getOrderPayment(widget.orderId);
    
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _orderNumber = data['order_number'];
        _qrisImageUrl = data['seller_qris'] ?? data['qris_image'];
        _isLoading = false;
      });
      
      if (data['status'] == 'paid') {
        setState(() => _isPaid = true);
        _showSuccessDialog();
      } else {
        _startStatusChecking();
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal memuat pembayaran')),
      );
    }
  }

  void _startStatusChecking() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPaid) {
        timer.cancel();
        return;
      }
      
      final result = await _apiService.getOrderPayment(widget.orderId);
      if (result['success'] == true) {
        final status = result['data']['status'];
        if (status == 'paid') {
          timer.cancel();
          setState(() => _isPaid = true);
          _showSuccessDialog();
        }
      }
    });
  }

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);
    final result = await _apiService.confirmPayment(widget.orderId);
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      setState(() => _isPaid = true);
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal konfirmasi pembayaran')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle, size: 60, color: Colors.green.shade600),
            const SizedBox(height: 12),
            const Text('Pembayaran Berhasil! 🎉'),
          ],
        ),
        content: Text(
          'Pesanan #$_orderNumber telah berhasil dibayar.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisImage() {
    if (_qrisImageUrl != null && _qrisImageUrl!.isNotEmpty) {
      if (_qrisImageUrl!.startsWith('data:image')) {
        try {
          final base64String = _qrisImageUrl!.split(',').last;
          return Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                base64Decode(base64String),
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildEmptyQRIS();
                },
              ),
            ),
          );
        } catch (e) {
          return _buildEmptyQRIS();
        }
      } else {
        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _qrisImageUrl!,
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 250,
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildEmptyQRIS();
              },
            ),
          ),
        );
      }
    }
    return _buildEmptyQRIS();
  }

  Widget _buildEmptyQRIS() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'QRIS tidak tersedia',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              'Penjual belum memiliki QRIS',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QRIS Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFDC2626),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Scan QRIS untuk Membayar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Pembayaran: Rp ${_formatNumber(widget.amount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  if (_orderNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pesanan: #$_orderNumber',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildQrisImage(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isPaid 
                          ? Colors.green.shade50 
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPaid 
                              ? Icons.check_circle 
                              : Icons.info_outline,
                          color: _isPaid 
                              ? Colors.green.shade700 
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isPaid 
                                ? '✅ Pembayaran telah dikonfirmasi!'
                                : 'Scan QRIS dengan aplikasi mobile banking atau e-wallet Anda',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPaid 
                                  ? Colors.green.shade700 
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isPaid 
                              ? () => Navigator.pop(context) 
                              : (_qrisImageUrl == null ? null : _confirmPayment),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPaid ? Colors.green : const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isPaid ? '✅ Selesai' : 'Konfirmasi Bayar',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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