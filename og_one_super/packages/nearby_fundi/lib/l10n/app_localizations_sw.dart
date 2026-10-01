// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'NearbyFundi';

  @override
  String get nearby => 'Nyumbani';

  @override
  String get nearbyMap => 'Ramani ya Karibu';

  @override
  String get near => 'Karibu na';

  @override
  String get blog => 'Blogu';

  @override
  String get requests => 'Maombi';

  @override
  String get myRequests => 'Maombi';

  @override
  String get profile => 'Profaili';

  @override
  String get settings => 'Mipangilio';

  @override
  String get chat => 'Mazungumzo';

  @override
  String get payments => 'Malipo';

  @override
  String get findFundi => 'Tafuta Fundi';

  @override
  String get searchLocation => '📍 Tafuta eneo...';

  @override
  String get search => 'Tafuta';

  @override
  String get filterByService => '🔧 Chuja kwa huduma...';

  @override
  String get all => 'Zote';

  @override
  String get allServices => 'Huduma Zote';

  @override
  String get category => 'Kategoria';

  @override
  String get noServicesFound => 'Hakuna huduma zilizopatikana';

  @override
  String get noServicesMatch => 'Hakuna huduma zinazolingana na kichujio chako';

  @override
  String get clearAllFilters => 'Futa Vichujio Vyote';

  @override
  String get clearFilters => 'Futa vichujio';

  @override
  String get filtered => 'Imechujwa';

  @override
  String get onlineOnly => 'Walioko mtandaoni pekee';

  @override
  String get viewOnMap => 'Angalia kwenye ramani';

  @override
  String get refresh => 'Fresha';

  @override
  String get noFundisFound => 'Hakuna Mafundi Waliopatikana';

  @override
  String get tryAdjustingSearch => 'Jaribu kubadilisha utafutaji wako au eneo';

  @override
  String get fundisFound => 'mafundi wamepatikana';

  @override
  String get searchingForFundis => 'Kutafuta mafundi...';

  @override
  String get oopsSomethingWentWrong => 'Lo! Kuna hitilafu imetokea';

  @override
  String get pleaseTryAgain => 'Tafadhali jaribu tena';

  @override
  String get retry => 'Jaribu Tena';

  @override
  String noResultsFor(Object service) {
    return 'Hakuna Mafundi kwa $service';
  }

  @override
  String noResultsForServiceCategory(Object category, Object service) {
    return 'Hakuna Mafundi kwa $service ($category)';
  }

  @override
  String get tryDifferentCategoryOrService => 'Jaribu kategoria au huduma nyingine';

  @override
  String get tryDifferentService => 'Jaribu kuchagua huduma nyingine';

  @override
  String get tryAdjustingLocation => 'Jaribu kubadilisha utafutaji wako au eneo';

  @override
  String get suggestionClearFilters => 'Jaribu kuondoa vichujio vyako';

  @override
  String get suggestionDifferentLocation => 'Jaribu eneo lingine';

  @override
  String get suggestionDifferentService => 'Jaribu huduma nyingine';

  @override
  String get suggestionRemoveFilters => 'Jaribu kuondoa vichujio vya huduma/kategoria';

  @override
  String get suggestionIncreaseRadius => 'Jaribu kuongeza eneo la utafutaji';

  @override
  String get suggestionAllCategories => 'Jaribu kuchagua \'Kategoria Zote\'';

  @override
  String get suggestionAllServices => 'Jaribu kuchagua \'Huduma Zote\'';

  @override
  String get kmAway => 'km mbali';

  @override
  String get viewProfile => 'Angalia Profaili';

  @override
  String get directions => 'Njia';

  @override
  String get online => 'Mtandaoni';

  @override
  String get offline => 'Nje ya Mtandao';

  @override
  String get request => 'Omba';

  @override
  String get requestThisFundi => 'Omba Fundi huyu';

  @override
  String get requestAlreadySent => 'Ombi tayari limetumwa';

  @override
  String get hourlyRate => 'Kiwango cha Saa';

  @override
  String get tzs => 'TZS';

  @override
  String get socialMedia => 'Mitandao ya Kijamii';

  @override
  String get contact => 'Mawasiliano';

  @override
  String get call => 'Piga';

  @override
  String get items => 'vitu';

  @override
  String get sendingToTechnician => 'Inatuma kwa fundi...';

  @override
  String get awaitingResponse => 'Kusubiri jibu...';

  @override
  String get noServicesSelected => 'Hakuna huduma zilizochaguliwa';

  @override
  String get selectService => 'Chagua huduma';

  @override
  String get welcomeBack => 'Karibu Tena';

  @override
  String get signInToContinue => 'Ingia ili kuendelea';

  @override
  String get signInManage => 'Ingia ili kusimamia huduma zako';

  @override
  String get emailAddress => 'Barua pepe';

  @override
  String get password => 'Nenosiri';

  @override
  String get forgotPassword => 'Umesahau Nenosiri?';

  @override
  String get signIn => 'Ingia';

  @override
  String get dontHaveAccount => 'Huna akaunti?';

  @override
  String get signUp => 'Jisajili';

  @override
  String get createAccount => 'Unda Akaunti';

  @override
  String get joinCommunity => 'Jiunge na jamii ya watumiaji mahiri';

  @override
  String get fullName => 'Jina Kamili';

  @override
  String get phoneNumber => 'Namba ya Simu';

  @override
  String get confirmPassword => 'Thibitisha Nenosiri';

  @override
  String get verificationCode => 'Msimbo wa Uthibitishaji';

  @override
  String get enterCodeSent => 'Ingiza msimbo uliotumwa kwa';

  @override
  String get enterOtp => 'Ingiza OTP';

  @override
  String get otpSent => 'Msimbo wa tarakimu 6 umetumwa kwa barua pepe yako';

  @override
  String get verifyOtp => 'Thibitisha OTP';

  @override
  String get backToSignIn => 'Rudi kwenye Kuingia';

  @override
  String get noWorries => 'Usijali — tutakutumia msimbo wa kuweka upya';

  @override
  String get resetPassword => 'Weka upya Nenosiri';

  @override
  String get enterEmailReset => 'Ingiza barua pepe yako ili kupokea msimbo wa uthibitishaji';

  @override
  String get sendResetCode => 'Tuma Msimbo wa Kuweka upya';

  @override
  String get setNewPassword => 'Weka Nenosiri Jipya';

  @override
  String get otpSentTo => 'OTP imetumwa kwa';

  @override
  String get otpCode => 'Msimbo wa OTP';

  @override
  String get newPassword => 'Nenosiri Jipya';

  @override
  String get resetPasswordButton => 'Weka upya Nenosiri';

  @override
  String get logout => 'Toka';

  @override
  String get logoutConfirmation => 'Una uhakika unataka kutoka?';

  @override
  String get deleteAccount => 'Futa Akaunti';

  @override
  String get deleteAccountConfirmation => 'Kitendo hiki ni cha kudumu. Data yako yote itapotea. Una uhakika?';

  @override
  String get areYouSure => 'Una uhakika?';

  @override
  String get yes => 'Ndio';

  @override
  String get no => 'Hapana';

  @override
  String get cancel => 'Ghairi';

  @override
  String get delete => 'Futa';

  @override
  String get enterEmail => 'Ingiza anwani yako ya barua pepe';

  @override
  String get enterValidEmail => 'Ingiza anwani sahihi ya barua pepe';

  @override
  String get enterPassword => 'Ingiza nenosiri lako';

  @override
  String get passwordMinLength => 'Nenosiri lazima liwe na angalau herufi 6';

  @override
  String get pleaseAcceptTerms => 'Tafadhali kubali Masharti na Sheria';

  @override
  String get iAgreeToThe => 'Nakubali';

  @override
  String get termsAndConditions => 'Masharti na Sheria';

  @override
  String get and => 'na';

  @override
  String get or => 'AU';

  @override
  String get continueWithGoogle => 'Endelea na Google';

  @override
  String get editProfile => 'Hariri Profaili';

  @override
  String get editProfileTitle => 'Hariri Profaili';

  @override
  String get updateInfo => 'Sasisha Taarifa Zako';

  @override
  String get name => 'Jina Kamili';

  @override
  String get phone => 'Simu';

  @override
  String get saveChanges => 'Hifadhi Mabadiliko';

  @override
  String get profileUpdated => 'Profaili imesasishwa';

  @override
  String get updateFailed => 'Kusasisha kumeshindwa';

  @override
  String get guest => 'Mgeni';

  @override
  String get technician => 'Fundi';

  @override
  String get technicianNotFound => 'Fundi hapatikani';

  @override
  String get about => 'Kuhusu';

  @override
  String get bio => 'Maelezo';

  @override
  String get experience => 'Uzoefu';

  @override
  String get years => 'miaka';

  @override
  String get area => 'Eneo';

  @override
  String get accountStatus => 'Hali ya Akaunti';

  @override
  String get active => 'Inatumika';

  @override
  String get onlineStatus => 'Hali ya Mtandao';

  @override
  String get youAreOnline => 'Uko mtandaoni';

  @override
  String get youAreOffline => 'Uko nje ya mtandao';

  @override
  String get servicesIOffer => 'Huduma Ninazotoa';

  @override
  String get selectServicesDialogTitle => 'Chagua Huduma';

  @override
  String get selectAtLeastOneService => 'Tafadhali chagua angalau huduma moja';

  @override
  String get servicesUpdated => 'Huduma zimesasishwa';

  @override
  String get pushNotifications => 'Arifa za Kusukuma';

  @override
  String get receiveAlerts => 'Pokea arifa kuhusu maombi na sasisho';

  @override
  String get language => 'Lugha';

  @override
  String get theme => 'Mandhari';

  @override
  String get aboutUs => 'Kuhusu Sisi';

  @override
  String get faq => 'Maswali Yanayoulizwa Sana';

  @override
  String get terms => 'Masharti na Sheria';

  @override
  String get contactUs => 'Wasiliana Nasi';

  @override
  String get version => 'Toleo';

  @override
  String get noRequestsYet => 'Hakuna maombi bado';

  @override
  String get requestsWillAppear => 'Maombi yako yataonekana hapa';

  @override
  String get cancelRequest => 'Ghairi Ombi';

  @override
  String get areYouSureCancel => 'Una uhakika unataka kughairi ombi hili?';

  @override
  String get requestSent => 'Ombi limetumwa kwa mafanikio!';

  @override
  String get preparingRequest => 'Kuandaa ombi lako...';

  @override
  String get validatingDetails => 'Kuthibitisha maelezo...';

  @override
  String get creatingRequest => 'Kuunda ombi la huduma...';

  @override
  String get failedToSubmit => 'Imeshindwa kutuma ombi.';

  @override
  String get describeIssue => 'Elezea tatizo lako';

  @override
  String get describeHint => 'mfano. AC yangu haipoi...';

  @override
  String get submitRequest => 'Tuma Ombi';

  @override
  String get done => 'Imekamilika';

  @override
  String get pleaseSelectService => 'Tafadhali chagua huduma';

  @override
  String get newRequest => 'Ombi Jipya';

  @override
  String get requestAccepted => 'Ombi Limekubaliwa';

  @override
  String get requestRejected => 'Ombi Limekataliwa';

  @override
  String get requestInProgress => 'Ombi Linaendelea';

  @override
  String get requestCompleted => 'Ombi Limekamilika';

  @override
  String get noBlogPosts => 'Bado hakuna machapisho.';

  @override
  String get noCommentsYet => 'Hakuna maoni bado. Kuwa wa kwanza!';

  @override
  String get writeComment => 'Andika maoni...';

  @override
  String get comments => 'Maoni';

  @override
  String get postedOn => 'Ilichapishwa tarehe';

  @override
  String get likes => 'Vipendwa';

  @override
  String get like => 'Penda';

  @override
  String get unlike => 'Toka kwenye Pendwa';

  @override
  String get share => 'Shiriki';

  @override
  String get edit => 'Hariri';

  @override
  String get deletePost => 'Futa Chapisho';

  @override
  String get areYouSureDeletePost => 'Una uhakika unataka kufuta chapisho hili?';

  @override
  String get postDeleted => 'Chapisho limefutwa';

  @override
  String get postCreated => 'Chapisho limeundwa';

  @override
  String get postUpdated => 'Chapisho limesasishwa';

  @override
  String get title => 'Kichwa';

  @override
  String get content => 'Maudhui';

  @override
  String get image => 'Picha';

  @override
  String get createPost => 'Unda Chapisho';

  @override
  String get updatePost => 'Sasisha Chapisho';

  @override
  String get myPosts => 'Machapisho Yangu';

  @override
  String get portfolio => 'Kwingineko';

  @override
  String get noPortfolioItems => 'Hakuna vitu kwenye kwingineko.';

  @override
  String get notifications => 'Arifa';

  @override
  String get markAllAsRead => 'Weka zote kama zimesomwa';

  @override
  String get noNotificationsYet => 'Hakuna arifa bado';

  @override
  String get notification => 'Arifa';

  @override
  String get noConversationsYet => 'Hakuna mazungumzo bado';

  @override
  String get startChattingWithFundis => 'Anza kuzungumza na mafundi karibu nawe';

  @override
  String get noMessagesYet => 'Hakuna ujumbe bado';

  @override
  String get sayHelloToStart => 'Sema hello kuanza mazungumzo';

  @override
  String get typeAMessage => 'Andika ujumbe...';

  @override
  String get justNow => 'Sasa hivi';

  @override
  String get copy => 'Nakili';

  @override
  String get messageCopied => 'Ujumbe umenakiliwa';

  @override
  String get messageDeleted => 'Ujumbe umefutwa';

  @override
  String get deleteMessage => 'Futa Ujumbe';

  @override
  String get areYouSureDeleteMessage => 'Una uhakika unataka kufuta ujumbe huu?';

  @override
  String get failedToSend => 'Imeshindwa kutuma ujumbe';

  @override
  String get failedToSendImage => 'Imeshindwa kutuma picha';

  @override
  String get failedToSendFile => 'Imeshindwa kutuma faili';

  @override
  String get voiceRecordingComingSoon => 'Kurekodi sauti inakuja hivi karibuni!';

  @override
  String get messageReactionAdded => 'Mwitikio umeongezwa';

  @override
  String get messageReactionRemoved => 'Mwitikio umeondolewa';

  @override
  String get typing => 'Anaandika...';

  @override
  String get download => 'Pakua';

  @override
  String get fileDownloaded => 'Faili imepakuliwa';

  @override
  String get fileDownloadFailed => 'Imeshindwa kupakua faili';

  @override
  String get conversationDeleted => 'Mazungumzo yamefutwa';

  @override
  String get areYouSureDeleteConversation => 'Una uhakika unataka kufuta mazungumzo haya?';

  @override
  String get noInternetConnection => 'Hakuna muunganisho wa mtandao';

  @override
  String get connecting => 'Inaunganisha...';

  @override
  String get disconnected => 'Imeondolewa';

  @override
  String get reconnecting => 'Inaunganisha tena...';

  @override
  String get noContent => 'Hakuna maudhui.';

  @override
  String get getInTouch => 'Wasiliana Nasi';

  @override
  String get email => 'Barua pepe';

  @override
  String get website => 'Tovuti';

  @override
  String get phoneNumbers => 'Namba za Simu';

  @override
  String get noFaqs => 'Hakuna Maswali Yanayoulizwa Sana.';

  @override
  String get welcomeFundi => 'Tafuta Fundi wa Kuaminika';

  @override
  String get findTrustedDesc => 'Ungana na fundi walio na uthibitisho na uzoefu karibu nawe. Omba huduma kama vile ukarabati wa AC, mabomba, na mengine.';

  @override
  String get requestTrack => 'Omba na Fuatilia';

  @override
  String get requestTrackDesc => 'Tuma ombi la huduma, kubaliwa na fundi, na fuata hali kwa wakati halisi. Rahisi, haraka, na ya kuaminika.';

  @override
  String get getStarted => 'Anza';

  @override
  String get next => 'Inayofuata';

  @override
  String get skip => 'Ruka';

  @override
  String get failed => 'Imeshindwa';

  @override
  String get services => 'Huduma';

  @override
  String get generalServices => 'Huduma za Jumla';

  @override
  String get fundi => 'Fundi';

  @override
  String get rate => 'Kiwango';

  @override
  String get aboutFundi => 'Kuhusu';

  @override
  String get servicesAndRate => 'Huduma na Kiwango';

  @override
  String get searchPlaceFirst => 'Tafuta eneo kwanza ili kuiona kwenye ramani.';

  @override
  String get searchPlaceHint => 'Rudi nyuma na utafute eneo kuona mafundi karibu.';

  @override
  String get aiAssistant => 'Msaidizi wa AI';

  @override
  String get comingSoon => 'inakuja hivi karibuni!';

  @override
  String get pleaseEnterLocation => 'Tafadhali ingiza mahali';

  @override
  String get searchServiceHint => 'Tafuta huduma (mfano. mabomba, umeme...)';

  @override
  String noFundisForService(Object service) {
    return 'Hakuna mafundi kwa $service';
  }

  @override
  String get refreshed => 'Imefresha';

  @override
  String get refreshFailed => 'Kufresha kumeshindwa';

  @override
  String get pullToRefresh => 'Buruta ili kufresha';

  @override
  String get loading => 'Inapakia...';

  @override
  String get showList => 'Orodha';

  @override
  String get viewAll => 'Ona Yote';

  @override
  String get jobsCompleted => 'kazi zilizokamilika';

  @override
  String get rating => 'Ukadiriaji';

  @override
  String get privacyPolicy => 'Sera ya Faragha';

  @override
  String get send => 'Tuma';
}
