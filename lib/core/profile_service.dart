import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  String _name = '';
  String _storeName = '';
  String _phone = '';
  String _pincode = '';
  String _address1 = '';
  String _address2 = '';
  String _city = '';
  String _state = '';

  String get name => _name;
  String get storeName => _storeName;
  String get phone => _phone;
  String get pincode => _pincode;
  String get address1 => _address1;
  String get address2 => _address2;
  String get city => _city;
  String get state => _state;

  String get avatarLetter => _name.isNotEmpty ? _name[0].toUpperCase() : 'U';

  String get fullAddress {
    List<String> parts = [];
    if (_address1.isNotEmpty) parts.add(_address1);
    if (_address2.isNotEmpty) parts.add(_address2);
    if (_city.isNotEmpty) parts.add(_city);
    if (_state.isNotEmpty) parts.add(_state);
    if (_pincode.isNotEmpty) parts.add(_pincode);
    return parts.join(', ');
  }

  ProfileService() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? 'Sudhir Singh';
    _storeName = prefs.getString('store_name') ?? 'Singh Agro Store';
    _phone = prefs.getString('phone') ?? '+91 9201896606';
    _pincode = prefs.getString('pincode') ?? '452001';
    _address1 = prefs.getString('address1') ?? 'Shop 12, Krishi Market';
    _address2 = prefs.getString('address2') ?? '';
    _city = prefs.getString('city') ?? 'Indore';
    _state = prefs.getString('state') ?? 'MP';
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String storeName,
    required String phone,
    required String pincode,
    required String address1,
    required String address2,
    required String city,
    required String state,
  }) async {
    _name = name;
    _storeName = storeName;
    _phone = phone;
    _pincode = pincode;
    _address1 = address1;
    _address2 = address2;
    _city = city;
    _state = state;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('store_name', _storeName);
    await prefs.setString('phone', _phone);
    await prefs.setString('pincode', _pincode);
    await prefs.setString('address1', _address1);
    await prefs.setString('address2', _address2);
    await prefs.setString('city', _city);
    await prefs.setString('state', _state);

    notifyListeners();
  }
}
