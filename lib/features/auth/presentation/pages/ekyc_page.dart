import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/utils/haptic_util.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';

class EkycPage extends StatefulWidget {
  const EkycPage({super.key});

  @override
  State<EkycPage> createState() => _EkycPageState();
}

class _EkycPageState extends State<EkycPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();

  File? _licenseImage;
  File? _shopImage;
  bool _isLicenseDeleted = false;
  bool _isShopImageDeleted = false;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  double _uploadProgress = 0;
  String _loadingMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileService>(context, listen: false).fetchProfileFromServer();
    });
  }

  Future<void> _pickImage(ImageSource source, bool isLicense) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Slightly lower for faster initial pick
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        HapticUtil.success();
        setState(() {
          if (isLicense) {
            _licenseImage = File(image.path);
            _isLicenseDeleted = false;
          } else {
            _shopImage = File(image.path);
            _isShopImageDeleted = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _pickDocument(bool isLicense) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        HapticUtil.success();
        setState(() {
          if (isLicense) {
            _licenseImage = File(result.files.single.path!);
            _isLicenseDeleted = false;
          } else {
            _shopImage = File(result.files.single.path!);
            _isShopImageDeleted = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking document: $e");
    }
  }

  bool _isPdf(String filePath) {
    return path.extension(filePath).toLowerCase() == '.pdf';
  }

  void _removeImage(bool isLicense) {
    // Stronger feedback for a destructive action
    HapticUtil.error();
    setState(() {
      if (isLicense) {
        _licenseImage = null;
        _isLicenseDeleted = true;
      } else {
        _shopImage = null;
        _isShopImageDeleted = true;
      }
    });
  }

  void _showFullImage(File? image) {
    if (image == null) return;
    // Medium is better for general selection
    HapticUtil.medium();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(image, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullRemoteImage(String url) {
    if (url.isEmpty) return;
    HapticUtil.medium();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: url.toLowerCase().endsWith('.pdf')
                  ? Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.redAccent,
                            size: 64,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "PDF Document Details",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions(bool isLicense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isLicense);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isLicense);
                },
              ),
              if (isLicense)
                ListTile(
                  leading: const Icon(
                    Icons.description_rounded,
                    color: Color(0xFF2E7D32),
                  ),
                  title: const Text(
                    'Document (PDF, Word, Image)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickDocument(isLicense);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileService = Provider.of<ProfileService>(context);
    final user = profileService.user;

    final bool hasSubmitted =
        user != null &&
        user.licenceImage != null &&
        user.licenceImage!.isNotEmpty;
    final bool isReadOnly =
        (user?.isKycComplete == true) ||
        (hasSubmitted && user?.kycStatus != 'rejected');

    if (isReadOnly) {
      if (_shopNameController.text.isEmpty && user?.shopName != null) {
        _shopNameController.text = user!.shopName;
      }
      if (_gstNumberController.text.isEmpty && user?.gstNumber != null) {
        _gstNumberController.text = user!.gstNumber!;
      }
    }

    final String uploadShopImageText;
    final String currentLocale = Localizations.localeOf(context).languageCode;
    switch (currentLocale) {
      case 'te':
        uploadShopImageText = 'షాప్ చిత్రాన్ని అప్‌లోడ్ చేయండి';
        break;
      case 'ta':
        uploadShopImageText = 'கடை புகைப்படத்தைப் பதிவேற்றவும்';
        break;
      case 'hi':
        uploadShopImageText = 'दुकान की तस्वीर अपलोड करें';
        break;
      case 'kn':
        uploadShopImageText = 'ಅಂಗಡಿಯ ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಿ';
        break;
      case 'mr':
        uploadShopImageText = 'दुकान फोटो अपलोड करा';
        break;
      default:
        uploadShopImageText = 'Upload Shop Image';
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        body: Stack(
          children: [
            SingleChildScrollView(
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
                          // Logo & App Name
                          Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.completeEkyc,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(fontSize: 28, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              l10n.ekycSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
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
                              l10n.step2Of2,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
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
                              if (isReadOnly) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (user?.isKycComplete == true)
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (user?.isKycComplete == true)
                                          ? const Color(0xFF81C784)
                                          : const Color(0xFFFFB74D),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        (user?.isKycComplete == true)
                                            ? Icons.check_circle_rounded
                                            : Icons.info_rounded,
                                        color: (user?.isKycComplete == true)
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFE65100),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          (user?.isKycComplete == true)
                                              ? "Your KYC is fully verified and active. You are a registered dealer."
                                              : "Documents under review",
                                          style: TextStyle(
                                            color: (user?.isKycComplete == true)
                                                ? const Color(0xFF1B5E20)
                                                : const Color(0xFFE65100),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF81C784,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        color: Color(0xFF2E7D32),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Retailer & Distributor",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1B5E20),
                                              letterSpacing: 0.3,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                l10n.shopName,
                                _shopNameController,
                                prefixIcon: Icons.storefront_rounded,
                                enabled: !isReadOnly,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                l10n.gstNumber,
                                _gstNumberController,
                                prefixIcon: Icons.assignment_turned_in_outlined,
                                isGst: true,
                                isOptional: true,
                                enabled: !isReadOnly,
                              ),
                              const SizedBox(height: 28),
                              _buildUploadArea(
                                l10n.uploadLicense,
                                _licenseImage,
                                _isLicenseDeleted ? null : user?.licenceImage,
                                isReadOnly,
                                () => _showImagePickerOptions(true),
                                () => _removeImage(true),
                              ),
                              const SizedBox(height: 16),
                              _buildUploadArea(
                                uploadShopImageText,
                                _shopImage,
                                _isShopImageDeleted ? null : user?.shopImage,
                                isReadOnly,
                                () => _showImagePickerOptions(false),
                                () => _removeImage(false),
                              ),
                              if (!isReadOnly) ...[
                                const SizedBox(height: 32),
                                // Professional Submit Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1B5E20),
                                        Color(0xFF2E7D32),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1B5E20,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              final bool hasLicense = _licenseImage != null ||
                                                  (user?.licenceImage != null &&
                                                      user!.licenceImage!.isNotEmpty &&
                                                      !_isLicenseDeleted);
                                              final bool hasShop = _shopImage != null ||
                                                  (user?.shopImage != null &&
                                                      user!.shopImage!.isNotEmpty &&
                                                      !_isShopImageDeleted);

                                              if (!hasLicense) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Please upload your business license",
                                                    ),
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                  ),
                                                );
                                                return;
                                              }

                                              if (!hasShop) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Please upload your shop image",
                                                    ),
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                  ),
                                                );
                                                return;
                                              }

                                              // Pre-upload validation for file types
                                              final allowedExtensions = [
                                                '.jpg',
                                                '.jpeg',
                                                '.png',
                                                '.pdf',
                                                '.doc',
                                                '.docx',
                                              ];

                                              String? extLic;
                                              if (_licenseImage != null) {
                                                extLic = path
                                                    .extension(
                                                      _licenseImage!.path,
                                                    )
                                                    .toLowerCase();
                                                if (!allowedExtensions.contains(
                                                  extLic,
                                                )) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                        "License document has invalid file type.",
                                                      ),
                                                      backgroundColor:
                                                          Colors.orange.shade800,
                                                    ),
                                                  );
                                                  return;
                                                }
                                              }

                                              String? extShop;
                                              if (_shopImage != null) {
                                                extShop = path
                                                    .extension(_shopImage!.path)
                                                    .toLowerCase();
                                                if (!allowedExtensions.contains(
                                                  extShop,
                                                )) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                        "Shop image has invalid file type.",
                                                      ),
                                                      backgroundColor:
                                                          Colors.orange.shade800,
                                                    ),
                                                  );
                                                  return;
                                                }
                                              }

                                              setState(() {
                                                _isLoading = true;
                                                _uploadProgress = 0;
                                                _loadingMessage =
                                                    "Optimizing document...";
                                              });
                                              HapticUtil.medium();

                                              try {
                                                String? finalLicensePath =
                                                    _licenseImage?.path;
                                                String? finalShopPath =
                                                    _shopImage?.path;

                                                // Compress license if it's an image
                                                if (finalLicensePath != null && extLic != null && [
                                                  '.jpg',
                                                  '.jpeg',
                                                  '.png',
                                                ].contains(extLic)) {
                                                  final tempDir =
                                                      await getTemporaryDirectory();
                                                  final targetPath = path.join(
                                                    tempDir.path,
                                                    "compressed_license_${DateTime.now().millisecondsSinceEpoch}$extLic",
                                                  );

                                                  final compressedFile =
                                                      await FlutterImageCompress.compressAndGetFile(
                                                        finalLicensePath,
                                                        targetPath,
                                                        quality: 60,
                                                      );

                                                  if (compressedFile != null) {
                                                    finalLicensePath =
                                                        compressedFile.path;
                                                  }
                                                }

                                                // Compress shop image if it's an image
                                                if (finalShopPath != null && extShop != null && [
                                                  '.jpg',
                                                  '.jpeg',
                                                  '.png',
                                                ].contains(extShop)) {
                                                  final tempDir =
                                                      await getTemporaryDirectory();
                                                  final targetPath = path.join(
                                                    tempDir.path,
                                                    "compressed_shop_${DateTime.now().millisecondsSinceEpoch}$extShop",
                                                  );

                                                  final compressedFile =
                                                      await FlutterImageCompress.compressAndGetFile(
                                                        finalShopPath,
                                                        targetPath,
                                                        quality: 60,
                                                      );

                                                  if (compressedFile != null) {
                                                    finalShopPath =
                                                        compressedFile.path;
                                                  }
                                                }

                                                setState(() {
                                                  _loadingMessage =
                                                      "Uploading to secure server...";
                                                });

                                                final response =
                                                    await HttpService.uploadFiles(
                                                      ApiConstants.kyc,
                                                      fields: {
                                                        'shopName':
                                                            _shopNameController
                                                                .text
                                                                .trim(),
                                                        'gstNumber':
                                                            _gstNumberController
                                                                .text
                                                                .trim()
                                                                .toUpperCase(),
                                                        'userType':
                                                            'Retailer and Distributor',
                                                      },
                                                      files: {
                                                        if (finalLicensePath != null)
                                                          'licenceImage':
                                                              finalLicensePath,
                                                        if (finalShopPath != null)
                                                          'shopImage':
                                                              finalShopPath,
                                                      },
                                                      onProgress:
                                                          (sent, total) {
                                                            setState(() {
                                                              _uploadProgress =
                                                                  sent / total;
                                                            });
                                                          },
                                                    );

                                                if (response.statusCode ==
                                                        200 ||
                                                    response.statusCode ==
                                                        201) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isLoading = false;
                                                      _uploadProgress = 1.0;
                                                    });
                                                    await AuthService.saveUserStatus(
                                                      isProfileComplete: true,
                                                      isKycComplete: false,
                                                    );
                                                    MetaAnalyticsService.logKycSubmitted(
                                                      kycType: 'Retailer and Distributor',
                                                    );
                                                    HapticUtil.success();
                                                    Navigator.pushNamedAndRemoveUntil(
                                                      context,
                                                      '/dashboard',
                                                      (route) => false,
                                                    );
                                                  }
                                                } else {
                                                  throw Exception(
                                                    'Failed to upload KYC documents',
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  setState(
                                                    () => _isLoading = false,
                                                  );

                                                  String errorMessage = e
                                                      .toString();
                                                  if (errorMessage.contains(
                                                    'DioException',
                                                  )) {
                                                    errorMessage =
                                                        "Network error. Please check your connection.";
                                                  }

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        errorMessage,
                                                      ),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: _uploadProgress > 0
                                                      ? _uploadProgress
                                                      : null,
                                                  backgroundColor:
                                                      Colors.white24,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                  minHeight: 4,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _loadingMessage,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                l10n.completeVerification,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
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
                                    l10n.dataSecureNotice,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Premium Skip Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.5),
                    child: InkWell(
                      onTap: () {
                        HapticUtil.light();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/dashboard',
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Skip",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: const Color(0xFF1B5E20),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF1B5E20),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
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
    String hint,
    TextEditingController controller, {
    IconData? prefixIcon,
    bool isGst = false,
    bool isOptional = false,
    bool enabled = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: enabled ? null : Colors.grey.shade700,
      ),
      decoration: InputDecoration(
        labelText: isOptional ? "$hint (Optional)" : hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: enabled ? const Color(0xFF1B5E20) : Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
        hintText: isOptional ? "Enter $hint (Optional)" : "Enter $hint",
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled ? const Color(0xFF1B5E20) : Colors.grey.shade500,
                size: 20,
              )
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
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
        ),
        counterText: "",
      ),
      autocorrect: !isGst,
      enableSuggestions: !isGst,
      textCapitalization: isGst
          ? TextCapitalization.characters
          : TextCapitalization.none,
      inputFormatters: isGst ? [UpperCaseTextFormatter()] : null,
      maxLength: isGst ? 15 : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (isOptional) return null;
          return l10n.fieldRequired;
        }
        if (hint == l10n.gstNumber) {
          // Standard Indian GST Regex
          final gstRegex = RegExp(
            r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
          );
          if (!gstRegex.hasMatch(value.toUpperCase())) {
            return "Invalid GST Format (e.g. 22AAAAA0000A1Z5)";
          }
        }
        return null;
      },
    );
  }

  Widget _buildUploadArea(
    String label,
    File? image,
    String? remoteUrl,
    bool isReadOnly,
    VoidCallback onTap,
    VoidCallback onRemove,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final bool hasImage =
        image != null || (remoteUrl != null && remoteUrl.isNotEmpty);

    return GestureDetector(
      onTap: hasImage
          ? () {
              if (image != null) {
                _showFullImage(image);
              } else if (remoteUrl != null) {
                _showFullRemoteImage(remoteUrl);
              }
            }
          : (isReadOnly ? null : onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasImage ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? const Color(0xFF1B5E20) : Colors.grey.shade200,
            width: hasImage ? 1.5 : 1,
          ),
          boxShadow: hasImage
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: hasImage
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: image != null
                          ? (!_isPdf(image.path) &&
                                    !['.jpg', '.jpeg', '.png'].contains(
                                      path.extension(image.path).toLowerCase(),
                                    )
                                ? Container(
                                    color: Colors.grey.shade100,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.article_rounded,
                                          color: Colors.blueAccent,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            path.basename(image.path),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _isPdf(image.path)
                                ? Container(
                                    color: Colors.grey.shade100,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.picture_as_pdf_rounded,
                                          color: Colors.redAccent,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            path.basename(image.path),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade700,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(image, fit: BoxFit.cover))
                          : (remoteUrl!.toLowerCase().endsWith('.pdf')
                                ? Container(
                                    color: Colors.grey.shade100,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf_rounded,
                                          color: Colors.redAccent,
                                          size: 48,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Business Licence PDF",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF616161),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.network(
                                    remoteUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey.shade100,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                  )),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Semantics(
                        label: "View fullscreen image",
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    if (!isReadOnly)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            _buildCircleButton(
                              icon: Icons.edit_rounded,
                              color: Colors.blue.shade600,
                              onTap: onTap,
                              label: "Edit image",
                            ),
                            const SizedBox(width: 8),
                            _buildCircleButton(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red.shade600,
                              onTap: onRemove,
                              label: "Remove image",
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isReadOnly ? "Uploaded" : "Selected",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : CustomPaint(
                  painter: DashedBorderPainter(
                    color: Colors.grey.shade300,
                    strokeWidth: 1.5,
                    gap: 5,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_a_photo_rounded,
                            color: isReadOnly
                                ? Colors.grey.shade400
                                : const Color(0xFF2E7D32),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isReadOnly
                                ? Colors.grey.shade400
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isReadOnly
                              ? "Upload disabled"
                              : l10n.tapToUploadNotice,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(15),
        ),
      );

    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => false;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
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
