class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profilePicture;
  final String? storeName;
  final String? qrisImage;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePicture,
    this.storeName,
    this.qrisImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'buyer',
      profilePicture: json['profilePicture'] ?? json['profile_picture'],
      storeName: json['storeName'] ?? json['store_name'],
      qrisImage: json['qrisImage'] ?? json['qris_image'],
    );
  }

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
    };
  }
}