import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';

class AddressModel {
  final String id;
  final String name;
  final String villageArea;
  final String cityTehsil;
  final String? state;
  final String pincode;
  final String phoneNumber;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.villageArea,
    required this.cityTehsil,
    this.state,
    required this.pincode,
    required this.phoneNumber,
    this.isDefault = false,
  });

  String get fullAddress => "$villageArea, $cityTehsil${state != null ? ", $state" : ""} - $pincode";

  AddressModel copyWith({
    String? id,
    String? name,
    String? villageArea,
    String? cityTehsil,
    String? state,
    String? pincode,
    String? phoneNumber,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      villageArea: villageArea ?? this.villageArea,
      cityTehsil: cityTehsil ?? this.cityTehsil,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json, {String? fallbackName}) {
    String addrName = json['name'] ?? '';
    if ((addrName == 'Home / Shop' || addrName.isEmpty) && fallbackName != null && fallbackName.isNotEmpty) {
      addrName = fallbackName;
    }
    return AddressModel(
      id: json['_id'] ?? '',
      name: addrName,
      villageArea: json['villageArea'] ?? '',
      cityTehsil: json['cityTehsil'] ?? '',
      state: json['state'],
      pincode: json['pincode'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'villageArea': villageArea,
    'cityTehsil': cityTehsil,
    'state': state,
    'pincode': pincode,
    'phoneNumber': phoneNumber,
    'isDefault': isDefault,
  };
}

class AddressService extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String _cachedUserName = '';

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;

  void setInitialLocalAddress(AddressModel address) {
    if (_addresses.isEmpty) {
      _addresses = [address];
      _cachedUserName = address.name;
      notifyListeners();
    }
  }

  Future<void> fetchAddresses({bool background = false}) async {
    if (!background) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await HttpService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userObj = data['user'] ?? {};
        final String fName = userObj['firstName'] ?? '';
        final String lName = userObj['lastName'] ?? '';
        final String fullName = fName.isNotEmpty ? "$fName $lName".trim() : (userObj['name'] ?? '');
        if (fullName.isNotEmpty) {
          _cachedUserName = fullName;
        }

        final List addrJson = userObj['shippingAddresses'] ?? [];
        if (addrJson.isNotEmpty) {
          _addresses = addrJson.map((j) => AddressModel.fromJson(j, fallbackName: _cachedUserName)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    } finally {
      if (!background) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    try {
      final response = await HttpService.post(
        ApiConstants.addresses,
        body: address.toJson(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List addrJson = data['addresses'];
        _addresses = addrJson.map((j) => AddressModel.fromJson(j, fallbackName: _cachedUserName)).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding address: $e");
      return false;
    }
  }

  Future<bool> deleteAddress(String id) async {
    try {
      final response = await HttpService.delete(ApiConstants.address(id));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List addrJson = data['addresses'];
        _addresses = addrJson.map((j) => AddressModel.fromJson(j, fallbackName: _cachedUserName)).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting address: $e");
      return false;
    }
  }

  Future<bool> setDefault(String id) async {
    // Optimistic Update: Instantly update UI
    final previousAddresses = List<AddressModel>.from(_addresses);
    _addresses = _addresses.map((addr) {
      return addr.copyWith(isDefault: addr.id == id);
    }).toList();
    notifyListeners();

    try {
      final response = await HttpService.patch(ApiConstants.addressDefault(id));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List addrJson = data['addresses'];
        _addresses = addrJson.map((j) => AddressModel.fromJson(j, fallbackName: _cachedUserName)).toList();
        notifyListeners();
        return true;
      } else {
        // Rollback on failure
        _addresses = previousAddresses;
        notifyListeners();
        debugPrint("Server Error: ${response.body}");
        return false;
      }
    } catch (e) {
      // Rollback on error
      _addresses = previousAddresses;
      notifyListeners();
      debugPrint("Error setting default address: $e");
      return false;
    }
  }
}
