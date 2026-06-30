import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/models/user_model.dart';
import 'package:krishikranti/core/network/auth_service.dart';

class ProfileService extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // Fallback getters for legacy code support
  String get name => _user?.name ?? '';
  String get storeName => _user?.shopName ?? '';
  String get phone => _user?.phoneNumber ?? '';
  String get pincode => _user?.address?.pincode ?? '';
  String get address1 => _user?.address?.villageArea ?? '';
  String get address2 => _user?.address?.addressLine2 ?? '';
  String get city => _user?.address?.cityTehsil ?? '';
  String get state => _user?.address?.state ?? '';
  String get avatarLetter => _user?.avatarLetter ?? 'U';

  String get fullAddress {
    if (_user?.address == null) return '';
    final addr = _user!.address!;
    List<String> parts = [];
    if (addr.villageArea.isNotEmpty) parts.add(addr.villageArea);
    if (addr.addressLine2 != null && addr.addressLine2!.isNotEmpty)
      parts.add(addr.addressLine2!);
    if (addr.cityTehsil.isNotEmpty) parts.add(addr.cityTehsil);
    if (addr.state != null && addr.state!.isNotEmpty) parts.add(addr.state!);
    if (addr.pincode.isNotEmpty) parts.add(addr.pincode);
    return parts.join(', ');
  }

  ProfileService() {
    _loadProfileFromLocal();
  }

  Future<void> _loadProfileFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user_profile_cache');
    if (userJson != null) {
      _user = UserModel.fromJsonString(userJson);
      notifyListeners();
    }
  }

  Future<void> fetchProfileFromServer() async {
    // Only show loading if we have NO cached data
    if (_user == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await HttpService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final newUser = UserModel.fromJson(data);

        if (newUser.isBlocked) {
          await HttpService.forceLogout();
          return;
        }

        final userMap = data['user'] ?? data;
        final bool isProfileComplete = userMap['isProfileComplete'] ?? true;

        // Update if data is different
        if (userJson(newUser) != userJson(_user)) {
          _user = newUser;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile_cache', newUser.toJson());
          notifyListeners();
        }

        await AuthService.saveUserStatus(
          isProfileComplete: isProfileComplete,
          isKycComplete: newUser.isKycComplete,
        );
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Helper to compare users
  String userJson(UserModel? u) => u?.toJson() ?? '';

  Future<bool> updateProfile({
    required String name,
    required String storeName,
    required String phone,
    required String pincode,
    required String address1,
    required String address2,
    required String city,
    required String state,
  }) async {
    // 1. Optimistic Update
    final newUser = UserModel(
      name: name,
      shopName: storeName,
      phoneNumber: phone,
      address: UserAddress(
        pincode: pincode,
        villageArea: address1,
        cityTehsil: city,
        state: state,
        addressLine2: address2,
      ),
    );

    _user = newUser;
    notifyListeners();

    // 2. Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_cache', newUser.toJson());

    // 3. Background API
    try {
      final names = name.split(' ');
      final firstName = names.isNotEmpty ? names[0] : name;
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final response = await HttpService.patch(
        ApiConstants.profile,
        body: {
          "firstName": firstName,
          "lastName": lastName,
          "shopName": storeName,
          "phoneNumber": phone,
          "address": {
            "villageArea": address1,
            "addressLine2": address2,
            "address2": address2,
            "cityTehsil": city,
            "state": state,
            "pincode": pincode,
          },
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error updating profile: $e");
      return false;
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      final response = await HttpService.post(
        ApiConstants.fcmToken,
        body: {"fcmToken": token},
      );
      if (response.statusCode == 200) {
        debugPrint("✅ FCM Token successfully synced with server.");
      }
    } catch (e) {
      debugPrint("❌ Error syncing FCM Token: $e");
    }
  }
}
