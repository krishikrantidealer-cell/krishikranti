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
  String get uploadLicense => 'लाइसेंस दस्तावेज़ अपलोड करें';

  @override
  String get uploadGst => 'जीएसटी दस्तावेज़ अपलोड करें';

  @override
  String get gstNumber => 'जीएसटी नंबर';

  @override
  String get aadhaarNumber => '12-अंकीय आधार संख्या';

  @override
  String get completeVerification => 'सत्यापन पूरा करें';

  @override
  String get dataSecureNotice => 'आपका डेटा एन्क्रिप्टेड और सुरक्षित है।';

  @override
  String get uploadLimitNotice => 'JPG/PNG/PDF 3MB तक';

  @override
  String get tapToUploadNotice => 'अपलोड करने के लिए टैप करें';

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

  @override
  String get readAll => 'सब पढ़ें';

  @override
  String get swipeToDeleteTip =>
      'सुझाव: हटाने के लिए नोटिफिकेशन पर बाईं ओर स्वाइप करें।';

  @override
  String get tabAll => 'सभी';

  @override
  String get tabOrders => 'ऑर्डर';

  @override
  String get tabOffers => 'ऑफर';

  @override
  String get noNotificationsYet => 'अभी कोई सूचना नहीं है';

  @override
  String get noOrderUpdatesYet => 'अभी कोई ऑर्डर अपडेट नहीं है';

  @override
  String get noOffersRightNow => 'अभी कोई ऑफर नहीं है';

  @override
  String get keepYouPosted => 'हम आपको नवीनतम अपडेट से अवगत कराते रहेंगे।';

  @override
  String get exploreProducts => 'उत्पाद खोजें';

  @override
  String get goodMorning => 'शुभ प्रभात';

  @override
  String get goodAfternoon => 'शुभ दोपहर';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get exploreTopSectors => 'शीर्ष कृषि क्षेत्रों का पता लगाएं';

  @override
  String get expertHelp => 'विशेषज्ञ सहायता';

  @override
  String exploreCollection(String collectionName) {
    return '$collectionName खोजें';
  }

  @override
  String get premiumFarmingEssentials => 'प्रीमियम कृषि आवश्यकताएं';

  @override
  String get exclusiveDeals => 'विशेष सौदे और छूट';

  @override
  String get bestOffers => 'सर्वश्रेष्ठ ऑफर';

  @override
  String get collections => 'संग्रह';

  @override
  String get footerBadgeSecure => 'सुरक्षित';

  @override
  String get footerBadgeFast => 'तेज';

  @override
  String get footerBadgeOrganic => 'जैविक';

  @override
  String get footerBadgeTrusted => 'विश्वसनीय';

  @override
  String get empoweringFarmers => '2026 से भारतीय किसानों को सशक्त बनाना‌।';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get older => 'पुराने';

  @override
  String get justNow => 'अभी-अभी';

  @override
  String get searchHintFungicides => 'कवकनाशी खोजें...';

  @override
  String get searchHintInsecticides => 'कीटनाशक खोजें...';

  @override
  String get searchHintHerbicides => 'खरपतवार नाशी खोजें...';

  @override
  String get searchHintBioProducts => 'जैव उत्पाद खोजें...';

  @override
  String get searchHintPgrs => 'PGRs खोजें...';

  @override
  String get searchHintFertilizers => 'उर्वरक खोजें...';

  @override
  String get categoryInsecticides => 'कीटनाशक';

  @override
  String get categoryFungicides => 'कवकनाशी';

  @override
  String get categoryHerbicides => 'खरपतवार नाशी';

  @override
  String get categoryBioProducts => 'जैव उत्पाद';

  @override
  String get categoryPgrs => 'पादप वृद्धि (PGR)';

  @override
  String get categoryFertilizers => 'उर्वरक';

  @override
  String get categoryDefault => 'कृषि उत्पाद';

  @override
  String get wishlistEmpty => 'आपकी विशलिस्ट खाली है';

  @override
  String get saveFavoritesInstruction =>
      'अपने पसंदीदा कृषि उत्पादों को सहेजें और उन्हें कभी भी तुरंत देखें।';

  @override
  String get exploreShop => 'दुकान देखें';

  @override
  String get clearWishlistTitle => 'पसंदीदा हटाएं';

  @override
  String get clearWishlistConfirm =>
      'क्या आप वाकई अपनी विशलिस्ट से सभी उत्पाद हटाना चाहते हैं?';

  @override
  String get clearAll => 'सभी हटाएं';

  @override
  String get added => 'जुड़ गया';

  @override
  String get deselectAll => 'सभी अचयनित करें';

  @override
  String get selectAll => 'सभी चुनें';

  @override
  String get done => 'पूर्ण';

  @override
  String get editLabel => 'संपादित करें';

  @override
  String itemCountLabel(int count) {
    return '$count उत्पाद';
  }

  @override
  String get secureCheckoutBadge => 'सुरक्षित चेकआउट';

  @override
  String get couponApplied => 'कूपन लागू किया गया!';

  @override
  String couponActiveMessage(String coupon) {
    return 'कूपन कोड \'$coupon\' सक्रिय है';
  }

  @override
  String get cartFeelsLight => 'आपकी कार्ट खाली है';

  @override
  String get discoverAgriProducts =>
      'सर्वश्रेष्ठ कृषि उत्पादों की खोज करें और आज ही खरीदारी शुरू करें।';

  @override
  String get beginExploring => 'खरीदारी शुरू करें';

  @override
  String get selectItemsToDelete => 'हटाने के लिए उत्पाद चुनें';

  @override
  String deleteSelected(int count) {
    return 'चयनित हटाएं ($count)';
  }

  @override
  String get continueToCheckout => 'चेकआउट के लिए आगे बढ़ें';

  @override
  String removeItemsTitle(int count) {
    return '$count उत्पाद हटाएं?';
  }

  @override
  String get removeItemsConfirm =>
      'क्या आप वाकई चयनित उत्पादों को कार्ट से हटाना चाहते हैं?';

  @override
  String get clearCartTitle => 'कार्ट खाली करें?';

  @override
  String get clearCartConfirm =>
      'क्या आप वाकई कार्ट से सभी उत्पाद हटाना चाहते हैं?';

  @override
  String get couponAppliedTitle => 'कूपन लागू!';

  @override
  String get offersAndBenefits => 'ऑफर और लाभ';

  @override
  String get freeGiftMessage =>
      'कूपन \'DEALERDHAMAKA\' लागू: मुफ्त उपहार जोड़ा गया! 🎁';

  @override
  String couponSavedMessage(String amount, String coupon) {
    return 'आपने $coupon के साथ ₹$amount की बचत की';
  }

  @override
  String get viewCouponsAndOffers => 'उपलब्ध कूपन और ऑफर देखें';

  @override
  String get giftLabel => 'उपहार';

  @override
  String get freeLabel => 'मुफ्त';

  @override
  String get enterQuantity => 'मात्रा दर्ज करें';

  @override
  String get specifyQuantityHint =>
      'उन उत्पादों की संख्या निर्दिष्ट करें जिन्हें आप ऑर्डर करना चाहते हैं।';

  @override
  String get egQuantity => 'उदा. 5';

  @override
  String get updateLabel => 'अपडेट करें';

  @override
  String get billDetails => 'बिल विवरण';

  @override
  String get itemTotalSubtotal => 'उत्पाद का कुल मूल्य';

  @override
  String get couponDiscount => 'कूपन छूट';

  @override
  String get deliveryCharges => 'वितरण शुल्क';

  @override
  String get totalAmountPayable => 'कुल देय राशि';

  @override
  String couponSavingsSuccess(String amount) {
    return 'बधाई हो! आपने इस खरीद पर ₹$amount बचाए!';
  }

  @override
  String get tabActive => 'सक्रिय';

  @override
  String get tabDelivered => 'वितरित';

  @override
  String get tabCancelled => 'रद्द';

  @override
  String get tabRto => 'आर टी ओ (RTO)';

  @override
  String get overview => 'अवलोकन';

  @override
  String activeOrdersLabel(int count) {
    return '$count सक्रिय ऑर्डर';
  }

  @override
  String get allOrdersHistory => 'सभी ऑर्डर इतिहास';

  @override
  String totalOrdersCount(int count) {
    return 'कुल $count ऑर्डर';
  }

  @override
  String get noOrdersYet => 'अभी कोई ऑर्डर नहीं है';

  @override
  String get noMatchingOrders => 'कोई मिलान ऑर्डर नहीं';

  @override
  String get orderJourneyBegins =>
      'आपकी कृषि यात्रा यहाँ से शुरू होती है। हमारे उत्पादों को देखें और आज ही अपना पहला ऑर्डर दें!';

  @override
  String noOrdersMatchingStatus(String status) {
    return 'हमें \'$status\' स्थिति के अंतर्गत कोई ऑर्डर नहीं मिला।';
  }

  @override
  String get startExploring => 'खोज शुरू करें';

  @override
  String get viewAllOrders => 'सभी ऑर्डर देखें';

  @override
  String get understandingOrderStatus => 'ऑर्डर की स्थिति समझना';

  @override
  String get whatEachStatusMeans =>
      'यहाँ बताया गया है कि आपके शिपमेंट के लिए प्रत्येक स्थिति का क्या अर्थ है:';

  @override
  String get processing => 'प्रक्रियाधीन';

  @override
  String get processingDesc =>
      'आपके उत्पादों की जाँच की जा रही है, पैक किया जा रहा है और भेजने के लिए तैयार किया जा रहा है।';

  @override
  String get shipped => 'भेज दिया गया';

  @override
  String get shippedDesc =>
      'आपका पैकेज हमारी सुविधा से निकल चुका है और मार्ग में है।';

  @override
  String get outForDelivery => 'वितरण के लिए बाहर';

  @override
  String get outForDeliveryDesc =>
      'आपका पैकेज आपके दरवाजे पर अंतिम वितरण के लिए निकल चुका है।';

  @override
  String get delivered => 'वितरित';

  @override
  String get deliveredDesc => 'शिपमेंट सफलतापूर्वक सौंप दिया गया है।';

  @override
  String get cancelled => 'रद्द';

  @override
  String get cancelledDesc =>
      'ऑर्डर रद्द कर दिया गया था। भुगतान वापस कर दिया जाएगा।';

  @override
  String get needImmediateHelp => 'तत्काल सहायता की आवश्यकता है?';

  @override
  String get supportStaffReady =>
      'हमारी सहायता टीम आपकी मदद के लिए हमेशा तैयार है।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get removeLabel => 'हटाएं';

  @override
  String get orderIdLabel => 'ऑर्डर #';

  @override
  String get paid => 'भुगतान किया गया';

  @override
  String advancePaid(String amount) {
    return 'अग्रिम: ₹$amount';
  }

  @override
  String remainingDue(String amount) {
    return 'शेष: ₹$amount';
  }

  @override
  String itemsCount(int count) {
    return '$count उत्पाद';
  }

  @override
  String cancelledOn(String date) {
    return '$date को रद्द किया गया';
  }

  @override
  String get crops => 'फसलें';

  @override
  String get cropsCollection => 'फसल संग्रह';

  @override
  String get shopByCrop => 'फसल के अनुसार खरीदें';

  @override
  String get browseCategories => 'श्रेणियां खोजें';

  @override
  String cropsCount(int count) {
    return '$count फसलें';
  }

  @override
  String categoriesCount(int count) {
    return '$count श्रेणियां';
  }

  @override
  String get searchHintCrops => 'फसलों के लिए खोजें...';

  @override
  String get searchHintSeeds => 'बीजों के लिए खोजें...';

  @override
  String get searchHintMachinery => 'कृषि उपकरणों के लिए खोजें...';

  @override
  String get searchHintOrganic => 'जैविक उत्पादों के लिए खोजें...';

  @override
  String get badgeGenuine => 'असली उत्पाद';

  @override
  String get badgeTested => 'परीक्षित';

  @override
  String get badgeExpress => 'तेज डिलीवरी';

  @override
  String get recentSearches => 'हाल की खोजें';

  @override
  String get whatAreYouLookingFor => 'आप क्या खोज रहे हैं?';

  @override
  String get tryAdjustingSearch => 'अपने खोज शब्दों को बदलने का प्रयास करें';

  @override
  String get quickDiscovery => 'त्वरित खोज';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get somethingWentWrong => 'ओह! कुछ गलत हो गया।';

  @override
  String get letsConnect => 'आइए संपर्क करें';

  @override
  String get supportSubtitle =>
      'हम आपके कृषि व्यवसाय की सहायता के लिए यहां हैं।';

  @override
  String get onlineSupportActive => 'ऑनलाइन • सहायता सक्रिय';

  @override
  String get offlineResponseDelayed => 'ऑफलाइन • उत्तर में देरी';

  @override
  String get supportHours => 'सोम-शनि (9:00 AM - 7:00 PM)';

  @override
  String get fastResponse => 'त्वरित प्रतिक्रिया';

  @override
  String get quickChat => 'त्वरित चैट';

  @override
  String get directLine => 'सीधी लाइन';

  @override
  String get officialMail => 'आधिकारिक मेल';

  @override
  String get sendQuickInquiry => 'एक त्वरित पूछताछ भेजें';

  @override
  String get selectTopic => 'विषय चुनें';

  @override
  String get messageDetails => 'संदेश का विवरण';

  @override
  String get sendWhatsApp => 'व्हाट्सएप पर भेजें';

  @override
  String get whyTrustKrishiKranti => 'कृषि क्रांति पर क्यों भरोसा करें';

  @override
  String get dataPrivate => 'डेटा निजी';

  @override
  String get cibrcRegd => 'CIB&RC पंजीकृत';

  @override
  String get gstInvoice => 'जीएसटी चालान';

  @override
  String get panIndiaDelivery => 'अखिल भारतीय डिलीवरी';

  @override
  String get topicOrderIssue => 'ऑर्डर की समस्या';

  @override
  String get topicRefundPayment => 'धनवापसी / भुगतान';

  @override
  String get topicBecomeDealer => 'डीलर बनें';

  @override
  String get topicProductQuery => 'उत्पाद पूछताछ';

  @override
  String get topicKycHelp => 'केवाईसी सहायता';

  @override
  String get callUs => 'हमें कॉल करें';

  @override
  String get whatsapp => 'व्हाट्सएप';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get seedsLabel => 'बीज';

  @override
  String get toolsLabel => 'उपकरण';

  @override
  String get availableCoupons => 'उपलब्ध कूपन';

  @override
  String get couponAppliedSuccessfully => 'कूपन सफलतापूर्वक लागू किया गया!';

  @override
  String get noCouponsAvailable => 'अभी कोई कूपन उपलब्ध नहीं है';

  @override
  String minPurchaseLabel(String amount) {
    return 'न्यूनतम खरीद: ₹$amount';
  }

  @override
  String get newUsersOnly => 'केवल नए उपयोगकर्ता';

  @override
  String get applyLabel => 'लागू करें';

  @override
  String get noItemsAvailable => 'कोई आइटम उपलब्ध नहीं है';

  @override
  String get secureCheckout => 'सुरक्षित चेकआउट';

  @override
  String get billingBreakdown => 'बिल का विवरण';

  @override
  String get subtotalLabel => 'उप-योग';

  @override
  String get couponDiscountLabel => 'कूपन छूट';

  @override
  String get grandTotal => 'कुल देय राशि';

  @override
  String advanceBookingDeposit(int percent) {
    return 'अग्रिम बुकिंग जमा ($percent%)';
  }

  @override
  String get remainingBalanceAtDelivery => 'वितरण पर शेष राशि';

  @override
  String get dealerDhamakaBanner =>
      'कूपन \'DEALERDHAMAKA\' लागू: मुफ्त उत्पाद जोड़ा गया! 🎁';

  @override
  String couponSavingsBannerCheckout(String amount) {
    return 'आपने इस कूपन से ₹$amount बचाए 🎉';
  }

  @override
  String get hundredPercentSecure => '100% सुरक्षित';

  @override
  String get fastDelivery => 'तेज़ डिलीवरी';

  @override
  String get paymentMode => 'भुगतान का तरीका';

  @override
  String get payFullOnline => 'पूरा ऑनलाइन भुगतान करें';

  @override
  String get payFullOnlineDesc =>
      'UPI/कार्ड के माध्यम से सुरक्षित रूप से पूर्ण ऑर्डर राशि का भुगतान करें';

  @override
  String get partialBookingAdvance => 'आंशिक बुकिंग अग्रिम';

  @override
  String get partialBookingAdvanceDesc =>
      'एक मामूली टोकन जमा के साथ अपना ऑर्डर बुक करें';

  @override
  String get chooseAdvanceAmount => 'अग्रिम राशि चुनें';

  @override
  String get payableAmount => 'देय राशि:';

  @override
  String get bookingAdvanceLabel => 'बुकिंग अग्रिम:';

  @override
  String get remainingBalanceDelivery => 'वितरण पर शेष राशि:';

  @override
  String get addAddressToPay => 'भुगतान के लिए पता जोड़ें';

  @override
  String get proceedToPay => 'भुगतान के लिए आगे बढ़ें';

  @override
  String get deliverTo => 'वितरित करें';

  @override
  String get changeAddress => 'बदलें';

  @override
  String get addShippingAddress => 'शिपिंग पता जोड़ें';

  @override
  String get addShippingAddressHint =>
      'ऑर्डर देने के लिए कृपया एक शिपिंग पता जोड़ें';

  @override
  String get selectShippingAddress => 'शिपिंग पता चुनें';

  @override
  String get addNewAddress => 'नया पता जोड़ें';

  @override
  String get pleaseSelectPaymentMethod => 'कृपया भुगतान विधि चुनें';

  @override
  String get pleaseSelectAddress => 'कृपया एक शिपिंग पता चुनें';

  @override
  String paymentFailed(String message) {
    return 'भुगतान विफल: $message';
  }

  @override
  String errorLaunchingRazorpay(String error) {
    return 'Razorpay शुरू करने में त्रुटि: $error';
  }

  @override
  String paymentSetupFailed(String error) {
    return 'भुगतान सेटअप विफल रहा: $error';
  }

  @override
  String failedToPlaceOrder(String error) {
    return 'ऑर्डर देने में विफल: $error';
  }

  @override
  String get orderSyncRequired => 'ऑर्डर सिंक आवश्यक';

  @override
  String get orderSyncDescription =>
      'आपका भुगतान सफल रहा, लेकिन हमारे सर्वर को आपके ऑर्डर विवरण की पुष्टि करते समय एक त्रुटि का सामना करना पड़ा।';

  @override
  String get paymentRefKeepSafe => 'भुगतान संदर्भ (सुरक्षित रखें):';

  @override
  String get doNotCloseApp =>
      'कृपया ऐप बंद न करें। अपने ऑर्डर पंजीकरण को तुरंत पूरा और सुरक्षित करने के लिए नीचे \'अभी पुनः प्रयास करें\' पर टैप करें।';

  @override
  String get copyId => 'आईडी कॉपी करें';

  @override
  String get retryNow => 'अभी पुनः प्रयास करें';

  @override
  String get paymentRefCopied => 'भुगतान संदर्भ क्लिपबोर्ड पर कॉपी किया गया!';

  @override
  String get securingYourOrder => 'आपका ऑर्डर सुरक्षित किया जा रहा है... 🔒';

  @override
  String get pciDssCompliant => 'PCI-DSS अनुपालन एसएसएल सुरक्षा परत';

  @override
  String get processingStep1 =>
      'क्लाइंट वातावरण सैंडबॉक्स को स्कैन किया जा रहा है... 🛡️';

  @override
  String get processingStep2 =>
      'लेन-देन इंजेक्शन कमजोरियों का विश्लेषण किया जा रहा है... 🔒';

  @override
  String get processingStep3 =>
      'सुरक्षित एपीआई सॉकेट हैंडशेक को सत्यापित किया जा रहा है... ⛓️';

  @override
  String get processingStep4 =>
      'पेलोड हस्ताक्षर अखंडता को मान्य किया जा रहा है... 🔑';

  @override
  String get processingStep5 =>
      'एंड-టు-एंड एसएसएल एन्क्रिप्शन को अंतिम रूप दिया जा रहा है... 🚀';

  @override
  String qtyLabel(int qty) {
    return 'मात्रा: $qty';
  }

  @override
  String goToMyOrders(int seconds) {
    return 'मेरे ऑर्डर पर जाएं (${seconds}s)';
  }

  @override
  String get orderSuccessMessage =>
      'आपकी खरीद के लिए धन्यवाद। हम शिपमेंट के लिए आपका ऑर्डर तैयार कर रहे हैं। आइए आगे बढ़ें!';

  @override
  String get orderSecuredMessage =>
      'आपकी बुकिंग जमा राशि प्राप्त हो गई है और आपका ऑर्डर अब सुरक्षित है। आइए आगे बढ़ें!';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileUpdatedSuccessfully => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई!';

  @override
  String get generalOptions => 'सामान्य विकल्प';

  @override
  String get identityVerification => 'पहचान सत्यापन';

  @override
  String get empoweringAgriDealers => 'भारत भर में कृषि डीलरों को सशक्त बनाना';

  @override
  String get storeName => 'दुकान का नाम';

  @override
  String get enterStoreName => 'अपने दुकान का नाम दर्ज करें';

  @override
  String get useCurrentLocation => 'वर्तमान स्थान उपयोग करें';

  @override
  String get addressHint => 'मकान नं., गली, क्षेत्र';

  @override
  String get address2Hint => 'लैंडमार्क, कॉलोनी, आदि';

  @override
  String get sortAndFilter => 'क्रम व फ़िल्टर';

  @override
  String get resetAll => 'सभी रीसेट करें';

  @override
  String get sortBy => 'इससे क्रमबद्ध करें';

  @override
  String get filterBy => 'इससे फ़िल्टर करें';

  @override
  String get inStockOnly => 'केवल स्टॉक में';

  @override
  String get inStockOnlyDesc => 'वर्तमान में अनुपलब्ध उत्पाद छुपाएं';

  @override
  String get exclusiveOffersDeals => 'विशेष ऑफर और डील्स';

  @override
  String get exclusiveOffersDealsDesc => 'कम मूल्य वाले डीलर उत्पाद दिखाएं';

  @override
  String get applyFilters => 'फ़िल्टर लागू करें';

  @override
  String get noProductsFound => 'कोई उत्पाद नहीं मिला';

  @override
  String get noProductsFoundDesc =>
      'आपके मानदंड या उपश्रेणी से मेल खाने वाले उत्पाद नहीं मिले।';

  @override
  String get clearAllFilters => 'सभी फ़िल्टर हटाएं';

  @override
  String get exclusiveCollection => 'विशेष संग्रह';

  @override
  String get loadingLabel => 'लोड हो रहा है...';

  @override
  String itemsAvailable(int count) {
    return '$count आइटम उपलब्ध';
  }

  @override
  String get selectPackagingQuantity => 'पैकेजिंग और मात्रा चुनें';

  @override
  String get expertChoice => 'विशेषज्ञ की पसंद';

  @override
  String get fastActing => 'तेज़ असर';

  @override
  String get hundredPercentOriginal => '100% मूल';

  @override
  String get addLabel => 'जोड़ें';

  @override
  String totalItems(int count) {
    return 'कुल आइटम: $count';
  }

  @override
  String grandTotalLabel(String amount) {
    return 'कुल योग: ₹$amount';
  }

  @override
  String get cancelLabel => 'रद्द करें';

  @override
  String get updateLabel2 => 'अपडेट करें';

  @override
  String get enterValueHint => 'मूल्य दर्ज करें';

  @override
  String get details => 'विवरण';

  @override
  String get specifications => 'विनिर्देशों';

  @override
  String get productDescription => 'उत्पाद विवरण';

  @override
  String get showMore => 'अधिक दिखाएं';

  @override
  String get showLess => 'कम दिखाएं';

  @override
  String get wholesaleTierPricing => 'थोक मूल्य निर्धारण';

  @override
  String currentVolume(String volume) {
    return 'वर्तमान मात्रा: $volume';
  }

  @override
  String get goToCart => 'कार्ट में जाएं';

  @override
  String get buyNow => 'अभी खरीदें';

  @override
  String get pleaseSelectPackSize => 'कृपया एक पैक आकार चुनें';

  @override
  String get failedToRemoveItem => 'आइटम हटाने में विफल';

  @override
  String failedToUpdateCart(String error) {
    return 'कार्ट अपडेट करने में विफल: $error';
  }

  @override
  String unlockTierPricing(String tier) {
    return '$tier मूल्य निर्धारण अनलॉक करें!';
  }

  @override
  String get getWholesaleRates => 'थोक मात्रा पर थोक दरें प्राप्त करें';

  @override
  String get regularPrice => 'नियमित मूल्य';

  @override
  String get wholesaleRate => 'थोक दर';

  @override
  String totalBulkSavings(String savings) {
    return 'कुल थोक बचत: ₹$savings!';
  }

  @override
  String get requiredVolumeProgression => 'आवश्यक मात्रा प्रगति';

  @override
  String currentProgress(String vol, int packs) {
    return 'वर्तमान: $vol ($packs पैक)';
  }

  @override
  String targetProgress(String vol, int packs) {
    return 'लक्ष्य: $vol ($packs पैक)';
  }

  @override
  String addingMorePacksUnlocks(int diff, String discount, String unit) {
    return 'इस आकार के $diff और पैक जोड़ने से सभी इकाइयों पर प्रति $unit ₹$discount की छूट मिलती है!';
  }

  @override
  String get keepCurrent => 'वर्तमान रखें';

  @override
  String addDiffAndSave(int diff) {
    return '$diff जोड़ें और बचाएं';
  }

  @override
  String get adjustQuantity => 'मात्रा समायोजित करें';

  @override
  String get confirmLabel => 'पुष्टि करें';

  @override
  String saveAmount(String amount) {
    return '₹$amount बचाएं';
  }

  @override
  String tierUnlockedMessage(String tier, String price, String unit) {
    return 'आपने $tier अनलॉक किया! अब ₹$price/$unit की कीमत का आनंद लें. 🎉';
  }

  @override
  String get zeroReviews => ' (0 समीक्षाएं)';

  @override
  String get stepCart => 'कार्ट';

  @override
  String get stepCheckout => 'चेकआउट';

  @override
  String get stepPayment => 'भुगतान';

  @override
  String get updateRequired => 'अपडेट आवश्यक है';

  @override
  String get updateAvailable => 'अपडेट उपलब्ध है';

  @override
  String get forceUpdateMsg =>
      'एक महत्वपूर्ण अपडेट उपलब्ध है। कृपया हमारी सेवाओं का उपयोग जारी रखने के लिए ऐप को अपडेट करें।';

  @override
  String get optionalUpdateMsg =>
      'नई सुविधाओं और सुधारों के साथ ऐप का नया वर्शन उपलब्ध है।';

  @override
  String get later => 'बाद में';

  @override
  String get updateNow => 'अभी अपडेट करें';

  @override
  String get kycUnderReview => 'दस्तावेज़ समीक्षा के अधीन हैं';

  @override
  String get kycUnderReviewSubtitle =>
      'आपके दस्तावेज़ वर्तमान में संसाधित किए जा रहे हैं।';
}
