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
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}