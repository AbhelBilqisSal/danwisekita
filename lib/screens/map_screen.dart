import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'store_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  
  final LatLng _defaultLocation = const LatLng(-6.9748, 107.6305); // Telkom University
  LatLng? _currentUserLocation;
  List<dynamic> _nearbySellers = [];
  bool _isLoadingLocation = true;
  bool _isLoadingSellers = false;
  Map<String, dynamic>? _selectedSeller;

  @override
  void initState() {
    super.initState();
    _initLocationAndSellers();
  }

  Future<void> _initLocationAndSellers() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    final position = await _determinePosition();
    if (position != null) {
      _currentUserLocation = LatLng(position.latitude, position.longitude);
    } else {
      _currentUserLocation = _defaultLocation;
    }
    
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
      // Pindahkan peta ke posisi user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_currentUserLocation!, 15.0);
        }
      });
      _fetchNearbySellers();
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

  Future<void> _fetchNearbySellers() async {
    if (_currentUserLocation == null) return;
    
    setState(() {
      _isLoadingSellers = true;
    });

    try {
      final sellers = await _apiService.getNearbySellers(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
      );
      if (mounted) {
        setState(() {
          _nearbySellers = sellers;
          _isLoadingSellers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil memuat ${sellers.length} penjual terdekat'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching nearby sellers: $e');
      if (mounted) {
        setState(() {
          _isLoadingSellers = false;
        });
      }
    }
  }

  void _recenterToUser() {
    if (_currentUserLocation != null) {
      _mapController.move(_currentUserLocation!, 15.0);
      _fetchNearbySellers();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    
    // 1. Tambah marker lokasi pembeli saat ini (Biru)
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          point: _currentUserLocation!,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Tambah marker untuk toko/penjual terdekat (Merah/Oranye)
    for (var seller in _nearbySellers) {
      final lat = double.tryParse(seller['latitude']?.toString() ?? '');
      final lng = double.tryParse(seller['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        final isSelected = _selectedSeller != null && _selectedSeller!['id'] == seller['id'];
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 70,
            height: 70,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSeller = seller;
                });
                _mapController.move(LatLng(lat, lng), 15.5);
              },
              child: AnimatedScale(
                scale: isSelected ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: isSelected ? 48 : 42,
                      color: isSelected ? const Color(0xFFDC2626) : Colors.orange.shade700,
                    ),
                    Positioned(
                      bottom: isSelected ? 16 : 13,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.store,
                          size: isSelected ? 16 : 14,
                          color: isSelected ? const Color(0xFFDC2626) : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Peta OpenStreetMap
          _isLoadingLocation
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFDC2626)),
                      SizedBox(height: 16),
                      Text(
                        'Memuat peta & lokasi GPS...',
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                      )
                    ],
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentUserLocation ?? _defaultLocation,
                    initialZoom: 15.0,
                    onTap: (_, __) {
                      if (_selectedSeller != null) {
                        setState(() {
                          _selectedSeller = null;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.danwise',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),

          // Linear Progress Bar saat memuat data penjual
          if (_isLoadingSellers)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: Color(0xFFDC2626),
                backgroundColor: Colors.transparent,
              ),
            ),

          // Floating Action Buttons (Refresh & Recenter)
          if (!_isLoadingLocation)
            Positioned(
              right: 16,
              bottom: _selectedSeller != null ? 210 : 24,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'refresh_sellers',
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    onPressed: _fetchNearbySellers,
                    child: const Icon(Icons.refresh),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'recenter_gps',
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    onPressed: _recenterToUser,
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

          // Panel Info Toko Terpilih di bagian bawah
          if (_selectedSeller != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildSellerDetailCard(_selectedSeller!),
            ),
        ],
      ),
    );
  }

  Widget _buildSellerDetailCard(Map<String, dynamic> seller) {
    final rating = seller['rating'] != null
        ? double.tryParse(seller['rating'].toString()) ?? 4.5
        : 4.5;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Singkat Toko
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    seller['nama_toko'] != null && seller['nama_toko'].toString().isNotEmpty
                        ? seller['nama_toko'].toString()[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              
              // Info Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller['nama_toko']?.toString() ?? 'Toko Terdekat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seller['alamat']?.toString() ?? 'Alamat Toko',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.navigation, color: Colors.blue, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${seller['distance']?.toString() ?? '0.0'} km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tombol Close Panel
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedSeller = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tombol Navigasi ke Toko
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreScreen(seller: seller),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Kunjungi Toko',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
