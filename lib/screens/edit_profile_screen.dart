import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
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
    _nameController = TextEditingController(text: profile.name);
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
    _nameController.dispose();
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
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (!mounted) return;
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (!mounted) return;
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (!mounted) return;
          setState(() {
            _pincodeController.text = place.postalCode ?? '';
            _addressLine1Controller.text = "${place.name}, ${place.subLocality}";
            _cityController.text = place.locality ?? '';
            _stateController.text = place.administrativeArea ?? '';
          });
        }
      }
    } catch (e) {
      // Location error handled silently for production
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get location. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// CUSTOM HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      
                      _buildField("Full Name", _nameController, "Enter your full name"),
                      const SizedBox(height: 12),
                      
                      _buildField("Store Name", _storeController, "Enter your store name"),
                      const SizedBox(height: 12),
                      
                      _buildField("Phone Number", _phoneController, "9876543210", keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),

                      /// LOCATION BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          icon: _isLocating 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))
                              : const Icon(Icons.my_location_outlined, size: 18, color: Color(0xFF2E7D32)),
                          label: const Text(
                            "Use Current Location",
                            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildField("Pincode", _pincodeController, "411001", keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      
                      _buildField("Address Line 1", _addressLine1Controller, "House no., Street, Area"),
                      const SizedBox(height: 12),
                      
                      _buildField("Address Line 2 (Optional)", _addressLine2Controller, "Landmark, Colony, etc."),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _buildField("City / District", _cityController, "Pune")),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField("State", _stateController, "Maharashtra")),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// ACTIONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Discard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final profileService = Provider.of<ProfileService>(context, listen: false);
                                  await profileService.updateProfile(
                                    name: _nameController.text,
                                    storeName: _storeController.text,
                                    phone: _phoneController.text,
                                    pincode: _pincodeController.text,
                                    address1: _addressLine1Controller.text,
                                    address2: _addressLine2Controller.text,
                                    city: _cityController.text,
                                    state: _stateController.text,
                                  );
                                  if (mounted) Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          validator: (value) {
             if (label.contains("Optional")) return null;
             if (value == null || value.isEmpty) return "Required";
             return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: Colors.grey.shade100)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide(color: Colors.grey.shade100)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1)
            ),
          ),
        ),
      ],
    );
  }
}
