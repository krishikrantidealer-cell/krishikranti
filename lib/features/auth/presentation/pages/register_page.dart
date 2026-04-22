import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingLocation = false;

  // Controllers for all fields
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void dispose() {
    _shopNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.enableLocationServices)),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _villageController.text = place.subLocality ?? place.name ?? '';
          _cityController.text = place.locality ?? '';
          _pincodeController.text = place.postalCode ?? '';
        });
      }
    } catch (e) {
      // Removed debugPrint for production
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8), // Very light green/white tint
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Layer 1: Green Header Section
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 90),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8F5E9), Color(0xFF81C784)],
                  ),
                ),
                child: Column(
                  children: [
                    // Logo & App Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 50,
                          fit: BoxFit.cover,
                          height: 50,
                        ),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(fontSize: 28),
                            children: [
                              TextSpan(
                                text: l10n.krishi,
                                style: const TextStyle(color: Color(0xFF1B5E20)),
                              ),
                              TextSpan(
                                text: l10n.dealer,
                                style: const TextStyle(color: Color(0xFFE67E22)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.createYourAccount,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.registerSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Text(
                        l10n.step1Of2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Layer 2: Form Card
            Transform.translate(
              offset: const Offset(0, -90),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          l10n.shopName,
                          _shopNameController,
                          prefixIcon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                l10n.firstName,
                                _firstNameController,
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                l10n.lastName,
                                _lastNameController,
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          l10n.email,
                          _emailController,
                          hint: 'example@gmail.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),

                        // Address Type Selector
                        Text(
                          l10n.addressType,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        _buildAddressTypeSelector(),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                l10n.villageArea,
                                _villageController,
                                prefixIcon: Icons.map_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                l10n.cityTehsil,
                                _cityController,
                                prefixIcon: Icons.location_city_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          l10n.pincode,
                          _pincodeController,
                          prefixIcon: Icons.pin_drop_outlined,
                        ),
                        const SizedBox(height: 12),

                        // Use Current Location Button
                        InkWell(
                          onTap: _isLoadingLocation ? null : _getLocation,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoadingLocation)
                                  const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  )
                                else ...[
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF2E7D32),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.useLocationAutofill,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pushNamed(context, '/ekyc');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              l10n.submitDetails,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    IconData? prefixIcon,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.fieldRequired;
        if (label == l10n.pincode && value.length != 6) return l10n.invalidPincode;
        return null;
      },
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF2E7D32), size: 18)
            : null,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        errorStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    final l10n = AppLocalizations.of(context)!;
    final types = [l10n.shop, l10n.home, l10n.godown, l10n.other];
    return DefaultTabController(
      length: types.length,
      initialIndex: 0,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TabBar(
          onTap: (index) {
            // Address type selection handled by TabController index
          },
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF2E7D32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 12),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
          dividerColor: Colors.transparent,
          tabs: types.map((type) => Tab(text: type)).toList(),
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 100, // Deepened the arc dip
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
