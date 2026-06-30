import 'dart:convert';

class UserModel {
  final String name;
  final String shopName;
  final String phoneNumber;
  final UserAddress? address;
  final String? avatarUrl;
  final bool isKycComplete;
  final String kycStatus;
  final String? licenceImage;
  final String? shopImage;
  final String? gstNumber;
  final bool isBlocked;

  UserModel({
    required this.name,
    required this.shopName,
    required this.phoneNumber,
    this.address,
    this.avatarUrl,
    this.isKycComplete = false,
    this.kycStatus = 'pending',
    this.licenceImage,
    this.shopImage,
    this.gstNumber,
    this.isBlocked = false,
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
      isKycComplete: user['isKycComplete'] ?? false,
      kycStatus: user['kycStatus'] ?? 'pending',
      licenceImage: user['licenceImage'],
      shopImage: user['shopImage'],
      gstNumber: user['gstNumber'],
      isBlocked: user['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shopName': shopName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'address': address?.toMap(),
      'isKycComplete': isKycComplete,
      'kycStatus': kycStatus,
      'licenceImage': licenceImage,
      'shopImage': shopImage,
      'gstNumber': gstNumber,
      'isBlocked': isBlocked,
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
    bool? isKycComplete,
    String? kycStatus,
    String? licenceImage,
    String? shopImage,
    String? gstNumber,
    bool? isBlocked,
  }) {
    return UserModel(
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isKycComplete: isKycComplete ?? this.isKycComplete,
      kycStatus: kycStatus ?? this.kycStatus,
      licenceImage: licenceImage ?? this.licenceImage,
      shopImage: shopImage ?? this.shopImage,
      gstNumber: gstNumber ?? this.gstNumber,
      isBlocked: isBlocked ?? this.isBlocked,
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
      'address2': addressLine2,
    };
  }
}
