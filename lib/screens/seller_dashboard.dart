import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'order_processing.dart';
import 'product_management.dart';
import 'profile_screen.dart';

import 'chat_list_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;
  bool _showMap = false;

  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(-6.9748, 107.6305); // Telkom University
  LatLng? _sellerLocation;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _showMap = (authService.currentUser?.mapActive ?? 1) == 1;
    if (authService.currentUser?.latitude != null && authService.currentUser?.longitude != null) {
      _sellerLocation = LatLng(authService.currentUser!.latitude!, authService.currentUser!.longitude!);
    }
    _loadData();
    if (_showMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initActiveLocation();
      });
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      } 

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error determining location: $e');
      return null;
    }
  }

  Future<void> _toggleMap(bool active) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (active) {
      final position = await _determinePosition();
      LatLng locationToSave;
      
      if (position != null) {
        double lat = position.latitude;
        double lng = position.longitude;
        
        // Snap to Telkom University if too far (e.g. emulator default location in California)
        if ((lat - -6.9748).abs() > 0.2 || (lng - 107.6305).abs() > 0.2) {
          final seed = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
          lat = -6.9748 + ((seed % 10) - 5) * 0.0003;
          lng = 107.6305 + (((seed * 3) % 10) - 5) * 0.0003;
        }
        
        locationToSave = LatLng(lat, lng);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Lokasi GPS didapatkan (Disesuaikan ke Telkom University)')),
          );
        }
      } else {
        locationToSave = _defaultLocation;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak, menggunakan lokasi default (Telkom University)')),
          );
        }
      }
      
      setState(() {
        _sellerLocation = locationToSave;
        _showMap = true;
      });
      
      await authService.updateProfile({
        'map_active': '1',
        'latitude': locationToSave.latitude.toString(),
        'longitude': locationToSave.longitude.toString(),
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(locationToSave, 15.0);
      });
      
    } else {
      setState(() {
        _showMap = false;
      });
      
      await authService.updateProfile({
        'map_active': '0',
      });
    }
  }

  Future<void> _initActiveLocation() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if ((authService.currentUser?.mapActive ?? 1) == 1) {
      final position = await _determinePosition();
      if (position != null) {
        double lat = position.latitude;
        double lng = position.longitude;
        
        // Snap to Telkom University if too far (e.g. emulator default location in California)
        if ((lat - -6.9748).abs() > 0.2 || (lng - 107.6305).abs() > 0.2) {
          final seed = int.tryParse(authService.currentUser?.id ?? '0') ?? 0;
          lat = -6.9748 + ((seed % 10) - 5) * 0.0003;
          lng = 107.6305 + (((seed * 3) % 10) - 5) * 0.0003;
        }
        
        final locationToSave = LatLng(lat, lng);
        if (mounted) {
          setState(() {
            _sellerLocation = locationToSave;
          });
          _mapController.move(locationToSave, 15.0);
        }
        
        await authService.updateProfile({
          'map_active': '1',
          'latitude': locationToSave.latitude.toString(),
          'longitude': locationToSave.longitude.toString(),
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final sellerId = authService.currentUser?.id ?? '1';
    
    _stats = await _apiService.getSellerStats(sellerId);
    _recentOrders = await _apiService.getOrders(sellerId: sellerId, status: 'pending');
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    final screens = [
      _buildDashboard(authService),
      const OrderProcessingScreen(),
      const ProductManagementScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/logo/danwise_logo.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'DanWise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur notifikasi akan segera hadir')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFDC2626),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFDC2626),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Produk Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(AuthService authService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: authService.currentUser?.profilePicture != null &&
                          authService.currentUser!.profilePicture!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            AppConstants.getImageUrl(authService.currentUser!.profilePicture),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                authService.currentUser?.name.isNotEmpty == true
                                    ? authService.currentUser!.name[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            authService.currentUser?.name.isNotEmpty == true
                                ? authService.currentUser!.name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${authService.currentUser?.name ?? 'Penjual'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Premium Seller',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const Text(' 4.8', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Pesanan Masuk',
                  value: '${_stats['pendingOrders'] ?? 0}',
                  change: '+15%',
                  changeColor: Colors.green,
                  icon: Icons.shopping_cart,
                  iconColor: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Pendapatan',
                  value: 'Rp ${_formatNumber(_stats['todayIncome'] ?? 0)}',
                  change: '+12%',
                  changeColor: Colors.green,
                  icon: Icons.monetization_on,
                  iconColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Produk',
                  value: '${_stats['totalProducts'] ?? 0}',
                  change: '+5',
                  changeColor: Colors.green,
                  icon: Icons.inventory,
                  iconColor: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Rating',
                  value: '${_stats['averageRating'] ?? 0}',
                  change: '',
                  changeColor: Colors.green,
                  icon: Icons.star,
                  iconColor: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Tambah Produk',
                  icon: Icons.add_box,
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Lihat Pesanan',
                  icon: Icons.receipt,
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Peta Lokasi Toko Anda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              Row(
                children: [
                  Text(
                    _showMap ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: _showMap ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showMap,
                    onChanged: (value) {
                      _toggleMap(value);
                    },
                    activeColor: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          if (_showMap) ...[
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _sellerLocation ??
                        LatLng(
                          double.tryParse(authService.currentUser?.latitude?.toString() ?? '') ?? _defaultLocation.latitude,
                          double.tryParse(authService.currentUser?.longitude?.toString() ?? '') ?? _defaultLocation.longitude,
                        ),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.danwise',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker Toko Anda (Merah)
                        Marker(
                          point: _sellerLocation ??
                              LatLng(
                                double.tryParse(authService.currentUser?.latitude?.toString() ?? '') ?? _defaultLocation.latitude,
                                double.tryParse(authService.currentUser?.longitude?.toString() ?? '') ?? _defaultLocation.longitude,
                              ),
                          width: 80,
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.store, color: Color(0xFFDC2626), size: 30),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                ),
                                child: Text(
                                  authService.currentUser?.storeName ?? 'Toko Anda',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ] else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Peta lokasi pembeli dinonaktifkan',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Pesanan Terbaru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.length > 3 ? 3 : _recentOrders.length,
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return _buildRecentOrderCard(order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (change.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                change,
                style: TextStyle(
                  fontSize: 10,
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(dynamic order) {
    final items = order['items'] as List;
    final itemNames = items.map((i) => i['product_name']).join(', ');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFFDC2626), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['buyer_name'] ?? 'Pembeli',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimeAgo(DateTime.parse(order['created_at'])),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Baru',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              itemNames,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp ${_formatNumber(order['total_amount'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _apiService.acceptOrder(order['id']);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Terima', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () async {
                        await _apiService.rejectOrder(order['id']);
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text('Tolak', style: TextStyle(color: const Color(0xFFDC2626), fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number is int) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}jt';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(0)}rb';
      }
      return number.toString();
    } else if (number is double) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}jt';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(0)}rb';
      }
      return number.toStringAsFixed(0);
    }
    return number.toString();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }
}

class SellerMapPainter extends CustomPainter {
  final String storeName;

  SellerMapPainter({required this.storeName});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Background (Telkom University Campus Area)
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // 2. Draw mock roads (Jalan Telekomunikasi, Sukabirus, Sukapura)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 16.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 18.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Jalan Telekomunikasi (Horizontal main road)
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), roadBorderPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), roadPaint);

    // Jalan Sukabirus (Vertical left road)
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadBorderPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);

    // Jalan Sukapura (Vertical right road)
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadBorderPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

    // 3. Draw Landmark Texts
    _drawText(canvas, "Jln. Telekomunikasi", Offset(size.width / 2 - 40, size.height / 2 - 16), fontSize: 8, color: Colors.grey.shade500);
    _drawText(canvas, "Sukabirus", Offset(size.width * 0.25 - 20, 10), fontSize: 7, color: Colors.grey.shade400);
    _drawText(canvas, "Sukapura", Offset(size.width * 0.75 - 20, 10), fontSize: 7, color: Colors.grey.shade400);
    _drawText(canvas, "Area Telkom University", Offset(size.width * 0.5 - 50, size.height - 18), fontSize: 8, color: const Color(0xFFDC2626).withOpacity(0.5), fontWeight: FontWeight.bold);

    // 4. Draw Active Area Circle (Telkom University Radius)
    final radiusPaint = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.03)
      ..style = PaintingStyle.fill;
    final radiusBorderPaint = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 65, radiusPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 65, radiusBorderPaint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, {double fontSize = 8, Color color = Colors.black, FontWeight fontWeight = FontWeight.normal}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}