import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcome;

  /// No description provided for @featuredProducts.
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get featuredProducts;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProducts;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @kycVerification.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycVerification;

  /// No description provided for @kycSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your KYC to unlock wholesale features.'**
  String get kycSubtitle;

  /// No description provided for @completeKyc.
  ///
  /// In en, this message translates to:
  /// **'Complete KYC'**
  String get completeKyc;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @welcomeToKrishidealer.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nKrishiDealer'**
  String get welcomeToKrishidealer;

  /// No description provided for @indiasTrustedPlatform.
  ///
  /// In en, this message translates to:
  /// **'India\'s trusted platform for\nfarmers & retailers'**
  String get indiasTrustedPlatform;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberHint;

  /// No description provided for @agreeTo.
  ///
  /// In en, this message translates to:
  /// **'I agree to our '**
  String get agreeTo;

  /// No description provided for @termsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy Policy'**
  String get termsPrivacyPolicy;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyYourNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Number'**
  String get verifyYourNumber;

  /// No description provided for @enterOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to\n+91 {phoneNumber}'**
  String enterOtpSentTo(String phoneNumber);

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in 00:{seconds}'**
  String resendIn(String seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get changeNumber;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @krishi.
  ///
  /// In en, this message translates to:
  /// **'Krishi'**
  String get krishi;

  /// No description provided for @dealer.
  ///
  /// In en, this message translates to:
  /// **'Dealer'**
  String get dealer;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your agro business to get started'**
  String get registerSubtitle;

  /// No description provided for @step1Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get step1Of2;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @addressType.
  ///
  /// In en, this message translates to:
  /// **'Address Type'**
  String get addressType;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @godown.
  ///
  /// In en, this message translates to:
  /// **'Godown'**
  String get godown;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @villageArea.
  ///
  /// In en, this message translates to:
  /// **'Village / Area'**
  String get villageArea;

  /// No description provided for @cityTehsil.
  ///
  /// In en, this message translates to:
  /// **'City / Tehsil'**
  String get cityTehsil;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode;

  /// No description provided for @useLocationAutofill.
  ///
  /// In en, this message translates to:
  /// **'Use current location to auto-fill PIN'**
  String get useLocationAutofill;

  /// No description provided for @submitDetails.
  ///
  /// In en, this message translates to:
  /// **'Submit Details'**
  String get submitDetails;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidPincode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Pincode'**
  String get invalidPincode;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get enableLocationServices;

  /// No description provided for @completeEkyc.
  ///
  /// In en, this message translates to:
  /// **'Complete e-KYC'**
  String get completeEkyc;

  /// No description provided for @ekycSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your account by providing\nbusiness documents'**
  String get ekycSubtitle;

  /// No description provided for @step2Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2'**
  String get step2Of2;

  /// No description provided for @registeringAs.
  ///
  /// In en, this message translates to:
  /// **'Registering as'**
  String get registeringAs;

  /// No description provided for @retailer.
  ///
  /// In en, this message translates to:
  /// **'Retailer'**
  String get retailer;

  /// No description provided for @distributor.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get distributor;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @uploadLicense.
  ///
  /// In en, this message translates to:
  /// **'Upload License Image'**
  String get uploadLicense;

  /// No description provided for @uploadGst.
  ///
  /// In en, this message translates to:
  /// **'Upload GST Image'**
  String get uploadGst;

  /// No description provided for @gstNumber.
  ///
  /// In en, this message translates to:
  /// **'GST Number'**
  String get gstNumber;

  /// No description provided for @aadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'12-digit Aadhaar Number'**
  String get aadhaarNumber;

  /// No description provided for @completeVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete Verification'**
  String get completeVerification;

  /// No description provided for @dataSecureNotice.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and secure.'**
  String get dataSecureNotice;

  /// No description provided for @uploadLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'JPG/PNG up to 3MB'**
  String get uploadLimitNotice;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @deliverHere.
  ///
  /// In en, this message translates to:
  /// **'Deliver to this Address'**
  String get deliverHere;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2Optional.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (Optional)'**
  String get addressLine2Optional;

  /// No description provided for @cityDistrict.
  ///
  /// In en, this message translates to:
  /// **'City / District'**
  String get cityDistrict;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @noAddressesFound.
  ///
  /// In en, this message translates to:
  /// **'No addresses found'**
  String get noAddressesFound;

  /// No description provided for @addAddressToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please add an address to continue'**
  String get addAddressToContinue;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location. Please try again.'**
  String get locationFailed;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
