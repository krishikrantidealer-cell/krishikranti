import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/utils/haptic_util.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingLocation = false;
  bool _isPincodeLoading = false;
  bool _isLoading = false;
  String _selectedAddressType = 'Shop'; // Default
  List<csc.State> _statesList = [];
  List<csc.City> _citiesList = [];
  csc.State? _selectedStateObj;
  csc.City? _selectedCityObj;

  // Controllers for all fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStates();
    _pincodeController.addListener(_onPincodeChanged);
  }

  void _onPincodeChanged() {
    final text = _pincodeController.text;
    if (text.length == 6) {
      _lookupPincode(text);
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isPincodeLoading = true);
    try {
      // Using a public API for Indian Pincodes
      final response = await HttpService.get(
        'https://api.postalpincode.in/pincode/$pincode',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          final String stateName = postOffice['State'];
          final String cityName = postOffice['District'];

          // 1. Match State
          final foundState = _statesList.firstWhere(
            (s) => s.name.toLowerCase() == stateName.toLowerCase(),
            orElse: () => _statesList.firstWhere(
              (s) => stateName.toLowerCase().contains(s.name.toLowerCase()),
              orElse: () =>
                  csc.State(name: stateName, countryCode: 'IN', isoCode: ''),
            ),
          );

          if (foundState.isoCode.isNotEmpty) {
            setState(() {
              _selectedStateObj = foundState;
              _stateController.text = foundState.name;
            });

            // 2. Load Cities for this state
            await _loadCities(foundState.isoCode);

            // 3. Match City
            final foundCity = _citiesList.firstWhere(
              (c) => c.name.toLowerCase() == cityName.toLowerCase(),
              orElse: () => csc.City(
                name: cityName,
                countryCode: 'IN',
                stateCode: foundState.isoCode,
              ),
            );

            setState(() {
              _selectedCityObj = foundCity;
              _cityController.text = foundCity.name;
            });
            HapticUtil.success(); // Stronger feedback for successful auto-fill
          }
        }
      }
    } catch (e) {
      // Silent error for UX
    } finally {
      if (mounted) setState(() => _isPincodeLoading = false);
    }
  }

  Future<void> _loadStates() async {
    final states = await csc.getStatesOfCountry('IN');
    if (mounted) {
      setState(() {
        _statesList = states;
      });
    }
  }

  Future<void> _loadCities(String stateCode) async {
    final cities = await csc.getStateCities('IN', stateCode);
    if (mounted) {
      setState(() {
        _citiesList = cities;
        _selectedCityObj = null;
        _cityController.text = '';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _villageController.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    final l10n = AppLocalizations.of(context)!;
    HapticUtil.medium();
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.enableLocationServices)));
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        HapticUtil.light();
        Placemark place = placemarks[0];
        setState(() {
          _villageController.text = place.subLocality ?? place.name ?? '';
          _pincodeController.text = place.postalCode ?? '';

          String? stateName = place.administrativeArea;
          String? cityName = place.locality;

          if (stateName != null) {
            final foundState = _statesList.firstWhere(
              (s) => s.name.toLowerCase() == stateName.toLowerCase(),
              orElse: () => _statesList.firstWhere(
                (s) => stateName.toLowerCase().contains(s.name.toLowerCase()),
                orElse: () => csc.State(name: stateName, countryCode: 'IN', isoCode: ''),
              ),
            );

            if (foundState.isoCode.isNotEmpty) {
              _selectedStateObj = foundState;
              _stateController.text = foundState.name;
              _loadCities(foundState.isoCode).then((_) {
                if (cityName != null) {
                  final foundCity = _citiesList.firstWhere(
                    (c) => c.name.toLowerCase() == cityName.toLowerCase(),
                    orElse: () => csc.City(name: cityName, countryCode: 'IN', stateCode: foundState.isoCode),
                  );
                  setState(() {
                    _selectedCityObj = foundCity;
                    _cityController.text = foundCity.name;
                  });
                }
              });
            } else {
              _stateController.text = stateName;
              _cityController.text = cityName ?? '';
            }
          }
        });
      }
    } catch (e) {
      // Removed debugPrint for production
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      HapticUtil.error();
      return;
    }

    final installSource = await MetaAnalyticsService.getInstallSource();
    final deepLinkUrl = await MetaAnalyticsService.getDeepLinkUrl();
    final registrationData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'addressType': _selectedAddressType,
      'source': installSource,
      'deepLinkUrl': deepLinkUrl,
      'address': {
        'villageArea': _villageController.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'address2': _addressLine2Controller.text.trim(),
        'cityTehsil': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      },
    };

    try {
      final response = await HttpService.post(
        ApiConstants.register,
        body: registrationData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local profile service
        if (mounted) {
          final profileService = Provider.of<ProfileService>(
            context,
            listen: false,
          );
          await profileService.updateProfile(
            name: '${_firstNameController.text} ${_lastNameController.text}',
            storeName: _selectedAddressType == 'Shop' ? 'My Store' : '',
            phone: '', // Phone is already verified
            pincode: _pincodeController.text,
            address1: _villageController.text,
            address2: _addressLine2Controller.text.trim(),
            city: _cityController.text,
            state: _stateController.text,
          );

          await AuthService.saveUserStatus(
            isProfileComplete: true,
            isKycComplete: await AuthService.isKycComplete(),
          );

          // Log registration completion to Meta/Facebook SDK
          MetaAnalyticsService.logCompletedRegistration(
            registrationMethod: 'Phone SMS',
          );

          HapticUtil.success();
          Navigator.pushNamed(context, '/kyc');
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Registration failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                padding: const EdgeInsets.only(top: 36, bottom: 64),
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
                          width: 40,
                          fit: BoxFit.cover,
                          height: 40,
                        ),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(fontSize: 24),
                            children: [
                              TextSpan(
                                text: l10n.krishi,
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              TextSpan(
                                text: l10n.dealer,
                                style: const TextStyle(
                                  color: Color(0xFFE67E22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.createYourAccount,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.registerSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.step1Of2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 11,
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
              offset: const Offset(0, -64),
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
                        // 1. Identity Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                l10n.firstName,
                                _firstNameController,
                                hint: "First",
                                prefixIcon: Icons.person_outline_rounded,
                                autofillHints: [AutofillHints.givenName],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                l10n.lastName,
                                _lastNameController,
                                hint: "Last",
                                prefixIcon: Icons.person_outline_rounded,
                                autofillHints: [AutofillHints.familyName],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 2. Address Type
                        Text(
                          l10n.addressType,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildAddressTypeSelector(),
                        const SizedBox(height: 14),

                        // 3. Detailed Address Line 1 (Full Width)
                        _buildTextField(
                          l10n.addressLine1,
                          _villageController,
                          hint: l10n.addressHint,
                          prefixIcon: Icons.map_outlined,
                          autofillHints: [AutofillHints.streetAddressLine1],
                        ),
                        const SizedBox(height: 10),

                        // 3b. Detailed Address Line 2 (Optional)
                        _buildTextField(
                          l10n.addressLine2Optional,
                          _addressLine2Controller,
                          hint: l10n.address2Hint,
                          prefixIcon: Icons.map_outlined,
                          isOptional: true,
                          autofillHints: [AutofillHints.streetAddressLine2],
                        ),
                        const SizedBox(height: 10),

                        // 4. State (Full Width)
                        _buildDropdownField<csc.State>(
                          l10n.state,
                          _selectedStateObj,
                          _statesList,
                          (state) => state.name,
                          Icons.map_sharp,
                          (val) {
                            if (val != null) {
                              _selectedStateObj = val;
                              _stateController.text = val.name;
                              _loadCities(val.isoCode);
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // 5. Regional Row (City | Pincode)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "${l10n.pincode} ✨",
                                _pincodeController,
                                hint: "411001",
                                prefixIcon: Icons.pin_drop_outlined,
                                keyboardType: TextInputType.number,
                                autofillHints: [AutofillHints.postalCode],
                                helperText: "Auto-fills City/State",
                                isSearching: _isPincodeLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField<csc.City>(
                                l10n.cityDistrict,
                                _selectedCityObj,
                                _citiesList,
                                (city) => city.name,
                                Icons.location_city_rounded,
                                (val) {
                                  setState(() {
                                    _selectedCityObj = val;
                                    _cityController.text = val?.name ?? '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Use Current Location Button
                        InkWell(
                          onTap: _isLoadingLocation ? null : _getLocation,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.useLocationAutofill,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1B5E20,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.submitDetails,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontSize: 15,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
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
    bool isOptional = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    String? helperText,
    bool isSearching = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (isOptional) return null;
            if (value == null || value.isEmpty) return l10n.fieldRequired;
            if (label.contains(l10n.pincode) && value.length != 6) {
              return l10n.invalidPincode;
            }
            return null;
          },
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint ?? label,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF2E7D32), size: 16)
                : null,
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                : null,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
            helperText: helperText,
            helperStyle: const TextStyle(
              fontSize: 9,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF2E7D32),
                width: 1.2,
              ),
            ),
            errorStyle: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T? value,
    List<T> items,
    String Function(T) itemLabel,
    IconData prefixIcon,
    void Function(T?) onChanged,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        DropdownButtonFormField<T>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? l10n.fieldRequired : null,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF2E7D32), size: 16),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF2E7D32),
                width: 1.2,
              ),
            ),
            errorStyle: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressTypeSelector() {
    final l10n = AppLocalizations.of(context)!;
    final types = [l10n.shop, l10n.home, l10n.godown, l10n.other];
    return DefaultTabController(
      length: types.length,
      initialIndex: 0,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          onTap: (index) {
            HapticUtil.light();
            setState(() {
              _selectedAddressType = types[index];
            });
          },
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF2E7D32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 11),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
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
    path.lineTo(0, size.height - 45);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 45,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
