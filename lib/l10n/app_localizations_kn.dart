// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get home => 'ಮನೆ';

  @override
  String get search => 'ಹುಡುಕಿ';

  @override
  String get categories => 'ವರ್ಗಗಳು';

  @override
  String get cart => 'ಕಾರ್ಟ್';

  @override
  String get profile => 'ಪ್ರೊಫೈಲ್';

  @override
  String get favorites => 'ಮೆಚ್ಚಿನವುಗಳು';

  @override
  String get myOrders => 'ನನ್ನ ಆರ್ಡರ್‌ಗಳು';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get add => 'ಸೇರಿಸಿ';

  @override
  String get viewMore => 'ಇನ್ನಷ್ಟು ನೋಡಿ';

  @override
  String get selectLanguage => 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get welcome => 'ಸ್ವಾಗತ,';

  @override
  String get featuredProducts => 'ವೈಶಿಷ್ಟ್ಯಗೊಳಿಸಿದ ಉತ್ಪನ್ನಗಳು';

  @override
  String get seeAll => 'ಎಲ್ಲವನ್ನೂ ನೋಡಿ';

  @override
  String get searchProducts => 'ಉತ್ಪನ್ನಗಳಿಗಾಗಿ ಹುಡುಕಿ...';

  @override
  String get noProducts => 'ಯಾವುದೇ ಉತ್ಪನ್ನಗಳು ಕಂಡುಬಂದಿಲ್ಲ';

  @override
  String get confirmOrder => 'ಆರ್ಡರ್ ದೃಢೀಕರಿಸಿ';

  @override
  String get logout => 'Logout';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get aboutUs => 'About Us';

  @override
  String get myAccount => 'My Account';

  @override
  String get kycVerification => 'KYC Verification';

  @override
  String get kycSubtitle => 'Complete your KYC to unlock wholesale features.';

  @override
  String get completeKyc => 'Complete KYC';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get welcomeToKrishidealer => 'Welcome to\nKrishiDealer';

  @override
  String get indiasTrustedPlatform =>
      'India\'s trusted platform for\nfarmers & retailers';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get phoneNumberHint => 'Phone Number';

  @override
  String get agreeTo => 'I agree to our ';

  @override
  String get termsPrivacyPolicy => 'Terms & Privacy Policy';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyYourNumber => 'Verify Your Number';

  @override
  String enterOtpSentTo(String phoneNumber) {
    return 'Enter the 6-digit code sent to\n+91 $phoneNumber';
  }

  @override
  String resendIn(String seconds) {
    return 'Resend in 00:$seconds';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get changeNumber => 'Change Number';

  @override
  String get verify => 'Verify';

  @override
  String get krishi => 'Krishi';

  @override
  String get dealer => 'Dealer';

  @override
  String get createYourAccount => 'Create Your Account';

  @override
  String get registerSubtitle => 'Register your agro business to get started';

  @override
  String get step1Of2 => 'Step 1 of 2';

  @override
  String get shopName => 'Shop Name';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get email => 'Email';

  @override
  String get addressType => 'Address Type';

  @override
  String get shop => 'Shop';

  @override
  String get godown => 'Godown';

  @override
  String get other => 'Other';

  @override
  String get villageArea => 'Village / Area';

  @override
  String get cityTehsil => 'City / Tehsil';

  @override
  String get pincode => 'Pincode';

  @override
  String get useLocationAutofill => 'Use current location to auto-fill PIN';

  @override
  String get submitDetails => 'Submit Details';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidPincode => 'Invalid Pincode';

  @override
  String get enableLocationServices => 'Please enable location services';

  @override
  String get completeEkyc => 'Complete e-KYC';

  @override
  String get ekycSubtitle =>
      'Secure your account by providing\nbusiness documents';

  @override
  String get step2Of2 => 'Step 2 of 2';

  @override
  String get registeringAs => 'Registering as';

  @override
  String get retailer => 'Retailer';

  @override
  String get distributor => 'Distributor';

  @override
  String get farmer => 'Farmer';

  @override
  String get uploadLicense => 'Upload License Image';

  @override
  String get uploadGst => 'Upload GST Image';

  @override
  String get gstNumber => 'GST Number';

  @override
  String get aadhaarNumber => '12-digit Aadhaar Number';

  @override
  String get completeVerification => 'Complete Verification';

  @override
  String get dataSecureNotice => 'Your data is encrypted and secure.';

  @override
  String get uploadLimitNotice => 'JPG/PNG up to 3MB';

  @override
  String get notifications => 'Notifications';

  @override
  String get shippingAddress => 'Shipping Address';

  @override
  String get addAddress => 'Add Address';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get deliverHere => 'Deliver to this Address';

  @override
  String get fullName => 'Full Name';

  @override
  String get addressLine1 => 'Address Line 1';

  @override
  String get addressLine2Optional => 'Address Line 2 (Optional)';

  @override
  String get cityDistrict => 'City / District';

  @override
  String get state => 'State';

  @override
  String get discard => 'Discard';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get noAddressesFound => 'No addresses found';

  @override
  String get addAddressToContinue => 'Please add an address to continue';

  @override
  String get locationFailed => 'Failed to get location. Please try again.';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get defaultLabel => 'Default';
}
