import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/shipping_address_screen.dart';

class EditAddressScreen extends StatefulWidget {
  final AddressModel? address;
  const EditAddressScreen({super.key, this.address});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
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
    _nameController = TextEditingController(text: widget.address?.name ?? "");
    _phoneController = TextEditingController(text: widget.address?.phone ?? "");
    // Extracting parts from the address string if editing
    // For simplicity in this mock, we'll just pre-fill name and phone and leave address fields for user to fill or use location
    _pincodeController = TextEditingController();
    _addressLine1Controller = TextEditingController();
    _addressLine2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();

    if (widget.address != null) {
      // Very basic parsing for existing address string
      final parts = widget.address!.address.split(', ');
      if (parts.length >= 3) {
         _addressLine1Controller.text = parts[0];
         _cityController.text = parts[parts.length - 3];
         _stateController.text = parts[parts.length - 2].split(' - ')[0];
         _pincodeController.text = parts[parts.length - 2].split(' - ').last;
      } else {
         _addressLine1Controller.text = widget.address!.address;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _pincodeController.text = place.postalCode ?? '';
            _addressLine1Controller.text = "${place.name ?? ''}, ${place.subLocality ?? ''}";
            _cityController.text = place.locality ?? '';
            _stateController.text = place.administrativeArea ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.address != null;
    final l10n = AppLocalizations.of(context)!;

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
                  Expanded(
                    child: Center(
                      child: Text(
                        isEdit ? l10n.editAddress : l10n.addAddress,
                        style: const TextStyle(
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
                      
                      _buildField(l10n.fullName, _nameController, "Enter your full name"),
                      const SizedBox(height: 12),
                      
                      _buildField(l10n.mobileNumber, _phoneController, "9876543210", keyboardType: TextInputType.phone),
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
                          label: Text(
                            l10n.useLocationAutofill,
                            style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildField(l10n.pincode, _pincodeController, "411001", keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      
                      _buildField(l10n.addressLine1, _addressLine1Controller, "House no., Street, Area"),
                      const SizedBox(height: 12),
                      
                      _buildField(l10n.addressLine2Optional, _addressLine2Controller, "Landmark, Colony, etc."),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _buildField(l10n.cityDistrict, _cityController, "Pune")),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(l10n.state, _stateController, "Maharashtra")),
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
                              child: Text(l10n.discard, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final fullAddress = "${_addressLine1Controller.text}, ${_addressLine2Controller.text.isNotEmpty ? "${_addressLine2Controller.text}, " : ""}${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}";
                                  
                                  final newAddress = AddressModel(
                                    id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: _nameController.text,
                                    address: fullAddress,
                                    phone: _phoneController.text,
                                    isDefault: widget.address?.isDefault ?? false,
                                  );
                                  
                                  Navigator.pop(context, newAddress);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: Text(l10n.saveChanges, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
