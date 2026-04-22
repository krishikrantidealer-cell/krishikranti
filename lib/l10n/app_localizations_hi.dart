// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get home => 'होम';

  @override
  String get search => 'खोजें';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get cart => 'कार्ट';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get favorites => 'पसंदीदा';

  @override
  String get myOrders => 'मेरे ऑर्डर';

  @override
  String get language => 'भाषा';

  @override
  String get add => 'जोड़ें';

  @override
  String get viewMore => 'और देखें';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get welcome => 'नमस्ते,';

  @override
  String get featuredProducts => 'विशेष उत्पाद';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get searchProducts => 'उत्पाद खोजें...';

  @override
  String get noProducts => 'कोई उत्पाद नहीं मिला';

  @override
  String get confirmOrder => 'ऑर्डर की पुष्टि करें';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get contactUs => 'संपर्क करें';

  @override
  String get aboutUs => 'हमारे बारे में';

  @override
  String get myAccount => 'मेरा खाता';

  @override
  String get kycVerification => 'KYC सत्यापन';

  @override
  String get kycSubtitle =>
      'थोक सुविधाओं को अनलॉक करने के लिए अपना KYC पूरा करें।';

  @override
  String get completeKyc => 'KYC पूरा करें';

  @override
  String get logoutConfirm => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get welcomeToKrishidealer => 'कृषि डीलर में\nआपका स्वागत है';

  @override
  String get indiasTrustedPlatform =>
      'किसानों और खुदरा विक्रेताओं के लिए\nभारत का भरोसेमंद मंच';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get phoneNumberHint => 'फोन नंबर';

  @override
  String get agreeTo => 'मैं हमारी ';

  @override
  String get termsPrivacyPolicy => 'शर्तों और गोपनीयता नीति से सहमत हूँ';

  @override
  String get sendOtp => 'ओटीपी भेजें';

  @override
  String get verifyYourNumber => 'अपना नंबर सत्यापित करें';

  @override
  String enterOtpSentTo(String phoneNumber) {
    return '+91 $phoneNumber पर भेजा गया\n6-अंकीय कोड दर्ज करें';
  }

  @override
  String resendIn(String seconds) {
    return '00:$seconds में पुन: भेजें';
  }

  @override
  String get resendOtp => 'ओटीपी पुनः भेजें';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get krishi => 'कृषि';

  @override
  String get dealer => 'डीलर';

  @override
  String get createYourAccount => 'अपना खाता बनाएं';

  @override
  String get registerSubtitle =>
      'शुरू करने के लिए अपना कृषि व्यवसाय पंजीकृत करें';

  @override
  String get step1Of2 => 'चरण 1 का 2';

  @override
  String get shopName => 'दुकान का नाम';

  @override
  String get firstName => 'पहला नाम';

  @override
  String get lastName => 'अंतिम नाम';

  @override
  String get email => 'ईमेल';

  @override
  String get addressType => 'पते का प्रकार';

  @override
  String get shop => 'दुकान';

  @override
  String get godown => 'गोदाम';

  @override
  String get other => 'अन्य';

  @override
  String get villageArea => 'गाँव / क्षेत्र';

  @override
  String get cityTehsil => 'शहर / तहसील';

  @override
  String get pincode => 'पिनकोड';

  @override
  String get useLocationAutofill =>
      'पिन स्वतः भरने के लिए वर्तमान स्थान का उपयोग करें';

  @override
  String get submitDetails => 'विवरण जमा करें';

  @override
  String get fieldRequired => 'आवश्यक';

  @override
  String get invalidPincode => 'अमान्य पिनकोड';

  @override
  String get enableLocationServices => 'कृपया स्थान सेवाएं सक्षम करें';

  @override
  String get completeEkyc => 'ई-केवाईसी पूरा करें';

  @override
  String get ekycSubtitle =>
      'व्यावसायिक दस्तावेज़ प्रदान करके अपना खाता सुरक्षित करें';

  @override
  String get step2Of2 => 'चरण 2 का 2';

  @override
  String get registeringAs => 'पंजीकरण के रूप में';

  @override
  String get retailer => 'खुदरा विक्रेता';

  @override
  String get distributor => 'वितरक';

  @override
  String get farmer => 'किसान';

  @override
  String get uploadLicense => 'लाइसेंस छवि अपलोड करें';

  @override
  String get uploadGst => 'जीएसटी छवि अपलोड करें';

  @override
  String get gstNumber => 'जीएसटी नंबर';

  @override
  String get aadhaarNumber => '12-अंकीय आधार संख्या';

  @override
  String get completeVerification => 'सत्यापन पूरा करें';

  @override
  String get dataSecureNotice => 'आपका डेटा एन्क्रिप्टेड और सुरक्षित है।';

  @override
  String get uploadLimitNotice => 'JPG/PNG 3MB तक';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get shippingAddress => 'शिपिंग पता';

  @override
  String get addAddress => 'पत्ता जोड़ें';

  @override
  String get editAddress => 'पत्ता संपादित करें';

  @override
  String get deliverHere => 'इस पते पर भेजें';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get addressLine1 => 'पता पंक्ति १';

  @override
  String get addressLine2Optional => 'पता पंक्ति २ (वैकल्पिक)';

  @override
  String get cityDistrict => 'शहर / जिला';

  @override
  String get state => 'राज्य';

  @override
  String get discard => 'रद्द करें';

  @override
  String get saveChanges => 'बदलें सहेजें';

  @override
  String get noAddressesFound => 'कोई पता नहीं मिला';

  @override
  String get addAddressToContinue =>
      'अपना ऑर्डर जारी रखने के लिए एक पता जोड़ें';

  @override
  String get locationFailed =>
      'स्थान प्राप्त करने में विफल। कृपया पुन: प्रयास करें।';

  @override
  String get edit => 'संपादित करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get defaultLabel => 'डिफ़ॉल्ट';
}
