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
  String get myRequests => 'Maombi Yangu';

  @override
  String get profile => 'Profaili';

  @override
  String get settings => 'Mipangilio';

  @override
  String get chat => 'Mazungumzo';

  @override
  String get payments => 'Malipo';

  @override
  String get jobs => 'Kazi';

  @override
  String get tickets => 'Tiketi';

  @override
  String get soon => 'Hivi karibuni';

  @override
  String get becomeFundi => 'Kuwa Fundi';

  @override
  String get secureChatTitle => 'Karibu kwenye mawasiliano salama ya kazi';

  @override
  String get secureChatDescription => 'Jadili huduma, jadiliana kuhusu bei na kubaliana kuhusu kazi kabla ya kufanya malipo.';

  @override
  String get secureChatBargain => 'Jadiliana bei moja kwa moja na fundi wako.';

  @override
  String get secureChatAgreePrice => 'Kubalianeni kuhusu gharama yote ya kazi.';

  @override
  String get secureChatDeposit => 'Lipa amana inayohitajika kwa usalama.';

  @override
  String get secureChatHoldDeposit => 'OG ONE-GROUP itahifadhi amana hadi kazi itakapokamilika.';

  @override
  String get secureChatWarning => 'Usitume malipo moja kwa moja kwa fundi nje ya mfumo wa OG ONE-GROUP.';

  @override
  String get secureChatCancel => 'Ghairi';

  @override
  String get secureChatGotIt => 'Sawa, nimeelewa';

  @override
  String get secureChatSafety => 'Usalama wa malipo yako ni muhimu';

  @override
  String get secureChatDepositInfo => 'Amana yako inalindwa kupitia mfumo wetu.';

  @override
  String get otpDigitRequired => 'Weka OTP ya tarakimu 6';

  @override
  String get passwordMinLength => 'Nenosiri lazima liwe na angalau herufi 6';

  @override
  String get repeatPassword => 'Rudia nenosiri lako';

  @override
  String get passwordsDoNotMatch => 'Manenosiri hayafanani';

  @override
  String get languageEnglish => 'English 🇬🇧';

  @override
  String get languageSwahili => 'Kiswahili 🇹🇿';

  @override
  String get themeLight => 'Mwanga ☀️';

  @override
  String get themeDark => 'Giza 🌙';

  @override
  String get themeSystem => 'Mfumo ⚙️';

  @override
  String get accountVerified => 'Akaunti imethibitishwa!';

  @override
  String get welcomeToApp => 'Karibu NearbyFundi';

  @override
  String welcomeToAppName(String name) {
    return 'Karibu NearbyFundi, $name';
  }

  @override
  String get takingYouToDashboard => 'Tunakupeleka kwenye dashibodi yako…';

  @override
  String get continueButton => 'Endelea';

  @override
  String get invalidOrExpiredCode => 'Nambari si sahihi au imeisha muda. Jaribu tena.';

  @override
  String get couldNotSendCodeAuto => 'Hatukuweza kutuma nambari kiotomatiki. Bonyeza \"Tuma tena\" hapa chini.';

  @override
  String codeSentBySms(String target) {
    return 'Tumetuma nambari ya tarakimu 6 kwa SMS kwenda\n$target';
  }

  @override
  String codeSentByEmail(String target) {
    return 'Tumetuma nambari ya tarakimu 6 kwenye barua pepe yako\n$target';
  }

  @override
  String get newCodeSent => 'Nambari mpya imetumwa.';

  @override
  String get couldNotResendCode => 'Imeshindwa kutuma tena. Jaribu tena.';

  @override
  String resendCodeIn(String time) {
    return 'Tuma tena baada ya $time';
  }

  @override
  String get resendCode => 'Tuma tena msimbo';

  @override
  String get changeMyDetails => 'Badilisha taarifa zangu';

  @override
  String get passwordResetSuccess => 'Nenosiri limebadilishwa kwa mafanikio';

  @override
  String get emailHint => 'wewe@mfano.com';

  @override
  String get registerPhoneHint => '712345678';

  @override
  String get splashTagline => 'Pata msaada unaoaminika, mahali unapohitaji.';

  @override
  String get onboardFindFundisTitle => 'Pata Mafundi';

  @override
  String get onboardFindFundisDesc => 'Gundua mafundi wanaoaminika na waliothibitishwa wanaotoa huduma bora karibu nawe.';

  @override
  String get onboardConnectFastTitle => 'Ungana Haraka';

  @override
  String get onboardConnectFastDesc => 'Vinjari wasifu wa mafundi, angalia ukadiriaji na ungana na mtaalamu sahihi.';

  @override
  String get onboardGetItDoneTitle => 'Kamilisha';

  @override
  String get onboardGetItDoneDesc => 'Tuma ombi lako, likubaliwe na fuatilia huduma yako kutoka mwanzo hadi mwisho.';

  @override
  String get benefitVerified => 'Imethibitishwa';

  @override
  String get benefitTrusted => 'Inaaminika';

  @override
  String get benefitFast => 'Haraka';

  @override
  String get rememberMe => 'Nikumbuke';

  @override
  String get orContinueWith => 'au endelea na';

  @override
  String get phoneHint => '679117291';

  @override
  String get pleaseEnterPhone => 'Tafadhali ingiza namba ya simu';

  @override
  String get enterValidPhoneDigits => 'Ingiza namba sahihi ya tarakimu 9';

  @override
  String get back => 'Rudi';

  @override
  String get trustedTechniciansNearYou => 'Mafundi wa kuaminika karibu nawe';

  @override
  String get nearbyFundiTagline => 'NearbyFundi • mafundi wa kuaminika karibu nawe';

  @override
  String get registerNameTooShort => 'Jina ni fupi sana';

  @override
  String get registerEmailRequired => 'Barua pepe inahitajika';

  @override
  String get registerPhoneRequired => 'Namba ya simu inahitajika';

  @override
  String get registerValidTanzaniaPhone => 'Weka namba sahihi ya Tanzania, mfano 0712 345 678';

  @override
  String get registerValidPhone => 'Weka namba sahihi ya simu';

  @override
  String get registerPasswordRequired => 'Nenosiri linahitajika';

  @override
  String get registerPasswordMinLength => 'Nenosiri lazima liwe na angalau herufi 8';

  @override
  String get registerPasswordStrength => 'Tumia herufi kubwa, herufi ndogo na namba';

  @override
  String get registerConfirmPasswordRequired => 'Tafadhali thibitisha nenosiri lako';

  @override
  String get registerPasswordsMismatch => 'Manenosiri hayafanani';

  @override
  String get registerFailedRetry => 'Usajili umeshindwa. Tafadhali jaribu tena.';

  @override
  String get registerOtpSendFailed => 'Akaunti imeundwa, lakini hatukuweza kutuma msimbo. Tafadhali jaribu tena.';

  @override
  String get registerPasswordHint => 'Herufi 8+, kubwa + ndogo + namba';

  @override
  String get registerRepeatPassword => 'Rudia nenosiri lako';

  @override
  String get registerRuleLength => 'Herufi 8+';

  @override
  String get registerRuleUppercase => 'Herufi kubwa';

  @override
  String get registerRuleLowercase => 'Herufi ndogo';

  @override
  String get registerRuleNumber => 'Namba';

  @override
  String get registerAlreadyHaveAccount => 'Tayari una akaunti?';

  @override
  String get registerSearchCountry => 'Tafuta nchi...';

  @override
  String get registerNoCountryFound => 'Hakuna nchi iliyopatikana';

  @override
  String get refresh => 'Sasisha';

  @override
  String get blogSearchHint => 'Tafuta kwa jina la fundi...';

  @override
  String get blogEmptySubtitle => 'Rudi baadaye kupata taarifa mpya kutoka kwa mafundi wetu.';

  @override
  String get retry => 'Jaribu Tena';

  @override
  String blogNoResults(String query) {
    return 'Hakuna machapisho yanayolingana na \"$query\"';
  }

  @override
  String get loadMorePosts => 'Pakia machapisho zaidi';

  @override
  String get imageNotAvailable => 'Picha haipatikani';

  @override
  String get viewProfile => 'Angalia Profaili';

  @override
  String get timeJustNow => 'Sasa hivi';

  @override
  String timeMinutesAgo(int count) {
    return 'Dakika $count zilizopita';
  }

  @override
  String timeHoursAgo(int count) {
    return 'Saa $count zilizopita';
  }

  @override
  String timeDaysAgo(int count) {
    return 'Siku $count zilizopita';
  }

  @override
  String get cancel => 'Ghairi';

  @override
  String get sendSmsCode => 'Tuma Msimbo wa SMS';

  @override
  String get confirmCompletionBody => 'Je, ungependa kutuma msimbo wa uthibitishaji wa tarakimu 6 kwa SMS ili kukamilisha kazi hii?';

  @override
  String get comingSoon => 'inakuja hivi karibuni!';

  @override
  String get yourReview => 'Maoni yako';

  @override
  String howWasTheJob(String name) {
    return 'Kazi ilikuwaje? Mpe $name alama na uache maoni.';
  }

  @override
  String rateJobTitle(String name) {
    return 'Mpe $name alama';
  }

  @override
  String get tapStarToRate => 'Gusa nyota kupima';

  @override
  String get ratingPoor => 'Mbaya';

  @override
  String get ratingFair => 'Wastani';

  @override
  String get ratingGood => 'Nzuri';

  @override
  String get ratingVeryGood => 'Nzuri sana';

  @override
  String get ratingExcellent => 'Bora';

  @override
  String get selectStarRating => 'Tafadhali chagua alama ya nyota.';

  @override
  String get reviewSubmitted => 'Asante kwa maoni yako!';

  @override
  String get failedSubmitReview => 'Imeshindwa kuwasilisha maoni.';

  @override
  String get remarkOptional => 'Maoni (hiari)';

  @override
  String get tellUsHowJobWent => 'Tuambie kazi ilikwendaje…';

  @override
  String get submitReview => 'Wasilisha maoni';

  @override
  String get maybeLater => 'Labda baadaye';

  @override
  String get rateThisJob => 'Kadiria kazi hii';

  @override
  String get chatToGetContact => 'Piga gumzo upate mawasiliano';

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
  String get editProfileSubtitle => 'Weka taarifa zako za kibinafsi ziwe za kisasa kila wakati.';

  @override
  String get personalInformation => 'Taarifa binafsi';

  @override
  String get editNameAndContact => 'Hariri jina lako na maelezo ya mawasiliano.';

  @override
  String get enterFullName => 'Ingiza jina lako kamili';

  @override
  String get enterPhoneNumber => 'Ingiza namba yako ya simu';

  @override
  String get nameRequiredError => 'Jina linahitajika';

  @override
  String get validNameError => 'Weka jina halali';

  @override
  String get name => 'Jina Kamili';

  @override
  String get phone => 'Simu';

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
  String noResultsFor(String service) {
    return 'Hakuna Mafundi kwa $service';
  }

  @override
  String noResultsForServiceCategory(String service, String category) {
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
  String get signInToContinue => 'Tafadhali ingia au unda akaunti ili kuendelea.';

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
  String get delete => 'Futa';

  @override
  String get enterEmail => 'Ingiza anwani yako ya barua pepe';

  @override
  String get enterValidEmail => 'Ingiza anwani sahihi ya barua pepe';

  @override
  String get enterPassword => 'Ingiza nenosiri lako';

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
  String get yourAccount => 'Akaunti Yako';

  @override
  String get managePersonalAccount => 'Simamia akaunti yako binafsi';

  @override
  String get updatePersonalInfo => 'Sasisha taarifa zako binafsi';

  @override
  String get manageAppPreferences => 'Simamia mapendeleo ya programu';

  @override
  String get yourNearbyFundiAccount => 'Akaunti yako ya NearbyFundi';

  @override
  String get accountActive => 'Akaunti inatumika';

  @override
  String get accountReadyToUse => 'Akaunti yako iko tayari kutumika.';

  @override
  String get dangerZone => 'Eneo la Hatari';

  @override
  String get irreversibleActions => 'Vitendo visivyoweza kurejeshwa';

  @override
  String get deleteAccountSubtitle => 'Ondoa akaunti yako na data kabisa';

  @override
  String get deleteAccountTitle => 'Futa akaunti?';

  @override
  String get deleteAccountWarning => 'Utatolewa kwenye programu hii mara moja. Unaweza kuingia tena wakati wowote.';

  @override
  String get manageSettings => 'Simamia mipangilio yako';

  @override
  String get personalizeExperience => 'Binafsisha uzoefu wako wa NearbyFundi.';

  @override
  String get lightAppearance => 'Muonekano mweupe';

  @override
  String get darkAppearance => 'Muonekano mweusi';

  @override
  String get followDeviceSettings => 'Fuata mipangilio ya kifaa';

  @override
  String get light => 'Mweupe';

  @override
  String get dark => 'Mweusi';

  @override
  String get system => 'Mfumo';

  @override
  String get preferences => 'Mapendeleo';

  @override
  String get information => 'Taarifa';

  @override
  String get appearance => 'Muonekano';

  @override
  String get manageYourAccount => 'Simamia akaunti yako';

  @override
  String get refreshProfile => 'Sasisha profaili';

  @override
  String get trustedConnection => 'Muunganisho wako wa kuaminika kwa mafundi wa karibu.';

  @override
  String get findTrustedNearby => 'Pata mafundi wa kuaminika karibu nawe.';

  @override
  String get nameRequired => 'Jina linahitajika';

  @override
  String get enterValidName => 'Ingiza jina sahihi';

  @override
  String get keepInfoUpdated => 'Weka taarifa zako binafsi ziwe za kisasa.';

  @override
  String get profileHeaderSubtitle => 'Simamia maelezo ya akaunti yako';

  @override
  String get cancelActionLabel => 'Ghairi';

  @override
  String get activeStatus => 'Inatumika';

  @override
  String get menu => 'Menyu';

  @override
  String get justNow => 'Sasa hivi';

  @override
  String minAgo(int count) {
    return 'Dakika $count zilizopita';
  }

  @override
  String hrAgo(int count) {
    return 'Saa $count zilizopita';
  }

  @override
  String daysAgo(int count) {
    return 'Siku $count zilizopita';
  }

  @override
  String get nearbyRefresh => 'Onyesha upya';

  @override
  String get nearbyFitAll => 'Onyesha vyote';

  @override
  String get nearbyNoTechniciansFound => 'Hakuna mafundi waliopatikana';

  @override
  String get nearbyTryAnotherLocation => 'Jaribu eneo lingine au huduma tofauti';

  @override
  String get nearbyNearYou => 'Karibu nawe';

  @override
  String nearbyApproxMinShort(String value) {
    return '~dk $value';
  }

  @override
  String nearbyMapSummary(int count, int radius) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mafundi $count',
      one: 'fundi 1',
    );
    return '$_temp0 • ndani ya km $radius';
  }

  @override
  String get techMapLocationUnavailable => 'Eneo la fundi huyu halipatikani.';

  @override
  String get techMapRefreshRoute => 'Onyesha upya njia';

  @override
  String get techMapCalculatingRoute => 'Inakokotoa njia…';

  @override
  String get techMapRecenter => 'Rudisha katikati';

  @override
  String get techMapMaps => 'Ramani';

  @override
  String get techMapOnline => 'Yupo mtandaoni';

  @override
  String get techMapOffline => 'Hayupo mtandaoni';

  @override
  String get pickerTitle => 'Chagua eneo';

  @override
  String get pickerOk => 'SAWA';

  @override
  String get pickerSettings => 'Mipangilio';

  @override
  String get pickerEnableLocation => 'Tafadhali washa huduma za eneo.';

  @override
  String get pickerPermissionDenied => 'Ruhusa ya eneo imekataliwa.';

  @override
  String get pickerPermissionDeniedForever => 'Ruhusa ya eneo imekataliwa kabisa.';

  @override
  String get pickerOutsideTanzania => 'Eneo lako liko nje ya Tanzania.';

  @override
  String get pickerLocationFailed => 'Imeshindwa kupata eneo lako. Tafadhali jaribu tena.';

  @override
  String get pickerPickInsideTanzania => 'Tafadhali chagua eneo ndani ya Tanzania.';

  @override
  String get pickerMyLocation => 'Eneo langu la sasa';

  @override
  String get pickerSearchHint => 'Tafuta mahali Tanzania…';

  @override
  String get pickerRecent => 'Za hivi karibuni';

  @override
  String get pickerClearAll => 'Futa zote';

  @override
  String get pickerRemove => 'Ondoa';

  @override
  String get pickerGettingAddress => 'Inapata anwani…';

  @override
  String get pickerTapMapHint => 'Gusa ramani au tafuta mahali';

  @override
  String get pickerUseLocation => 'Tumia eneo hili';

  @override
  String get nearbyFindFundiTitle => 'Tafuta fundi karibu nawe';

  @override
  String get nearbySearch => 'Tafuta';

  @override
  String get nearbyShowSearch => 'Onyesha utafutaji';

  @override
  String get nearbyHideSearch => 'Ficha utafutaji';

  @override
  String get nearbyClearSearch => 'Futa utafutaji';

  @override
  String get nearbyFilterByService => 'Chuja kwa huduma...';

  @override
  String get nearbyChooseOnMap => 'Chagua eneo kwenye ramani';

  @override
  String get nearbyRecommendedReason => 'Bora zaidi karibu nawe: ukadiriaji, kazi na maombi';

  @override
  String get nearbyRecentSearches => 'Utafutaji wa hivi karibuni';

  @override
  String get nearbyClear => 'Futa';

  @override
  String get nearbyClearFilters => 'Futa vichujio';

  @override
  String get nearbyFindingRoutes => 'Inatafuta njia bora...';

  @override
  String get nearbySearchForTechnicians => 'Tafuta mafundi';

  @override
  String get nearbyNoTechniciansNearby => 'Hakuna mafundi walio karibu';

  @override
  String get nearbyYou => 'Wewe';

  @override
  String get nearbyZoomIn => 'Kuza';

  @override
  String get nearbyZoomOut => 'Punguza';

  @override
  String get nearbyFitTechnicians => 'Onyesha mafundi wote';

  @override
  String get nearbyShowList => 'Onyesha orodha ya mafundi';

  @override
  String get nearbyShowFullMap => 'Onyesha ramani nzima';

  @override
  String get nearbyViewProfile => 'Tazama Wasifu';

  @override
  String get nearbyDirections => 'Pata maelekezo';

  @override
  String get nearbyCouldNotOpenMaps => 'Imeshindwa kufungua programu ya ramani.';

  @override
  String get nearbyTopPick => 'Chaguo bora';

  @override
  String get nearbyAll => 'Zote';

  @override
  String get nearbySearchFailed => 'Utafutaji umeshindikana. Tafadhali angalia mtandao wako ujaribu tena.';

  @override
  String get nearbyInvalidLocation => 'Eneo ulilochagua si sahihi. Tafadhali jaribu tena.';

  @override
  String get nearbySearchLoginMessage => 'Ingia au fungua akaunti ili kutafuta mafundi walio karibu nawe.';

  @override
  String get nearbyFilterLoginMessage => 'Ingia au fungua akaunti ili kuchuja mafundi kwa huduma.';

  @override
  String get nearbySearchHint => 'Tafuta eneo au chagua kwenye ramani.';

  @override
  String get nearbyStatDistance => 'Umbali';

  @override
  String get nearbyStatDriveTime => 'Muda wa safari';

  @override
  String get nearbyStatRating => 'Ukadiriaji';

  @override
  String get nearbyStatJobsDone => 'Kazi zilizokamilika';

  @override
  String get nearbyStatRequests => 'Maombi';

  @override
  String get nearbyStatReviews => 'Maoni';

  @override
  String nearbyKm(String value) {
    return 'km $value';
  }

  @override
  String nearbyApproxMin(String value) {
    return '~dakika $value';
  }

  @override
  String nearbyFoundWithRadius(int count, int radius) {
    return '$count wamepatikana • km $radius';
  }

  @override
  String nearbyExpandedNotice(int radius) {
    return 'Hakuna mafundi walio karibu sana, kwa hiyo tumetafuta hadi km $radius.';
  }

  @override
  String nearbyNoneWithinMax(int radius) {
    return 'Hakuna mafundi ndani ya km $radius kutoka eneo hili. Jaribu eneo au huduma nyingine.';
  }

  @override
  String nearbyNoneWithin(int radius) {
    return 'Hakuna mafundi ndani ya km $radius kutoka eneo hili.';
  }

  @override
  String nearbySearchWiderUpTo(int radius) {
    return 'Tafuta eneo pana zaidi (hadi km $radius)';
  }

  @override
  String nearbyJobsCount(int count) {
    return 'kazi $count';
  }

  @override
  String nearbyRequestsCount(int count) {
    return 'maombi $count';
  }

  @override
  String nearbyJobsDone(int count) {
    return 'kazi $count zimekamilika';
  }

  @override
  String get today => 'Leo';

  @override
  String get yesterday => 'Jana';

  @override
  String get deleteMessageForEveryone => 'Futa kwa kila mtu';

  @override
  String get deleteMessageForMe => 'Futa kwangu';

  @override
  String get removedForBoth => 'Imeondolewa kwa wote wawili';

  @override
  String get removedOnPhone => 'Imeondolewa kwenye simu hii pekee';

  @override
  String get deleted => 'Imefutwa';

  @override
  String get forwarded => 'Imetumwa mbele';

  @override
  String get copied => 'Imenakiliwa';

  @override
  String get typingEllipsis => 'anaandika…';

  @override
  String get pinnedMessage => 'Ujumbe uliobandikwa';

  @override
  String pinnedCount(int count, int total) {
    return 'Umebandika $count kati ya $total';
  }

  @override
  String get msgDeleted => 'Ujumbe huu umefutwa';

  @override
  String get tapToRetry => 'Gusa kujaribu tena';

  @override
  String get notSent => 'Haujatumwa';

  @override
  String get editProfile => 'Hariri Profaili';

  @override
  String get editProfileTitle => 'Hariri Profaili';

  @override
  String get updateInfo => 'Sasisha Taarifa Zako';

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
  String get noRequestsYet => 'Bado huna maombi yoyote';

  @override
  String get requestsWillAppear => 'Maombi yako ya huduma yataonekana hapa.';

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
  String get pleaseEnterLocation => 'Tafadhali ingiza mahali';

  @override
  String get searchServiceHint => 'Tafuta huduma (mfano mabomba, umeme...)';

  @override
  String noFundisForService(String service) {
    return 'Hakuna mafundi kwa $service';
  }

  @override
  String get refreshed => 'Imesasishwa kwa mafanikio';

  @override
  String get refreshFailed => 'Imeshindwa kusasisha data';

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

  @override
  String get noJobsYet => 'Hakuna kazi bado';

  @override
  String get noJobsHint => 'Maombi yaliyokubaliwa unayoyaweka kama kazi yataonekana hapa.';

  @override
  String get activeJobs => 'Kazi Zinazoendelea';

  @override
  String get completedJobs => 'Kazi Zilizokamilika';

  @override
  String get markComplete => 'Weka Imekamilika';

  @override
  String get jobCompletedMsg => 'Kazi imekamilika. Tiketi imefungwa.';

  @override
  String get couldNotStartCompletion => 'Imeshindwa kuanza kukamilisha.';

  @override
  String get viewDetails => 'Angalia Maelezo';

  @override
  String get statusInProgress => 'Inaendelea';

  @override
  String get statusCompleted => 'Imekamilika';

  @override
  String get noJobsMatchFilter => 'Hakuna kazi zinazolingana na kichujio chako';

  @override
  String get noContactDetails => 'Hakuna maelezo ya mawasiliano yaliyopatikana kwa fundi huyu.';

  @override
  String get contactFundi => 'Wasiliana na Fundi';

  @override
  String get chats => 'Mazungumzo';

  @override
  String get archives => 'Kumbukumbu';

  @override
  String get updates => 'Taarifa Mpya';

  @override
  String get message => 'Ujumbe';

  @override
  String get reply => 'Jibu';

  @override
  String get sayHello => 'Sema habari kuanza mazungumzo';

  @override
  String get noArchivedChats => 'Hakuna mazungumzo yaliyohifadhiwa';

  @override
  String get nothingHere => 'Hakuna kitu hapa';

  @override
  String get findTechnicians => 'Tafuta mafundi';

  @override
  String get unread => 'Ambazo hazijasomwa';

  @override
  String unreadCount(int count) {
    return 'Ambazo hazijasomwa $count';
  }

  @override
  String get pinned => 'Zilizobandikwa';

  @override
  String get pinChat => 'Bandika mazungumzo';

  @override
  String get unpinChat => 'Ondoa kubandika';

  @override
  String get archiveChat => 'Hifadhi mazungumzo';

  @override
  String get unarchiveChat => 'Ondoa kwenye kumbukumbu';

  @override
  String get deleteChat => 'Futa mazungumzo';

  @override
  String deleteChatConfirm(String name) {
    return 'Futa mazungumzo na $name?';
  }

  @override
  String get deleteChatWarning => 'Ujumbe wote na faili zote kwenye mazungumzo haya zitafutwa kwa wote wawili.';

  @override
  String get chatArchived => 'Mazungumzo yamehifadhiwa';

  @override
  String get chatUnarchived => 'Mazungumzo yameondolewa kwenye kumbukumbu';

  @override
  String get chatDeleted => 'Mazungumzo yamefutwa';

  @override
  String get chatDeleteFailed => 'Imeshindwa kufuta mazungumzo';

  @override
  String get noRecentUpdates => 'Hakuna taarifa mpya za hivi karibuni';

  @override
  String get postsFromFundis => 'Machapisho kutoka kwa mafundi unaozungumza nao yanaonekana hapa';

  @override
  String get newUpdates => 'Mpya';

  @override
  String get viewedUpdates => 'Zilizoangaliwa';

  @override
  String newPosts(int count) {
    return 'Chapisho $count jipya';
  }

  @override
  String newPostsPlural(int count) {
    return 'Machapisho $count mapya';
  }

  @override
  String hAgo(int count) {
    return 'Saa $count zilizopita';
  }

  @override
  String get mediaLinksDocs => 'Vyombo vya habari, viungo na nyaraka';

  @override
  String get starredMessages => 'Ujumbe uliowekwa alama';

  @override
  String pinnedXOfY(int current, int total) {
    return 'Umebandikwa $current kati ya $total';
  }

  @override
  String get originalMsgNotAvailable => 'Ujumbe wa awali haupatikani tena.';

  @override
  String get fileNotAllowed => 'Aina hii ya faili hairuhusiwi.';

  @override
  String fileTooLarge(int max) {
    return 'Faili ni kubwa mno. Kiwango cha juu ni $max MB kwa aina hii.';
  }

  @override
  String get camera => 'Kamera';

  @override
  String get photos => 'Picha';

  @override
  String get video => 'Video';

  @override
  String get document => 'Nyaraka';

  @override
  String get fileSizeHint => 'Picha 5 MB · Video 20 MB · Faili 15 MB';

  @override
  String get messagePinned => 'Ujumbe umebandikwa';

  @override
  String get messageUnpinned => 'Ujumbe umebanduliwa';

  @override
  String get starred => 'Imewekwa alama';

  @override
  String get removedFromStarred => 'Imeondolewa kwenye alama';

  @override
  String deleteMessages(int count) {
    return 'Futa ujumbe $count?';
  }

  @override
  String get deleteForEveryone => 'Futa kwa kila mtu';

  @override
  String get deleteForMe => 'Futa kwangu';

  @override
  String get onlyRemovedThisPhone => 'Imeondolewa kwenye simu hii pekee';

  @override
  String msgCouldNotBeDeleted(int count) {
    return 'Ujumbe $count haukuweza kufutwa kwa kila mtu.';
  }

  @override
  String get you => 'Wewe';

  @override
  String get thisMessageWasDeleted => 'Ujumbe huu ulifutwa';

  @override
  String get messageInfo => 'Taarifa za ujumbe';

  @override
  String get read => 'Imesomwa';

  @override
  String get delivered => 'Imefikishwa';

  @override
  String get sent => 'Imetumwa';

  @override
  String reactionsCount(int count) {
    return 'Majibu · $count';
  }

  @override
  String get couldNotLoadInfo => 'Imeshindwa kupakia taarifa';

  @override
  String get noMedia => 'Hakuna vyombo vya habari';

  @override
  String get noDocs => 'Hakuna nyaraka';

  @override
  String get noLinks => 'Hakuna viungo';

  @override
  String get media => 'Vyombo vya habari';

  @override
  String get docs => 'Nyaraka';

  @override
  String get links => 'Viungo';

  @override
  String get saveShare => 'Hifadhi / shiriki';

  @override
  String get noChatsToForward => 'Hakuna mazungumzo ya kutumia mbele';

  @override
  String get forwardMsgTo => 'Tuma ujumbe mbele kwa…';

  @override
  String forwardMsgsTo(int count) {
    return 'Tuma ujumbe $count mbele kwa…';
  }

  @override
  String get sending => 'Inatuma…';

  @override
  String get more => 'Zaidi';

  @override
  String get info => 'Taarifa';

  @override
  String get select => 'Chagua';

  @override
  String get forward => 'Tuma mbele';

  @override
  String get pin => 'Bandika';

  @override
  String get unpin => 'Bandua';

  @override
  String get star => 'Weka alama';

  @override
  String get unstar => 'Ondoa alama';

  @override
  String get save => 'Hifadhi';

  @override
  String get noStarredMessages => 'Hakuna ujumbe uliowekwa alama';

  @override
  String get file => 'Faili';

  @override
  String get showInChat => 'Onyesha kwenye mazungumzo';

  @override
  String newPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Machapisho $count mapya',
      one: 'Chapisho 1 jipya',
    );
    return '$_temp0';
  }

  @override
  String get noTicketsYet => 'Hakuna tiketi bado';

  @override
  String get noTicketsHint => 'Tiketi huundwa unapoweka ombi kama kazi.';

  @override
  String get fundiLabel => 'Fundi';

  @override
  String get createdOn => 'Imeundwa';

  @override
  String get completedOn => 'Imekamilika';

  @override
  String get searchByFundiName => 'Tafuta kwa jina la fundi...';

  @override
  String get checkBackLater => 'Angalia baadaye kwa masasisho kutoka kwa mafundi wetu.';

  @override
  String get noPostsMatch => 'Hakuna machapisho yanayolingana na';

  @override
  String get tapToPlayVideo => 'Gusa kucheza video';

  @override
  String get tapToPayForJob => 'Gusa Kulipa Kazi';

  @override
  String get payForJobConfirm => 'Je, unataka kulipa kazi?';

  @override
  String get confirm => 'Nenda Kulipa';

  @override
  String get startedOn => 'Ilianza';

  @override
  String get completedOnLabel => 'Imekamilika';

  @override
  String get descriptionLabel => 'Maelezo';

  @override
  String get ticketLabel => 'Tiketi';

  @override
  String get payForJob => 'Lipia Kazi';

  @override
  String get confirmCompletion => 'Thibitisha Ukamilishaji';

  @override
  String get sendingSmsCode => 'Inatuma Msimbo wa SMS…';

  @override
  String get jobCompletedSuccess => 'Kazi imekamilika kwa mafanikio!';

  @override
  String get jobNotFound => 'Kazi haipatikani';

  @override
  String get couldNotSendSms => 'Imeshindwa kutuma msimbo wa uthibitishaji kwa SMS.';

  @override
  String get enterSixDigitCode => 'Ingiza msimbo wa tarakimu 6 uliopokea kwa SMS.';

  @override
  String get invalidCodeTryAgain => 'Msimbo si sahihi. Angalia SMS na ujaribu tena.';

  @override
  String get couldNotResendSms => 'Imeshindwa kutuma tena msimbo wa SMS.';

  @override
  String get enterSmsCodeHint => 'Ingiza msimbo wa tarakimu 6 uliotumwa kwa SMS kwenye simu yako ili kuthibitisha ukamilishaji.';

  @override
  String get verifyAndComplete => 'Thibitisha na Ukamilishe';

  @override
  String resendIn(int seconds) {
    return 'Tuma tena baada ya sekunde $seconds';
  }

  @override
  String get confirmCompletionTitle => 'Thibitisha Ukamilishaji';

  @override
  String get completionCodeHint => '------';

  @override
  String get filterByFundiOrService => 'Chuja kwa fundi au huduma...';

  @override
  String get allLabel => 'Zote';

  @override
  String get statusPending => 'Inasubiri';

  @override
  String get statusAccepted => 'Imekubaliwa';

  @override
  String get statusRejected => 'Imekataliwa';

  @override
  String get statusCancelled => 'Imeghairiwa';

  @override
  String get statTotal => 'Jumla';

  @override
  String get statClosed => 'Zilizofungwa';

  @override
  String get noRequestsMatchFilter => 'Hakuna maombi yanayolingana na kichujio chako';

  @override
  String get sectionActiveRequests => 'Maombi Yanayoendelea';

  @override
  String get sectionClosedRequests => 'Maombi Yaliyofungwa';

  @override
  String get cancelAction => 'Ghairi';

  @override
  String get viewJob => 'Tazama Kazi';

  @override
  String get chatAction => 'Piga Gumzo';

  @override
  String get detailsAction => 'Maelezo';

  @override
  String get couldNotCancelRequest => 'Imeshindwa kughairi ombi.';

  @override
  String get markAsJob => 'Weka kama kazi';

  @override
  String markAsJobConfirm(String name) {
    return 'Anza kazi hii na $name? Tiketi itaundwa.';
  }

  @override
  String get couldNotCreateJob => 'Imeshindwa kuunda kazi.';

  @override
  String get timeAgoJustNow => 'Sasa hivi';

  @override
  String timeAgoMinutes(int count) {
    return 'Dakika $count zilizopita';
  }

  @override
  String timeAgoHours(int count) {
    return 'Saa $count zilizopita';
  }

  @override
  String timeAgoDays(int count) {
    return 'Siku $count zilizopita';
  }

  @override
  String get requestDetailsTitle => 'Maelezo ya Ombi';

  @override
  String get fieldService => 'Huduma';

  @override
  String get fieldCategory => 'Kategoria';

  @override
  String get fieldDescription => 'Maelezo';

  @override
  String get fieldFundi => 'Fundi';

  @override
  String get fieldArea => 'Eneo';

  @override
  String get fieldRequestedOn => 'Iliombwa';

  @override
  String get fieldStatus => 'Hali';

  @override
  String get closeAction => 'Funga';

  @override
  String get signInToReadBlog => 'Ingia au unda akaunti ili kusoma blogu na vidokezo vyetu.';

  @override
  String get signInToRequests => 'Ingia au unda akaunti ili kutuma na kufuatilia maombi yako ya huduma.';

  @override
  String get signInToJobs => 'Ingia au unda akaunti ili kuona na kusimamia kazi zako.';

  @override
  String get signInToProfile => 'Ingia au unda akaunti ili kuona na kuhariri profaili yako.';

  @override
  String get signInToTickets => 'Ingia au unda akaunti ili kuona tiketi zako.';

  @override
  String get signInToChat => 'Ingia au unda akaunti ili kuzungumza na mafundi.';

  @override
  String get signInToNotifications => 'Ingia au unda akaunti ili kuona arifa zako.';

  @override
  String get signInToRefresh => 'Ingia au unda akaunti ili kusasisha data yako.';

  @override
  String get guestUser => 'Mtumiaji Mgeni';

  @override
  String get notLoggedIn => 'Hujaingia';

  @override
  String get caughtUp => 'Umeshafika mwisho';

  @override
  String get notifyWhenNew => 'Tutakujulisha kukiwa na kitu kipya.';

  @override
  String get chatLabel => 'Mazungumzo';

  @override
  String get newRequestLabel => 'Ombi Jipya';

  @override
  String get requestAcceptedLabel => 'Ombi Limekubaliwa';

  @override
  String get requestRejectedLabel => 'Ombi Limekataliwa';

  @override
  String get notificationLabel => 'Arifa';

  @override
  String get unreadNotifications => 'arifa ambazo hazijasomwa';
}
