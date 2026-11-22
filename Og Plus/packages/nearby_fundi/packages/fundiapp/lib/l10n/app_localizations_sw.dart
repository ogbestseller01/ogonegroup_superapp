// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'NETSAF FUNDI APP';

  @override
  String get fundiAppTitle => 'NETSAF FUNDI APP';

  @override
  String get hello => 'Habari';

  @override
  String get home => 'Nyumbani';

  @override
  String get settings => 'Mipangilio';

  @override
  String get language => 'Lugha';

  @override
  String get logout => 'Toka';

  @override
  String get deleteAccount => 'Futa Akaunti';

  @override
  String get profile => 'Wasifu';

  @override
  String get notifications => 'Arifa';

  @override
  String get aiAssistant => 'Msaidizi wa AI';

  @override
  String get chat => 'Gumzo';

  @override
  String get blog => 'Blogu';

  @override
  String get more => 'Zaidi';

  @override
  String get comingSoon => 'Inakuja hivi karibuni!';

  @override
  String get quickActions => 'Vitendo vya Haraka';

  @override
  String get regStep1Failed => 'Imeshindwa kufungua akaunti yako. Tafadhali angalia taarifa zako na ujaribu tena.';

  @override
  String get regOtpDeliveryFailed => 'Akaunti imefunguliwa, lakini hatukuweza kutuma msimbo sasa. Bonyeza Tuma Tena kwenye skrini inayofuata.';

  @override
  String regOtpSentSms(String recipient) {
    return 'Tumetuma msimbo wa tarakimu 6 kwa SMS kwenda $recipient';
  }

  @override
  String regOtpSentEmail(String recipient) {
    return 'Tumetuma msimbo wa tarakimu 6 kwenye barua pepe yako $recipient';
  }

  @override
  String get welcomeBack => 'Karibu Tena';

  @override
  String get signInManage => 'Ingia ili kusimamia huduma zako';

  @override
  String get emailAddress => 'Barua Pepe';

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
  String get becomeFundi => 'Kuwa Fundi';

  @override
  String get joinProvider => 'Jiunge kama mtoa huduma';

  @override
  String get fundiRegistration => 'Usajili wa Fundi';

  @override
  String get fillDetails => 'Jaza taarifa zako ili uanze kuhudumia wateja';

  @override
  String get phoneNumber => 'Namba ya Simu';

  @override
  String get serviceArea => 'Eneo la Huduma';

  @override
  String get selectServices => 'Chagua Huduma';

  @override
  String get confirmPassword => 'Thibitisha Nenosiri';

  @override
  String get registerAsFundi => 'Jisajili kama Fundi';

  @override
  String get alreadyHaveAccount => 'Tayari una akaunti?';

  @override
  String get verificationCode => 'Msimbo wa Uthibitisho';

  @override
  String get enterCodeSent => 'Weka msimbo uliotumwa kwa';

  @override
  String get enterOtp => 'Weka OTP';

  @override
  String get otpSent => 'Msimbo wa tarakimu 6 umetumwa kwenye barua pepe yako';

  @override
  String get verifyOtp => 'Thibitisha OTP';

  @override
  String get backToSignIn => 'Rudi Kuingia';

  @override
  String get noWorries => 'Usijali — tutakutumia msimbo wa kubadilisha';

  @override
  String get resetPassword => 'Weka Upya Nenosiri';

  @override
  String get enterEmailReset => 'Weka barua pepe yako ili upokee msimbo wa uthibitisho';

  @override
  String get sendResetCode => 'Tuma Msimbo wa Kubadilisha';

  @override
  String get setNewPassword => 'Weka Nenosiri Jipya';

  @override
  String get otpSentTo => 'OTP imetumwa kwa';

  @override
  String get otpCode => 'Msimbo wa OTP';

  @override
  String get newPassword => 'Nenosiri Jipya';

  @override
  String get resetPasswordButton => 'Weka Upya Nenosiri';

  @override
  String get myProfile => 'Profaili ';

  @override
  String get editProfile => 'Hariri Wasifu';

  @override
  String get profileDetails => 'Maelezo ya Wasifu';

  @override
  String get updateInfo => 'Sasisha Taarifa Zako';

  @override
  String get name => 'Jina Kamili';

  @override
  String get phone => 'Simu';

  @override
  String get bio => 'Maelezo Mafupi';

  @override
  String get hourlyRate => 'Gharama kwa Saa (TZS)';

  @override
  String get area => 'Eneo la Huduma';

  @override
  String get experience => 'Uzoefu';

  @override
  String get years => 'miaka';

  @override
  String get tzs => 'TZS';

  @override
  String get accountStatus => 'Hali ya Akaunti';

  @override
  String get active => 'Hai';

  @override
  String get onlineStatus => 'Hali ya Mtandaoni';

  @override
  String get servicesIOffer => 'Huduma Ninazotoa';

  @override
  String get noServicesSelected => 'Hakuna huduma zilizochaguliwa';

  @override
  String get saveChanges => 'Hifadhi Mabadiliko';

  @override
  String get updateFailed => 'Imeshindwa kusasisha';

  @override
  String get retry => 'Jaribu Tena';

  @override
  String get customers => 'Wateja';

  @override
  String get searchCustomers => 'Tafuta wateja';

  @override
  String get noCustomersYet => 'Hakuna wateja bado';

  @override
  String get customersWillAppear => 'Wateja wataonekana hapa watakapokutumia ujumbe';

  @override
  String get deleteChat => 'Futa gumzo';

  @override
  String get deleteChatConfirmation => 'Ujumbe na faili zote zitaondolewa kwa nyote wawili.';

  @override
  String get chatDeleted => 'Gumzo limefutwa';

  @override
  String get failedToDeleteChat => 'Imeshindwa kufuta gumzo';

  @override
  String get archiveChat => 'Hifadhi gumzo';

  @override
  String get unarchiveChat => 'Toa gumzo kwenye hifadhi';

  @override
  String get pinChat => 'Bandika gumzo';

  @override
  String get unpinChat => 'Ondoa gumzo lililobandikwa';

  @override
  String get chatArchived => 'Gumzo limehifadhiwa';

  @override
  String get chatUnarchived => 'Gumzo limetolewa kwenye hifadhi';

  @override
  String get copy => 'Nakili';

  @override
  String get deleteMessage => 'Futa ujumbe?';

  @override
  String get reply => 'Jibu';

  @override
  String get forward => 'Sambaza';

  @override
  String get star => 'Weka nyota';

  @override
  String get unstar => 'Ondoa nyota';

  @override
  String get pin => 'Bandika';

  @override
  String get unpin => 'Ondoa kibandiko';

  @override
  String get info => 'Maelezo';

  @override
  String get select => 'Chagua';

  @override
  String get savedToGallery => 'Imehifadhiwa kwenye ghala lako';

  @override
  String get noAppToOpen => 'Hakuna programu iliyosakinishwa inayoweza kufungua aina hii ya faili.';

  @override
  String get photo => '📷 Picha';

  @override
  String get videoFile => '🎥 Video';

  @override
  String get attachment => '📎 Kiambatisho';

  @override
  String get online => 'Mtandaoni';

  @override
  String get offline => 'Nje ya mtandao';

  @override
  String get youAreOnline => 'Uko mtandaoni';

  @override
  String get youAreOffline => 'Uko nje ya mtandao';

  @override
  String get lastSeen => 'Alionekana hivi karibuni';

  @override
  String get fundiDashboard => 'Dashibodi';

  @override
  String get welcomeFundi => 'Karibu Fundi';

  @override
  String get manageServicesPosts => 'Simamia huduma, machapisho na maombi yako yote mahali pamoja.';

  @override
  String get stayConnected => 'Endelea Kuunganishwa';

  @override
  String get getNotifications => 'Pokea arifa za papo hapo za maombi mapya na masasisho.';

  @override
  String get getStarted => 'Anza';

  @override
  String get next => 'Endelea';

  @override
  String get skip => 'Ruka';

  @override
  String get totalRequests => 'Jumla ya Maombi';

  @override
  String get pending => 'Yanayosubiri';

  @override
  String get completed => 'Yaliyokamilika';

  @override
  String get myPosts => 'Machapisho ';

  @override
  String get noPosts => 'Hakuna machapisho bado.';

  @override
  String get createPost => 'Unda chapisho lako la kwanza';

  @override
  String get createPostTitle => 'Unda Chapisho';

  @override
  String get editPostTitle => 'Hariri Chapisho';

  @override
  String get postCreated => 'Chapisho limeundwa';

  @override
  String get postUpdated => 'Chapisho limesasishwa';

  @override
  String get postDeleted => 'Chapisho limefutwa';

  @override
  String get deletePost => 'Futa Chapisho';

  @override
  String get filterByTitleContent => 'Chuja kwa kichwa au maudhui...';

  @override
  String get portfolio => 'Kazi Zangu';

  @override
  String get noPortfolio => 'Hakuna kazi zilizowekwa.';

  @override
  String get addPortfolio => 'Ongeza kazi yako ya kwanza';

  @override
  String get addPortfolioItem => 'Ongeza Kazi';

  @override
  String get editPortfolioItem => 'Hariri Kazi';

  @override
  String get itemAdded => 'Kazi imeongezwa';

  @override
  String get itemUpdated => 'Kazi imesasishwa';

  @override
  String get itemDeleted => 'Kazi imefutwa';

  @override
  String get deletePortfolioItem => 'Futa Kazi';

  @override
  String get filterByDescription => 'Chuja kwa maelezo...';

  @override
  String get requests => 'Maombi';

  @override
  String get noRequests => 'Hakuna maombi bado.';

  @override
  String get accept => 'Kubali';

  @override
  String get reject => 'Kataa';

  @override
  String get customer => 'Mteja';

  @override
  String get service => 'Huduma';

  @override
  String get description => 'Maelezo';

  @override
  String get filterByCustomerService => 'Chuja kwa mteja au huduma...';

  @override
  String get noMatchingRequests => 'Hakuna maombi yanayolingana';

  @override
  String get requestAccepted => 'Ombi limekubaliwa';

  @override
  String get requestRejected => 'Ombi limekataliwa';

  @override
  String get chatWithCustomer => 'Ongea na Mteja';

  @override
  String get aboutUs => 'Kuhusu Sisi';

  @override
  String get aboutFundiApp => 'Kuhusu NETSAF FUNDI APP';

  @override
  String get terms => 'Vigezo na Masharti';

  @override
  String get faq => 'Maswali Yanayoulizwa Mara kwa Mara';

  @override
  String get contactUs => 'Wasiliana Nasi';

  @override
  String get noContent => 'Hakuna maudhui yanayopatikana.';

  @override
  String get getInTouch => 'Wasiliana Nasi';

  @override
  String get email => 'Barua Pepe';

  @override
  String get website => 'Tovuti';

  @override
  String get phoneNumbers => 'Namba za Simu';

  @override
  String get noFaqs => 'Hakuna maswali yanayopatikana.';

  @override
  String get pushNotifications => 'Arifa za Papo Hapo';

  @override
  String get receiveAlerts => 'Pokea tahadhari kuhusu maombi';

  @override
  String get noNotificationsYet => 'Hakuna arifa bado';

  @override
  String get unreadNotifications => 'arifa ambazo hazijasomwa';

  @override
  String get noNewNotifications => 'Hakuna arifa mpya';

  @override
  String get notification => 'Arifa';

  @override
  String get markAllAsRead => 'Weka zote kuwa zimesomwa';

  @override
  String get noMessagesYet => 'Hakuna ujumbe bado';

  @override
  String get sayHelloToStart => 'Sema habari ili uanze kuzungumza!';

  @override
  String get typeAMessage => 'Andika ujumbe...';

  @override
  String get typing => 'Anaandika...';

  @override
  String get messageDeleted => 'Ujumbe umefutwa';

  @override
  String get messageCopied => 'Ujumbe umenakiliwa';

  @override
  String get failedToSend => 'Imeshindwa kutuma ujumbe';

  @override
  String get failedToSendImage => 'Imeshindwa kutuma picha';

  @override
  String get failedToSendFile => 'Imeshindwa kutuma faili';

  @override
  String get deleteMessageConfirmation => 'Futa ujumbe huu?';

  @override
  String get selectImage => 'Chagua picha';

  @override
  String get image => 'Picha';

  @override
  String get file => 'Faili';

  @override
  String get voiceMessage => 'Ujumbe wa sauti';

  @override
  String get video => 'Video';

  @override
  String get justNow => 'Sasa hivi';

  @override
  String get noConversationsYet => 'Hakuna mazungumzo bado';

  @override
  String get startChattingWithFundis => 'Anza kuzungumza na wateja walio karibu nawe';

  @override
  String get viewProfile => 'Tazama Wasifu';

  @override
  String get clearChat => 'Futa Gumzo Lote';

  @override
  String get blockUser => 'Mzuie Mtumiaji';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Ghala';

  @override
  String get document => 'Hati';

  @override
  String get recordVoice => 'Rekodi sauti';

  @override
  String get stopRecording => 'Acha kurekodi';

  @override
  String get downloadFile => 'Pakua Faili';

  @override
  String get deleteFile => 'Futa Faili';

  @override
  String get deleteConversation => 'Futa Mazungumzo';

  @override
  String get deleteConversationConfirmation => 'Una uhakika unataka kufuta mazungumzo yote? Kitendo hiki hakiwezi kutenduliwa.';

  @override
  String get conversationDeleted => 'Mazungumzo yamefutwa';

  @override
  String get fileDownloaded => 'Faili imepakuliwa kwa mafanikio';

  @override
  String get fileDeleted => 'Faili imefutwa kwa mafanikio';

  @override
  String get downloadFailed => 'Imeshindwa kupakua faili';

  @override
  String get deleteFailed => 'Imeshindwa kufuta faili';

  @override
  String get permissionDenied => 'Ruhusa imekataliwa';

  @override
  String get storagePermissionDenied => 'Ruhusa ya hifadhi imekataliwa';

  @override
  String get photosPermissionDenied => 'Ruhusa ya picha imekataliwa';

  @override
  String get filterTiles => 'Chuja vipengele...';

  @override
  String get noMatchingTiles => 'Hakuna vipengele vinavyolingana';

  @override
  String get noMatchingItems => 'Hakuna vitu vinavyolingana';

  @override
  String get cancel => 'Ghairi';

  @override
  String get add => 'Ongeza';

  @override
  String get update => 'Sasisha';

  @override
  String get create => 'Unda';

  @override
  String get delete => 'Futa';

  @override
  String get call => 'Piga Simu';

  @override
  String get areYouSure => 'Una uhakika?';

  @override
  String get logoutConfirmation => 'Una uhakika unataka kutoka?';

  @override
  String get deleteAccountConfirmation => 'Kitendo hiki ni cha kudumu. Data yako yote itapotea. Una uhakika?';

  @override
  String get selectServicesDialogTitle => 'Chagua Huduma';

  @override
  String get selectAtLeastOneService => 'Chagua angalau huduma moja';

  @override
  String get servicesUpdated => 'Huduma zimesasishwa';

  @override
  String get profileUpdated => 'Wasifu umesasishwa kwa mafanikio';

  @override
  String get open => 'Fungua';

  @override
  String get openFile => 'Fungua Faili';

  @override
  String get inProgress => 'Inaendelea';

  @override
  String get markComplete => 'Weka Kuwa Imekamilika';

  @override
  String get requestCompleted => 'Ombi limekamilika';

  @override
  String get completeRequest => 'Kamilisha Ombi';

  @override
  String get completeConfirmation => 'Una uhakika unataka kuweka ombi hili kuwa limekamilika?';

  @override
  String get completedSuccess => 'Ombi limekamilika kwa mafanikio!';

  @override
  String get failedToComplete => 'Imeshindwa kukamilisha ombi';

  @override
  String get startWork => 'Anza Kazi';

  @override
  String get requestInProgress => 'Ombi linaendelea';

  @override
  String get accepted => 'Limekubaliwa';

  @override
  String get rejected => 'Limekataliwa';

  @override
  String get cancelled => 'Limeghairiwa';

  @override
  String get filterByStatus => 'Chuja kwa hali';

  @override
  String get all => 'Yote';

  @override
  String get noRequestsMatchFilter => 'Hakuna maombi yanayolingana na kichujio';

  @override
  String get subscriptions => 'Usajili';

  @override
  String get mySubscriptions => 'Usajili Wangu';

  @override
  String get subscriptionStatus => 'Hali ya Usajili';

  @override
  String get choosePlan => 'Chagua Mpango Wako';

  @override
  String get selectPlan => 'Chagua mpango wa usajili unaokufaa';

  @override
  String get continueToPayment => 'Endelea kwenye Malipo';

  @override
  String get paymentMethods => 'Njia za Malipo';

  @override
  String get choosePaymentMethod => 'Chagua Njia ya Malipo';

  @override
  String get selectedPlan => 'Mpango Uliochaguliwa';

  @override
  String get paymentReference => 'Kumbukumbu ya Malipo';

  @override
  String get paymentReferenceHint => 'mf., MPESA-123456';

  @override
  String get notes => 'Maelezo';

  @override
  String get notesHint => 'Taarifa nyingine yoyote...';

  @override
  String get uploadPaymentProof => 'Pakia Uthibitisho wa Malipo';

  @override
  String get tapToUpload => 'Gusa kupakia uthibitisho wa malipo';

  @override
  String get paymentProofFormats => 'JPG, PNG, au PDF';

  @override
  String get paymentInstructions => 'Maelekezo ya Malipo';

  @override
  String sendAmountTo(String amount) {
    return 'Tuma $amount kwa:';
  }

  @override
  String get account => 'Akaunti';

  @override
  String get submitSubscription => 'Wasilisha Usajili';

  @override
  String get subscriptionCreated => 'Usajili Umeundwa!';

  @override
  String get subscriptionCreatedMessage => 'Ombi lako la usajili limeundwa kwa mafanikio.';

  @override
  String get waitForApproval => 'Tafadhali subiri idhini ya msimamizi. Utaarifiwa usajili wako utakapoidhinishwa.';

  @override
  String get goToDashboard => 'Nenda kwenye Dashibodi';

  @override
  String get renewNow => 'Huisha Sasa';

  @override
  String get subscribeNow => 'Jisajili Sasa';

  @override
  String get subscriptionExpired => 'Usajili Umeisha';

  @override
  String get subscriptionPending => 'Inasubiri Idhini';

  @override
  String get subscriptionActive => 'Hai';

  @override
  String get subscriptionInactive => 'Haifanyi kazi';

  @override
  String daysRemaining(int days) {
    return 'Siku $days zimebaki';
  }

  @override
  String expiresOn(String date) {
    return 'Inaisha: $date';
  }

  @override
  String validUntil(String date) {
    return 'Inatumika hadi: $date';
  }

  @override
  String get noSubscriptions => 'Hakuna usajili bado';

  @override
  String get noInvoices => 'Hakuna ankara zinazopatikana';

  @override
  String invoiceNumber(String number) {
    return 'Ankara #$number';
  }

  @override
  String get invoiceStatus => 'Hali';

  @override
  String get viewInvoice => 'Tazama Ankara';

  @override
  String get downloadPdf => 'Pakua PDF';

  @override
  String get subscriptionHistory => 'Historia ya Usajili';

  @override
  String get paid => 'Imelipwa';

  @override
  String get unpaid => 'Haijalipwa';

  @override
  String get yourSubscriptionHasExpired => 'Usajili wako umeisha. Tafadhali huisha ili kuendelea.';

  @override
  String get subscriptionPendingApproval => 'Usajili wako unasubiri idhini. Tafadhali subiri.';

  @override
  String get subscribeToUnlock => 'Jisajili ili kufungua huduma zote za Fundi.';

  @override
  String get rateCards => 'Kadi za Bei';

  @override
  String get subscriptionDetails => 'Maelezo ya Usajili';

  @override
  String get invoiceDetails => 'Maelezo ya Ankara';

  @override
  String get activePlan => 'Mpango Unaotumika';

  @override
  String get amountPaid => 'Kiasi Kilicholipwa';

  @override
  String get paymentMethod => 'Njia ya Malipo';

  @override
  String get paymentReferenceLabel => 'Kumbukumbu ya Malipo';

  @override
  String get approvedAt => 'Iliidhinishwa Tarehe';

  @override
  String get approvedBy => 'Iliidhinishwa Na';

  @override
  String get adminNotes => 'Maelezo ya Msimamizi';

  @override
  String get noNotifications => 'Hakuna Arifa';

  @override
  String get allCaughtUp => 'Umemaliza zote!';

  @override
  String get refresh => 'Onyesha Upya';

  @override
  String get viewNotifications => 'Tazama Arifa';

  @override
  String get seeAllNotifications => 'Tazama arifa zako zote zinazoingia';

  @override
  String get markAllRead => 'Weka Zote Zimesomwa';

  @override
  String get loadingNotifications => 'Inapakia arifa...';

  @override
  String get viewAllNotifications => 'Tazama Arifa Zote';

  @override
  String get notificationSettings => 'Mipangilio ya Arifa';

  @override
  String get invoices => 'Ankara';

  @override
  String get certificate => 'Cheti';

  @override
  String approvedOn(String date) {
    return 'Iliidhinishwa tarehe $date';
  }

  @override
  String startedOn(String date) {
    return 'Ilianza: $date';
  }

  @override
  String createdOn(String date) {
    return 'Iliundwa: $date';
  }

  @override
  String paidOn(String date) {
    return 'Ililipwa: $date';
  }

  @override
  String dueOn(String date) {
    return 'Inapaswa kulipwa: $date';
  }

  @override
  String subscriptionReference(String id) {
    return 'Usajili #$id';
  }

  @override
  String get plan => 'Mpango';

  @override
  String get status => 'Hali';

  @override
  String get download => 'Pakua';

  @override
  String get share => 'Shiriki';

  @override
  String get openPdf => 'Fungua PDF';

  @override
  String get privacyPolicy => 'Sera ya Faragha';

  @override
  String get tapToChangePhoto => 'Gusa kamera kubadilisha picha';

  @override
  String get nidaNumber => 'Namba ya NIDA';

  @override
  String get typeArea => 'Andika eneo';

  @override
  String get pickOnMap => 'Chagua kwenye ramani';

  @override
  String get typeAreaOrPickOnMap => 'Andika eneo au chagua kwenye ramani';

  @override
  String get oops => 'Lo!';

  @override
  String get themeLabel => 'Mandhari';

  @override
  String get themeLight => 'Mwanga';

  @override
  String get themeDark => 'Giza';

  @override
  String get backToApp => 'Rudi kwenye programu';

  @override
  String get regBack => 'Rudi';

  @override
  String get regContinue => 'Endelea';

  @override
  String regStepOf(int current, int total) {
    return 'Hatua $current ya $total';
  }

  @override
  String get regCreateAccountTitle => 'Fungua akaunti yako';

  @override
  String get regCreateAccountSubtitle => 'Tutatuma msimbo kwenye simu yako ili kuithibitisha.';

  @override
  String get regFullName => 'Jina kamili';

  @override
  String get regPhoneHint => 'Namba ya simu';

  @override
  String get regEmailOptional => 'Barua pepe (si lazima)';

  @override
  String get regPasswordHint => 'Nenosiri (angalau herufi 8)';

  @override
  String get regConfirmPasswordHint => 'Thibitisha nenosiri';

  @override
  String get regPhotoOptional => 'Picha (si lazima)';

  @override
  String get regChooseGallery => 'Chagua kutoka ghala';

  @override
  String get regTakePhoto => 'Piga picha';

  @override
  String get regRemovePhoto => 'Ondoa picha';

  @override
  String get regSearchCountry => 'Tafuta nchi...';

  @override
  String get regNoCountryFound => 'Hakuna nchi iliyopatikana';

  @override
  String get regNameRequired => 'Jina linahitajika';

  @override
  String get regPhoneRequired => 'Namba ya simu inahitajika';

  @override
  String get regPhoneInvalidTz => 'Weka namba sahihi ya Tanzania (mf. 0682 131 178)';

  @override
  String get regPhoneInvalid => 'Weka namba sahihi ya simu';

  @override
  String get regEmailInvalid => 'Weka barua pepe sahihi';

  @override
  String get regPasswordMin => 'Angalau herufi 8';

  @override
  String get regPasswordMismatch => 'Manenosiri hayalingani';

  @override
  String get regIdentityTitle => 'Thibitisha utambulisho wako';

  @override
  String get regIdentitySubtitle => 'Hutumiwa na timu yetu pekee kuidhinisha akaunti yako.';

  @override
  String get regIdNida => 'NIDA';

  @override
  String get regIdLicense => 'Leseni ya udereva';

  @override
  String get regIdVoter => 'Kitambulisho cha Mpiga Kura (KURA)';

  @override
  String get regNidaHint => 'Namba ya NIDA (tarakimu 20)';

  @override
  String get regVoterHint => 'Namba ya Mpiga Kura (tarakimu 12)';

  @override
  String get regLicenseHint => 'Namba ya leseni (angalau tarakimu 10)';

  @override
  String get regEnterId => 'Weka namba ya kitambulisho';

  @override
  String get regNidaLen => 'NIDA lazima iwe tarakimu 20 kamili';

  @override
  String get regVoterLen => 'Namba ya Mpiga Kura lazima iwe tarakimu 12 kamili';

  @override
  String get regLicenseLen => 'Leseni lazima iwe angalau tarakimu 10';

  @override
  String get regAddIdPhoto => 'Gusa kuongeza picha ya kitambulisho chako (si lazima)';

  @override
  String get regFingerprintTitle => 'Alama ya kidole kwa wino';

  @override
  String get regFingerprintHeadIdle => 'Weka kidole chako';

  @override
  String get regFingerprintHeadDone => 'Alama ya kidole imechukuliwa';

  @override
  String get regFingerprintDescIdle => 'Gusa na bonyeza eneo lililo hapa chini kupiga alama ya kidole chako.';

  @override
  String get regFingerprintDescDone => 'Alama ya kidole chako imechukuliwa. Gusa kitufe kilicho hapa chini kuendelea.';

  @override
  String get regFingerprintChipIdle => 'Gusa hapa';

  @override
  String get regFingerprintChipDone => 'Tayari';

  @override
  String get regFingerprintStamp => 'Gusa kupiga alama';

  @override
  String get regFingerprintScanning => 'Inachukua…';

  @override
  String get regFingerprintSubmit => 'Wasilisha na endelea';

  @override
  String get regFingerprintRetry => 'Jaribu tena';

  @override
  String get regFingerprintSaveFailed => 'Imeshindwa kuhifadhi alama ya kidole.';

  @override
  String get regFaceTitle => 'Kupiga picha ya uso';

  @override
  String get regFaceOpening => 'Inafungua kamera…';

  @override
  String get regFacePosition => 'Weka uso wako ndani ya fremu';

  @override
  String get regFaceNone => 'Hakuna uso uliogunduliwa';

  @override
  String get regFaceCloser => 'Sogea karibu';

  @override
  String get regFaceFarther => 'Rudi nyuma kidogo';

  @override
  String get regFaceHold => 'Tulia…';

  @override
  String get regFaceConfirmPhoto => 'Thibitisha picha yako';

  @override
  String get regFaceSaving => 'Inahifadhi…';

  @override
  String get regFaceUnavailable => 'Kamera haipatikani';

  @override
  String get regFaceNoCamera => 'Hakuna kamera kwenye kifaa hiki.';

  @override
  String regFaceOpenFailed(String error) {
    return 'Imeshindwa kufungua kamera: $error';
  }

  @override
  String regFaceCaptureFailed(String error) {
    return 'Imeshindwa kupiga picha: $error';
  }

  @override
  String get regFaceSaveFailed => 'Imeshindwa kuhifadhi picha ya uso.';

  @override
  String regFaceSubmitFailed(String error) {
    return 'Uwasilishaji umeshindwa: $error';
  }

  @override
  String regFaceFallbackFailed(String error) {
    return 'Kamera mbadala imeshindwa: $error';
  }

  @override
  String get regFaceCapturing => 'Inapiga picha…';

  @override
  String get regFaceCaptureNow => 'Piga sasa';

  @override
  String get regFaceRetake => 'Piga tena';

  @override
  String get regFaceConfirm => 'Thibitisha';

  @override
  String get regFaceSystemCamera => 'Tumia kamera ya mfumo';

  @override
  String get regKinTitle => 'Mtu wa dharura';

  @override
  String get regKinSubtitle => 'Tuwasiliane na nani wakati wa dharura?';

  @override
  String get regKinRelationship => 'Uhusiano (mf. Mwenzi, Mzazi, Ndugu)';

  @override
  String get regKinRelationRequired => 'Uhusiano unahitajika';

  @override
  String get regReviewTitle => 'Kagua na Wasilisha';

  @override
  String get regReviewHeading => 'Tafadhali kagua taarifa za usajili wako';

  @override
  String get regCompletedSteps => 'Hatua zilizokamilika';

  @override
  String get regAccountCreated => 'Akaunti imefunguliwa';

  @override
  String get regIdentityVerified => 'Utambulisho umehifadhiwa';

  @override
  String get regFingerprintEnrolled => 'Alama ya kidole imechukuliwa';

  @override
  String get regFaceEnrolled => 'Uso umechukuliwa';

  @override
  String get regKinSaved => 'Mtu wa dharura amehifadhiwa';

  @override
  String get regRelationship => 'Uhusiano';

  @override
  String get regSubmit => 'Wasilisha usajili';

  @override
  String get regBackToStep5 => 'Rudi hatua ya 5';

  @override
  String get regSubmittedTitle => 'Usajili umewasilishwa!';

  @override
  String get regSubmittedBody => 'Akaunti yako inasubiri uthibitisho wa msimamizi. Utapokea SMS itakapoidhinishwa.';

  @override
  String get regSubmitFailed => 'Uwasilishaji umeshindwa. Tafadhali jaribu tena.';

  @override
  String get regSessionExpired => 'Kipindi cha usajili kimeisha. Tafadhali anza upya.';

  @override
  String get jobs => 'Kazi';

  @override
  String get tickets => 'Tiketi';

  @override
  String get downloads => 'Vipakuliwa';

  @override
  String get subscription => 'Usajili';

  @override
  String get viewAll => 'Tazama Zote';

  @override
  String get viewAllShort => 'Tazama zote';

  @override
  String get latestRequests => 'Maombi ya Hivi Karibuni';

  @override
  String get activeJobs => 'Kazi Zinazoendelea';

  @override
  String get openTickets => 'Tiketi Zilizo Wazi';

  @override
  String get noActiveJobs => 'Hakuna kazi zinazoendelea';

  @override
  String get noOpenTickets => 'Hakuna tiketi zilizo wazi';

  @override
  String get noJobsFound => 'Hakuna kazi zilizopatikana';

  @override
  String get noTicketsFound => 'Hakuna tiketi zilizopatikana';

  @override
  String get searchJobsHint => 'Tafuta namba ya kazi, mteja, huduma...';

  @override
  String get searchTicketsHint => 'Tafuta tiketi, kazi, mteja, huduma...';

  @override
  String get subscriptionComingSoonTitle => 'Usajili';

  @override
  String get subscriptionComingSoonBody => 'Toleo la Premium — Linakuja hivi karibuni 🚀\nFungua huduma zaidi na ukuze biashara yako.';

  @override
  String get pendingStatus => 'INASUBIRI';

  @override
  String get onProgressStatus => 'INAENDELEA';

  @override
  String get completedStatus => 'IMEKAMILIKA';

  @override
  String get jobDetails => 'Maelezo ya Kazi';

  @override
  String get ticketDetails => 'Maelezo ya Tiketi';

  @override
  String get noTicket => 'Hakuna tiketi';

  @override
  String ticketsCount(int count) {
    return 'Tiketi ($count)';
  }

  @override
  String get noTicketsForJob => 'Hakuna tiketi za kazi hii';

  @override
  String get downloadTicket => 'Pakua Tiketi';

  @override
  String downloadingTicket(String number) {
    return 'Inapakua tiketi $number...';
  }

  @override
  String get jobNumber => 'Namba ya kazi';

  @override
  String get ticketNumber => 'Namba ya tiketi';

  @override
  String get title => 'Kichwa';

  @override
  String get category => 'Kategoria';

  @override
  String get requestDescription => 'Maelezo ya ombi';

  @override
  String get started => 'Ilianza';

  @override
  String get completedLabel => 'Imekamilika';

  @override
  String get jobStatus => 'Hali ya kazi';

  @override
  String get ticketStatus => 'Hali ya tiketi';

  @override
  String get created => 'Iliundwa';

  @override
  String get areYouSureDeleteMessage => 'Una uhakika unataka kufuta ujumbe huu?';

  @override
  String get filterAll => 'Yote';

  @override
  String get filterOnProgress => 'Inaendelea';

  @override
  String get filterCompleted => 'Imekamilika';

  @override
  String get settingsPreferences => 'Mapendeleo';

  @override
  String get settingsInformation => 'Taarifa';

  @override
  String get settingsAccount => 'Akaunti';

  @override
  String get settingsDarkMode => 'Hali ya Giza';

  @override
  String get settingsDarkOn => 'Mandhari ya giza imewashwa';

  @override
  String get settingsLightOn => 'Mandhari ya mwanga imewashwa';

  @override
  String get editServices => 'Hariri huduma';

  @override
  String get noServicesAvailable => 'Hakuna huduma zinazopatikana.';

  @override
  String get couldNotDeleteAccount => 'Imeshindwa kufuta akaunti';

  @override
  String get payments => 'Malipo';

  @override
  String get myPortfolio => 'Kazi Zangu';

  @override
  String get noPostsYet => 'Hakuna Machapisho Bado';

  @override
  String get uploadPhotosToShowcase => 'Pakia picha za kazi zako kuonyesha ujuzi wako.';

  @override
  String get newPortfolioPost => 'Chapisho Jipya la Kazi';

  @override
  String get tapToSelectImages => 'Gusa kuchagua picha';

  @override
  String get editPost => 'Hariri Chapisho';

  @override
  String get addMoreImages => 'Ongeza picha zaidi';

  @override
  String get post => 'Chapisha';

  @override
  String get deletePostTitle => 'Futa Chapisho?';

  @override
  String get deletePostConfirmation => 'Una uhakika unataka kuondoa chapisho hili lote?';

  @override
  String get editImages => 'Hariri Picha';

  @override
  String get myBalance => 'Salio Langu';

  @override
  String get earnings => 'Mapato';

  @override
  String get reports => 'Ripoti';

  @override
  String get recentJobs => 'Kazi za Hivi Karibuni';

  @override
  String get recentTickets => 'Tiketi za Hivi Karibuni';

  @override
  String get noJobsYet => 'Hakuna kazi bado';

  @override
  String get noTicketsYet => 'Hakuna tiketi bado';

  @override
  String get comingSoonTitle => 'Inakuja Hivi Karibuni';

  @override
  String get comingSoonBody => 'Huduma hii inakuja hivi karibuni 🚀\nEndelea kufuatilia masasisho.';

  @override
  String get goodMorning => 'Habari za asubuhi';

  @override
  String get goodAfternoon => 'Habari za mchana';

  @override
  String get goodEvening => 'Habari za jioni';

  @override
  String pendingCount(int count) {
    return '$count Yanasubiri';
  }

  @override
  String get acceptedStatus => 'LIMEKUBALIWA';

  @override
  String get rejectedStatus => 'LIMEKATALIWA';

  @override
  String get cancelledStatus => 'LIMEGHAIRIWA';
}
