import 'dart:convert';

class UserModel {
  final String name;
  final String shopName;
  final String phoneNumber;
  final UserAddress? address;
  final String? avatarUrl;

  UserModel({
    required this.name,
    required this.shopName,
    required this.phoneNumber,
    this.address,
    this.avatarUrl,
  });

  String get avatarLetter => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested 'user' key if present
    final user = json['user'] ?? json;
    
    final String fName = user['firstName'] ?? '';
    final String lName = user['lastName'] ?? '';
    final String fullName = fName.isNotEmpty ? "$fName $lName".trim() : (user['name'] ?? '');

    return UserModel(
      name: fullName,
      shopName: user['shopName'] ?? user['storeName'] ?? '',
      phoneNumber: user['phoneNumber'] ?? user['phone'] ?? '',
      avatarUrl: user['avatarUrl'],
      address: user['address'] != null ? UserAddress.fromJson(user['address']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shopName': shopName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'address': address?.toMap(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJsonString(String source) => 
      UserModel.fromJson(jsonDecode(source));

  UserModel copyWith({
    String? name,
    String? shopName,
    String? phoneNumber,
    UserAddress? address,
    String? avatarUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class UserAddress {
  final String pincode;
  final String villageArea;
  final String cityTehsil;
  final String? state;
  final String? addressLine2;

  UserAddress({
    required this.pincode,
    required this.villageArea,
    required this.cityTehsil,
    this.state,
    this.addressLine2,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      pincode: json['pincode']?.toString() ?? json['zipCode']?.toString() ?? '',
      villageArea: json['villageArea'] ?? json['address1'] ?? json['addressLine1'] ?? '',
      cityTehsil: json['cityTehsil'] ?? json['city'] ?? json['district'] ?? '',
      state: json['state'] ?? json['province'] ?? '',
      addressLine2: json['addressLine2'] ?? json['address2'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pincode': pincode,
      'villageArea': villageArea,
      'cityTehsil': cityTehsil,
      'state': state,
      'addressLine2': addressLine2,
    };
  }
}
