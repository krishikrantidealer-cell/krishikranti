import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/main.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _storeController;
  late TextEditingController _phoneController;
  late TextEditingController _pincodeController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileService>(context, listen: false);
    final names = profile.name.split(' ');
    final fName = names.isNotEmpty ? names[0] : '';
    final lName = names.length > 1 ? names.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: fName);
    _lastNameController = TextEditingController(text: lName);
    _storeController = TextEditingController(text: profile.storeName);
    _phoneController = TextEditingController(text: profile.phone);
    _pincodeController = TextEditingController(text: profile.pincode);
    _addressLine1Controller = TextEditingController(text: profile.address1);
    _addressLine2Controller = TextEditingController(text: profile.address2);
    _cityController = TextEditingController(text: profile.city);
    _stateController = TextEditingController(text: profile.state);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _storeController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (!mounted) return;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (!mounted) return;
          setState(() {
            _pincodeController.text = place.postalCode ?? '';
            _addressLine1Controller.text =
                "${place.name}, ${place.subLocality}";
            _cityController.text = place.locality ?? '';
            _stateController.text = place.administrativeArea ?? '';
          });
        }
      }
    } catch (e) {
      // Location error handled silently for production
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to get location. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              /// CUSTOM HEADER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(CupertinoIcons.back, size: 28),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                "First Name",
                                _firstNameController,
                                "First",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                "Last Name",
                                _lastNameController,
                                "Last",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          "Store Name",
                          _storeController,
                          "Enter your store name",
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          "Phone Number",
                          _phoneController,
                          "9876543210",
                          keyboardType: TextInputType.phone,
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        /// LOCATION BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _isLocating ? null : _getCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_outlined,
                                    size: 18,
                                    color: Color(0xFF2E7D32),
                                  ),
                            label: const Text(
                              "Use Current Location",
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildField(
                          "Pincode",
                          _pincodeController,
                          "411001",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          "Address Line 1",
                          _addressLine1Controller,
                          "House no., Street, Area",
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          "Address Line 2 (Optional)",
                          _addressLine2Controller,
                          "Landmark, Colony, etc.",
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                "City / District",
                                _cityController,
                                "Pune",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                "State",
                                _stateController,
                                "Maharashtra",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        /// ACTIONS
                        const SizedBox(height: 24),

                        /// ACTIONS - Simplified Full-Width Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isSaving = true);

                                      // 1. Instant Pop (Optimistic Navigation)
                                      Navigator.pop(context);

                                      // 2. Background Sync
                                      try {
                                        final profileService =
                                            Provider.of<ProfileService>(
                                              context,
                                              listen: false,
                                            );
                                        final success = await profileService
                                            .updateProfile(
                                              name:
                                                  '${_firstNameController.text} ${_lastNameController.text}'
                                                      .trim(),
                                              storeName: _storeController.text,
                                              phone: _phoneController.text,
                                              pincode: _pincodeController.text,
                                              address1:
                                                  _addressLine1Controller.text,
                                              address2:
                                                  _addressLine2Controller.text,
                                              city: _cityController.text,
                                              state: _stateController.text,
                                            );

                                        if (success) {
                                          messengerKey.currentState?.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Profile updated successfully!",
                                              ),
                                              backgroundColor: Color(
                                                0xFF2E7D32,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        debugPrint("Profile sync error: $e");
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: const Color(
                                0xFF2E7D32,
                              ).withValues(alpha: 0.6),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14,
            color: readOnly ? Colors.grey.shade800 : Colors.black87,
            fontWeight: readOnly ? FontWeight.w700 : FontWeight.normal,
          ),
          validator: (value) {
            if (readOnly) return null; // Skip validation for read-only fields
            if (label.contains("Optional")) return null;
            if (value == null || value.isEmpty) return "Required";
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF0F0F0)
                : const Color(0xFFFAFAFA),
            suffixIcon: readOnly
                ? const Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: readOnly
                    ? Colors.grey.shade200
                    : const Color(0xFF2E7D32),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
