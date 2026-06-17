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
  /// **'Upload License Document'**
  String get uploadLicense;

  /// No description provided for @uploadGst.
  ///
  /// In en, this message translates to:
  /// **'Upload GST Document'**
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
  /// **'Only images, PDFs, and Word documents are allowed!'**
  String get uploadLimitNotice;

  /// No description provided for @tapToUploadNotice.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUploadNotice;

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

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get readAll;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @tabOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get tabOffers;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noOrderUpdatesYet.
  ///
  /// In en, this message translates to:
  /// **'No order updates yet'**
  String get noOrderUpdatesYet;

  /// No description provided for @noOffersRightNow.
  ///
  /// In en, this message translates to:
  /// **'No offers right now'**
  String get noOffersRightNow;

  /// No description provided for @keepYouPosted.
  ///
  /// In en, this message translates to:
  /// **'We\'ll keep you posted with the latest updates.'**
  String get keepYouPosted;

  /// No description provided for @exploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore Products'**
  String get exploreProducts;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @exploreTopSectors.
  ///
  /// In en, this message translates to:
  /// **'Explore top agricultural sectors'**
  String get exploreTopSectors;

  /// No description provided for @expertHelp.
  ///
  /// In en, this message translates to:
  /// **'Expert Help'**
  String get expertHelp;

  /// No description provided for @exploreCollection.
  ///
  /// In en, this message translates to:
  /// **'Explore {collectionName}'**
  String exploreCollection(String collectionName);

  /// No description provided for @premiumFarmingEssentials.
  ///
  /// In en, this message translates to:
  /// **'Premium farming essentials'**
  String get premiumFarmingEssentials;

  /// No description provided for @exclusiveDeals.
  ///
  /// In en, this message translates to:
  /// **'Exclusive deals & discounts'**
  String get exclusiveDeals;

  /// No description provided for @bestOffers.
  ///
  /// In en, this message translates to:
  /// **'Best Offers'**
  String get bestOffers;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @footerBadgeSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get footerBadgeSecure;

  /// No description provided for @footerBadgeFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get footerBadgeFast;

  /// No description provided for @footerBadgeOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get footerBadgeOrganic;

  /// No description provided for @footerBadgeTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get footerBadgeTrusted;

  /// No description provided for @empoweringFarmers.
  ///
  /// In en, this message translates to:
  /// **'Empowering Indian Farmers since 2026.'**
  String get empoweringFarmers;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @searchHintFungicides.
  ///
  /// In en, this message translates to:
  /// **'Search for \'Fungicides\'...'**
  String get searchHintFungicides;

  /// No description provided for @searchHintInsecticides.
  ///
  /// In en, this message translates to:
  /// **'Search for \'Insecticides\'...'**
  String get searchHintInsecticides;

  /// No description provided for @searchHintHerbicides.
  ///
  /// In en, this message translates to:
  /// **'Search for \'Herbicides\'...'**
  String get searchHintHerbicides;

  /// No description provided for @searchHintBioProducts.
  ///
  /// In en, this message translates to:
  /// **'Search for \'Bio-Products\'...'**
  String get searchHintBioProducts;

  /// No description provided for @searchHintPgrs.
  ///
  /// In en, this message translates to:
  /// **'Search for \'PGRs\'...'**
  String get searchHintPgrs;

  /// No description provided for @searchHintFertilizers.
  ///
  /// In en, this message translates to:
  /// **'Search for \'Fertilizers\'...'**
  String get searchHintFertilizers;

  /// No description provided for @categoryInsecticides.
  ///
  /// In en, this message translates to:
  /// **'Insecticides'**
  String get categoryInsecticides;

  /// No description provided for @categoryFungicides.
  ///
  /// In en, this message translates to:
  /// **'Fungicides'**
  String get categoryFungicides;

  /// No description provided for @categoryHerbicides.
  ///
  /// In en, this message translates to:
  /// **'Herbicides'**
  String get categoryHerbicides;

  /// No description provided for @categoryBioProducts.
  ///
  /// In en, this message translates to:
  /// **'Bio-Products'**
  String get categoryBioProducts;

  /// No description provided for @categoryPgrs.
  ///
  /// In en, this message translates to:
  /// **'PGRs'**
  String get categoryPgrs;

  /// No description provided for @categoryFertilizers.
  ///
  /// In en, this message translates to:
  /// **'Fertilizers'**
  String get categoryFertilizers;

  /// No description provided for @categoryDefault.
  ///
  /// In en, this message translates to:
  /// **'Agri Products'**
  String get categoryDefault;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your Wishlist is Empty'**
  String get wishlistEmpty;

  /// No description provided for @saveFavoritesInstruction.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite farming essentials and access them instantly anytime.'**
  String get saveFavoritesInstruction;

  /// No description provided for @exploreShop.
  ///
  /// In en, this message translates to:
  /// **'Explore Shop'**
  String get exploreShop;

  /// No description provided for @clearWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Favorites'**
  String get clearWishlistTitle;

  /// No description provided for @clearWishlistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from your wishlist?'**
  String get clearWishlistConfirm;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get editLabel;

  /// No description provided for @itemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{ITEM} other{ITEMS}}'**
  String itemCountLabel(int count);

  /// No description provided for @secureCheckoutBadge.
  ///
  /// In en, this message translates to:
  /// **'SECURE CHECKOUT'**
  String get secureCheckoutBadge;

  /// No description provided for @couponApplied.
  ///
  /// In en, this message translates to:
  /// **'COUPON APPLIED!'**
  String get couponApplied;

  /// No description provided for @couponActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Code \'{coupon}\' is active'**
  String couponActiveMessage(String coupon);

  /// No description provided for @cartFeelsLight.
  ///
  /// In en, this message translates to:
  /// **'Your cart feels light'**
  String get cartFeelsLight;

  /// No description provided for @discoverAgriProducts.
  ///
  /// In en, this message translates to:
  /// **'Discover premium agricultural products and start your growing journey today.'**
  String get discoverAgriProducts;

  /// No description provided for @beginExploring.
  ///
  /// In en, this message translates to:
  /// **'Begin Exploring'**
  String get beginExploring;

  /// No description provided for @selectItemsToDelete.
  ///
  /// In en, this message translates to:
  /// **'SELECT ITEMS TO DELETE'**
  String get selectItemsToDelete;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'DELETE SELECTED ({count})'**
  String deleteSelected(int count);

  /// No description provided for @continueToCheckout.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE TO CHECKOUT'**
  String get continueToCheckout;

  /// No description provided for @removeItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} items?'**
  String removeItemsTitle(int count);

  /// No description provided for @removeItemsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected items from your cart?'**
  String get removeItemsConfirm;

  /// No description provided for @clearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart?'**
  String get clearCartTitle;

  /// No description provided for @clearCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from your cart?'**
  String get clearCartConfirm;

  /// No description provided for @couponAppliedTitle.
  ///
  /// In en, this message translates to:
  /// **'Coupon Applied!'**
  String get couponAppliedTitle;

  /// No description provided for @offersAndBenefits.
  ///
  /// In en, this message translates to:
  /// **'Offers & Benefits'**
  String get offersAndBenefits;

  /// No description provided for @freeGiftMessage.
  ///
  /// In en, this message translates to:
  /// **'Coupon \'DEALERDHAMAKA\' applied: Free product added! 🎁'**
  String get freeGiftMessage;

  /// No description provided for @couponSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'You saved ₹{amount} with {coupon}'**
  String couponSavedMessage(String amount, String coupon);

  /// No description provided for @viewCouponsAndOffers.
  ///
  /// In en, this message translates to:
  /// **'View available coupons and offers'**
  String get viewCouponsAndOffers;

  /// No description provided for @giftLabel.
  ///
  /// In en, this message translates to:
  /// **'GIFT'**
  String get giftLabel;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get freeLabel;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enterQuantity;

  /// No description provided for @specifyQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'Specify the number of items you\'d like to order.'**
  String get specifyQuantityHint;

  /// No description provided for @egQuantity.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5'**
  String get egQuantity;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateLabel;

  /// No description provided for @billDetails.
  ///
  /// In en, this message translates to:
  /// **'BILL DETAILS'**
  String get billDetails;

  /// No description provided for @itemTotalSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Item Total (Subtotal)'**
  String get itemTotalSubtotal;

  /// No description provided for @couponDiscount.
  ///
  /// In en, this message translates to:
  /// **'Coupon Discount'**
  String get couponDiscount;

  /// No description provided for @deliveryCharges.
  ///
  /// In en, this message translates to:
  /// **'Delivery Charges'**
  String get deliveryCharges;

  /// No description provided for @totalAmountPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Amount Payable'**
  String get totalAmountPayable;

  /// No description provided for @couponSavingsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Yay! You saved ₹{amount} on this purchase!'**
  String couponSavingsSuccess(String amount);

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get tabDelivered;

  /// No description provided for @tabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tabCancelled;

  /// No description provided for @tabRto.
  ///
  /// In en, this message translates to:
  /// **'RTO'**
  String get tabRto;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @activeOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Active {count, plural, =1{Order} other{Orders}}'**
  String activeOrdersLabel(int count);

  /// No description provided for @allOrdersHistory.
  ///
  /// In en, this message translates to:
  /// **'All Orders History'**
  String get allOrdersHistory;

  /// No description provided for @totalOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Total'**
  String totalOrdersCount(int count);

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No Orders Yet'**
  String get noOrdersYet;

  /// No description provided for @noMatchingOrders.
  ///
  /// In en, this message translates to:
  /// **'No Matching Orders'**
  String get noMatchingOrders;

  /// No description provided for @orderJourneyBegins.
  ///
  /// In en, this message translates to:
  /// **'Your agricultural journey begins here. Explore our catalog and place your first order today!'**
  String get orderJourneyBegins;

  /// No description provided for @noOrdersMatchingStatus.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any orders under the \'{status}\' status.'**
  String noOrdersMatchingStatus(String status);

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start Exploring'**
  String get startExploring;

  /// No description provided for @viewAllOrders.
  ///
  /// In en, this message translates to:
  /// **'View All Orders'**
  String get viewAllOrders;

  /// No description provided for @understandingOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Understanding Order Status'**
  String get understandingOrderStatus;

  /// No description provided for @whatEachStatusMeans.
  ///
  /// In en, this message translates to:
  /// **'Here is what each status means for your shipment:'**
  String get whatEachStatusMeans;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @processingDesc.
  ///
  /// In en, this message translates to:
  /// **'Your items are being inspected, packed, and prepared for dispatch.'**
  String get processingDesc;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @shippedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your package has left our facility and is in transit.'**
  String get shippedDesc;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @outForDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your package is out for final delivery to your doorstep.'**
  String get outForDeliveryDesc;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @deliveredDesc.
  ///
  /// In en, this message translates to:
  /// **'The shipment has been successfully handed over.'**
  String get deliveredDesc;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cancelledDesc.
  ///
  /// In en, this message translates to:
  /// **'The order was cancelled. Payments will be refunded.'**
  String get cancelledDesc;

  /// No description provided for @needImmediateHelp.
  ///
  /// In en, this message translates to:
  /// **'Need immediate help?'**
  String get needImmediateHelp;

  /// No description provided for @supportStaffReady.
  ///
  /// In en, this message translates to:
  /// **'Our 24/7 support staff is ready to assist you.'**
  String get supportStaffReady;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get removeLabel;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ORDER #'**
  String get orderIdLabel;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @advancePaid.
  ///
  /// In en, this message translates to:
  /// **'Adv: ₹{amount}'**
  String advancePaid(String amount);

  /// No description provided for @remainingDue.
  ///
  /// In en, this message translates to:
  /// **'Due: ₹{amount}'**
  String remainingDue(String amount);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{item} other{items}}'**
  String itemsCount(int count);

  /// No description provided for @cancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on {date}'**
  String cancelledOn(String date);

  /// No description provided for @crops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get crops;

  /// No description provided for @cropsCollection.
  ///
  /// In en, this message translates to:
  /// **'Crop Collection'**
  String get cropsCollection;

  /// No description provided for @shopByCrop.
  ///
  /// In en, this message translates to:
  /// **'Shop by Crop'**
  String get shopByCrop;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @cropsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{Crop} other{Crops}}'**
  String cropsCount(int count);

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Categories'**
  String categoriesCount(int count);

  /// No description provided for @searchHintCrops.
  ///
  /// In en, this message translates to:
  /// **'Search for crops...'**
  String get searchHintCrops;

  /// No description provided for @searchHintSeeds.
  ///
  /// In en, this message translates to:
  /// **'Search for seeds...'**
  String get searchHintSeeds;

  /// No description provided for @searchHintMachinery.
  ///
  /// In en, this message translates to:
  /// **'Search for machinery...'**
  String get searchHintMachinery;

  /// No description provided for @searchHintOrganic.
  ///
  /// In en, this message translates to:
  /// **'Search for organic...'**
  String get searchHintOrganic;

  /// No description provided for @badgeGenuine.
  ///
  /// In en, this message translates to:
  /// **'Genuine'**
  String get badgeGenuine;

  /// No description provided for @badgeTested.
  ///
  /// In en, this message translates to:
  /// **'Tested'**
  String get badgeTested;

  /// No description provided for @badgeExpress.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get badgeExpress;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @whatAreYouLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get whatAreYouLookingFor;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingSearch;

  /// No description provided for @quickDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Quick Discovery'**
  String get quickDiscovery;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @letsConnect.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Connect'**
  String get letsConnect;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help support your agro-business.'**
  String get supportSubtitle;

  /// No description provided for @onlineSupportActive.
  ///
  /// In en, this message translates to:
  /// **'Online • Support Active'**
  String get onlineSupportActive;

  /// No description provided for @offlineResponseDelayed.
  ///
  /// In en, this message translates to:
  /// **'Offline • Response Delayed'**
  String get offlineResponseDelayed;

  /// No description provided for @supportHours.
  ///
  /// In en, this message translates to:
  /// **'Mon-Sat (9:00 AM - 7:00 PM)'**
  String get supportHours;

  /// No description provided for @fastResponse.
  ///
  /// In en, this message translates to:
  /// **'Fast response'**
  String get fastResponse;

  /// No description provided for @quickChat.
  ///
  /// In en, this message translates to:
  /// **'Quick Chat'**
  String get quickChat;

  /// No description provided for @directLine.
  ///
  /// In en, this message translates to:
  /// **'Direct Line'**
  String get directLine;

  /// No description provided for @officialMail.
  ///
  /// In en, this message translates to:
  /// **'Official Mail'**
  String get officialMail;

  /// No description provided for @sendQuickInquiry.
  ///
  /// In en, this message translates to:
  /// **'Send a Quick Inquiry'**
  String get sendQuickInquiry;

  /// No description provided for @selectTopic.
  ///
  /// In en, this message translates to:
  /// **'SELECT TOPIC'**
  String get selectTopic;

  /// No description provided for @messageDetails.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE DETAILS'**
  String get messageDetails;

  /// No description provided for @sendWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp'**
  String get sendWhatsApp;

  /// No description provided for @whyTrustKrishiKranti.
  ///
  /// In en, this message translates to:
  /// **'Why Trust Krishi Kranti'**
  String get whyTrustKrishiKranti;

  /// No description provided for @dataPrivate.
  ///
  /// In en, this message translates to:
  /// **'Data Private'**
  String get dataPrivate;

  /// No description provided for @cibrcRegd.
  ///
  /// In en, this message translates to:
  /// **'CIB&RC Regd.'**
  String get cibrcRegd;

  /// No description provided for @gstInvoice.
  ///
  /// In en, this message translates to:
  /// **'GST Invoice'**
  String get gstInvoice;

  /// No description provided for @panIndiaDelivery.
  ///
  /// In en, this message translates to:
  /// **'PAN-India Delivery'**
  String get panIndiaDelivery;

  /// No description provided for @topicOrderIssue.
  ///
  /// In en, this message translates to:
  /// **'Order Issue'**
  String get topicOrderIssue;

  /// No description provided for @topicRefundPayment.
  ///
  /// In en, this message translates to:
  /// **'Refund / Payment'**
  String get topicRefundPayment;

  /// No description provided for @topicBecomeDealer.
  ///
  /// In en, this message translates to:
  /// **'Become a Dealer'**
  String get topicBecomeDealer;

  /// No description provided for @topicProductQuery.
  ///
  /// In en, this message translates to:
  /// **'Product Query'**
  String get topicProductQuery;

  /// No description provided for @topicKycHelp.
  ///
  /// In en, this message translates to:
  /// **'KYC Help'**
  String get topicKycHelp;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @seedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seedsLabel;

  /// No description provided for @toolsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsLabel;

  /// No description provided for @availableCoupons.
  ///
  /// In en, this message translates to:
  /// **'Available Coupons'**
  String get availableCoupons;

  /// No description provided for @couponAppliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied successfully!'**
  String get couponAppliedSuccessfully;

  /// No description provided for @noCouponsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No coupons available right now'**
  String get noCouponsAvailable;

  /// No description provided for @minPurchaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Purchase: ₹{amount}'**
  String minPurchaseLabel(String amount);

  /// No description provided for @newUsersOnly.
  ///
  /// In en, this message translates to:
  /// **'New Users Only'**
  String get newUsersOnly;

  /// No description provided for @applyLabel.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get applyLabel;

  /// No description provided for @noItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No items available'**
  String get noItemsAvailable;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure Checkout'**
  String get secureCheckout;

  /// No description provided for @billingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Billing Breakdown'**
  String get billingBreakdown;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @couponDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon Discount'**
  String get couponDiscountLabel;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @advanceBookingDeposit.
  ///
  /// In en, this message translates to:
  /// **'Advance Booking Deposit ({percent}%)'**
  String advanceBookingDeposit(int percent);

  /// No description provided for @remainingBalanceAtDelivery.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance at Delivery'**
  String get remainingBalanceAtDelivery;

  /// No description provided for @dealerDhamakaBanner.
  ///
  /// In en, this message translates to:
  /// **'Coupon \'DEALERDHAMAKA\' applied: Free product added! 🎁'**
  String get dealerDhamakaBanner;

  /// No description provided for @couponSavingsBannerCheckout.
  ///
  /// In en, this message translates to:
  /// **'You saved ₹{amount} with this coupon 🎉'**
  String couponSavingsBannerCheckout(String amount);

  /// No description provided for @hundredPercentSecure.
  ///
  /// In en, this message translates to:
  /// **'100% Secure'**
  String get hundredPercentSecure;

  /// No description provided for @fastDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fast Delivery'**
  String get fastDelivery;

  /// No description provided for @paymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentMode;

  /// No description provided for @payFullOnline.
  ///
  /// In en, this message translates to:
  /// **'Pay Full Online'**
  String get payFullOnline;

  /// No description provided for @payFullOnlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay complete order amount safely via UPI/Cards'**
  String get payFullOnlineDesc;

  /// No description provided for @partialBookingAdvance.
  ///
  /// In en, this message translates to:
  /// **'Partial Booking Advance'**
  String get partialBookingAdvance;

  /// No description provided for @partialBookingAdvanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Book your order with a minor token deposit'**
  String get partialBookingAdvanceDesc;

  /// No description provided for @chooseAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Choose Advance Amount'**
  String get chooseAdvanceAmount;

  /// No description provided for @payableAmount.
  ///
  /// In en, this message translates to:
  /// **'Payable Amount:'**
  String get payableAmount;

  /// No description provided for @bookingAdvanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking Advance:'**
  String get bookingAdvanceLabel;

  /// No description provided for @remainingBalanceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance at Delivery:'**
  String get remainingBalanceDelivery;

  /// No description provided for @addAddressToPay.
  ///
  /// In en, this message translates to:
  /// **'Add Address to Pay'**
  String get addAddressToPay;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Pay'**
  String get proceedToPay;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'DELIVER TO'**
  String get deliverTo;

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAddress;

  /// No description provided for @addShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Shipping Address'**
  String get addShippingAddress;

  /// No description provided for @addShippingAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Please add a shipping address to place order'**
  String get addShippingAddressHint;

  /// No description provided for @selectShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Shipping Address'**
  String get selectShippingAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @pleaseSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a shipping address'**
  String get pleaseSelectAddress;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed: {message}'**
  String paymentFailed(String message);

  /// No description provided for @errorLaunchingRazorpay.
  ///
  /// In en, this message translates to:
  /// **'Error launching Razorpay: {error}'**
  String errorLaunchingRazorpay(String error);

  /// No description provided for @paymentSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment setup failed: {error}'**
  String paymentSetupFailed(String error);

  /// No description provided for @failedToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order: {error}'**
  String failedToPlaceOrder(String error);

  /// No description provided for @orderSyncRequired.
  ///
  /// In en, this message translates to:
  /// **'Order Sync Required'**
  String get orderSyncRequired;

  /// No description provided for @orderSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Your payment was successful, but our server encountered an error while confirming your order details.'**
  String get orderSyncDescription;

  /// No description provided for @paymentRefKeepSafe.
  ///
  /// In en, this message translates to:
  /// **'Payment Reference (Keep Safe):'**
  String get paymentRefKeepSafe;

  /// No description provided for @doNotCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Please do NOT close the app. Tap \'Retry Now\' below to complete and secure your order registration immediately.'**
  String get doNotCloseApp;

  /// No description provided for @copyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry Now'**
  String get retryNow;

  /// No description provided for @paymentRefCopied.
  ///
  /// In en, this message translates to:
  /// **'Payment reference copied to clipboard!'**
  String get paymentRefCopied;

  /// No description provided for @securingYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Securing Your Order... 🔒'**
  String get securingYourOrder;

  /// No description provided for @pciDssCompliant.
  ///
  /// In en, this message translates to:
  /// **'PCI-DSS compliant SSL security layer'**
  String get pciDssCompliant;

  /// No description provided for @processingStep1.
  ///
  /// In en, this message translates to:
  /// **'Scanning client environment sandbox... 🛡️'**
  String get processingStep1;

  /// No description provided for @processingStep2.
  ///
  /// In en, this message translates to:
  /// **'Analyzing transaction injection vulnerabilities... 🔒'**
  String get processingStep2;

  /// No description provided for @processingStep3.
  ///
  /// In en, this message translates to:
  /// **'Verifying secure API socket handshake... ⛓️'**
  String get processingStep3;

  /// No description provided for @processingStep4.
  ///
  /// In en, this message translates to:
  /// **'Validating payload signature integrity... 🔑'**
  String get processingStep4;

  /// No description provided for @processingStep5.
  ///
  /// In en, this message translates to:
  /// **'Finalizing end-to-end SSL encryption... 🚀'**
  String get processingStep5;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String qtyLabel(int qty);

  /// No description provided for @goToMyOrders.
  ///
  /// In en, this message translates to:
  /// **'Go to My Orders ({seconds}s)'**
  String goToMyOrders(int seconds);

  /// No description provided for @orderSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase. We are preparing your order for shipment. Let\'s get growing!'**
  String get orderSuccessMessage;

  /// No description provided for @orderSecuredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your booking deposit was received and your order is now secured. Let\'s get growing!'**
  String get orderSecuredMessage;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @generalOptions.
  ///
  /// In en, this message translates to:
  /// **'General Options'**
  String get generalOptions;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// No description provided for @empoweringAgriDealers.
  ///
  /// In en, this message translates to:
  /// **'Empowering Agri Dealers Across India'**
  String get empoweringAgriDealers;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @enterStoreName.
  ///
  /// In en, this message translates to:
  /// **'Enter your store name'**
  String get enterStoreName;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'House no., Street, Area'**
  String get addressHint;

  /// No description provided for @address2Hint.
  ///
  /// In en, this message translates to:
  /// **'Landmark, Colony, etc.'**
  String get address2Hint;

  /// No description provided for @sortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get sortAndFilter;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'SORT BY'**
  String get sortBy;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'FILTER BY'**
  String get filterBy;

  /// No description provided for @inStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In Stock Only'**
  String get inStockOnly;

  /// No description provided for @inStockOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide products that are currently unavailable'**
  String get inStockOnlyDesc;

  /// No description provided for @exclusiveOffersDeals.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Offers & Deals'**
  String get exclusiveOffersDeals;

  /// No description provided for @exclusiveOffersDealsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show items with marked down dealer pricing'**
  String get exclusiveOffersDealsDesc;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No Products Found'**
  String get noProductsFound;

  /// No description provided for @noProductsFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any products matching your current criteria or subcategory.'**
  String get noProductsFoundDesc;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @exclusiveCollection.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Collection'**
  String get exclusiveCollection;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @itemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} items available'**
  String itemsAvailable(int count);

  /// No description provided for @selectPackagingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Select Packaging & Quantity'**
  String get selectPackagingQuantity;

  /// No description provided for @expertChoice.
  ///
  /// In en, this message translates to:
  /// **'Expert Choice'**
  String get expertChoice;

  /// No description provided for @fastActing.
  ///
  /// In en, this message translates to:
  /// **'Fast Acting'**
  String get fastActing;

  /// No description provided for @hundredPercentOriginal.
  ///
  /// In en, this message translates to:
  /// **'100% Original'**
  String get hundredPercentOriginal;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addLabel;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items: {count}'**
  String totalItems(int count);

  /// No description provided for @grandTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand Total: ₹{amount}'**
  String grandTotalLabel(String amount);

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelLabel;

  /// No description provided for @updateLabel2.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateLabel2;

  /// No description provided for @enterValueHint.
  ///
  /// In en, this message translates to:
  /// **'Enter value'**
  String get enterValueHint;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @wholesaleTierPricing.
  ///
  /// In en, this message translates to:
  /// **'Wholesale Tier Pricing'**
  String get wholesaleTierPricing;

  /// No description provided for @currentVolume.
  ///
  /// In en, this message translates to:
  /// **'Current Volume: {volume}'**
  String currentVolume(String volume);

  /// No description provided for @goToCart.
  ///
  /// In en, this message translates to:
  /// **'GO TO CART'**
  String get goToCart;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'BUY NOW'**
  String get buyNow;

  /// No description provided for @pleaseSelectPackSize.
  ///
  /// In en, this message translates to:
  /// **'Please select a pack size'**
  String get pleaseSelectPackSize;

  /// No description provided for @failedToRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove item'**
  String get failedToRemoveItem;

  /// No description provided for @failedToUpdateCart.
  ///
  /// In en, this message translates to:
  /// **'Failed to update cart: {error}'**
  String failedToUpdateCart(String error);

  /// No description provided for @unlockTierPricing.
  ///
  /// In en, this message translates to:
  /// **'Unlock {tier} Pricing!'**
  String unlockTierPricing(String tier);

  /// No description provided for @getWholesaleRates.
  ///
  /// In en, this message translates to:
  /// **'Get wholesale rates on bulk volume'**
  String get getWholesaleRates;

  /// No description provided for @regularPrice.
  ///
  /// In en, this message translates to:
  /// **'Regular Price'**
  String get regularPrice;

  /// No description provided for @wholesaleRate.
  ///
  /// In en, this message translates to:
  /// **'WHOLESALE RATE'**
  String get wholesaleRate;

  /// No description provided for @totalBulkSavings.
  ///
  /// In en, this message translates to:
  /// **'Total Bulk Savings: ₹{savings}!'**
  String totalBulkSavings(String savings);

  /// No description provided for @requiredVolumeProgression.
  ///
  /// In en, this message translates to:
  /// **'Required Volume Progression'**
  String get requiredVolumeProgression;

  /// No description provided for @currentProgress.
  ///
  /// In en, this message translates to:
  /// **'Current: {vol} ({packs} packs)'**
  String currentProgress(String vol, int packs);

  /// No description provided for @targetProgress.
  ///
  /// In en, this message translates to:
  /// **'Target: {vol} ({packs} packs)'**
  String targetProgress(String vol, int packs);

  /// No description provided for @addingMorePacksUnlocks.
  ///
  /// In en, this message translates to:
  /// **'Adding {diff} more packs of this size unlocks ₹{discount} discount per {unit} on ALL units!'**
  String addingMorePacksUnlocks(int diff, String discount, String unit);

  /// No description provided for @keepCurrent.
  ///
  /// In en, this message translates to:
  /// **'KEEP CURRENT'**
  String get keepCurrent;

  /// No description provided for @addDiffAndSave.
  ///
  /// In en, this message translates to:
  /// **'ADD {diff} & SAVE'**
  String addDiffAndSave(int diff);

  /// No description provided for @adjustQuantity.
  ///
  /// In en, this message translates to:
  /// **'Adjust Quantity'**
  String get adjustQuantity;

  /// No description provided for @confirmLabel.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirmLabel;

  /// No description provided for @saveAmount.
  ///
  /// In en, this message translates to:
  /// **'SAVE ₹{amount}'**
  String saveAmount(String amount);

  /// No description provided for @tierUnlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'You unlocked {tier}! Now enjoying ₹{price}/{unit} pricing. 🎉'**
  String tierUnlockedMessage(String tier, String price, String unit);

  /// No description provided for @zeroReviews.
  ///
  /// In en, this message translates to:
  /// **' (0 reviews)'**
  String get zeroReviews;

  /// No description provided for @stepCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get stepCart;

  /// No description provided for @stepCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get stepCheckout;

  /// No description provided for @stepPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get stepPayment;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequired;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @forceUpdateMsg.
  ///
  /// In en, this message translates to:
  /// **'A critical update is available. Please update the app to continue using our services.'**
  String get forceUpdateMsg;

  /// No description provided for @optionalUpdateMsg.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available with new features and improvements.'**
  String get optionalUpdateMsg;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'UPDATE NOW'**
  String get updateNow;
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
