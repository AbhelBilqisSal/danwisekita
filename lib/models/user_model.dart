/// Model User DanWise.
///
/// Mendukung parsing dari JSON backend yang menggunakan snake_case,
/// serta serialisasi ke JSON (camelCase untuk penyimpanan lokal).
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'buyer', 'seller', 'admin', 'komunitas'
  final String? profilePicture;
  final String? storeName;
  final String? qrisImage;
  final String status;
  final String? komunitasId;
  final int mapActive; // 1 = active, 0 = inactive
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePicture,
    this.storeName,
    this.qrisImage,
    this.status = 'approved',
    this.komunitasId,
    this.mapActive = 1,
    this.latitude,
    this.longitude,
  });

  /// Parse dari JSON backend (snake_case) atau dari local storage (camelCase).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'buyer',
      profilePicture: json['profile_picture']?.toString() ??
          json['profilePicture']?.toString(),
      storeName:
          json['store_name']?.toString() ?? json['storeName']?.toString(),
      qrisImage:
          json['qris_image']?.toString() ?? json['qrisImage']?.toString(),
      status: json['status']?.toString() ?? 'approved',
      komunitasId: json['komunitas_id']?.toString() ?? json['komunitasId']?.toString(),
      mapActive: json['map_active'] is int
          ? json['map_active']
          : (int.tryParse(json['map_active']?.toString() ?? '') ??
              (json['mapActive'] is int
                  ? json['mapActive']
                  : (int.tryParse(json['mapActive']?.toString() ?? '') ?? 1))),
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  /// Serialisasi ke JSON (camelCase untuk local storage).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePicture': profilePicture,
      'storeName': storeName,
      'qrisImage': qrisImage,
      'status': status,
      'komunitasId': komunitasId,
      'mapActive': mapActive,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Membuat salinan UserModel dengan field yang di-update.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? profilePicture,
    String? storeName,
    String? qrisImage,
    String? status,
    String? komunitasId,
    int? mapActive,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      storeName: storeName ?? this.storeName,
      qrisImage: qrisImage ?? this.qrisImage,
      status: status ?? this.status,
      komunitasId: komunitasId ?? this.komunitasId,
      mapActive: mapActive ?? this.mapActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}