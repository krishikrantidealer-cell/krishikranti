import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EkycPage extends StatefulWidget {
  const EkycPage({super.key});

  @override
  State<EkycPage> createState() => _EkycPageState();
}

class _EkycPageState extends State<EkycPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'Retailer';

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _aadhaarNumberController =
      TextEditingController();

  File? _licenseImage;
  File? _gstImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'license') {
          _licenseImage = File(image.path);
        } else if (type == 'gst') {
          _gstImage = File(image.path);
        }
      });
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _gstNumberController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Layer 1: Green Header Section (Matching other screens)
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40, bottom: 80),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8F5E9), Color(0xFF81C784)],
                  ),
                ),
                child: Column(
                  children: [
                    // Logo & App Name (Matching Phone Verify Page)
                    Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete e-KYC',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Secure your account by providing\nbusiness documents',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Step 2 of 2',
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

            // Layer 2: Main Form Card
            Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
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
                        Text(
                          'Registering as',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildRoleSelector(),
                        const SizedBox(height: 16),
                        ..._buildDynamicFields(),
                        const SizedBox(height: 20),
                        // Professional Submit Button
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
                                color: const Color(0xFF1B5E20).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/dashboard',
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Complete Verification',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.verified_user,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Your data is encrypted and secure.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
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

  Widget _buildRoleSelector() {
    final roles = ['Retailer', 'Distributor', 'Farmer'];
    return DefaultTabController(
      length: roles.length,
      initialIndex: roles.indexOf(_selectedRole),
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TabBar(
              onTap: (index) => setState(() => _selectedRole = roles[index]),
              labelPadding: EdgeInsets.zero,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1B5E20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontSize: 13),
              unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: roles.map((role) => Tab(text: role)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    if (_selectedRole == 'Retailer') {
      return [
        _buildTextField(
          'Shop Name',
          _shopNameController,
          prefixIcon: Icons.storefront_rounded,
        ),
        const SizedBox(height: 12),
        _buildUploadArea(
          'Upload License Image',
          _licenseImage,
          () => _pickImage('license'),
        ),
      ];
    } else if (_selectedRole == 'Distributor') {
      return [
        _buildTextField(
          'Shop Name',
          _shopNameController,
          prefixIcon: Icons.storefront_rounded,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'GST Number',
          _gstNumberController,
          prefixIcon: Icons.assignment_turned_in_outlined,
        ),
        const SizedBox(height: 12),
        _buildUploadArea(
          'Upload GST Image',
          _gstImage,
          () => _pickImage('gst'),
        ),
        const SizedBox(height: 12),
        _buildUploadArea(
          'Upload License Image',
          _licenseImage,
          () => _pickImage('license'),
        ),
      ];
    } else {
      return [
        _buildTextField(
          '12-digit Aadhaar Number',
          _aadhaarNumberController,
          prefixIcon: Icons.badge_outlined,
        ),
      ];
    }
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF1B5E20), size: 20)
            : null,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
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
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        return null;
      },
    );
  }

  Widget _buildUploadArea(String label, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: image != null ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null
                ? const Color(0xFF1B5E20)
                : Colors.grey.shade200,
            width: image != null ? 1.5 : 1,
          ),
          boxShadow: image != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  image,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else ...[
              const Icon(
                Icons.upload_rounded,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'JPG/PNG up to 3MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20, // Less dip for compact look
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
