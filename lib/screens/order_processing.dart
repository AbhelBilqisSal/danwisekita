import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class OrderProcessingScreen extends StatefulWidget {
  const OrderProcessingScreen({super.key});

  @override
  State<OrderProcessingScreen> createState() => _OrderProcessingScreenState();
}

class _OrderProcessingScreenState extends State<OrderProcessingScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _processingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  final Map<String, bool> _showMaps = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final sellerId = authService.currentUser?.id ?? '1';
    
    final allOrders = await _apiService.getOrders(sellerId: sellerId);
    
    const pendingStatuses = ['pending', 'paid', 'menunggu_verifikasi'];
    _pendingOrders = allOrders
        .where((o) => o != null && pendingStatuses.contains(o['status']))
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    _processingOrders = allOrders
        .where((o) => o != null && o['status'] == 'proses')
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    _completedOrders = allOrders
        .where((o) => o != null && (o['status'] == 'selesai' || o['status'] == 'cancelled'))
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    
    setState(() => _isLoading = false);
  }

  Future<void> _acceptOrder(String orderId) async {
    final result = await _apiService.acceptOrder(orderId);
    if (result['success'] == true) {
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pesanan diterima')),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pesanan'),
        content: const Text('Apakah Anda yakin ingin menolak pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final result = await _apiService.rejectOrder(orderId);
      if (result['success'] == true) {
        await _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Pesanan ditolak')),
          );
        }
      }
    }
  }

  Future<void> _completeOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Pesanan'),
        content: const Text('Apakah pesanan sudah selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Selesai', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final result = await _apiService.completeOrder(orderId);
      if (result['success'] == true) {
        await _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Pesanan selesai')),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> get _currentOrders {
    switch (_selectedTab) {
      case 0:
        return _pendingOrders;
      case 1:
        return _processingOrders;
      default:
        return _completedOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFDC2626),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Menunggu', _pendingOrders.length),
                _buildTabButton(1, 'Diproses', _processingOrders.length),
                _buildTabButton(2, 'Selesai', _completedOrders.length),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada pesanan',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: const Color(0xFFDC2626),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _currentOrders.length,
                          itemBuilder: (context, index) {
                            final order = _currentOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, int count) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDC2626) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$title ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final items = order['items'] as List;
    final totalItems = items.fold(0, (sum, item) {
      final q = item['quantity'];
      final qVal = q is int ? q : (int.tryParse(q.toString()) ?? 0);
      return sum + qVal;
    });
    final isCompleted = order['status'] == 'selesai';
    final isRejected = order['status'] == 'cancelled';
    final isFinished = isCompleted || isRejected;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isFinished ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFinished
            ? BorderSide(
                color: isCompleted
                    ? Colors.green.shade200
                    : Colors.red.shade200,
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isFinished
                              ? (isCompleted
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1))
                              : const Color(0xFFDC2626).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFinished
                              ? (isCompleted ? Icons.check_circle : Icons.cancel)
                              : Icons.person,
                          color: isFinished
                              ? (isCompleted ? Colors.green : Colors.red)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['buyer_name'] ?? 'Pembeli',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatDateTime(order['created_at']),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(order['status']),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(order['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Item list with better formatting
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['product_name']}',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'x${item['quantity']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Item',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        '$totalItems item',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Completed/Rejected status banner
            if (isFinished) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.verified : Icons.block,
                      color: isCompleted ? Colors.green.shade600 : Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompleted
                                ? 'Pesanan Selesai'
                                : 'Pesanan Ditolak',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCompleted
                                ? 'Pesanan telah berhasil diselesaikan'
                                : 'Pesanan telah ditolak oleh penjual',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCompleted
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (order['status'] == 'proses') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Peta Lokasi Pengiriman',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Text(
                        _showMaps[order['id'].toString()] == true ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: _showMaps[order['id'].toString()] == true ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _showMaps[order['id'].toString()] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _showMaps[order['id'].toString()] = value;
                          });
                        },
                        activeColor: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ],
              ),
              if (_showMaps[order['id'].toString()] == true) ...[
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MapGridPainter(),
                          ),
                        ),
                        Positioned(
                          left: 30,
                          top: 40,
                          child: Column(
                            children: [
                              const Icon(Icons.store, color: Color(0xFFDC2626), size: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
                                ),
                                child: const Text('Toko', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 40,
                          bottom: 30,
                          child: Column(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue, size: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
                                ),
                                child: const Text('Pembeli', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.navigation, size: 10, color: Color(0xFFDC2626)),
                                SizedBox(width: 4),
                                Text(
                                  'Jarak: 1.5 km (10 mnt)',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pesanan',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Rp ${_formatNumber(order['total_amount'])}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? Colors.green.shade700
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                if (['pending', 'paid', 'menunggu_verifikasi'].contains(order['status']))
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _acceptOrder(order['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Terima'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _rejectOrder(order['id']),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                if (order['status'] == 'proses')
                  ElevatedButton(
                    onPressed: () => _completeOrder(order['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Selesaikan Pesanan'),
                  ),
                if (isFinished)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: isCompleted
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? 'Selesai' : 'Ditolak',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'paid':
      case 'menunggu_verifikasi':
        return Colors.orange.shade100;
      case 'proses':
        return Colors.blue.shade100;
      case 'selesai':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'pending':
      case 'paid':
      case 'menunggu_verifikasi':
        return Colors.orange.shade700;
      case 'proses':
        return Colors.blue.shade700;
      case 'selesai':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'paid':
        return 'Sudah Dibayar';
      case 'menunggu_verifikasi':
        return 'Menunggu Verifikasi';
      case 'proses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      case 'cancelled':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final double parsed = double.tryParse(number.toString()) ?? 0.0;
    final int num = parsed.toInt();
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw main road
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final roadBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(30 + 12, 40 + 12)
      ..quadraticBezierTo(size.width / 2, size.height / 3, size.width - 40 - 12, size.height - 30 - 12);

    canvas.drawPath(path, roadBorderPaint);
    canvas.drawPath(path, roadPaint);

    // Draw route line (red)
    final routePaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePath = Path()
      ..moveTo(30 + 12, 40 + 12)
      ..quadraticBezierTo(size.width / 2, size.height / 3, size.width - 40 - 12, size.height - 30 - 12);

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}