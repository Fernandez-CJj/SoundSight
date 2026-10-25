// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get drawerHome => 'Pangunahing Pahina';

  @override
  String get searchMusic => 'Maghanap ng musika';

  @override
  String get musicLibrary => 'Aklatan ng Musika';

  @override
  String get musicLibraryDescription =>
      'Tingnan ang mga piyesang in-upload ng SoundSight.';

  @override
  String get searchMusicHint => 'Maghanap ayon sa pamagat';

  @override
  String get clearSearch => 'Burahin ang paghahanap';

  @override
  String get signInToSearchMusic =>
      'Mag-sign in upang makita ang aklatan ng musika.';

  @override
  String get musicLibraryLoadError => 'Hindi ma-load ang aklatan ng musika.';

  @override
  String get noLibraryPieces => 'Wala pang available na piyesa ng musika.';

  @override
  String get noMusicSearchResults =>
      'Walang piyesang tumutugma sa iyong paghahanap.';

  @override
  String get untitledPiece => 'Piyesang walang pamagat';

  @override
  String get libraryPieceMissing => 'Hindi na available ang piyesang ito.';

  @override
  String get libraryPracticeFilesMissing =>
      'Kulang ang mga file na kailangan para sa napiling paraan ng pagtugtog.';

  @override
  String musicLibraryOpenPiece(String title) {
    return 'Buksan ang $title';
  }

  @override
  String get drawerMusicSheets => 'Mga Music Sheet';

  @override
  String get drawerUploadSheet => 'Mag-upload ng Sheet';

  @override
  String get drawerPractice => 'Pagsasanay';

  @override
  String get drawerPracticeResults => 'Mga Resulta ng Pagsasanay';

  @override
  String get drawerMidi => 'MIDI';

  @override
  String get drawerMic => 'Mikropono';

  @override
  String get drawerFlyaway => 'Flyaway';

  @override
  String get drawerSavedSheets => 'Mga Naka-save na Sheet';

  @override
  String get drawerComposition => 'Komposisyon';

  @override
  String get drawerPublishedCompositions => 'Mga Nailathalang Komposisyon';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Wika';

  @override
  String get english => 'English';

  @override
  String get filipino => 'Filipino';

  @override
  String get logout => 'Mag-logout';

  @override
  String get logoutQuestion => 'Mag-logout?';

  @override
  String get logoutConfirmation => 'Sigurado ka bang gusto mong mag-logout?';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get languageSaveFailed => 'Hindi na-save ang napiling wika.';

  @override
  String get pianoPlayer => 'Manunugtog ng Piano';

  @override
  String get notAssessed => 'Hindi pa nasusuri';

  @override
  String get beginner => 'Baguhan';

  @override
  String get intermediate => 'Katamtaman';

  @override
  String get advanced => 'Mahusay';

  @override
  String get musicSheets => 'Mga Music Sheet';

  @override
  String get addSheetTooltip => 'Magdagdag ng sheet';

  @override
  String get yourLibrary => 'Iyong library';

  @override
  String get libraryDescription =>
      'Buksan at pamahalaan ang iyong mga na-upload na music sheet.';

  @override
  String get noMusicSheets => 'Wala pang music sheet';

  @override
  String get noMusicSheetsDescription =>
      'Mag-upload ng mga larawan o PDF upang simulan ang iyong music-sheet library.';

  @override
  String get addMusicSheet => 'Magdagdag ng Music Sheet';

  @override
  String get musicSheetsLoadError => 'Hindi ma-load ang iyong mga music sheet.';

  @override
  String get musicSheetsLoadErrorHelp =>
      'Suriin ang iyong koneksyon sa internet at subukan muli.';

  @override
  String get signInForMusicSheets =>
      'Mag-sign in upang makita ang iyong mga music sheet.';

  @override
  String get untitledSheet => 'Music Sheet na Walang Pamagat';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pahina',
      one: '1 pahina',
    );
    return '$_temp0';
  }

  @override
  String get pdf => 'PDF';

  @override
  String get images => 'Mga Larawan';

  @override
  String addedDate(String date) {
    return 'Idinagdag noong $date';
  }

  @override
  String get rename => 'Palitan ang pangalan';

  @override
  String get delete => 'Burahin';

  @override
  String get renameSheet => 'Palitan ang pangalan ng sheet';

  @override
  String get sheetTitle => 'Pamagat ng sheet';

  @override
  String get enterSheetTitle => 'Maglagay ng pamagat para sa sheet na ito.';

  @override
  String get save => 'I-save';

  @override
  String get deleteSheetQuestion => 'Burahin ang sheet?';

  @override
  String deleteSheetConfirmation(String title) {
    return 'Permanenteng buburahin ang \"$title\" at lahat ng file nito.';
  }

  @override
  String get musicSheetRenamed => 'Napalitan ang pangalan ng music sheet.';

  @override
  String get musicSheetRenameFailed =>
      'Hindi mapalitan ang pangalan ng music sheet.';

  @override
  String get waitForTranslationBeforeDelete =>
      'Hintaying matapos ang pag-convert ng music sheet bago ito burahin.';

  @override
  String musicSheetDeleted(String title) {
    return 'Nabura ang \"$title\".';
  }

  @override
  String get musicSheetDeleteFailed => 'Hindi mabura ang music sheet.';

  @override
  String get play => 'I-play';

  @override
  String get choosePlayMode => 'Pumili ng play mode';

  @override
  String get sightReading => 'Pagbabasa ng Nota';

  @override
  String get synthesia => 'Synthesia';

  @override
  String get arPractice => 'AR Practice';

  @override
  String get translateBeforeAr =>
      'I-convert muna ang music sheet bago simulan ang AR Practice.';

  @override
  String get translatedMidiMissing =>
      'Hindi pa handa ang file na kailangan para sa practice mode na ito.';

  @override
  String get openArFailed => 'Hindi mabuksan ang AR Practice.';

  @override
  String get translateBeforeSynthesia =>
      'I-convert muna ang music sheet bago simulan ang Synthesia.';

  @override
  String get openSynthesiaFailed => 'Hindi mabuksan ang Synthesia.';

  @override
  String get translateBeforeSightReading =>
      'I-convert muna ang music sheet bago simulan ang Pagbabasa ng Nota.';

  @override
  String get translatedPracticeFilesMissing =>
      'Hindi pa handa ang mga file na kailangan para sa practice mode na ito.';

  @override
  String get openSightReadingFailed => 'Hindi mabuksan ang Pagbabasa ng Nota.';

  @override
  String get recognized => 'Na-convert';

  @override
  String get original => 'Orihinal';

  @override
  String get recognizedPdfLoadFailed =>
      'Hindi ma-load ang na-convert na sheet. Ipinapakita na lamang ang orihinal na sheet.';

  @override
  String get retry => 'Subukan muli';

  @override
  String pageNumber(int number) {
    return 'Pahina $number';
  }

  @override
  String get musicSheetHasNoFiles => 'Walang file ang music sheet na ito.';

  @override
  String get fileLoadFailed => 'Hindi ma-load ang file.';

  @override
  String get tryAgain => 'Subukan Muli';

  @override
  String get translateSheetAgainQuestion => 'I-convert muli ang sheet na ito?';

  @override
  String get translateMusicSheetQuestion => 'I-convert ang music sheet?';

  @override
  String retranslateDescription(String title) {
    return 'Ipoproseso muli ng SoundSight ang \"$title\" at papalitan ang kasalukuyang na-convert na bersyon nito.';
  }

  @override
  String translateDescription(String title) {
    return 'Gagawa ang SoundSight ng digital na bersyon ng \"$title\" na maaaring patugtugin. Maaaring tumagal ito nang ilang minuto.';
  }

  @override
  String get continueAction => 'Magpatuloy';

  @override
  String get translate => 'I-convert';

  @override
  String get translatingMusicSheet => 'Kino-convert ang music sheet';

  @override
  String get translationLoadingDescription =>
      'Binabasa ng SoundSight ang mga nota. Mangyaring maghintay at panatilihing bukas ang app.';

  @override
  String get translationComplete => 'Tapos na ang pag-convert';

  @override
  String translationResult(int noteCount, int partCount) {
    String _temp0 = intl.Intl.pluralLogic(
      noteCount,
      locale: localeName,
      other: '$noteCount nota',
      one: '1 nota',
    );
    String _temp1 = intl.Intl.pluralLogic(
      partCount,
      locale: localeName,
      other: '$partCount bahagi',
      one: '1 bahagi',
    );
    return 'Nakita ng SoundSight ang $_temp0 sa $_temp1.';
  }

  @override
  String get done => 'Tapos na';

  @override
  String get translationFailed => 'Nabigo ang pag-convert';

  @override
  String get close => 'Isara';

  @override
  String get translationReady => 'Handa na ang na-convert na sheet';

  @override
  String translationSummary(int noteCount, int partCount) {
    String _temp0 = intl.Intl.pluralLogic(
      noteCount,
      locale: localeName,
      other: '$noteCount nota',
      one: '1 nota',
    );
    String _temp1 = intl.Intl.pluralLogic(
      partCount,
      locale: localeName,
      other: '$partCount bahagi',
      one: '1 bahagi',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String get translationFailedDescription =>
      'Hindi ma-convert ang sheet. Maaari mong subukan muli.';

  @override
  String get translationProcessingDescription =>
      'Binabasa ng SoundSight ang mga nota.';

  @override
  String get translationStartDescription =>
      'Gumawa ng digital na bersyong maaaring gamitin sa mga practice mode ng SoundSight.';

  @override
  String get reconvert => 'I-convert Muli';

  @override
  String get translationGenericError => 'Hindi ma-convert ang music sheet.';

  @override
  String get translationTimedOut =>
      'Masyadong matagal ang pag-convert. Subukan muli.';

  @override
  String get translationConnectionError =>
      'Hindi makakonekta ang SoundSight. Suriin ang iyong internet connection at subukan muli.';

  @override
  String get translationRejected =>
      'Hindi mabasa ng SoundSight ang music sheet na ito. Gumamit ng mas malinaw na larawan o PDF.';

  @override
  String get translationInvalidResponse =>
      'Nagkaproblema habang kino-convert ang music sheet. Subukan muli.';

  @override
  String get audioPreview => 'Audio preview';

  @override
  String get audioLoading => 'Nilo-load ang audio...';

  @override
  String get audioPlaying => 'Pinapatugtog ang na-convert na musika';

  @override
  String get audioPaused => 'Naka-pause ang playback';

  @override
  String get audioIdle => 'Pakinggan ang na-convert na music sheet';

  @override
  String get pause => 'I-pause';

  @override
  String get stop => 'Ihinto';

  @override
  String get audioPlaybackError => 'Hindi ma-play ang audio preview.';

  @override
  String get addSheet => 'Magdagdag ng Sheet';

  @override
  String get deleteAllSelectedFilesTooltip =>
      'Burahin ang lahat ng napiling file';

  @override
  String get addYourSheetMusic => 'Idagdag ang iyong sheet music';

  @override
  String get addSheetDescription =>
      'Mag-upload ng isang PDF o kumuha ng malinaw na larawan ng naka-print na sheet.';

  @override
  String get chooseOneMethod => 'Pumili ng isang paraan para sa bawat sheet';

  @override
  String get sheetMethodLimits =>
      '1 PDF (20 MB, 20 pahina) o hanggang 20 kinuhang larawan (5 MB bawat isa). Hindi maaaring pagsamahin ang mga ito.';

  @override
  String get openingPdf => 'Binubuksan ang PDF...';

  @override
  String get uploadPdf => 'Mag-upload ng PDF';

  @override
  String get uploadPdfDescription =>
      'Pumili ng 1 PDF na hanggang 20 MB at 20 pahina.';

  @override
  String get capturePages => 'Kunan ang mga Pahina';

  @override
  String get capturePagesDescription =>
      'Kumuha ng hanggang 20 larawan, 5 MB bawat isa.';

  @override
  String get captureTips => 'Mga tip sa pagkuha';

  @override
  String get captureTipsDescription =>
      'Kumuha ng mas malinaw at mas tumpak na resulta';

  @override
  String get captureTipLighting => 'Gumamit ng maayos at pantay na ilaw.';

  @override
  String get captureTipFlat =>
      'Ilatag nang patag ang sheet music sa isang ibabaw.';

  @override
  String get captureTipVisible =>
      'Tiyaking nakikita, tuwid, at malinaw ang buong pahina.';

  @override
  String get selectedFiles => 'Mga napiling file';

  @override
  String get selectedFileInstructions =>
      'I-tap para i-preview • I-swipe pakanan para alisin';

  @override
  String selectedImageLimit(int count, int maximum) {
    return '$count / $maximum';
  }

  @override
  String get onePdf => '1 PDF';

  @override
  String selectedPdfMetadata(String size, String pages) {
    return 'PDF • $size • $pages';
  }

  @override
  String selectedImageMetadata(String size) {
    return 'Larawan • $size';
  }

  @override
  String get deleteAllFilesQuestion => 'Burahin ang lahat ng file?';

  @override
  String deleteSelectedFilesConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lahat ng $count napiling file',
      one: 'napiling file',
    );
    return 'Aalisin nito ang $_temp0.';
  }

  @override
  String get deleteAll => 'Burahin Lahat';

  @override
  String get removeFileQuestion => 'Alisin ang file?';

  @override
  String removeFileConfirmation(String fileName) {
    return 'Gusto mo bang alisin ang $fileName?';
  }

  @override
  String get remove => 'Alisin';

  @override
  String get nameYourSheet => 'Pangalanan ang iyong sheet';

  @override
  String get upload => 'I-upload';

  @override
  String get sheetSaved => 'Na-save ang sheet';

  @override
  String get unableToSave => 'Hindi ma-save';

  @override
  String sheetSavedDescription(String title) {
    return 'Matagumpay na na-upload at na-save ang \"$title\".';
  }

  @override
  String get sheetSaveFailedDescription =>
      'Hindi ma-save ang sheet. Suriin ang iyong koneksyon at subukan muli.';

  @override
  String get backToSelection => 'Bumalik sa pagpili';

  @override
  String get saveSheet => 'I-save ang Sheet';

  @override
  String savingProgress(int percent) {
    return 'Sine-save $percent%';
  }

  @override
  String get signInBeforeSaving =>
      'Kailangan mong mag-sign in bago mag-save ng sheet.';

  @override
  String get onlyOnePdf =>
      'Isang PDF lamang ang maaaring i-upload. Burahin ang napiling PDF bago pumili ng iba.';

  @override
  String get deleteImagesBeforePdf =>
      'Burahin ang lahat ng kinuhang larawan bago mag-upload ng PDF.';

  @override
  String get selectExactlyOnePdf => 'Pumili ng eksaktong isang PDF.';

  @override
  String get onlyPdfFiles => 'Mga PDF file lamang ang maaaring i-upload.';

  @override
  String get pdfSizeLimit => 'Dapat 20 MB o mas maliit ang PDF.';

  @override
  String get pdfHasNoPages => 'Walang pahina ang PDF.';

  @override
  String pdfPageLimit(int count, int maximum) {
    return 'May $count pahina ang PDF na ito. Hanggang $maximum pahina lamang ang pinapayagan.';
  }

  @override
  String get pdfReadFailed =>
      'Hindi mabasa ang PDF. Tiyaking wasto at hindi naka-lock ang PDF.';

  @override
  String get deletePdfBeforeCapture =>
      'Burahin ang napiling PDF bago kumuha ng mga larawan.';

  @override
  String imageCountLimit(int maximum) {
    return 'Hanggang $maximum larawan lamang ang maaaring idagdag.';
  }

  @override
  String get capturedImageSizeLimit =>
      'Mas malaki sa 5 MB ang kinuhang larawan. Subukang kunan itong muli.';

  @override
  String get openProfile => 'Buksan ang profile';

  @override
  String homeGreeting(String username) {
    return 'Kumusta, $username';
  }

  @override
  String get homeEncouragement =>
      'Magpatuloy sa pagsasanay. Nagsisimula sa iyo ang mahusay na musika.';

  @override
  String get startPractice => 'Simulan ang Pagsasanay';

  @override
  String get practiceBannerDescription =>
      'Paunlarin ang iyong kakayahan sa musika, pagbutihin ang katumpakan, at paghusayin ang iyong pagtugtog.';

  @override
  String get playerProgress => 'Pag-unlad ng Manunugtog';

  @override
  String get underAssessment => 'Sinusuri pa';

  @override
  String rankLabel(String rank) {
    return 'Ranggo: $rank';
  }

  @override
  String levelLabel(int level) {
    return 'ANTAS $level';
  }

  @override
  String get experience => 'Karanasan';

  @override
  String xpNeeded(int count) {
    return 'Kailangan ng $count XP';
  }

  @override
  String get nextLevel => 'Susunod na antas';

  @override
  String get quickActions => 'Mga Mabilisang Aksyon';

  @override
  String get captureSheet => 'Kunan ang Sheet';

  @override
  String get communityCompositions => 'Mga Komposisyon ng Komunidad';

  @override
  String get communityCompositionsDescription =>
      'Tumuklas ng musikang ibinahagi ng ibang user.';

  @override
  String get seeAll => 'Tingnan Lahat';

  @override
  String get communityCompositionsLoadFailed =>
      'Hindi ma-load ang mga komposisyon ng komunidad.';

  @override
  String get noCommunityCompositions =>
      'Wala pang ibinabahaging komposisyon sa komunidad.';

  @override
  String communityPlaying(String title) {
    return 'Pinapatugtog ang \"$title\".';
  }

  @override
  String get communityPlaybackStopped => 'Itinigil ang playback.';

  @override
  String get communityNoPlaybackData =>
      'Walang playback data ang bersyong ito. Ilathala itong muli.';

  @override
  String get communityPlaybackFailed =>
      'Hindi mapatugtog ang nailathalang komposisyon.';

  @override
  String get profile => 'Profile';

  @override
  String get achievements => 'Mga Nakamit';

  @override
  String get viewAchievementDetails => 'Tingnan ang detalye';

  @override
  String get achievementDetails => 'Mga Detalye ng Badge';

  @override
  String achievementProgress(int earned, int total) {
    return 'Nakamit na badge: $earned sa $total';
  }

  @override
  String get badgeFirstMeasure => 'Unang Sukat';

  @override
  String get badgeFirstMeasureDescription =>
      'Tapusin ang pagsusuri ng kasanayan upang malaman ang iyong antas sa SoundSight.';

  @override
  String get badgeSheetCollector => 'Kolektor ng Piyesa';

  @override
  String get badgeSheetCollectorDescription =>
      'I-save ang una mong music sheet sa pag-upload ng file o pagkuha ng larawan gamit ang camera.';

  @override
  String get badgeFirstComposer => 'Unang Kompositor';

  @override
  String get badgeFirstComposerDescription =>
      'I-save ang una mong komposisyon, mano-mano man o mula sa recording.';

  @override
  String get badgeMiddleC => 'Gitnang C';

  @override
  String get badgeMiddleCDescription =>
      'Tapusin ang stage 3 ng leksiyon: Ang Gitnang C.';

  @override
  String get badgeFirstMelody => 'Unang Melodiya';

  @override
  String get badgeFirstMelodyDescription =>
      'Tapusin ang stage 6 ng leksiyon: Tugtuin ang Twinkle Twinkle.';

  @override
  String get badgeGrowingMusician => 'Umuunlad na Musikero';

  @override
  String get badgeGrowingMusicianDescription =>
      'Tapusin ang stage 9 ng leksiyon: Tugtuin ang Fur Elise.';

  @override
  String get badgeChordBuilder => 'Tagabuo ng Chord';

  @override
  String get badgeChordBuilderDescription =>
      'Tapusin ang stage 12 ng leksiyon: Mga Chord.';

  @override
  String get badgeMusicNavigator => 'Gabay sa Musika';

  @override
  String get badgeMusicNavigatorDescription =>
      'Tapusin ang stage 15 ng leksiyon: Nashville Number System.';

  @override
  String get badgeSoundSightMaster => 'Dalubhasa sa SoundSight';

  @override
  String get badgeSoundSightMasterDescription =>
      'Tapusin ang lahat ng 16 na stage ng leksiyon.';

  @override
  String get badgeUnlocked => 'Nakamit';

  @override
  String get badgeLocked => 'Naka-lock';

  @override
  String get badgeChecking => 'Sinusuri';

  @override
  String get badgeEarnedAnnouncement => 'Nakamit ang badge!';

  @override
  String get editProfileTooltip => 'I-edit ang profile';

  @override
  String get profilePicture => 'Larawan sa Profile';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'I-edit ang Profile';

  @override
  String get preferences => 'Mga Kagustuhan';

  @override
  String get appAppearance => 'Itsura ng app';

  @override
  String get assessment => 'Pagsusuri';

  @override
  String get retryAssessmentStatus => 'Subukang Muli ang Status';

  @override
  String get loadingAssessment => 'Nilo-load ang Pagsusuri';

  @override
  String get startAssessment => 'Simulan ang Pagsusuri';

  @override
  String get resumeAssessment => 'Ipagpatuloy ang Pagsusuri';

  @override
  String get viewAssessmentResults => 'Tingnan ang mga Resulta';

  @override
  String get assessmentExpired => 'Nag-expire ang Pagsusuri';

  @override
  String get assessmentLoadFailedDescription =>
      'Hindi ma-load ang pagsusuri. I-tap upang subukan muli.';

  @override
  String get assessmentLoadingDescription =>
      'Sinusuri ang kasalukuyang status ng iyong pagsusuri.';

  @override
  String get assessmentNotStartedDescription =>
      'Magsimula kapag handa ka na. Hindi pa nagsisimula ang timer.';

  @override
  String get assessmentInProgressDescription =>
      'Magpatuloy bago matapos ang aktibong 72-oras na palugit.';

  @override
  String get assessmentCompletedDescription =>
      'Suriin ang iyong permanenteng antas at mga marka sa bawat seksyon.';

  @override
  String get assessmentExpiredDescription =>
      'Nag-expire ang pagsusuri at hindi na maaaring ulitin. Mananatili ang iyong naitalang antas; kung wala pa, itatalaga ang Baguhan.';

  @override
  String get updatePersonalInformation =>
      'I-update ang iyong personal na impormasyon.';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get emailCannotBeChanged => 'Hindi maaaring baguhin ang email';

  @override
  String get saveChanges => 'I-save ang mga Pagbabago';

  @override
  String get usernameRequired => 'Hindi maaaring walang laman ang username.';

  @override
  String get profileSaveFailed =>
      'Hindi ma-save ang mga pagbabago sa profile. Subukan muli.';

  @override
  String get profilePictureSizeLimit =>
      'Dapat mas maliit sa 5 MB ang larawan sa profile.';

  @override
  String get saveChangesQuestion => 'I-save ang mga pagbabago?';

  @override
  String get profileSaveConfirmation =>
      'Sigurado ka bang gusto mong i-update ang impormasyon sa iyong profile?';

  @override
  String get uploadingProfilePicture => 'Ina-upload ang larawan sa profile...';

  @override
  String get savingProfileChanges =>
      'Sine-save ang mga pagbabago sa profile...';

  @override
  String get pleaseWait => 'Mangyaring maghintay sandali.';

  @override
  String get myCompositions => 'Aking mga Komposisyon';

  @override
  String get newComposition => 'Bagong Komposisyon';

  @override
  String get yourPianoPieces => 'Iyong mga piyesa sa piano';

  @override
  String get compositionsDescription =>
      'Gumawa, magpatugtog, at mamahala ng iyong mga simpleng melodiya.';

  @override
  String get noCompositions => 'Wala pang komposisyon';

  @override
  String get noCompositionsDescription =>
      'Gawin ang iyong unang piyesa sa piano gamit ang mga melodiya, chord, at pasadyang measure.';

  @override
  String get compositionsLoadError =>
      'Hindi ma-load ang iyong mga komposisyon.';

  @override
  String get signInForCompositions =>
      'Mag-sign in upang makita ang iyong mga komposisyon.';

  @override
  String get compositionSavedFilesReady =>
      'Na-save ang komposisyon at handa na ang mga music file.';

  @override
  String get compositionSavedFilesPending =>
      'Ligtas na na-save ang komposisyon. Hindi pa handa ang sheet music at mga playback file nito.';

  @override
  String get compositionSaved => 'Na-save ang komposisyon.';

  @override
  String compositionDeleted(String title) {
    return 'Nabura ang \"$title\".';
  }

  @override
  String get compositionMusicFilesReady => 'Handa na ang iyong mga music file.';

  @override
  String get compositionMusicFilesFailed =>
      'Na-save ang komposisyon, ngunit hindi pa rin maihanda ang mga music file. Subukan muli kapag available na ang serbisyo.';

  @override
  String get compositionDeleteFailed => 'Hindi mabura ang komposisyon.';

  @override
  String get deleteCompositionQuestion => 'Burahin ang komposisyon?';

  @override
  String deleteCompositionConfirmation(String title) {
    return 'Sigurado ka bang gusto mong burahin ang \"$title\"? Hindi na ito maibabalik.';
  }

  @override
  String get manual => 'Manwal';

  @override
  String get recording => 'Pagre-record';

  @override
  String get preparingMusicFiles => 'Inihahanda ang iyong mga music file';

  @override
  String get musicFilesNeedUpdating => 'Kailangang i-update ang mga music file';

  @override
  String get musicFilesNotReady => 'Hindi pa handa ang mga music file';

  @override
  String get musicFilesOutOfDateDescription =>
      'Na-save ang iyong mga pagbabago, ngunit mas lumang bersyon ang nasa mga available na file.';

  @override
  String get musicFilesNotReadyDescription =>
      'Hindi pa handa ang iyong sheet music at mga playback file.';

  @override
  String get view => 'Tingnan';

  @override
  String get notSavedYet => 'Hindi pa na-save';

  @override
  String lastEdited(String date) {
    return 'Huling in-edit noong $date';
  }

  @override
  String get createYourPianoPiece => 'Gawin ang iyong piyesa sa piano';

  @override
  String get newCompositionManualDescription =>
      'Piliin ang panimulang pamagat, key, tempo, at meter. Maaari mong baguhin ang mga ito sa composition workspace.';

  @override
  String get newCompositionRecordingDescription =>
      'Pumili ng pamagat, key, at meter. Matutukoy ang tempo at mga measure mula sa iyong pagtugtog.';

  @override
  String get compositionTitle => 'Pamagat ng Komposisyon';

  @override
  String get compositionTitleHint => 'Halimbawa: Aking Unang Awit';

  @override
  String get compositionTitleRequired => 'Maglagay ng pamagat ng komposisyon.';

  @override
  String get compositionTitleTooLong =>
      'Dapat 80 character o mas kaunti ang pamagat.';

  @override
  String get tempo => 'Tempo';

  @override
  String get tempoDescription =>
      'Mas mabagal ang mababang BPM. Mas mabilis ang mataas na BPM.';

  @override
  String get tempoRangeHint => '40 hanggang 200';

  @override
  String get validTempoRequired => 'Maglagay ng wastong tempo.';

  @override
  String get tempoRangeError =>
      'Dapat nasa pagitan ng 40 at 200 BPM ang tempo.';

  @override
  String get detectedTempoDescription =>
      'Matutukoy ang tempo at bilang ng measure mula sa iyong pagtugtog.';

  @override
  String get compositionSettings => 'Mga Setting ng Komposisyon';

  @override
  String get compositionSettingsDescription =>
      'Itakda ang estrukturang musikal ng piyesang ito.';

  @override
  String get keySignature => 'Key Signature';

  @override
  String get timeSignature => 'Time Signature';

  @override
  String get opening => 'Binubuksan...';

  @override
  String get openRecorder => 'Buksan ang Recorder';

  @override
  String get startComposing => 'Simulan ang Pagkomposo';

  @override
  String get signInBeforeCreatingComposition =>
      'Mag-sign in bago gumawa ng komposisyon.';

  @override
  String get compositionDetails => 'Mga Detalye ng Komposisyon';

  @override
  String get editComposition => 'I-edit ang Komposisyon';

  @override
  String get deleteComposition => 'Burahin ang Komposisyon';

  @override
  String get pianoSolo => 'Piano Solo';

  @override
  String get keyLabel => 'Key';

  @override
  String get timeLabel => 'Sukat';

  @override
  String get editedLabel => 'Huling in-edit';

  @override
  String get loading => 'Nilo-load';

  @override
  String get paused => 'Naka-pause';

  @override
  String get playing => 'Nagpe-play';

  @override
  String get ready => 'Handa';

  @override
  String get listenToComposition => 'Pakinggan ang iyong komposisyon';

  @override
  String get playFromBeginning => 'I-play mula sa simula';

  @override
  String get compositionSummary => 'Buod ng Komposisyon';

  @override
  String measureLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mga Measure',
      one: 'Measure',
    );
    return '$_temp0';
  }

  @override
  String noteLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mga Nota',
      one: 'Nota',
    );
    return '$_temp0';
  }

  @override
  String get duration => 'Tagal';

  @override
  String get musicFilesReady => 'Handa na ang mga music file';

  @override
  String get musicFilesReadyDescription =>
      'Handa na ang iyong sheet music at mga playback file.';

  @override
  String musicFilesPrepared(String date) {
    return 'Inihanda noong $date.';
  }

  @override
  String get retryGeneration => 'Subukang Ihanda Muli';

  @override
  String get checkingPublicationStatus =>
      'Sinusuri ang status ng paglalathala...';

  @override
  String get publishingUpdateProgress => 'Inilalathala ang Update...';

  @override
  String get unpublishingProgress => 'Inaalis sa pagkakalathala...';

  @override
  String get publishingProgress => 'Inilalathala...';

  @override
  String get publishUpdate => 'Ilathala ang Update';

  @override
  String get publish => 'Ilathala';

  @override
  String get unpublishComposition => 'Alisin sa Pagkakalathala';

  @override
  String get publishComposition => 'Ilathala ang Komposisyon';

  @override
  String get deletingProgress => 'Binubura...';

  @override
  String get compositionHasNoNotes => 'Wala pang nota ang komposisyong ito.';

  @override
  String get compositionValidationFailed =>
      'May hindi wastong data ang komposisyong ito at hindi ito ma-play.';

  @override
  String get compositionPlaybackFailed =>
      'Hindi ma-play ang komposisyon. Suriin ang mga piano audio file.';

  @override
  String get unavailable => 'Hindi available';

  @override
  String get addNoteBeforePublishing =>
      'Magdagdag ng kahit isang nota bago maglathala.';

  @override
  String get prepareFilesBeforePublishing =>
      'Ihanda ang sheet music at mga playback file bago maglathala.';

  @override
  String get compositionUnpublished =>
      'Matagumpay na inalis sa pagkakalathala ang komposisyon.';

  @override
  String get compositionUpdatePublished =>
      'Matagumpay na nailathala ang update ng komposisyon.';

  @override
  String get compositionPublished =>
      'Matagumpay na nailathala ang komposisyon.';

  @override
  String get compositionUnpublishFailed =>
      'Hindi maalis sa pagkakalathala ang komposisyon.';

  @override
  String get compositionPublishFailed =>
      'Hindi mailathala ang komposisyon. Tiyaking tumatakbo ang backend.';

  @override
  String get compositionPublishUnauthorized =>
      'Hindi ma-verify ang iyong publishing session. Mag-sign out, mag-sign in muli, at subukan ulit.';

  @override
  String get updatedCompositionLoadFailed =>
      'Hindi ma-load ang na-update na komposisyon.';

  @override
  String get prepareLatestFilesBeforeAr =>
      'Ihanda ang pinakabagong mga music file bago simulan ang AR Practice.';

  @override
  String get generatedMidiMissing => 'Nawawala ang nabuong MIDI file.';

  @override
  String get prepareLatestFilesBeforeSightReading =>
      'Ihanda ang pinakabagong mga music file bago simulan ang Pagbabasa ng Nota.';

  @override
  String get generatedPracticeFilesMissing =>
      'Nawawala ang nabuong MusicXML, MIDI, o MP3 file.';

  @override
  String publishUpdateQuestion(String title) {
    return 'Ilathala ang pinakabagong mga pagbabago sa \"$title\"?';
  }

  @override
  String publishCompositionQuestion(String title) {
    return 'Ilathala ang \"$title\"?';
  }

  @override
  String get publishUpdateDescription =>
      'Gagawa ng bagong nailathalang bersyon at PDF. Mananatili ang mga dating bersyon, like, komento, at save.';

  @override
  String get publishCompositionDescription =>
      'Gagawa ng PDF music sheet at ibabahagi ito sa ibang user ng SoundSight.';

  @override
  String get unpublishCompositionQuestion =>
      'Alisin sa pagkakalathala ang komposisyon?';

  @override
  String unpublishCompositionConfirmation(String title) {
    return 'Aalisin ang \"$title\" at lahat ng nailathalang bersyon nito mula sa community feed.';
  }

  @override
  String get unpublish => 'Alisin';

  @override
  String get unpublishingComposition =>
      'Inaalis sa pagkakalathala ang komposisyon...';

  @override
  String get unpublishingCompositionDescription =>
      'Inaalis ang lahat ng nailathalang bersyon at PDF. Mangyaring maghintay.';

  @override
  String get generatedPreview => 'Nabuong preview';

  @override
  String get generatedPreviewDescription =>
      'Suriin ang iyong sheet music at pakinggan ito bago maglathala.';

  @override
  String get compositionPlayback => 'Playback ng komposisyon';

  @override
  String get loadingComposition => 'Nilo-load ang iyong komposisyon...';

  @override
  String get playingComposition => 'Pinapatugtog ang iyong komposisyon';

  @override
  String get listenGeneratedComposition => 'Pakinggan ang nabuong komposisyon';

  @override
  String get sheetMusic => 'Sheet music';

  @override
  String get fullScreen => 'Buong screen';

  @override
  String get sheetMusicLoadFailed => 'Hindi ma-load ang sheet music.';

  @override
  String get checkConnectionTryAgain =>
      'Suriin ang iyong koneksyon, pagkatapos ay subukan muli.';

  @override
  String get compositionSettingsTooltip => 'Mga setting ng komposisyon';

  @override
  String get saveCompositionTooltip => 'I-save ang komposisyon';

  @override
  String get automaticDurationDescription =>
      'Susundan ng Awtomatiko kung gaano katagal pinipindot ang mga MIDI key.';

  @override
  String get automaticKeyHoldHelper =>
      'Ginagamit ng Awtomatiko ang tagal ng pagpindot sa key.';

  @override
  String get pianoKeyboard => 'Keyboard ng Piano';

  @override
  String get swipeHorizontally => 'Mag-swipe pahalang';

  @override
  String get back => 'Pabalik';

  @override
  String get forward => 'Pasulong';

  @override
  String get moveBackUsingDuration => 'Bumalik gamit ang napiling tagal';

  @override
  String get moveForwardUsingDuration => 'Sumulong gamit ang napiling tagal';

  @override
  String get rest => 'Pahinga';

  @override
  String get insertRest => 'Maglagay ng Pahinga';

  @override
  String get insertRestUsingDuration =>
      'Maglagay ng pahinga gamit ang napiling tagal';

  @override
  String get overview => 'Pangkalahatang-ideya';

  @override
  String get toggleSongOverview =>
      'Ipakita o itago ang pangkalahatang-ideya ng buong awit';

  @override
  String get saving => 'Sine-save';

  @override
  String get savingEllipsis => 'Sine-save...';

  @override
  String get saveComposition => 'I-save ang Komposisyon';

  @override
  String get beat => 'beat';

  @override
  String get beats => 'mga beat';

  @override
  String selectedNotePosition(
    int measure,
    String beat,
    String duration,
    String unit,
  ) {
    return 'Measure $measure • Beat $beat • $duration $unit';
  }

  @override
  String get clearSelection => 'Alisin ang pagpili';

  @override
  String get tied => 'Naka-tie';

  @override
  String get addMeasure => 'Magdagdag ng Measure';

  @override
  String get deleteSelection => 'Burahin ang Napili';

  @override
  String get unsupportedPianoKey =>
      'Ang piano key na iyon ay wala sa sinusuportahang A0 hanggang C8.';

  @override
  String get selectSingleNoteBeforePlaying =>
      'Pumili lamang ng isang nota, o alisin ang pagpili, bago tumugtog.';

  @override
  String get clearSelectedNoteBeforeChord =>
      'Alisin ang napiling nota bago gumawa ng chord.';

  @override
  String get stopPlaybackBeforeEditing =>
      'Ihinto ang playback bago i-edit ang komposisyon.';

  @override
  String compositionNoteLimitReached(int count) {
    return 'Mayroon nang $count sa 256 pinapayagang nota ang komposisyong ito.';
  }

  @override
  String get pianoNotePlaybackFailed => 'Hindi ma-play ang nota ng piano.';

  @override
  String get measureActionUnavailable =>
      'Hindi available ang aksyon na iyon para sa measure.';

  @override
  String get selectNoteFirst => 'Pumili muna ng kahit isang nota.';

  @override
  String notesCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota ang nakopya.',
      one: '1 nota ang nakopya.',
    );
    return '$_temp0';
  }

  @override
  String get selectChordFirst => 'Pumili muna ng chord.';

  @override
  String get addNoteBeforePlaying =>
      'Magdagdag muna ng kahit isang nota bago tumugtog.';

  @override
  String get compositionSaveFailed => 'Hindi ma-save ang komposisyon.';

  @override
  String get chordMode => 'Chord Mode';

  @override
  String chordNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get allowStacking => 'Payagan ang pagsasabay';

  @override
  String get chordModeDescription =>
      'Payagang magsimula ang maraming nota sa parehong beat.';

  @override
  String chordNotesCombined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota ang pinagsama',
      one: '1 nota ang pinagsama',
    );
    return '$_temp0';
  }

  @override
  String get finishChord => 'Tapusin ang Chord';

  @override
  String get layerNotes => 'Magpatong ng mga Nota';

  @override
  String measureBeatPosition(int measure, String beat) {
    return 'Measure $measure • Beat $beat';
  }

  @override
  String get independentNotes => 'Magkakahiwalay na mga nota';

  @override
  String addNextNoteHere(String position) {
    return '$position — idagdag dito ang susunod na nota.';
  }

  @override
  String get layerNotesDescription =>
      'Magdagdag ng mas maiikling nota habang patuloy na tumutugtog ang isa pang nota.';

  @override
  String get undo => 'I-undo';

  @override
  String get redo => 'I-redo';

  @override
  String get copy => 'Kopyahin';

  @override
  String get paste => 'I-paste';

  @override
  String get selectAll => 'Piliin Lahat';

  @override
  String get removeTie => 'Alisin ang Tie';

  @override
  String get tieToNext => 'I-tie sa Susunod';

  @override
  String get deleteWholeChord => 'Burahin ang Buong Chord';

  @override
  String get historyAndEditing => 'History at pag-edit';

  @override
  String get performanceSettings => 'Mga setting ng pagtugtog';

  @override
  String get performance => 'Pagtugtog';

  @override
  String get performanceDescription =>
      'Ayusin ang playback at tunog ng mga bagong nota.';

  @override
  String get volume => 'Volume';

  @override
  String get noteVelocity => 'Velocity ng nota';

  @override
  String get fromCursor => 'Mula sa cursor';

  @override
  String get loopMeasure => 'Ulitin ang measure';

  @override
  String get sustain => 'Sustain';

  @override
  String get metronome => 'Metronome';

  @override
  String get resume => 'Ipagpatuloy';

  @override
  String get playback => 'Playback';

  @override
  String get pianoRoll => 'Piano Roll';

  @override
  String measureNumber(int number) {
    return 'Measure $number';
  }

  @override
  String get deleteSelectedNote => 'Burahin ang napiling nota';

  @override
  String get deleteSelectedNotes => 'Burahin ang mga napiling nota';

  @override
  String get measures => 'Mga Measure';

  @override
  String get measure => 'Measure';

  @override
  String totalCount(int count) {
    return '$count lahat';
  }

  @override
  String get previousMeasure => 'Nakaraang measure';

  @override
  String get nextMeasure => 'Susunod na measure';

  @override
  String get previousOctave => 'Nakaraang octave';

  @override
  String get selectOctave => 'Pumili ng octave';

  @override
  String octaveNumber(int number) {
    return 'Octave $number';
  }

  @override
  String octaveWithRange(int number, String range) {
    return 'Octave $number - $range';
  }

  @override
  String get nextOctave => 'Susunod na octave';

  @override
  String get viewAllNotes => 'Tingnan ang lahat ng nota';

  @override
  String notesBelowOctave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota sa ibaba ng octave na ito',
      one: '1 nota sa ibaba ng octave na ito',
    );
    return '$_temp0';
  }

  @override
  String notesAboveOctave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota sa itaas ng octave na ito',
      one: '1 nota sa itaas ng octave na ito',
    );
    return '$_temp0';
  }

  @override
  String get tapPianoKeyToAdd => 'I-tap ang piano key upang magdagdag ng nota';

  @override
  String get noNotesInOctave => 'Walang nota sa octave na ito';

  @override
  String get allNotes => 'Lahat ng Nota';

  @override
  String get noNotesAdded => 'Wala pang naidagdag na nota.';

  @override
  String beatWithNotes(String beat, String notes) {
    return 'Beat $beat: $notes';
  }

  @override
  String pianoKeySemanticLabel(String key) {
    return 'Piano key $key';
  }

  @override
  String get measureActions => 'Mga aksyon sa measure';

  @override
  String get addMeasureAfter => 'Magdagdag ng measure pagkatapos';

  @override
  String get insertMeasureBefore => 'Maglagay ng measure bago nito';

  @override
  String get duplicateMeasure => 'Kopyahin ang measure';

  @override
  String get moveMeasureLeft => 'Ilipat pakaliwa ang measure';

  @override
  String get moveMeasureRight => 'Ilipat pakanan ang measure';

  @override
  String get clearMeasure => 'Alisin ang laman ng measure';

  @override
  String get deleteMeasure => 'Burahin ang measure';

  @override
  String get wholeNote => 'Buong Nota';

  @override
  String get dottedHalfNote => 'Dotted Half';

  @override
  String get halfNote => 'Half Note';

  @override
  String get dottedQuarterNote => 'Dotted Quarter';

  @override
  String get quarterNote => 'Quarter Note';

  @override
  String get dottedEighthNote => 'Dotted Eighth';

  @override
  String get eighthNote => 'Eighth Note';

  @override
  String get triplet => 'Triplet';

  @override
  String get sixteenthNote => 'Sixteenth Note';

  @override
  String get chooseLengthBeforePiano =>
      'Piliin ang tagal bago i-tap ang piano key.';

  @override
  String get automatic => 'Awtomatiko';

  @override
  String get chooseNoteDuration => 'Piliin ang Tagal ng Nota';

  @override
  String get chooseFixedOrKeyHold =>
      'Pumili ng takdang tagal o gamitin ang tagal ng pagpindot sa key.';

  @override
  String get chooseNextNoteLength =>
      'Piliin kung gaano katagal ang susunod na nota.';

  @override
  String get useKeyHoldTime => 'Gamitin ang tagal ng pagpindot sa key';

  @override
  String get swipeToViewPiano => 'Mag-swipe pahalang upang makita ang piano';

  @override
  String get apply => 'Ilapat';

  @override
  String get saveCompositionQuestion => 'I-save ang komposisyon?';

  @override
  String get replaceSavedCompositionDescription =>
      'Papalitan ng kasalukuyang mga pagbabago ang dating naka-save na bersyon.';

  @override
  String get createCompositionFilesDescription =>
      'Gagawin ang iyong komposisyon at mga music file nito.';

  @override
  String get keepEditing => 'Ipagpatuloy ang Pag-edit';

  @override
  String get discardUnsavedChanges =>
      'Itapon ang mga hindi na-save na pagbabago?';

  @override
  String get discardUnsavedChangesDescription =>
      'Mawawala ang iyong mga pagbabago kapag umalis ka nang hindi nagse-save.';

  @override
  String get discard => 'Itapon';

  @override
  String get switchCamera => 'Palitan ang camera';

  @override
  String get generatingCompositionFiles =>
      'Ginagawa ang mga file ng komposisyon...';

  @override
  String get keepScreenOpen => 'Panatilihing bukas ang screen na ito.';

  @override
  String get stopRecording => 'Ihinto ang pag-record';

  @override
  String get startRecording => 'Simulan ang pag-record';

  @override
  String get noCameraAvailable =>
      'Walang camera na available sa device na ito.';

  @override
  String get cameraOpenFailed => 'Hindi mabuksan ang camera.';

  @override
  String recordingNoteLimitWarning(int current, int maximum) {
    return 'Nakapagtala ka na ng $current sa limitasyong $maximum nota.';
  }

  @override
  String recordingNoteLimitReached(int maximum) {
    return 'Naabot na ang limitasyong $maximum nota. Bitawan ang mga nakapindot na key upang matapos.';
  }

  @override
  String get recordingStartFailed => 'Hindi masimulan ang pag-record.';

  @override
  String get recordingLengthWarning =>
      'Malapit mo nang maabot ang pinakamahabang oras ng pag-record.';

  @override
  String get recordingLengthReached =>
      'Naabot na ang pinakamahabang oras ng pag-record.';

  @override
  String get releaseHeldKeysToFinish =>
      'Bitawan ang mga nakapindot na key upang matapos ang pag-record.';

  @override
  String get cameraSaveRestarted =>
      'Hindi natapos ng camera ang pag-save ng video. Muling sinimulan ang camera.';

  @override
  String get videoRecordingFailed =>
      'Hindi nagtagumpay ang pag-record ng video.';

  @override
  String get noNotesRecorded => 'Walang na-record na nota';

  @override
  String get noNotesRecordedDescription =>
      'Tumugtog ng kahit isang buong nota sa nakakonektang MIDI piano bago ihinto.';

  @override
  String get recordAgain => 'Mag-record Muli';

  @override
  String get compositionCreated => 'Matagumpay na nagawa ang komposisyon.';

  @override
  String get compositionNotSaved => 'Hindi na-save ang komposisyon';

  @override
  String get recordingStillAvailable =>
      'Available pa rin ang iyong recording. Suriin ang koneksyon at subukang i-save muli.';

  @override
  String get retrySave => 'Subukang I-save Muli';

  @override
  String get filesNotGenerated => 'Hindi nagawa ang mga file';

  @override
  String get filesNotGeneratedDescription =>
      'Na-save ang komposisyon, ngunit hindi nagawa ang PDF, MIDI, MusicXML, at MP3 nito.';

  @override
  String get finish => 'Tapusin';

  @override
  String get recordingComplete => 'Tapos na ang Pag-record';

  @override
  String get capturedNotes => 'Mga naitalang nota';

  @override
  String get detectedTempo => 'Natukoy na tempo';

  @override
  String get calculatedMeasures => 'Nakalkulang mga measure';

  @override
  String get generate => 'Gawin';

  @override
  String get exploreMusic => 'Tuklasin ang musika';

  @override
  String get exploreMusicDescription =>
      'Tingnan ang mga music sheet na ibinahagi ng ibang SoundSight user.';

  @override
  String get noPublishedCompositions => 'Wala pang nailathalang komposisyon';

  @override
  String get noPublishedCompositionsDescription =>
      'Lalabas dito ang mga music sheet na inilathala ng komunidad ng SoundSight.';

  @override
  String get publishedCompositionsLoadFailed =>
      'Hindi ma-load ang mga nailathalang komposisyon.';

  @override
  String get checkConnectionFirestorePermissions =>
      'Suriin ang iyong koneksyon at mga pahintulot sa Firestore.';

  @override
  String get signInForPublishedCompositions =>
      'Mag-sign in upang makita ang mga nailathalang komposisyon.';

  @override
  String publishedCompositionUnpublished(String title) {
    return 'Inalis sa pagkakalathala ang \"$title\".';
  }

  @override
  String get signInForSavedSheets =>
      'Mag-sign in upang makita ang mga naka-save na sheet.';

  @override
  String get savedSheetsSignedOutDescription =>
      'Lalabas dito ang mga bersyon ng komposisyong na-save mo.';

  @override
  String get savedSheetsLoadFailed =>
      'Hindi ma-load ang mga naka-save na sheet.';

  @override
  String get noSavedSheets => 'Wala pang naka-save na sheet';

  @override
  String get noSavedSheetsDescription =>
      'Mag-save ng nailathalang bersyon upang makita ito rito.';

  @override
  String publishedBy(String author) {
    return 'Ni $author';
  }

  @override
  String versionLabel(int version) {
    return 'Bersyon $version';
  }

  @override
  String compositionMeasureCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count measure',
      one: '1 measure',
    );
    return '$_temp0';
  }

  @override
  String compositionNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get saved => 'Naka-save';

  @override
  String get viewSheet => 'Tingnan ang Sheet';

  @override
  String get likeUpdateFailed => 'Hindi ma-update ang like.';

  @override
  String get savedCompositionUpdateFailed =>
      'Hindi ma-update ang naka-save na komposisyon.';

  @override
  String get removeSavedSheetQuestion => 'Alisin ang naka-save na sheet?';

  @override
  String get saveSheetQuestion => 'I-save ang sheet na ito?';

  @override
  String removeSavedSheetDescription(String title, int version) {
    return 'Alisin ang bersyon $version ng \"$title\" mula sa Mga Naka-save na Sheet?';
  }

  @override
  String saveSheetDescription(String title, int version) {
    return 'I-save ang bersyon $version ng \"$title\" upang makita mo ito sa Mga Naka-save na Sheet sa susunod?';
  }

  @override
  String get recentlyPublished => 'Kamakailang inilathala';

  @override
  String publishedOn(String date) {
    return 'Inilathala noong $date';
  }

  @override
  String get stopPlaybackTooltip => 'Ihinto ang playback';

  @override
  String get playCompositionTooltip => 'Patugtugin ang komposisyon';

  @override
  String get publishedSightReadingUnavailable =>
      'Hindi available ang mga file para sa Sight Reading. Hilingin sa may-ari na ilathala muli ang komposisyon.';

  @override
  String get publishedArFileUnavailable =>
      'Hindi available ang MIDI file para sa AR Practice. Hilingin sa may-ari na ilathala muli ang komposisyon.';

  @override
  String get publishedSheetLoadFailed => 'Hindi ma-load ang music sheet.';

  @override
  String get checkConnectionStoragePermissions =>
      'Suriin ang iyong koneksyon at mga pahintulot sa Firebase Storage.';

  @override
  String commentsVersion(int version) {
    return 'Mga Komento • V$version';
  }

  @override
  String get commentsLoadFailed => 'Hindi ma-load ang mga komento.';

  @override
  String get noCommentsYet => 'Wala pang komento';

  @override
  String get noCommentsDescription => 'Ikaw ang unang magbahagi ng saloobin.';

  @override
  String get deleteCommentTooltip => 'Burahin ang komento';

  @override
  String get writeComment => 'Sumulat ng komento...';

  @override
  String get commentPostFailed => 'Hindi ma-post ang komento.';

  @override
  String get deleteCommentQuestion => 'Burahin ang komento?';

  @override
  String get deleteCommentDescription =>
      'Permanenteng aalisin ang komentong ito.';

  @override
  String get commentDeleteFailed => 'Hindi mabura ang komento.';

  @override
  String get justNow => 'Ngayon lang';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuto ang nakalipas',
      one: '1 minuto ang nakalipas',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oras ang nakalipas',
      one: '1 oras ang nakalipas',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count araw ang nakalipas',
      one: '1 araw ang nakalipas',
    );
    return '$_temp0';
  }

  @override
  String get namePianoSetup => 'Pangalanan ang piano setup na ito';

  @override
  String get pianoSetupName => 'Pangalan ng piano setup';

  @override
  String get pianoSetupNameHint => 'Halimbawa: Piano sa Kuwarto';

  @override
  String get enterPianoSetupName =>
      'Maglagay ng pangalan para sa piano setup na ito.';

  @override
  String get searchingForPiano => 'Hinahanap ang piano';

  @override
  String get pointCameraAtKeyboard => 'Itutok ang camera sa keyboard ng piano';

  @override
  String get moveFartherBack => 'Ilayo pa ang camera';

  @override
  String get makeMorePianoKeysVisible =>
      'Ipakita ang mas maraming piano key sa camera';

  @override
  String get keepKeyboardClear => 'Panatilihing walang harang ang keyboard';

  @override
  String get moveObjectsOutOfView =>
      'Alisin ang iyong mga kamay at ibang bagay sa camera view';

  @override
  String get holdPhoneSteady => 'Panatilihing hindi gumagalaw ang phone';

  @override
  String get keepCameraStill => 'Huwag igalaw ang camera sandali';

  @override
  String get pianoDetected => 'Natukoy ang piano';

  @override
  String get visibleKeyboardReady =>
      'Handa na ang nakikitang bahagi ng keyboard';

  @override
  String get checkVisibleKeys => 'Suriin ang mga nakikitang key';

  @override
  String get dragCornersAroundKeys =>
      'I-drag ang mga puting sulok upang palibutan ang mga piano key';

  @override
  String get selectMiddleC => 'Piliin ang Middle C';

  @override
  String get tapMiddleCInCamera =>
      'I-tap ang Middle C sa piano na nakikita sa camera';

  @override
  String get connectingToPiano => 'Kumokonekta sa iyong piano';

  @override
  String get pianoConnectionNeeded => 'Kailangang ikonekta ang piano';

  @override
  String get searchingAvailableKeyboard =>
      'Naghahanap ng available na keyboard';

  @override
  String reconnectOrUseManualGuide(String status) {
    return '$status. Kumonekta muli o gamitin ang manual guide.';
  }

  @override
  String get middleCFound => 'Nahanap ang Middle C';

  @override
  String get releaseMiddleCToContinue =>
      'Bitawan ang Middle C upang magpatuloy';

  @override
  String get tapSameKeyInCamera => 'I-tap ang parehong key sa camera view';

  @override
  String get findMiddleC => 'Hanapin ang Middle C';

  @override
  String get pressWhiteKeyNearCenter =>
      'Pindutin ang anumang white key malapit sa gitna ng keyboard';

  @override
  String get blackKeyPressed =>
      'Black key iyon. Pindutin ang kalapit na white key.';

  @override
  String get left => 'pakaliwa';

  @override
  String get right => 'pakanan';

  @override
  String moveWhiteKeys(int count, String direction) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count white key',
      one: '1 white key',
    );
    return 'Lumipat ng $_temp0 $direction.';
  }

  @override
  String get pianoKeysReady => 'Handa na ang mga piano key';

  @override
  String get checkKeyLabels => 'Tiyaking nasa tamang key ang bawat label';

  @override
  String get middleCSelected => 'Napili ang Middle C';

  @override
  String get moveBackForMoreKeys =>
      'Ilayo pa ang camera kung gusto mong magsama ng mas maraming key';

  @override
  String get connectingToDigitalPiano => 'Kumokonekta sa iyong digital piano';

  @override
  String get digitalPianoNotConnected => 'Hindi nakakonekta ang digital piano';

  @override
  String get connectPianoOrUseManualGuide =>
      'Ikonekta ito upang mahanap ang Middle C, o gamitin ang manual guide';

  @override
  String get releaseMiddleCThenAlign =>
      'Bitawan ito, pagkatapos ay gamitin ang key na ito upang itapat ang mga naka-save na hugis';

  @override
  String get useMiddleCAsGuide => 'Gamitin ang Middle C bilang gabay';

  @override
  String get alignSavedC4Shape =>
      'Itapat ang naka-save na hugis ng C4 sa key na ito sa iyong piano';

  @override
  String get alignPianoSetup => 'Itapat ang iyong piano setup';

  @override
  String get matchSavedShapes =>
      'Itapat ang mga naka-save na hugis sa piano, pagkatapos ay magpatuloy';

  @override
  String get pianoSetupLoaded => 'Na-load ang piano setup';

  @override
  String get pianoSetupSaved => 'Na-save ang piano setup';

  @override
  String get pianoSetupPreparationFailed =>
      'Hindi maihanda ang piano setup na ito';

  @override
  String get pianoSetupDefaultName => 'Piano setup';

  @override
  String pianoSetupReady(String name) {
    return 'Handa nang gamitin ang \"$name\"';
  }

  @override
  String get savingPianoSetup => 'Sine-save ang iyong piano setup';

  @override
  String get keepOpenWhileSavingSetup =>
      'Panatilihing bukas ang screen na ito hanggang matapos ang pag-save';

  @override
  String get pianoSetupNotSaved => 'Hindi na-save ang piano setup';

  @override
  String get loadingPianoSetup => 'Nilo-load ang iyong piano setup';

  @override
  String get preparingSavedPianoKeys =>
      'Inihahanda ang mga naka-save na piano key';

  @override
  String get noRearCameraAvailable =>
      'Walang rear camera na available sa device na ito.';

  @override
  String get calibrationCameraOpenFailed =>
      'Hindi mabuksan ng SoundSight ang camera. Suriin ang pahintulot sa camera at subukang muli.';

  @override
  String get recalibrate => 'Mag-calibrate Muli';

  @override
  String get useMidiGuide => 'Gamitin ang MIDI guide';

  @override
  String get connecting => 'Kumokonekta';

  @override
  String get useManualGuide => 'Gamitin ang manual guide';

  @override
  String get adjustVisibleKeys => 'Ayusin ang mga nakikitang key';

  @override
  String get savePianoSetup => 'I-save ang piano setup';

  @override
  String get setUpAgain => 'I-set up muli';

  @override
  String get makeChanges => 'Gumawa ng pagbabago';

  @override
  String get useAction => 'Gamitin';

  @override
  String get keysAreVisible => 'Nakikita ang mga key';

  @override
  String get pianoSetupSaveFailed =>
      'Hindi ma-save ang iyong piano setup. Suriin ang internet connection at subukang muli.';

  @override
  String get needHelpFindingMiddleC =>
      'Kailangan ng tulong sa paghahanap ng Middle C?';

  @override
  String get middleCHelpSavedAlignment =>
      'Ikonekta ang iyong digital piano gamit ang USB o MIDI cable nito bago iposisyon ang phone. Gagabayan ka ng SoundSight sa Middle C, pagkatapos ay magagamit mo ang key na iyon upang itapat ang mga naka-save na hugis sa iyong piano.';

  @override
  String get middleCHelpNewCalibration =>
      'Ikonekta ang iyong digital piano gamit ang USB o MIDI cable nito bago iposisyon ang phone. Kapag nakikita na ang mga piano key, gagabayan ka ng SoundSight sa Middle C.';

  @override
  String get manualGuide => 'Manual guide';

  @override
  String get iKnowMiddleC => 'Alam ko ito';

  @override
  String get connectPiano => 'Ikonekta ang piano';

  @override
  String get digitalPianoNotFound => 'Hindi nahanap ang digital piano';

  @override
  String get digitalPianoNotFoundDescription =>
      'Tiyaking nakabukas ang iyong digital piano at nakakonekta sa phone na ito ang cable nito. Maaari mo ring hanapin ang Middle C gamit ang mga black key.';

  @override
  String get findMiddleCManually => 'Hanapin nang manual ang Middle C';

  @override
  String findMiddleCManuallyDescription(String instruction) {
    return 'Malapit sa gitna ng keyboard, humanap ng grupo ng dalawang black key. Ang Middle C, na tinatawag ding C4, ay ang white key na kaagad na nasa kaliwa ng pares na iyon. $instruction';
  }

  @override
  String get manualGuideSavedAlignment =>
      'Gamitin ang Middle C bilang gabay habang ipinoposisyon ang phone hanggang maitapat sa mga piano key ang mga hugis sa screen.';

  @override
  String get manualGuideBeforeCalibration =>
      'Iposisyon ang phone upang makita ang mga piano key, pagkatapos ay i-tap ang Middle C sa camera view kapag hiniling.';

  @override
  String get manualGuideTapKey => 'I-tap ang white key na iyon sa camera view.';

  @override
  String get gotIt => 'Naintindihan ko';

  @override
  String get digitalPianoDisconnected => 'Nadiskonekta ang iyong digital piano';

  @override
  String get searching => 'Naghahanap';

  @override
  String get noDigitalPianoFound => 'Walang nahanap na digital piano';

  @override
  String connectedDevice(String device) {
    return 'Nakakonekta: $device';
  }

  @override
  String get digitalPianoConnected => 'Nakakonekta ang digital piano';

  @override
  String digitalPianoReadyForCalibration(String device) {
    return 'Handa na ang $device. Panatilihin itong nakakonekta, pagkatapos ay iposisyon ang phone sa ibabaw ng keyboard.';
  }

  @override
  String digitalPianoReady(String device) {
    return 'Handa nang gamitin ang $device.';
  }

  @override
  String get connectionFailed => 'Hindi nakakonekta';

  @override
  String get songStillLoading => 'Nilo-load pa ang kanta. Subukang muli.';

  @override
  String get noPlayableKeys => 'walang maaaring tugtuging key';

  @override
  String remainingNotes(String notes, int count) {
    return '$notes, at $count pa';
  }

  @override
  String get morePianoKeysNeeded => 'Kailangan ng mas maraming piano key';

  @override
  String morePianoKeysDescription(
    String requiredRange,
    String calibrationRange,
    String missingNotes,
  ) {
    return 'Gumagamit ang kantang ito ng mga nota mula $requiredRange, ngunit $calibrationRange lamang ang kasalukuyang nakikita ng camera.\n\nMga key na wala sa camera view: $missingNotes\n\nIlayo pa ang phone at i-set up muli ang piano, o pumili ng ibang naka-save na piano setup na nagpapakita ng lahat ng key na ito.';
  }

  @override
  String get reviewPianoSetup => 'Suriin ang piano setup';

  @override
  String get preparePhoneForCalibration => 'Ihanda ang iyong phone';

  @override
  String get preparePhoneForCalibrationDescription =>
      'I-set up ang iyong phone bago mag-calibrate upang tumpak na matukoy ng SoundSight ang piano.';

  @override
  String get mountPhoneSecurely =>
      'Ikabit nang maayos ang phone sa arm, stand, o matibay na holder.';

  @override
  String get useLandscapeOrientation =>
      'I-rotate ang phone sa landscape orientation.';

  @override
  String get keepPianoKeysVisible =>
      'Iposisyon ang camera sa ibabaw ng keyboard at tiyaking nakikita ang lahat ng key na gagamitin mo.';

  @override
  String get useClearLighting =>
      'Gumamit ng pantay na ilaw at iwasan ang matinding anino o silaw.';

  @override
  String get keepPhoneFixed =>
      'Panatilihing nakapirmi ang phone habang nagka-calibrate at nagsasanay.';

  @override
  String get clearKeyboardBeforeDetection =>
      'Alisin ang mga kamay at ibang bagay habang tinutukoy ng SoundSight ang keyboard.';

  @override
  String get calibrationGuideTitle => 'Gabay sa pag-calibrate';

  @override
  String get skip => 'Laktawan';

  @override
  String get next => 'Susunod';

  @override
  String get startCalibration => 'Simulan ang calibration';

  @override
  String get calibrationGuideImageUnavailable =>
      'Hindi maipakita ang larawan para sa gabay na ito.';

  @override
  String get calibrationGuideMountTitle =>
      'Ikabit at iposisyon ang iyong phone';

  @override
  String get calibrationGuideMountDescription =>
      'Ikabit nang maayos ang phone sa arm, stand, o matibay na holder. Ilagay ito sa landscape sa ibabaw ng keyboard at iharap ang rear camera sa mga key. Gumamit ng pantay na ilaw, iwasan ang matinding anino, at huwag igalaw ang phone habang nagka-calibrate.';

  @override
  String get calibrationGuideDetectedGroupTitle =>
      'Suriin ang natukoy na grupo ng mga key';

  @override
  String get calibrationGuideDetectedGroupDescription =>
      'Maglalagay ang SoundSight ng berdeng outline sa grupo ng mga key na natukoy nito. Ang grupong nasa outline—hindi lahat ng key na nakikita ng camera—ang gagamitin ng app.';

  @override
  String get calibrationGuideDetectedGroupEmphasis =>
      'Huwag palawakin ang outline upang masakop ang lahat ng nakikitang key.';

  @override
  String get calibrationGuideAdjustCornersTitle =>
      'Itapat ang mga sulok sa grupong iyon';

  @override
  String get calibrationGuideAdjustCornersDescription =>
      'I-drag ang bawat puting sulok upang sundan ng berdeng outline ang apat na panlabas na sulok ng natukoy na grupo ng mga key. Isama ang buong haba ng mga key na iyon, ngunit huwag isama sa outline ang mga key na wala sa grupong iyon.';

  @override
  String get calibrationGuideAdjustCornersEmphasis =>
      'Ang grupong pinili lamang ng SoundSight ang lagyan ng outline.';

  @override
  String get calibrationGuideMiddleCTitle => 'Piliin ang Middle C (C4)';

  @override
  String get calibrationGuideMiddleCDescription =>
      'Kapag lumitaw ang mga label ng key, i-tap ang C4 sa camera view. Ito ang white key na kaagad na nasa kaliwa ng grupo ng dalawang black key malapit sa gitna ng keyboard. Tiyaking nakatapat nang tama ang ibang label bago mag-save.';

  @override
  String get pianoSetupScreenTitle => 'Setup ng Piano';

  @override
  String get deleteAllPianoSetupsTooltip => 'Burahin lahat ng piano setup';

  @override
  String get preparingSong => 'Inihahanda ang kanta...';

  @override
  String get newPianoSetup => 'Bagong piano setup';

  @override
  String get choosePianoSetup => 'Piliin ang iyong piano setup';

  @override
  String get savedPianoSetup => 'Naka-save na piano setup';

  @override
  String pianoSetupLastSaved(String date, String time) {
    return 'Huling na-save noong $date nang $time';
  }

  @override
  String get deletePianoSetupQuestion => 'Burahin ang piano setup?';

  @override
  String deletePianoSetupDescription(String name) {
    return 'Permanenteng buburahin nito ang \"$name\". Hindi na ito maibabalik.';
  }

  @override
  String pianoSetupDeleted(String name) {
    return 'Nabura ang \"$name\".';
  }

  @override
  String get pianoSetupDeleteFailed => 'Hindi mabura ang piano setup.';

  @override
  String get deleteAllPianoSetupsQuestion => 'Burahin lahat ng piano setup?';

  @override
  String get deleteAllPianoSetupsDescription =>
      'Permanenteng buburahin ang lahat ng naka-save na piano setup. Hindi na ito maibabalik.';

  @override
  String get allPianoSetupsDeleted => 'Nabura ang lahat ng piano setup.';

  @override
  String get somePianoSetupsDeleteFailed =>
      'Hindi mabura ang ilang piano setup.';

  @override
  String get noSavedPianoSetups => 'Wala pang naka-save na piano setup';

  @override
  String get createPianoSetupDescription =>
      'Gumawa ng piano setup upang malaman ng SoundSight kung nasaan ang mga key.';

  @override
  String get loadingYourPianoSetups => 'Nilo-load ang iyong mga piano setup...';

  @override
  String get pianoSetupsLoadFailed =>
      'Hindi ma-load ang iyong mga piano setup.';

  @override
  String get checkConnectionThenTryAgain =>
      'Suriin ang iyong koneksyon, pagkatapos ay subukang muli.';

  @override
  String get songPreparationForArFailed =>
      'Hindi maihanda ang kantang ito para sa AR Practice.';

  @override
  String get selectedPianoSetupLoadFailed =>
      'Hindi ma-load ang napiling piano setup.';

  @override
  String get synthesiaPerformanceMode => 'Performance Mode';

  @override
  String get synthesiaWaitMode => 'Wait Mode';

  @override
  String get synthesiaPerformanceModeDescription =>
      'Tumugtog kasabay ng gumagalaw na timeline habang sinusuri ang iyong pitch at timing.';

  @override
  String get synthesiaWaitModeDescription =>
      'Magsanay sa sarili mong bilis habang naghihintay ang timeline sa bawat nota o chord.';

  @override
  String get synthesiaPerformanceDetailMovingNotes =>
      'Patuloy na gumagalaw ang mga bumabagsak na nota kapag may nalaktawang nota.';

  @override
  String get synthesiaPerformanceDetailEvaluation =>
      'Sinusuri ang iyong mga nota, timing, chord, at tagal ng pagpindot sa mga key.';

  @override
  String get synthesiaPerformanceDetailSkillTiming =>
      'Nakabatay sa kasalukuyan mong player level ang palugit sa timing.';

  @override
  String get synthesiaWaitDetailNoTimeLimit =>
      'Walang limitasyon sa oras habang nagsasanay ka.';

  @override
  String get synthesiaWaitDetailHoldNotes =>
      'Panatilihing nakapindot ang mahahabang nota habang papalapit sa linya ang mga susunod na nota at chord.';

  @override
  String get synthesiaWaitDetailReleaseKeys =>
      'Bitawan ang bawat key kapag ganap nang naubos ang bumabagsak na nota nito.';

  @override
  String get synthesiaWaitDetailDragTimeline =>
      'Mag-drag nang patayo sa bahagi ng mga bumabagsak na nota upang balikan ang ibang bahagi ng score.';

  @override
  String synthesiaSwitchToModeQuestion(String mode) {
    return 'Lumipat sa $mode?';
  }

  @override
  String get synthesiaSwitchMode => 'Lumipat ng Mode';

  @override
  String get synthesiaConnectMidiKeyboard => 'Ikonekta ang iyong MIDI keyboard';

  @override
  String get synthesiaPerformanceRequiresMidi =>
      'Kailangan ng Performance Mode ang iyong MIDI keyboard upang masuri ang mga notang tinutugtog mo at ang timing ng mga ito.';

  @override
  String get synthesiaWaitRequiresMidi =>
      'Kailangan ng Wait Mode ang iyong MIDI keyboard upang marinig ang bawat nota at umusad ang timeline.';

  @override
  String get synthesiaConnectMidi => 'Ikonekta ang MIDI';

  @override
  String get synthesiaMidiDisconnected => 'Nadiskonekta ang MIDI';

  @override
  String get synthesiaSearchingMidiPiano => 'Naghahanap ng MIDI piano...';

  @override
  String get synthesiaNoMidiPianoDetected => 'Walang natukoy na MIDI piano';

  @override
  String synthesiaConnectingToDevice(String device) {
    return 'Kumokonekta sa $device...';
  }

  @override
  String get synthesiaMidiConnectionFailed => 'Hindi nakakonekta ang MIDI.';

  @override
  String get synthesiaCouldNotConnectMidiPiano =>
      'Hindi makakonekta sa MIDI piano';

  @override
  String get synthesiaConnectionRestoredStartAgain =>
      'Naibalik ang koneksyon. Magsimula muli kapag handa ka na.';

  @override
  String get synthesiaConnectionRestoredPlayAgain =>
      'Naibalik ang koneksyon—tugtugin muli ang bahaging ito.';

  @override
  String get synthesiaNoMp3Preview =>
      'Walang MP3 audio preview ang score na ito.';

  @override
  String get synthesiaMp3PlaybackFailed => 'Hindi ma-play ang MP3 preview.';

  @override
  String get synthesiaTryAgainHoldFullLength =>
      'Subukang muli—panatilihing nakapindot ang bawat key sa buong haba ng nota nito.';

  @override
  String get synthesiaTryHighlightedAgain =>
      'Subukang muli ang naka-highlight na nota o chord.';

  @override
  String get synthesiaReleaseMistakenNotes =>
      'Bitawan ang mga maling nota, pagkatapos ay subukang muli ang bahaging ito.';

  @override
  String get synthesiaReleaseChordPressTogether =>
      'Bitawan ang chord, pagkatapos ay sabay-sabay na pindutin ang mga nota nito.';

  @override
  String get synthesiaCorrectNotesKeepHolding =>
      'Tama ang mga nota—panatilihing nakapindot.';

  @override
  String synthesiaNoteHeldTooLong(String note) {
    return 'Masyadong matagal na pinindot ang $note';
  }

  @override
  String synthesiaReleaseAllNoteHeldTooLong(String note) {
    return 'Bitawan ang lahat ng key—masyadong matagal na pinindot ang $note.';
  }

  @override
  String synthesiaReleaseNotes(String notes) {
    return 'Bitawan ang $notes';
  }

  @override
  String synthesiaPlayNotes(String notes) {
    return 'Tugtugin ang $notes';
  }

  @override
  String synthesiaHoldWhilePlaying(String heldNotes, String expectedNotes) {
    return 'Panatilihing nakapindot ang $heldNotes habang tinutugtog ang $expectedNotes';
  }

  @override
  String get synthesiaGetReadyNextNote => 'Maghanda para sa susunod na nota.';

  @override
  String synthesiaNoteReleasedTooSoon(String note) {
    return 'Masyadong maagang binitawan ang $note';
  }

  @override
  String get synthesiaReleasedTooSoonTryAgain =>
      'Masyadong maagang binitawan—bitawan ang lahat ng key at subukang muli.';

  @override
  String get synthesiaReleaseAllBeforeMoving =>
      'Bitawan ang lahat ng key bago lumipat sa ibang bahagi.';

  @override
  String get synthesiaPerfect => 'Perpekto!';

  @override
  String get synthesiaExerciseCompleted => 'Natapos ang Ehersisyo';

  @override
  String get synthesiaCompletedWithoutMistakes =>
      'Natapos mo ang score nang walang pagkakamali.';

  @override
  String synthesiaCompletedWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Natapos mo ang score na may $count pagkakamali. Suriin ang detalyadong feedback sa ibaba.',
      one:
          'Natapos mo ang score na may 1 pagkakamali. Suriin ang detalyadong feedback sa ibaba.',
    );
    return '$_temp0';
  }

  @override
  String get synthesiaCorrectOnTime => 'Tama at nasa oras';

  @override
  String get synthesiaWrongNotes => 'Maling mga nota';

  @override
  String get synthesiaNotPlayed => 'Hindi tinugtog';

  @override
  String get synthesiaPlayedOnTime => 'Tinugtog sa oras';

  @override
  String get synthesiaMusicLength => 'Haba ng musika';

  @override
  String get synthesiaCompleted => 'Natapos';

  @override
  String get synthesiaFirstTry => 'Unang pagsubok';

  @override
  String get synthesiaMistakes => 'Mga pagkakamali';

  @override
  String get synthesiaTime => 'Oras';

  @override
  String get synthesiaNoLimit => 'Walang limitasyon';

  @override
  String get synthesiaScoreLabel => 'ISKOR';

  @override
  String get synthesiaSavingResult =>
      'Sine-save ang resulta ng Synthesia performance...';

  @override
  String get synthesiaResultSaved =>
      'Na-save ang resulta ng Synthesia performance';

  @override
  String get synthesiaResultNotSaved =>
      'Hindi na-save ang resulta ng Synthesia performance.';

  @override
  String get synthesiaRetrySave => 'Subukang i-save muli';

  @override
  String get synthesiaViewFullResult => 'Tingnan ang buong resulta';

  @override
  String get synthesiaWhatToWorkOn => 'Dapat pagtuunan';

  @override
  String get synthesiaHowToImprove => 'Paano pagbutihin';

  @override
  String get synthesiaNoRepeatedProblems =>
      'Wala kang paulit-ulit na naging problema.';

  @override
  String synthesiaTroubleWithNoteTimes(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nahirapan ka sa $note nang $count beses.',
      one: 'Nahirapan ka sa $note nang 1 beses.',
    );
    return '$_temp0';
  }

  @override
  String synthesiaGroupsReleasedEarly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'May mga notang masyadong maagang binitawan sa $count grupo ng nota.',
      one: 'May mga notang masyadong maagang binitawan sa 1 grupo ng nota.',
    );
    return '$_temp0';
  }

  @override
  String synthesiaCorrectGroupsNeedReview(int correctCount, int reviewCount) {
    return 'Tama ang $correctCount grupo ng nota, at kailangang suriin ang $reviewCount.';
  }

  @override
  String get synthesiaWaitModeNotSaved =>
      'Ang Wait Mode ay pagsasanay na walang score at hindi sine-save.';

  @override
  String get synthesiaSuggestionPerfect =>
      'Mahusay! Tama mong natugtog ang bawat bahagi. Ulitin ang piyesa nang may parehong kontrol.';

  @override
  String get synthesiaSuggestionAlmostPerfect =>
      'Halos perpekto na. Tugtugin itong muli sa parehong bilis at pagtuunan ang mga naka-highlight na bahagi.';

  @override
  String synthesiaSuggestionDifficultNote(String note) {
    return 'Nahirapan ka sa $note. Dahan-dahang sanayin ang paghahanap sa key na iyon bago ulitin ang buong piyesa.';
  }

  @override
  String get synthesiaSuggestionReleasedTooSoon =>
      'Masyadong maagang binitawan ang ilang nota. Panatilihing nakapindot ang bawat key hanggang sapat nang naubos ang bumabagsak na nota nito.';

  @override
  String get synthesiaSuggestionMissedNotes =>
      'Umabot sa linya ang ilang nota bago mo natugtog ang mga ito. Tumingin nang isang nota sa unahan at panatilihin ang pantay na beat.';

  @override
  String get synthesiaSuggestionPlayedLate =>
      'Madalas kang tumugtog pagkatapos ng beat. Tumingin nang isang nota sa unahan upang mas maagang maging handa ang iyong mga daliri.';

  @override
  String get synthesiaSuggestionPlayedEarly =>
      'Madalas kang tumugtog bago ang beat. Magbilang nang pantay at hintaying umabot sa linya ang bawat nota.';

  @override
  String get synthesiaSuggestionChordTiming =>
      'Hiwa-hiwalay na napindot ang ilang nota ng chord. Sanaying pindutin nang sabay-sabay ang bawat key sa chord.';

  @override
  String get synthesiaSuggestionWrongNotes =>
      'Dahan-dahang sanayin ang mahirap na bahagi at suriin ang bawat key bago bumalik sa buong bilis.';

  @override
  String get synthesiaSuggestionGeneralPractice =>
      'Dahan-dahang tugtugin ang mahihirap na bahagi nang ilang beses, pagkatapos ay subukan muli ang buong piyesa.';

  @override
  String get synthesiaUntitledScore => 'Score na walang pamagat';

  @override
  String get synthesiaPreparing => 'Inihahanda ang Synthesia...';

  @override
  String get synthesiaScorePreparationFailed => 'Hindi maihanda ang score.';

  @override
  String get synthesiaStartPerformance => 'Simulan ang Performance';

  @override
  String get synthesiaStartWaitMode => 'Simulan ang Wait Mode';

  @override
  String get synthesiaWait => 'Hintay';

  @override
  String get synthesiaPerformance => 'Performance';

  @override
  String get synthesiaControls => 'Mga Control';

  @override
  String get synthesiaLoadingMp3Preview => 'Nilo-load ang MP3 preview';

  @override
  String get synthesiaListeningMp3Preview => 'Pinakikinggan ang MP3 preview';

  @override
  String get synthesiaPracticeInterrupted => 'Naantala ang pagsasanay';

  @override
  String get synthesiaPlayHighlightedNoteOrChord =>
      'Tugtugin ang naka-highlight na nota o chord';

  @override
  String get synthesiaReady => 'Handa';

  @override
  String get synthesiaFollowFallingNotes => 'Sundan ang mga bumabagsak na nota';

  @override
  String get synthesiaMidiOffline => 'Offline ang MIDI';

  @override
  String get synthesiaCloseControls => 'Isara ang mga control';

  @override
  String get synthesiaMidiReconnectPrompt =>
      'Hindi nakakonekta ang MIDI keyboard. I-on o ikonekta itong muli, pagkatapos ay i-tap ang Ikonekta ang MIDI upang subukan muli.';

  @override
  String get synthesiaListen => 'Pakinggan';

  @override
  String get synthesiaConnected => 'Nakakonekta';

  @override
  String get synthesiaStart => 'Simulan';

  @override
  String get synthesiaRestart => 'Simulan Muli';

  @override
  String get synthesiaReleaseAllKeysToContinue =>
      'Bitawan ang lahat ng key upang magpatuloy';

  @override
  String synthesiaPlayedNotes(String feedback, String notes) {
    return '$feedback · Tinugtog: $notes';
  }

  @override
  String get synthesiaNone => 'Wala';

  @override
  String synthesiaNoteGroupPosition(String time, int group) {
    return '$time · Grupo ng nota $group';
  }

  @override
  String get synthesiaNoTimeLimitCompact => 'Walang limitasyon';

  @override
  String synthesiaTargetDuration(String duration) {
    return 'Target $duration';
  }

  @override
  String get synthesiaNoNotesAvailable => 'Walang available na nota';

  @override
  String get synthesiaTooEarly => 'Masyadong maaga';

  @override
  String get synthesiaTooLate => 'Masyadong huli';

  @override
  String get synthesiaWrongNote => 'Maling nota';

  @override
  String get synthesiaCompleteChord => 'Buuin ang chord';

  @override
  String get synthesiaChordNotesNotTogether =>
      'Hindi sabay-sabay ang mga nota ng chord';

  @override
  String get synthesiaCorrectAfterMistake => 'Tama pagkatapos magkamali';

  @override
  String get synthesiaCorrect => 'Tama';

  @override
  String get synthesiaReleasedTooSoon => 'Masyadong maagang binitawan';

  @override
  String get synthesiaDurationComplete => 'Kumpleto ang tagal';

  @override
  String get synthesiaTimingMissed => 'Hindi nasunod ang timing';

  @override
  String get synthesiaWrong => 'Mali';

  @override
  String get synthesiaMissed => 'Nalaktawan';

  @override
  String get sightReadingWait => 'Hintay';

  @override
  String get sightReadingPerformance => 'Performance';

  @override
  String get sightReadingControls => 'Mga kontrol';

  @override
  String get sightReadingPreparingProgress => 'Inihahanda ang progreso';

  @override
  String get sightReadingPerformanceMode => 'Performance Mode';

  @override
  String get sightReadingWaitMode => 'Wait Mode';

  @override
  String get sightReadingPerformanceModeDescription =>
      'Pindutin ang Simula, pagkatapos ay tumugtog ng anumang MIDI key kapag handa ka na.';

  @override
  String get sightReadingWaitModeDescription =>
      'Magsanay sa sarili mong bilis habang pinag-aaralan kung gaano katagal pipindutin ang bawat nota.';

  @override
  String get sightReadingPerformanceDetailNoPause =>
      'Hindi hihinto ang piyesa kapag may notang hindi natugtog.';

  @override
  String get sightReadingPerformanceDetailEvaluation =>
      'Susuriin ang iyong mga nota at timing ayon sa MIDI timeline.';

  @override
  String get sightReadingPerformanceDetailFirstKey =>
      'Sisimulan ng unang key ang timeline at susuriin ito tama man o mali.';

  @override
  String get sightReadingWaitDetailNoTimeLimit =>
      'Walang limitasyon sa oras habang nagsasanay ka.';

  @override
  String get sightReadingWaitDetailHoldLength =>
      'Pindutin ang bawat key ayon sa haba ng nota, pagkatapos ay bitawan kapag inutusan.';

  @override
  String get sightReadingWaitDetailContinuedNotes =>
      'May mga notang nagpapatuloy habang tumutugtog ng kasunod; kapag maagang binitawan, babalik ang cursor upang masubukan mo ulit.';

  @override
  String sightReadingSwitchToModeQuestion(String mode) {
    return 'Lumipat sa $mode?';
  }

  @override
  String get sightReadingSwitchMode => 'Lumipat ng Mode';

  @override
  String get sightReadingConnectMidiKeyboard =>
      'Ikonekta ang iyong MIDI keyboard';

  @override
  String get sightReadingPerformanceRequiresMidi =>
      'Kailangan ng Performance Mode ang iyong MIDI keyboard upang marinig ang mga notang tinutugtog mo. Ikonekta ito, pagkatapos ay tumugtog ng anumang key kapag handa ka na.';

  @override
  String get sightReadingWaitRequiresMidi =>
      'Kailangan ng Wait Mode ang iyong MIDI keyboard upang marinig ang bawat nota at umusad ang cursor.';

  @override
  String get sightReadingConnectMidi => 'Ikonekta ang MIDI';

  @override
  String get sightReadingStartPerformance => 'Simulan ang Performance';

  @override
  String sightReadingPlayedNotes(String feedback, String notes) {
    return '$feedback · Tinugtog: $notes';
  }

  @override
  String sightReadingHintPlay(String notes) {
    return 'Pahiwatig: tugtugin ang $notes';
  }

  @override
  String get sightReadingPreparingScore => 'Inihahanda ang iyong piyesa';

  @override
  String get sightReadingLoadingNotationTimingAudio =>
      'Nilo-load ang notasyon, timing, at audio...';

  @override
  String get sightReadingCouldNotPrepareScore =>
      'Hindi maihanda ang piyesang ito';

  @override
  String get sightReadingUnknownLoadError =>
      'Nagkaroon ng hindi kilalang problema sa pag-load ng piyesa.';

  @override
  String get sightReadingTryAgain => 'Subukan Muli';

  @override
  String get sightReadingPressAnyMidiKey =>
      'Pindutin ang anumang MIDI key upang magsimula';

  @override
  String get sightReadingNone => 'Wala';

  @override
  String get sightReadingWaitingEllipsis => 'Naghihintay...';

  @override
  String sightReadingPlayedWithHint(String playedNotes, String expectedNotes) {
    return 'Tinugtog: $playedNotes · Pahiwatig: tugtugin ang $expectedNotes';
  }

  @override
  String sightReadingPlayed(String notes) {
    return 'Tinugtog: $notes';
  }

  @override
  String get sightReadingCloseControls => 'Isara ang mga kontrol';

  @override
  String get sightReadingMidiReconnectPrompt =>
      'Hindi nakakonekta ang MIDI keyboard. I-on o ikonekta itong muli, pagkatapos ay pindutin ang Ikonekta ang MIDI upang subukan ulit.';

  @override
  String get sightReadingListen => 'Pakinggan';

  @override
  String get sightReadingFollowCursor => 'Sundan ang gumagalaw na cursor';

  @override
  String get sightReadingStartWhenMidiReady =>
      'Magsimula kapag handa na ang iyong MIDI keyboard';

  @override
  String get sightReadingPlaying => 'Tumutugtog';

  @override
  String get sightReadingWaiting => 'Naghihintay';

  @override
  String get sightReadingStart => 'Simula';

  @override
  String get sightReadingHoldUntilCursor =>
      'Pindutin hanggang dumating ang cursor';

  @override
  String get sightReadingComposition => 'Komposisyon';

  @override
  String get sightReadingMusicSheet => 'Music Sheet';

  @override
  String get sightReadingNoTimeLimit => 'Walang limitasyon sa oras';

  @override
  String get sightReadingReadingTimeline => 'Binabasa ang timeline...';

  @override
  String get sightReadingTimelineUnavailable => 'Hindi available ang timeline';

  @override
  String sightReadingTargetDuration(String duration) {
    return 'Target na $duration';
  }

  @override
  String get sightReadingPressAnyKeyToStart =>
      'Pindutin ang anumang key upang magsimula';

  @override
  String get sightReadingConnected => 'Nakakonekta';

  @override
  String get sightReadingSearching => 'Naghahanap';

  @override
  String get sightReadingConnecting => 'Kumokonekta';

  @override
  String sightReadingConnectedDevice(String device) {
    return 'Nakakonekta: $device';
  }

  @override
  String get sightReadingSearchingEllipsis => 'Naghahanap...';

  @override
  String get sightReadingConnectingEllipsis => 'Kumokonekta...';

  @override
  String get sightReadingNoDeviceDetected => 'Walang natukoy na device';

  @override
  String get sightReadingConnectionFailed => 'Hindi nakakonekta';

  @override
  String get sightReadingNotConnected => 'Hindi nakakonekta';

  @override
  String get sightReadingNoMp3Preview =>
      'Walang MP3 audio preview ang piyesang ito.';

  @override
  String get sightReadingPlaybackFailed =>
      'Hindi mapatugtog ang preview ng piyesa.';

  @override
  String get sightReadingMusicXmlMissing => 'Nawawala ang MusicXML file.';

  @override
  String get sightReadingMusicXmlDownloadFailed =>
      'Hindi ma-download ang MusicXML file.';

  @override
  String get sightReadingScoreLoadFailed => 'Hindi ma-load ang piyesa.';

  @override
  String get sightReadingScorePreparationFailed =>
      'Hindi maihanda ang MusicXML para sa Sight Reading.';

  @override
  String get sightReadingMidiFileMissing =>
      'Walang MIDI file ang hamon na ito.';

  @override
  String get sightReadingMidiTimelineUnavailable =>
      'Hindi ma-load ang MIDI timeline.';

  @override
  String get sightReadingUntitledScore => 'Piyesang walang pamagat';

  @override
  String get sightReadingReady => 'Handa';

  @override
  String get sightReadingWaitingForMidi => 'Naghihintay sa MIDI file';

  @override
  String get sightReadingPlayOnTime => 'Tumugtog sa tamang oras';

  @override
  String get sightReadingMissed => 'Hindi natugtog';

  @override
  String get sightReadingWrongNote => 'Maling nota';

  @override
  String get sightReadingCompleteChord => 'Kumpletuhin ang chord';

  @override
  String get sightReadingChordNotesNotTogether =>
      'Hindi sabay-sabay ang mga nota ng chord';

  @override
  String get sightReadingCorrectAfterMistake =>
      'Tama pagkatapos ng pagkakamali';

  @override
  String get sightReadingCorrectNotesKeepHolding =>
      'Tama ang mga nota—patuloy na pindutin';

  @override
  String get sightReadingCorrect => 'Tama';

  @override
  String get sightReadingReleasedTooSoon => 'Masyadong maagang binitawan';

  @override
  String get sightReadingTooEarly => 'Masyadong maaga';

  @override
  String get sightReadingTooLate => 'Masyadong huli';

  @override
  String get sightReadingWrong => 'Mali';

  @override
  String get sightReadingKeepPlaying => 'Magpatuloy sa pagtugtog';

  @override
  String get sightReadingDurationComplete => 'Kumpleto ang haba ng nota';

  @override
  String get sightReadingCompleted => 'Tapos na';

  @override
  String sightReadingKeepHolding(int percentage) {
    return 'Patuloy na pindutin · $percentage%';
  }

  @override
  String sightReadingReleaseBeforePlayingAgain(String note) {
    return 'Bitawan ang $note bago ito tugtugin muli';
  }

  @override
  String sightReadingReleaseHeldTooLong(String notes) {
    return 'Bitawan ang $notes—masyadong matagal na pinindot';
  }

  @override
  String sightReadingNoteHeldTooLong(String note) {
    return 'Masyadong matagal na pinindot ang $note';
  }

  @override
  String sightReadingNoteReleasedTooSoon(String note) {
    return 'Masyadong maagang binitawan ang $note';
  }

  @override
  String sightReadingHoldWhilePlayingNext(String notes) {
    return 'Patuloy na pindutin ang $notes habang tinutugtog ang mga susunod na nota';
  }

  @override
  String sightReadingHoldWhilePlaying(String heldNotes, String expectedNotes) {
    return 'Patuloy na pindutin ang $heldNotes habang tinutugtog ang $expectedNotes';
  }

  @override
  String sightReadingReleaseNotes(String notes) {
    return 'Bitawan ang $notes';
  }

  @override
  String get sightReadingReleasedContinue =>
      'Nabitawan na—magpatuloy sa naka-highlight na nota';

  @override
  String get sightReadingTryAgainHoldUntilCursor =>
      'Subukan muli—pindutin hanggang makarating ang cursor sa susunod na nota';

  @override
  String get sightReadingWaitModeNoXp =>
      'Hindi nagbibigay ng XP ang Wait Mode.';

  @override
  String get sightReadingLessonNoXp =>
      'Hindi nagbibigay ng XP ang araling ito.';

  @override
  String get sightReadingNoXpImperfect =>
      'Walang XP na nakuha. Kumpletuhin ang Performance Mode nang walang pagkakamali.';

  @override
  String get sightReadingProgressSaveFailed =>
      'Hindi na-save ang progreso. Pakisubukan muli.';

  @override
  String get sightReadingAlreadyCompleted =>
      'Nakumpleto na ito. Isang beses lamang ibinibigay ang XP.';

  @override
  String get sightReadingRetryRequired => 'Kailangang Subukan Muli';

  @override
  String get sightReadingRetryRequiredDescription =>
      'Nagpakita ng pahiwatig sa pagsubok na ito. Subukan muli at kumpletuhin ang piyesa nang hindi umaabot sa limang sunod-sunod na pagkakamali.';

  @override
  String get sightReadingPerfect => 'Perpekto!';

  @override
  String get sightReadingPerfectDescription =>
      'Nakumpleto mo ang piyesa nang walang pagkakamali o pahiwatig.';

  @override
  String get sightReadingExerciseCompleted => 'Tapos na ang Ehersisyo';

  @override
  String sightReadingCompletedWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nakumpleto mo ang piyesa na may $count pagkakamali. Suriin ang detalyadong feedback sa ibaba.',
      one:
          'Nakumpleto mo ang piyesa na may 1 pagkakamali. Suriin ang detalyadong feedback sa ibaba.',
    );
    return '$_temp0';
  }

  @override
  String sightReadingWaitCompletedWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nakumpleto mo ang piyesa na may $count pagkakamali, ngunit hindi mo kinailangan ng pahiwatig.',
      one:
          'Nakumpleto mo ang piyesa na may 1 pagkakamali, ngunit hindi mo kinailangan ng pahiwatig.',
    );
    return '$_temp0';
  }

  @override
  String get sightReadingCorrectOnTime => 'Tama sa oras';

  @override
  String get sightReadingWrongNotes => 'Maling mga nota';

  @override
  String get sightReadingNotPlayed => 'Hindi natugtog';

  @override
  String get sightReadingPlayedOnTime => 'Natugtog sa oras';

  @override
  String get sightReadingMusicLength => 'Haba ng musika';

  @override
  String get sightReadingFirstTry => 'Unang pagsubok';

  @override
  String get sightReadingMistakes => 'Mga pagkakamali';

  @override
  String get sightReadingHintUsed => 'Gumamit ng pahiwatig';

  @override
  String get sightReadingYes => 'Oo';

  @override
  String get sightReadingNo => 'Hindi';

  @override
  String get sightReadingTime => 'Oras';

  @override
  String get sightReadingNoLimit => 'Walang limitasyon';

  @override
  String get sightReadingScoreLabel => 'ISKOR';

  @override
  String get sightReadingWhatToWorkOn => 'Dapat pagtuunan';

  @override
  String get sightReadingHowToImprove => 'Paano paghusayin';

  @override
  String get sightReadingNoRepeatedProblems =>
      'Wala kang paulit-ulit na naging problema.';

  @override
  String sightReadingClefDifficulty(
    String clef,
    int errorCount,
    int totalCount,
  ) {
    return 'Naging mahirap ang $clef sa $errorCount sa $totalCount pangkat ng nota.';
  }

  @override
  String sightReadingTroubleWithNoteTimes(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nahirapan ka sa $note nang $count beses.',
      one: 'Nahirapan ka sa $note nang 1 beses.',
    );
    return '$_temp0';
  }

  @override
  String sightReadingWrongAndMissedGroups(int wrongCount, int missedCount) {
    return 'May maling key sa $wrongCount pangkat ng nota, at $missedCount ang hindi natugtog.';
  }

  @override
  String get sightReadingSavingResult =>
      'Sine-save ang resulta ng pagsasanay...';

  @override
  String get sightReadingResultSaved => 'Na-save ang resulta ng pagsasanay';

  @override
  String get sightReadingResultNotSaved => 'Hindi na-save ang resulta';

  @override
  String get sightReadingRetrySave => 'Subukang i-save muli';

  @override
  String get sightReadingViewFullResult => 'Tingnan ang buong resulta';

  @override
  String get sightReadingTrebleClefDescription =>
      'Pagbasa ng matataas na nota (treble clef)';

  @override
  String get sightReadingBassClefDescription =>
      'Pagbasa ng mabababang nota (bass clef)';

  @override
  String get sightReadingUnknownClefDescription => 'Isang bahagi ng piyesa';

  @override
  String sightReadingOtherClefDescription(String clef) {
    return 'Pagbasa ng $clef clef';
  }

  @override
  String get sightReadingSuggestionPerfect =>
      'Magaling! Tama mong natugtog ang bawat bahagi. Subukan ang parehong piyesa nang mas mabilis kapag handa ka na.';

  @override
  String get sightReadingSuggestionAlmostPerfect =>
      'Halos perpekto na. Tugtugin itong muli sa parehong bilis, pagkatapos ay subukang mas mabilis nang kaunti.';

  @override
  String get sightReadingSuggestionBassClef =>
      'Naging mahirap ang mabababang nota sa bass clef. Sanayin muna nang mabagal ang bahagi ng kaliwang kamay.';

  @override
  String get sightReadingSuggestionTrebleClef =>
      'Naging mahirap ang matataas na nota sa treble clef. Sanayin muna nang mabagal ang bahagi ng kanang kamay.';

  @override
  String sightReadingSuggestionOtherClef(String clef) {
    return 'Naging mahirap ang $clef clef. Sanayin muna nang mabagal ang bahaging iyon bago tugtugin muli ang buong piyesa.';
  }

  @override
  String sightReadingSuggestionDifficultNote(String note) {
    return 'Nahirapan kang hanapin ang $note. Sanaying hanapin nang mabagal ang key na iyon, pagkatapos ay tugtugin ito kasama ng mga katabing nota.';
  }

  @override
  String get sightReadingSuggestionReleasedTooSoon =>
      'May mga notang masyadong maagang binitawan. Pindutin ang bawat key hanggang matapos ang buong haba ng nota.';

  @override
  String get sightReadingSuggestionMissedNotes =>
      'May mga notang lumampas bago mo natugtog. Bagalan ang piyesa at bilangin nang malakas ang kumpas habang nagsasanay.';

  @override
  String get sightReadingSuggestionPlayedLate =>
      'Madalas kang tumugtog pagkatapos ng kumpas. Bagalan at tumingin ng isang nota sa unahan upang mas maagang maging handa ang iyong mga daliri.';

  @override
  String get sightReadingSuggestionPlayedEarly =>
      'Madalas kang tumugtog bago ang kumpas. Magbilang nang pantay at hintayin ang kumpas bago pindutin ang key.';

  @override
  String get sightReadingSuggestionChordTiming =>
      'Hindi sabay-sabay na napindot ang ilang nota sa chord. Sanaying pindutin nang sabay ang lahat ng key sa bawat chord, isang kamay muna.';

  @override
  String get sightReadingSuggestionGeneralPractice =>
      'Sanayin nang mabagal ang mahihirap na bahagi nang ilang beses, pagkatapos ay subukang muli ang buong piyesa sa normal na bilis.';

  @override
  String get arPracticePianoPractice => 'Pagsasanay sa piano';

  @override
  String get arPracticeConnectMidiPiano => 'Ikonekta ang MIDI piano';

  @override
  String get arPracticeStopWarning =>
      'Kapag pinili ang Ihinto, babalik ka sa screen ng paghahanda upang makapagpalit ng mode. Hindi mase-save ang hindi natapos na pagsubok na ito.';

  @override
  String get arPracticeChooseNotation => 'Pumili ng notasyon';

  @override
  String get arPracticeChooseNotationDescription =>
      'Piliin kung paano mo gustong lumitaw ang musika habang nagsasanay.';

  @override
  String get arPracticeNotes => 'Mga nota';

  @override
  String get arPracticeNumberNotation => 'Notasyong numero';

  @override
  String get arPracticeDisconnectedDescription =>
      'Huminto ang pagsasanay upang hindi maisama sa resulta ang oras na walang koneksyon at mga notang hindi natugtog.';

  @override
  String get arPracticeEndAttempt => 'Tapusin ang pagsubok';

  @override
  String get arPracticeReconnecting => 'Muling kumokonekta...';

  @override
  String get arPracticeReconnect => 'Ikonekta muli';

  @override
  String get arPracticeReconnectFailed =>
      'Hindi muling makakonekta. Suriin ang cable at piano, pagkatapos ay subukan muli.';

  @override
  String arPracticeSwitchToModeQuestion(String mode) {
    return 'Lumipat sa $mode?';
  }

  @override
  String get arPracticeWaitModeDescription =>
      'Sa Wait Mode, hihinto sa linya ng pagtugtog ang bawat bumabagsak na nota hanggang matugtog mo ang tamang key o chord, pindutin ito ayon sa ipinakitang haba, at bitawan. Walang kailangang habuling oras bago mo pindutin ang mga nota.\n\nIre-reset ng pagpapalit ng mode ang kasalukuyang pagsubok.';

  @override
  String get arPracticePerformanceModeDescription =>
      'Sa Performance Mode, patuloy na gagalaw ang mga bumabagsak na nota kasabay ng kanta. Susuriin ang tono, oras ng pagtugtog, at tagal ng pagpindot mo sa bawat key.\n\nIre-reset ng pagpapalit ng mode ang kasalukuyang pagsubok.';

  @override
  String get arPracticeSwitchMode => 'Lumipat ng mode';

  @override
  String get arPracticeConnectionRestoredTryAgain =>
      'Naibalik ang koneksyon—tugtugin muli ang bahaging ito';

  @override
  String get arPracticeTryAgainFullLength =>
      'Subukan muli—pindutin ang bawat key ayon sa buong haba ng nota';

  @override
  String get arPracticeSavingResult =>
      'Sine-save ang resulta ng AR performance...';

  @override
  String get arPracticeResultSaved => 'Na-save ang resulta ng AR performance';

  @override
  String get arPracticeResultNotSaved =>
      'Hindi na-save ang resulta ng AR performance.';

  @override
  String get arPracticeNumberNotationVideoFailed =>
      'Hindi mabuksan ang video ng notasyong numero.';

  @override
  String get practiceResultsTitle => 'Mga Resulta ng Pagsasanay';

  @override
  String get practiceResultsDeleteAllTooltip =>
      'Burahin ang lahat ng resulta ng pagsasanay';

  @override
  String get practiceResultsSignIn =>
      'Mag-sign in upang makita ang mga resulta ng pagsasanay';

  @override
  String get practiceResultsSignInDescription =>
      'Dito lalabas ang mga natapos na pagsubok sa Performance Mode.';

  @override
  String get practiceResultsLoadFailed => 'Hindi ma-load ang mga resulta';

  @override
  String get practiceResultsCheckConnection =>
      'Suriin ang iyong koneksyon at subukan muli.';

  @override
  String get practiceResultsEmpty => 'Wala pang resulta ng pagsasanay';

  @override
  String get practiceResultsEmptyDescription =>
      'Kumpletuhin ang isang piyesa sa Performance Mode upang malikha ang una mong resulta.';

  @override
  String get practiceResultsSearchHint => 'Maghanap ayon sa pamagat ng piyesa';

  @override
  String get practiceResultsClearSearch => 'I-clear ang paghahanap';

  @override
  String get practiceResultsAll => 'LAHAT';

  @override
  String get practiceResultsFilters => 'Mga Filter';

  @override
  String get practiceResultsNoMatches => 'Walang tumutugmang resulta';

  @override
  String get practiceResultsNoMatchesDescription =>
      'Subukang baguhin ang paghahanap o mga filter.';

  @override
  String get practiceResultsClearFilters => 'I-clear ang mga Filter';

  @override
  String get practiceResultsFilterAndSort => 'I-filter at ayusin';

  @override
  String get practiceResultsClearAll => 'I-clear lahat';

  @override
  String get practiceResultsCloseFilters => 'Isara ang mga filter';

  @override
  String get practiceResultsDate => 'Petsa';

  @override
  String get practiceResultsAccuracy => 'Katumpakan';

  @override
  String get practiceResultsSource => 'Pinagmulan';

  @override
  String get practiceResultsSortBy => 'Ayusin ayon sa';

  @override
  String get practiceResultsReset => 'I-reset';

  @override
  String get practiceResultsApplyFilters => 'Ilapat ang mga Filter';

  @override
  String get practiceResultsAllTime => 'Lahat ng panahon';

  @override
  String get practiceResultsToday => 'Ngayon';

  @override
  String get practiceResultsLast7Days => 'Huling 7 araw';

  @override
  String get practiceResultsLast30Days => 'Huling 30 araw';

  @override
  String get practiceResultsAllScores => 'Lahat ng iskor';

  @override
  String get practiceResultsBelow75 => 'Mas mababa sa 75%';

  @override
  String get practiceResultsAllSources => 'Lahat ng pinagmulan';

  @override
  String get practiceResultsMusicSheet => 'Music Sheet';

  @override
  String get practiceResultsLesson => 'Aralin';

  @override
  String get practiceResultsComposition => 'Komposisyon';

  @override
  String get practiceResultsChallenge => 'Hamon';

  @override
  String get practiceResultsNewestFirst => 'Pinakabago muna';

  @override
  String get practiceResultsOldestFirst => 'Pinakaluma muna';

  @override
  String get practiceResultsHighestAccuracy => 'Pinakamataas na katumpakan';

  @override
  String get practiceResultsLowestAccuracy => 'Pinakamababang katumpakan';

  @override
  String get practiceResultsSightReading => 'SIGHT READING';

  @override
  String get practiceResultsSynthesia => 'SYNTHESIA';

  @override
  String get practiceResultsArPerformance => 'AR PERFORMANCE';

  @override
  String get practiceResultsGeneralSuggestion =>
      'Dahan-dahang sanayin ang mahihirap na bahagi, pagkatapos ay tugtugin muli ang piyesa.';

  @override
  String practiceResultsCardMetadata(String source, String date, String score) {
    return '$source · $date · Iskor $score';
  }

  @override
  String practiceResultsWrongNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maling nota',
      one: '1 maling nota',
    );
    return '$_temp0';
  }

  @override
  String practiceResultsNotPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hindi natugtog',
      one: '1 hindi natugtog',
    );
    return '$_temp0';
  }

  @override
  String get practiceResultsDeleteQuestion =>
      'Burahin ang resulta ng pagsasanay?';

  @override
  String practiceResultsDeleteDescription(String title) {
    return 'Aalisin nito ang resulta para sa \"$title\" at ang detalyadong pagsusuri ng mga nota. Hindi na ito maibabalik.';
  }

  @override
  String get practiceResultsDeleteFailed =>
      'Hindi mabura ang resulta ng pagsasanay.';

  @override
  String get practiceResultsDeleteAllQuestion =>
      'Burahin ang lahat ng resulta ng pagsasanay?';

  @override
  String get practiceResultsDeleteAllDescription =>
      'Permanenteng buburahin ang lahat ng naka-save na resulta ng pagsasanay at detalyadong pagsusuri ng mga nota. Hindi na ito maibabalik.';

  @override
  String get practiceResultsDeleteAll => 'Burahin Lahat';

  @override
  String get practiceResultsDeleteAllSuccess =>
      'Nabura ang lahat ng resulta ng pagsasanay.';

  @override
  String get practiceResultsDeleteAllFailed =>
      'May ilang resulta ng pagsasanay na hindi mabura.';

  @override
  String get practiceResultsJustNow => 'Ngayon lang';

  @override
  String get practiceResultsPracticeHigherNotes =>
      'Sanayin ang matataas na nota';

  @override
  String get practiceResultsPracticeLowerNotes => 'Sanayin ang mabababang nota';

  @override
  String practiceResultsPracticeClef(String clef) {
    return 'Sanayin ang $clef clef';
  }

  @override
  String get practiceResultTitle => 'Resulta ng Pagsasanay';

  @override
  String get practiceResultPerformance => 'Performance';

  @override
  String practiceResultSummaryMetadata(
    String source,
    String mode,
    String date,
  ) {
    return '$source · $mode · $date';
  }

  @override
  String practiceResultPlayedOnTimePercent(int percentage) {
    return '$percentage% ang natugtog sa oras';
  }

  @override
  String get practiceResultCorrect => 'Tama';

  @override
  String get practiceResultWrongNotes => 'Maling mga nota';

  @override
  String get practiceResultNotPlayed => 'Hindi natugtog';

  @override
  String get practiceResultMusicLength => 'Haba ng musika';

  @override
  String get practiceResultYourTime => 'Iyong oras';

  @override
  String get practiceResultWhatToWorkOn => 'Dapat pagtuunan';

  @override
  String get practiceResultHowEachClefWent => 'Resulta sa bawat clef';

  @override
  String practiceResultClefDifficulty(
    String clef,
    int errorCount,
    int totalCount,
  ) {
    return '$clef: nahirapan sa $errorCount sa $totalCount';
  }

  @override
  String get practiceResultDifficultNotes => 'Mga notang naging mahirap';

  @override
  String get practiceResultNoDifficultNotes =>
      'Walang iisang nota ang nagdulot ng paulit-ulit na problema.';

  @override
  String practiceResultNoteDifficulty(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$note: nahirapan nang $count beses',
      one: '$note: nahirapan nang 1 beses',
    );
    return '$_temp0';
  }

  @override
  String get practiceResultOtherKeys => 'Iba pang key na pinindot mo';

  @override
  String get practiceResultNoExtraKeys =>
      'Wala kang napindot na dagdag na maling key.';

  @override
  String practiceResultKeyPressed(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$note pinindot nang $count beses',
      one: '$note pinindot nang 1 beses',
    );
    return '$_temp0';
  }

  @override
  String get practiceResultHowToImprove => 'Paano pagbutihin';

  @override
  String practiceResultNotesToReview(int count) {
    return 'Mga notang susuriin ($count)';
  }

  @override
  String get practiceResultReviewDescription =>
      'Mga bahagi lamang na kailangan pang sanayin';

  @override
  String get practiceResultErrorLogFailed =>
      'Hindi ma-load ang detalyadong tala ng mga pagkakamali.';

  @override
  String get practiceResultNoErrors =>
      'Walang naitalang pagkakamali sa pagsubok na ito.';

  @override
  String get practiceResultNone => 'Wala';

  @override
  String practiceResultNoteGroup(int number) {
    return 'Grupo ng nota $number';
  }

  @override
  String practiceResultNoteGroupMeasure(int number, String measure) {
    return 'Grupo ng nota $number · Sukat $measure';
  }

  @override
  String practiceResultIssueSummary(String issues, String clefs, String time) {
    return '$issues · $clefs · Sa $time';
  }

  @override
  String practiceResultExpectedAndPlayed(String expected, String played) {
    return 'Nasa piyesa: $expected   Tinugtog mo: $played';
  }

  @override
  String get practiceResultEventuallyMatched =>
      'Nahanap mo ang tamang mga nota pagkatapos ng unang pagkakamali.';

  @override
  String get practiceResultUnavailable =>
      'Hindi available ang resultang ito ng pagsasanay.';

  @override
  String get practiceResultTrebleClef => 'Treble clef (matataas na nota)';

  @override
  String get practiceResultBassClef => 'Bass clef (mabababang nota)';

  @override
  String get practiceResultAltoClef => 'Alto clef';

  @override
  String get practiceResultTenorClef => 'Tenor clef';

  @override
  String get practiceResultPercussion => 'Percussion';

  @override
  String get practiceResultScoreSection => 'Bahagi ng piyesa';

  @override
  String get practiceResultNoCorrectNote =>
      'Walang tamang notang natugtog sa bahaging ito.';

  @override
  String get practiceResultTimingOnBeat =>
      'Halos eksaktong tumama sa kumpas ang oras ng pagtugtog mo.';

  @override
  String practiceResultBeforeBeat(String seconds) {
    return 'Tumugtog ka nang humigit-kumulang $seconds segundo bago ang kumpas.';
  }

  @override
  String practiceResultAfterBeat(String seconds) {
    return 'Tumugtog ka nang humigit-kumulang $seconds segundo pagkatapos ng kumpas.';
  }

  @override
  String get practiceResultIssueWrongNote => 'Ibang key ang natugtog';

  @override
  String get practiceResultIssueEarly => 'Masyadong maaga';

  @override
  String get practiceResultIssueLate => 'Masyadong huli';

  @override
  String get practiceResultIssueMissed => 'Walang notang natugtog';

  @override
  String get practiceResultIssueChordTiming =>
      'Hindi sabay-sabay ang mga nota ng chord';

  @override
  String get practiceResultIssueReleasedEarly => 'Masyadong maagang binitawan';

  @override
  String get assessmentUnableToLoad =>
      'Hindi ma-load ang pagsusuri. Subukan muli.';

  @override
  String get assessmentUnableToStart =>
      'Hindi masimulan ang pagsusuri. Subukan muli.';

  @override
  String get assessmentUnableToContinue =>
      'Hindi maipagpatuloy ang pagsusuri. Subukan muli.';

  @override
  String get assessmentAcceptBeginnerQuestion =>
      'Tanggapin ang antas na Beginner?';

  @override
  String get assessmentAcceptBeginnerDescription =>
      'Batay sa iyong mga sagot, nasa antas na Beginner ang hindi bababa sa isang kinakailangang kasanayan. Kapag tinanggap ito, lalaktawan ang Pagbasa ng Notasyon at Pagtugtog sa Piano. Permanente ang resultang ito at hindi na maaaring ulitin ang pagsusuri.';

  @override
  String get assessmentReviewAnswers => 'Suriin ang mga Sagot';

  @override
  String get assessmentAcceptBeginner => 'Tanggapin ang Beginner';

  @override
  String get assessmentStartQuestion => 'Simulan ang pagsusuri?';

  @override
  String get assessmentStartWarning =>
      'Magsisimula agad ang iyong 72-oras na palugit. Isang beses mo lamang maaaring kunin ang pagsusuri. Kung mag-expire ito, mananatili ang iyong naitalang antas, o itatalaga ang Baguhan kung wala ka pang antas.';

  @override
  String get start => 'Simulan';

  @override
  String get assessmentSkillAssessment => 'Pagsusuri ng kasanayan';

  @override
  String get assessmentInProgressTitle =>
      'Kasalukuyang isinasagawa ang pagsusuri';

  @override
  String get assessmentCompletedTitle => 'Tapos na ang pagsusuri';

  @override
  String get assessmentExpiredTitle => 'Nag-expire ang pagsusuri';

  @override
  String get assessmentSkillDescription =>
      'Kumpletuhin ang pagsusuri upang matukoy ang iyong SoundSight Level. Magsisimula lamang ang 72-oras na palugit kapag pinindot mo ang Simulan.';

  @override
  String get assessmentActiveDescription =>
      'Nagsimula na ang iyong pagsusuri. Magpatuloy bago ang deadline upang makuha ang iyong SoundSight Level.';

  @override
  String get assessmentCompleteDescription =>
      'Tapos na ang iyong pagsusuri. Tingnan ang iyong permanenteng SoundSight Level at mga resulta ng bawat bahagi.';

  @override
  String get assessmentExpiredFullDescription =>
      'Hindi natapos ang pagsusuri sa loob ng 72 oras at hindi na ito maaaring ulitin. Mananatili ang iyong naitalang antas, o itatalaga ang Baguhan kung wala ka pang antas.';

  @override
  String get assessmentViewResults => 'Tingnan ang mga Resulta';

  @override
  String get assessmentContinueHome => 'Magpatuloy sa Home';

  @override
  String get assessmentSkipForNow => 'Laktawan Muna';

  @override
  String get assessmentContinueLater => 'Ipagpatuloy Mamaya';

  @override
  String get assessmentTimeRemaining => 'Natitirang oras';

  @override
  String assessmentDurationDays(int days, int hours, int minutes) {
    return '${days}a ${hours}o ${minutes}m';
  }

  @override
  String assessmentDurationHours(int hours, int minutes) {
    return '${hours}o ${minutes}m';
  }

  @override
  String assessmentDurationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get assessmentBeforeYouBegin => 'Bago ka magsimula';

  @override
  String get assessmentReadCarefully =>
      'Basahing mabuti ang sumusunod na impormasyon.';

  @override
  String get assessmentImportantInformation => 'Mahalagang impormasyon';

  @override
  String get assessmentLevelExplanation =>
      'Sinusukat ng iyong SoundSight Level ang pinagsamang kakayahan mo sa pagbasa ng piyesa at pagtugtog ng piano.';

  @override
  String get assessmentTimingExplanation =>
      'Mas humihigpit ang tiyempo ng piano sa bawat antas. Maaaring tumugtog ang Beginner nang hanggang 500 ms na maaga o huli, 350 ms para sa Intermediate, at 250 ms para sa Advanced.';

  @override
  String get assessmentPassingExplanation =>
      'Kailangan ang hindi bababa sa 4 sa 6 na tamang sagot sa bawat antas ng notasyon. Kailangan naman ang hindi bababa sa 70% tamang grupo ng nota o chord sa piano. Kailangan ding maipasa ang lahat ng mas mababang antas bago ang mas mataas na antas.';

  @override
  String get assessmentChordExplanation =>
      'Upang mabilang na tama ang chord, kailangang pindutin ang lahat ng kinakailangang key sa loob ng 200 ms mula sa isa\'t isa at sa tamang tiyempo ng antas.';

  @override
  String get assessmentOneAttempt =>
      'Isang beses mo lamang maaaring kunin ang pagsusuri. Hindi na maaaring simulan muli ang nag-expire na pagtatangka.';

  @override
  String get assessmentDeadlineExplanation =>
      'Kailangang matapos ang pagsusuri sa loob ng 72 oras mula nang simulan ito.';

  @override
  String get assessmentExpirationExplanation =>
      'Kung mag-expire ang pagsusuri bago matapos, mananatili ang iyong naitalang antas. Itatalaga ang Baguhan kung wala ka pang antas.';

  @override
  String get assessmentLeaveExplanation =>
      'Maaari kang umalis sa pagitan ng mga bahagi at magpatuloy mamaya habang aktibo pa ang pagsusuri.';

  @override
  String get assessmentPreparationExplanation =>
      'Ihanda ang iyong MIDI keyboard, koneksyon sa internet, at isang tahimik na lugar bago magpatuloy.';

  @override
  String get assessmentNoTimeRemaining => 'Wala nang natitirang oras';

  @override
  String get assessmentContinue => 'Ipagpatuloy ang Pagsusuri';

  @override
  String get returnAction => 'Bumalik';

  @override
  String get assessmentBackgroundQuestions => 'Mga Tanong Tungkol sa Karanasan';

  @override
  String get assessmentExperienceHeading => 'Ikuwento ang iyong karanasan';

  @override
  String get assessmentExperienceDescription =>
      'Nakakatulong ang mga sagot na ito upang iangkop ang iyong karanasan. Kung nagsisimula ka pa lamang sa piano o hindi ka pa natutong magbasa ng piyesa, maaari mong tanggapin ang antas na Beginner at laktawan ang mga natitirang bahagi.';

  @override
  String get assessmentDeadlineContinues =>
      'Patuloy ang iyong deadline habang sumasagot.';

  @override
  String get assessmentAnswerEveryQuestion =>
      'Sagutin ang lahat ng tanong bago magpatuloy.';

  @override
  String get assessmentSaveAnswersFailed =>
      'Hindi ma-save ang iyong mga sagot. Subukan muli.';

  @override
  String get assessmentSelectOneAnswer => 'Pumili ng isang sagot.';

  @override
  String get assessmentQuestionPianoExperience =>
      'Gaano ka na katagal tumutugtog ng piano o keyboard?';

  @override
  String get assessmentQuestionSheetMusicExperience =>
      'Gaano ka kapamilyar sa pagbasa ng piyesa?';

  @override
  String get assessmentQuestionLearningMethod =>
      'Paano ka pangunahing natutong tumugtog ng piano?';

  @override
  String get assessmentQuestionPrimaryGoal =>
      'Ano ang pangunahing layunin mo sa SoundSight?';

  @override
  String get assessmentOptionNewToPiano => 'Nagsisimula pa lamang ako';

  @override
  String get assessmentOptionUnderOneYear => 'Mas mababa sa isang taon';

  @override
  String get assessmentOptionOneToThreeYears => 'Isa hanggang tatlong taon';

  @override
  String get assessmentOptionMoreThanThreeYears => 'Mahigit tatlong taon';

  @override
  String get assessmentOptionNotFamiliar =>
      'Hindi pa ako natutong magbasa ng piyesa';

  @override
  String get assessmentOptionBasicFamiliarity =>
      'Nakikilala ko ang ilang nota at simbolo';

  @override
  String get assessmentOptionModerateFamiliarity =>
      'Nakakabasa ako ng simpleng piyesa';

  @override
  String get assessmentOptionComfortable =>
      'Komportable akong magbasa ng piyesa';

  @override
  String get assessmentOptionNoFormalLearning =>
      'Hindi pa ako nagsisimulang matuto';

  @override
  String get assessmentOptionTeacher => 'Sa tulong ng guro sa piano';

  @override
  String get assessmentOptionSelfTaught => 'Sariling pag-aaral';

  @override
  String get assessmentOptionMixedLearning =>
      'Pinagsamang leksiyon at sariling pag-aaral';

  @override
  String get assessmentOptionLearnNotation =>
      'Matutong magbasa ng notasyong pangmusika';

  @override
  String get assessmentOptionImproveSightReading =>
      'Pagbutihin ang aking sight-reading';

  @override
  String get assessmentOptionImproveCoordination =>
      'Pagbutihin ang koordinasyon ko sa piano';

  @override
  String get assessmentOptionTrackProgress =>
      'Unawain at subaybayan ang kasalukuyan kong kakayahan';

  @override
  String get assessmentNotationReading => 'Pagbasa ng Notasyon';

  @override
  String get assessmentNotationSemantics =>
      'Notasyong pangmusika para sa kasalukuyang tanong sa pagsusuri';

  @override
  String get assessmentAnswerEveryNotationQuestion =>
      'Sagutin ang lahat ng tanong bago isumite.';

  @override
  String get assessmentPleaseAnswerEveryNotationQuestion =>
      'Sagutin ang lahat ng tanong sa notasyon.';

  @override
  String get assessmentSaveNotationFailed =>
      'Hindi ma-save ang iyong mga sagot sa notasyon. Subukan muli.';

  @override
  String get previous => 'Nakaraan';

  @override
  String get submit => 'Isumite';

  @override
  String assessmentQuestionProgress(int current, int total) {
    return 'Tanong $current sa $total';
  }

  @override
  String assessmentAnsweredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ang nasagutan',
      one: '1 ang nasagutan',
    );
    return '$_temp0';
  }

  @override
  String get assessmentNotationPromptNote => 'Anong nota ang ipinapakita?';

  @override
  String get assessmentNotationPromptBeatValue =>
      'Sa 4/4 na kumpas, ilang beat ang katumbas ng notang ito?';

  @override
  String get assessmentNotationPromptTimeSignature =>
      'Ano ang ibig sabihin ng time signature na ito?';

  @override
  String get assessmentNotationPromptLedgerNote =>
      'Anong nota sa ledger line ang ipinapakita?';

  @override
  String get assessmentNotationPromptAccidental =>
      'Anong notang may accidental ang ipinapakita?';

  @override
  String get assessmentNotationPromptMajorKey =>
      'Anong major key signature ang ipinapakita?';

  @override
  String get assessmentNotationPromptIntervalSize =>
      'Ano ang laki ng nakasulat na interval?';

  @override
  String get assessmentNotationPromptUpperLedgerNote =>
      'Anong nota sa itaas na ledger line ang ipinapakita?';

  @override
  String get assessmentNotationPromptCompoundMeter =>
      'Paano karaniwang binibilang ang compound meter na ito?';

  @override
  String get assessmentNotationPromptWrittenInterval =>
      'Ano ang nakasulat na interval?';

  @override
  String get assessmentNotationPromptRootChord =>
      'Anong chord sa root position ang ipinapakita?';

  @override
  String get assessmentNotationPromptPassageBeats =>
      'Ilang quarter-note beat ang nasa bahaging ito?';

  @override
  String get assessmentOptionHalfBeat => '1/2 beat';

  @override
  String get assessmentOptionOneBeat => '1 beat';

  @override
  String get assessmentOptionTwoBeats => '2 beat';

  @override
  String get assessmentOptionThreeBeats => '3 beat';

  @override
  String get assessmentOptionFourBeats => '4 beat';

  @override
  String get assessmentOptionFiveBeats => '5 beat';

  @override
  String get assessmentOptionTwoQuarterBeats =>
      'Dalawang quarter-note beat bawat sukat';

  @override
  String get assessmentOptionThreeQuarterBeats =>
      'Tatlong quarter-note beat bawat sukat';

  @override
  String get assessmentOptionFourQuarterBeats =>
      'Apat na quarter-note beat bawat sukat';

  @override
  String get assessmentOptionFourEighthBeats =>
      'Apat na eighth-note beat bawat sukat';

  @override
  String get assessmentOptionTwoDottedQuarterBeats =>
      'Dalawang dotted-quarter beat';

  @override
  String get assessmentOptionSixQuarterBeats => 'Anim na quarter-note beat';

  @override
  String get assessmentOptionSecond => 'Second';

  @override
  String get assessmentOptionThird => 'Third';

  @override
  String get assessmentOptionFourth => 'Fourth';

  @override
  String get assessmentOptionFifth => 'Fifth';

  @override
  String get assessmentOptionMajorThird => 'Major third';

  @override
  String get assessmentOptionPerfectFourth => 'Perfect fourth';

  @override
  String get assessmentOptionPerfectFifth => 'Perfect fifth';

  @override
  String get assessmentOptionMajorSixth => 'Major sixth';

  @override
  String get assessmentPianoExecution => 'Pagtugtog sa Piano';

  @override
  String get assessmentMidiNotConnected => 'Hindi nakakonekta';

  @override
  String get assessmentMidiSearching => 'Naghahanap...';

  @override
  String get assessmentMidiNotDetected => 'Walang natukoy na MIDI device';

  @override
  String get assessmentMidiConnecting => 'Kumokonekta...';

  @override
  String get assessmentMidiConnected => 'Nakakonekta';

  @override
  String assessmentMidiConnectedDevice(String deviceName) {
    return 'Nakakonekta: $deviceName';
  }

  @override
  String get assessmentMidiConnectionFailed => 'Hindi nakakonekta';

  @override
  String get assessmentMidiConnectError =>
      'Hindi makakonekta sa MIDI keyboard.';

  @override
  String get assessmentMidiDisconnected => 'Nadiskonekta ang MIDI keyboard';

  @override
  String get assessmentMidiInterrupted =>
      'Natanggal ang koneksyon sa MIDI. Ikonekta itong muli at simulang muli ang gawaing ito.';

  @override
  String get assessmentSavePianoFailed =>
      'Hindi ma-save ang mga resulta sa piano. Subukan muli.';

  @override
  String assessmentTaskProgress(int current, int total) {
    return 'Gawain $current sa $total';
  }

  @override
  String get refresh => 'I-refresh';

  @override
  String get assessmentKeysToPlay => 'Mga key na tutugtugin';

  @override
  String get assessmentWhenToPlay => 'Kailan tutugtugin';

  @override
  String get assessmentMiddleCExplanation =>
      'Ang C4 ang Middle C. Ipinapakita ng numero ang octave sa piano.';

  @override
  String assessmentTempoCountIn(int tempo, int count) {
    return '$tempo BPM • $count-beat na count-in';
  }

  @override
  String get assessmentCountIn => 'Count-in';

  @override
  String assessmentWaitForGo(String keys) {
    return 'Maghintay. Tugtugin ang $keys kapag lumabas ang GO.';
  }

  @override
  String get assessmentTaskRecorded => 'Naitala ang gawain';

  @override
  String get assessmentStartTaskGuidance =>
      'Pindutin ang Simulan ang Gawain kapag handa ka na. Hintayin ang buong count-in, pagkatapos ay tugtugin ang unang ipinakitang key o chord kasabay ng GO. Isang beses lamang maaaring gawin ang bawat gawaing may puntos sa sesyong ito.';

  @override
  String get assessmentTaskComplete => 'Tapos na ang gawain';

  @override
  String assessmentBeatNumber(int number) {
    return 'Beat $number';
  }

  @override
  String assessmentPlayNow(String keys) {
    return 'Tugtugin ngayon: $keys';
  }

  @override
  String get assessmentWaitingMidi => 'Naghihintay ng MIDI input';

  @override
  String assessmentHeldKeys(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count key ang kasalukuyang nakapindot',
      one: '1 key ang kasalukuyang nakapindot',
    );
    return '$_temp0';
  }

  @override
  String get assessmentGetReady => 'Humanda';

  @override
  String get assessmentPerforming => 'Tumutugtog';

  @override
  String get assessmentSubmitPianoResults => 'Isumite ang mga Resulta sa Piano';

  @override
  String get assessmentNextTask => 'Susunod na Gawain';

  @override
  String get assessmentConnectMidi => 'Ikonekta ang MIDI';

  @override
  String get assessmentStartTask => 'Simulan ang Gawain';

  @override
  String get assessmentTaskMiddleCTitle => 'Middle C';

  @override
  String get assessmentTaskMiddleCInstruction =>
      'Tugtugin ang C4, na siyang Middle C.';

  @override
  String get assessmentTaskMiddleCTiming =>
      'Tugtugin nang isang beses ang C4 kapag lumabas ang GO.';

  @override
  String get assessmentTaskFiveFingerTitle => 'Five-finger pattern';

  @override
  String get assessmentTaskFiveFingerInstruction =>
      'Tugtugin nang pataas ang C4, D4, E4, F4, at G4.';

  @override
  String assessmentTaskNoteEveryClickTiming(String firstNote) {
    return 'Tugtugin ang $firstNote kasabay ng GO, pagkatapos ay isang nota sa bawat susunod na click.';
  }

  @override
  String get assessmentTaskCMajorChordTitle => 'C major chord';

  @override
  String get assessmentTaskCMajorChordInstruction =>
      'Tugtugin nang sabay ang C4, E4, at G4.';

  @override
  String get assessmentTaskChordGoTiming =>
      'Tugtugin nang isang beses ang buong chord kapag lumabas ang GO.';

  @override
  String get assessmentTaskCMajorScaleTitle => 'C major scale';

  @override
  String get assessmentTaskCMajorScaleInstruction =>
      'Tugtugin nang pataas ang C major scale mula C4 hanggang C5.';

  @override
  String get assessmentTaskCMajorArpeggioTitle => 'C major arpeggio';

  @override
  String get assessmentTaskCMajorArpeggioInstruction =>
      'Tugtugin ang C4, E4, G4, C5, G4, E4, at C4.';

  @override
  String get assessmentTaskChordProgressionTitle => 'Chord progression';

  @override
  String get assessmentTaskChordProgressionInstruction =>
      'Tugtugin ang C3-E3-G3, F3-A3-C4, G3-B3-D4, at pagkatapos ay C3-E3-G3.';

  @override
  String get assessmentTaskChordEverySecondClickTiming =>
      'Tugtugin ang unang chord kasabay ng GO, pagkatapos ay isang chord sa bawat ikalawang click.';

  @override
  String get assessmentTaskTwoOctaveTitle => 'Two-octave scale';

  @override
  String get assessmentTaskTwoOctaveInstruction =>
      'Tugtugin nang pataas ang C major scale mula C3 hanggang C5.';

  @override
  String get assessmentTaskChordInversionsTitle => 'Mga chord inversion';

  @override
  String get assessmentTaskChordInversionsInstruction =>
      'Tugtugin ang C3-E3-G3, E3-G3-C4, G3-C4-E4, at pagkatapos ay C4-E4-G4.';

  @override
  String get assessmentTaskParallelScaleTitle => 'Parallel scale';

  @override
  String get assessmentTaskParallelScaleInstruction =>
      'Tugtugin ang C3-C4 hanggang C4-C5 gamit ang dalawang kamay sa magkapantay na galaw.';

  @override
  String get assessmentTaskParallelTiming =>
      'Tugtugin ang dalawang C key kasabay ng GO, pagkatapos ay ang susunod na pares sa bawat click.';

  @override
  String get assessmentReview => 'Pagsusuri ng mga Resulta';

  @override
  String get assessmentApplyLevelFailed =>
      'Hindi mailapat ang naka-save mong antas ng kasanayan. Subukan muli.';

  @override
  String get assessmentBeginnerShortcutSummary =>
      'Ipinapakita ng iyong mga sagot tungkol sa karanasan na bago pa sa iyo ang hindi bababa sa isang kinakailangang kasanayan. Nilaktawan ang mga bahaging may puntos at itinalaga ang Beginner.';

  @override
  String get assessmentNotationSection => 'Pagbasa ng notasyon';

  @override
  String get assessmentPianoSection => 'Pagtugtog sa piano';

  @override
  String assessmentCorrectScore(int correct, int total) {
    return '$correct sa $total ang tama';
  }

  @override
  String assessmentCorrectGroupsScore(int correct, int total) {
    return '$correct sa $total grupo ang tama';
  }

  @override
  String get assessmentFinalLevelExplanation =>
      'Ginagamit ng iyong huling antas ang mas mababa sa antas ng notasyon at piano. Hindi maitatago ng lakas sa isang kinakailangang kasanayan ang kahinaan sa isa pa.';

  @override
  String get assessmentYourLevel => 'Iyong SoundSight Level';

  @override
  String get assessmentNoSavedAnswer => 'Walang naka-save na sagot';

  @override
  String get assessmentBackgroundAnswers => 'Mga sagot tungkol sa karanasan';

  @override
  String get assessmentCorrect => 'Tama';

  @override
  String assessmentCorrectAnswer(String answer) {
    return 'Tamang sagot: $answer';
  }

  @override
  String get assessmentNotationAnswers => 'Mga sagot sa notasyon';

  @override
  String get assessmentNoSavedResult => 'Walang naka-save na resulta';

  @override
  String assessmentPianoResultDetails(int wrong, int missed, int timing) {
    return '$wrong mali, $missed hindi natugtog, $timing pagkakamali sa tiyempo';
  }

  @override
  String get assessmentPianoTaskResults => 'Mga resulta ng gawain sa piano';

  @override
  String get assessmentResultUnavailable =>
      'Tapos na ang pagsusuri, ngunit hindi maipakita ang mga detalye ng naka-save na resulta.';

  @override
  String get lessonSignInRequired => 'Mag-sign in upang buksan ang mga aralin.';

  @override
  String get lessonProgressLoadFailed =>
      'Hindi ma-load ang progreso sa mga aralin. Subukan muli.';

  @override
  String get lessonProgressSaveFailed =>
      'Hindi ma-save ang progreso sa mga aralin. Subukan muli.';

  @override
  String lessonCompactProgress(int completed, int total) {
    return '$completed/$total ang kumpleto';
  }

  @override
  String get lessonAllStagesComplete => 'Kumpleto na ang lahat ng yugto';

  @override
  String lessonStageProgress(int current, int total) {
    return 'Yugto $current sa $total';
  }

  @override
  String lessonStagesCompleted(int completed, int total) {
    return '$completed sa $total yugto ang nakumpleto';
  }

  @override
  String lessonSavingStageProgress(int stage) {
    return 'Sine-save ang progreso sa Yugto $stage...';
  }

  @override
  String lessonStageProgressNotSaved(int stage) {
    return 'Naipasa ang Yugto $stage, ngunit hindi na-save ang progreso.';
  }

  @override
  String get lessonVideoAndQuiz => 'Video at pagsusulit';

  @override
  String get lessonPianoPerformance => 'Pagtugtog sa piano';

  @override
  String get lessonCompleted => 'Kumpleto';

  @override
  String get lessonCurrent => 'Kasalukuyan';

  @override
  String get lessonLocked => 'Naka-lock';

  @override
  String get lessonReplay => 'Ulitin';

  @override
  String lessonStageAndStatus(int stage, String status) {
    return 'YUGTO $stage  /  $status';
  }

  @override
  String lessonStageLabel(int stage) {
    return 'Yugto $stage';
  }

  @override
  String lessonFinishStageToUnlock(int stage) {
    return 'Tapusin ang Yugto $stage upang ma-unlock ang yugtong ito.';
  }

  @override
  String get lessonRankMilestone => 'Mahalagang yugto ng ranggo';

  @override
  String lessonStageReplayComplete(int stage) {
    return 'Natapos ang pag-ulit sa Yugto $stage.';
  }

  @override
  String get lessonAllStagesCompleteMessage =>
      'Kumpleto na ang lahat ng yugto!';

  @override
  String lessonStageUnlocked(int stage) {
    return 'Na-unlock ang Yugto $stage!';
  }

  @override
  String get lessonAdvancedRankWillNotLower =>
      'Advanced na ang iyong ranggo. Hindi ito bababa kapag natapos mo ang yugtong ito.';

  @override
  String get lessonIntermediateRankKept =>
      'Intermediate na ang iyong ranggo. Mananatili ito kapag natapos mo ang yugtong ito.';

  @override
  String get lessonIntermediateAwardedFirstCompletion =>
      'Iginagawad ang promosyon sa Intermediate sa unang pagkumpleto ng yugtong ito.';

  @override
  String get lessonPerfectRunPromotesIntermediate =>
      'Kapag perpekto ang iyong Performance at na-save ang progreso, aangat ka sa Intermediate.';

  @override
  String get lessonAdvancedRankKept =>
      'Advanced na ang iyong ranggo. Mananatili ito kapag natapos mo ang yugtong ito.';

  @override
  String get lessonAdvancedAwardedFirstCompletion =>
      'Iginagawad ang promosyon sa Advanced sa unang pagkumpleto ng yugtong ito.';

  @override
  String get lessonPerfectRunPromotesAdvanced =>
      'Kapag perpekto ang iyong Performance sa huling yugtong ito at na-save ang progreso, aangat ka sa Advanced.';

  @override
  String lessonStageSemantics(
    int stage,
    String title,
    String activity,
    String status,
  ) {
    return 'Yugto $stage, $title, $activity, $status';
  }

  @override
  String lessonNumberTitle(int number, String title) {
    return 'Aralin $number: $title';
  }

  @override
  String get lessonStage1ShortTitle => 'Ang Canvas';

  @override
  String get lessonStage2ShortTitle => 'Ang Grand Staff';

  @override
  String get lessonStage3ShortTitle => 'Middle C';

  @override
  String get lessonStage4ShortTitle => 'Hanapin at Tugtugin ang Middle C';

  @override
  String get lessonStage5ShortTitle => 'Mga Nota sa Musika';

  @override
  String get lessonStage6ShortTitle => 'Tugtugin ang Twinkle Twinkle';

  @override
  String get lessonStage7ShortTitle => 'Mga Numero ng Daliri';

  @override
  String get lessonStage8ShortTitle => 'Mga Accidental';

  @override
  String get lessonStage9ShortTitle => 'Tugtugin ang Für Elise';

  @override
  String get lessonStage10ShortTitle => 'Mga Time Signature';

  @override
  String get lessonStage11ShortTitle => 'Pakiramdam sa Tiyempo';

  @override
  String get lessonStage11Title => 'Pagsubok sa Pagtugtog ng Time Signature';

  @override
  String get lessonStage12ShortTitle => 'Mga Chord';

  @override
  String get lessonStage13ShortTitle => 'Mga Major at Minor Scale';

  @override
  String get lessonStage14ShortTitle => 'Tugtugin ang C Minor Scale';

  @override
  String get lessonStage15ShortTitle => 'Nashville Number System';

  @override
  String get lessonStage16ShortTitle => 'Tugtugin ang Isang Kanta';

  @override
  String get lessonWatchThenQuiz =>
      'Panoorin ang video lesson, pagkatapos ay sagutan ang pagsusulit upang balikan ang aralin.';

  @override
  String get lessonOpenScoreAndPlay =>
      'Buksan ang piyesa, ikonekta ang iyong piano, at tugtugin ang mga ipinakitang nota.';

  @override
  String lessonWatchTopicVideo(String topic) {
    return 'Panoorin ang video lesson tungkol sa $topic.';
  }

  @override
  String get lessonPlayWithMovingCursor =>
      'Ikonekta ang iyong piano at tugtugin ang piyesa kasabay ng gumagalaw na cursor.';

  @override
  String get lessonWatchViewPdfAndQuiz =>
      'Panoorin ang aralin, tingnan ang gabay sa mga chord, at sagutan ang pagsusulit.';

  @override
  String get lessonConnectAndPlayScore =>
      'Ikonekta ang iyong piano at tugtugin ang mga notang ipinakita sa piyesa.';

  @override
  String get lessonSightReadingChallenge => 'Hamon sa Sight Reading';

  @override
  String get lessonSightReadingChallengeDescription =>
      'Ikonekta ang iyong piano at tugtugin ang piyesa';

  @override
  String get lessonVideoLesson => 'Video lesson';

  @override
  String get lessonQuestions => 'Mga tanong sa aralin';

  @override
  String get lessonSheetMusic => 'Piyesa';

  @override
  String get lessonCompressedMusicXmlScore => 'Naka-compress na MusicXML score';

  @override
  String get lessonSightReadingScore => 'Piyesa para sa sight reading';

  @override
  String get lessonFile => 'File ng aralin';

  @override
  String get lessonChordCheatSheet => 'Gabay sa mga chord';

  @override
  String get lessonQuiz => 'Pagsusulit sa aralin';

  @override
  String lessonStageQuizTitle(int stage) {
    return 'Pagsusulit sa Yugto $stage';
  }

  @override
  String get lessonOpenFromVideoPlayer =>
      'Buksan ang araling ito mula sa video player.';

  @override
  String get lessonQuizLoadFailed =>
      'Hindi ma-load ang pagsusulit sa araling ito.';

  @override
  String get lessonPdfLoadFailed => 'Hindi ma-load ang PDF ng araling ito.';

  @override
  String get lessonSightReadingFilesRequired =>
      'Kailangan ng sight reading ang magkatugmang MIDI at MusicXML file.';

  @override
  String get lessonFileEmpty => 'Walang laman ang file ng araling ito.';

  @override
  String lessonQuestionProgress(int current, int total) {
    return 'Tanong $current sa $total';
  }

  @override
  String get lessonQuizComplete => 'Tapos na ang pagsusulit';

  @override
  String lessonQuizScore(int correct, int total) {
    return 'Iyong iskor: $correct/$total';
  }

  @override
  String get lessonQuizPerfect =>
      'Perpekto ang iskor! Maa-unlock ang susunod na yugto kapag na-save ang progreso.';

  @override
  String get lessonQuizRetryGuidance =>
      'Suriin ang iyong mga sagot sa ibaba. Subukan muli gamit ang bagong pagkakasunod-sunod ng mga tanong upang makakuha ng perpektong iskor.';

  @override
  String get lessonBackToStages => 'Bumalik sa mga yugto';

  @override
  String lessonYourAnswer(String answer) {
    return 'Iyong sagot: $answer';
  }

  @override
  String get lessonNoAnswer => 'Walang sagot';

  @override
  String lessonCorrectAnswer(String answer) {
    return 'Tamang sagot: $answer';
  }

  @override
  String get lessonVideoLoadFailed => 'Hindi ma-load ang video lesson.';

  @override
  String get lessonPauseVideo => 'I-pause ang video';

  @override
  String get lessonPlayVideo => 'I-play ang video';

  @override
  String get lessonBackToPractice => 'Bumalik sa Pagsasanay';

  @override
  String get lessonStartQuiz => 'Simulan ang Pagsusulit';

  @override
  String get lessonViewPdf => 'Tingnan ang PDF';
}
