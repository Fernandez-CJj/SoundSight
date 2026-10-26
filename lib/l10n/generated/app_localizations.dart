import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('fil'),
  ];

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @searchMusic.
  ///
  /// In en, this message translates to:
  /// **'Search music'**
  String get searchMusic;

  /// No description provided for @musicLibrary.
  ///
  /// In en, this message translates to:
  /// **'Music Library'**
  String get musicLibrary;

  /// No description provided for @musicLibraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse pieces uploaded by SoundSight.'**
  String get musicLibraryDescription;

  /// No description provided for @searchMusicHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title'**
  String get searchMusicHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @signInToSearchMusic.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse the music library.'**
  String get signInToSearchMusic;

  /// No description provided for @musicLibraryLoadError.
  ///
  /// In en, this message translates to:
  /// **'The music library could not be loaded.'**
  String get musicLibraryLoadError;

  /// No description provided for @noLibraryPieces.
  ///
  /// In en, this message translates to:
  /// **'No music pieces available yet.'**
  String get noLibraryPieces;

  /// No description provided for @noMusicSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No music pieces match your search.'**
  String get noMusicSearchResults;

  /// No description provided for @untitledPiece.
  ///
  /// In en, this message translates to:
  /// **'Untitled piece'**
  String get untitledPiece;

  /// No description provided for @libraryPieceMissing.
  ///
  /// In en, this message translates to:
  /// **'This music piece is no longer available.'**
  String get libraryPieceMissing;

  /// No description provided for @libraryPracticeFilesMissing.
  ///
  /// In en, this message translates to:
  /// **'This piece is missing files needed for that play mode.'**
  String get libraryPracticeFilesMissing;

  /// No description provided for @musicLibraryOpenPiece.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String musicLibraryOpenPiece(String title);

  /// No description provided for @drawerMusicSheets.
  ///
  /// In en, this message translates to:
  /// **'Music Sheets'**
  String get drawerMusicSheets;

  /// No description provided for @drawerUploadSheet.
  ///
  /// In en, this message translates to:
  /// **'Upload Sheet'**
  String get drawerUploadSheet;

  /// No description provided for @drawerPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get drawerPractice;

  /// No description provided for @drawerPracticeResults.
  ///
  /// In en, this message translates to:
  /// **'Practice Results'**
  String get drawerPracticeResults;

  /// No description provided for @drawerMidi.
  ///
  /// In en, this message translates to:
  /// **'MIDI'**
  String get drawerMidi;

  /// No description provided for @drawerFlyaway.
  ///
  /// In en, this message translates to:
  /// **'Flyaway'**
  String get drawerFlyaway;

  /// No description provided for @drawerSavedSheets.
  ///
  /// In en, this message translates to:
  /// **'Saved Compositions'**
  String get drawerSavedSheets;

  /// No description provided for @drawerComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get drawerComposition;

  /// No description provided for @drawerPublishedCompositions.
  ///
  /// In en, this message translates to:
  /// **'Published Compositions'**
  String get drawerPublishedCompositions;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @filipino.
  ///
  /// In en, this message translates to:
  /// **'Filipino'**
  String get filipino;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get logoutQuestion;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The language preference could not be saved.'**
  String get languageSaveFailed;

  /// No description provided for @pianoPlayer.
  ///
  /// In en, this message translates to:
  /// **'Piano Player'**
  String get pianoPlayer;

  /// No description provided for @notAssessed.
  ///
  /// In en, this message translates to:
  /// **'Not assessed'**
  String get notAssessed;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @musicSheets.
  ///
  /// In en, this message translates to:
  /// **'Music Sheets'**
  String get musicSheets;

  /// No description provided for @addSheetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add sheet'**
  String get addSheetTooltip;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get yourLibrary;

  /// No description provided for @libraryDescription.
  ///
  /// In en, this message translates to:
  /// **'Open and manage your uploaded music sheets.'**
  String get libraryDescription;

  /// No description provided for @noMusicSheets.
  ///
  /// In en, this message translates to:
  /// **'No music sheets yet'**
  String get noMusicSheets;

  /// No description provided for @noMusicSheetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload images or a PDF to start building your music-sheet library.'**
  String get noMusicSheetsDescription;

  /// No description provided for @addMusicSheet.
  ///
  /// In en, this message translates to:
  /// **'Add Music Sheet'**
  String get addMusicSheet;

  /// No description provided for @musicSheetsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your music sheets could not be loaded.'**
  String get musicSheetsLoadError;

  /// No description provided for @musicSheetsLoadErrorHelp.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get musicSheetsLoadErrorHelp;

  /// No description provided for @signInForMusicSheets.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your music sheets.'**
  String get signInForMusicSheets;

  /// No description provided for @untitledSheet.
  ///
  /// In en, this message translates to:
  /// **'Untitled Sheet'**
  String get untitledSheet;

  /// No description provided for @pageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 page} other {{count} pages}}'**
  String pageCount(int count);

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @addedDate.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String addedDate(String date);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @renameSheet.
  ///
  /// In en, this message translates to:
  /// **'Rename sheet'**
  String get renameSheet;

  /// No description provided for @sheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Sheet title'**
  String get sheetTitle;

  /// No description provided for @enterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for this sheet.'**
  String get enterSheetTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteSheetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete sheet?'**
  String get deleteSheetQuestion;

  /// No description provided for @deleteSheetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and all of its files will be permanently deleted.'**
  String deleteSheetConfirmation(String title);

  /// No description provided for @musicSheetRenamed.
  ///
  /// In en, this message translates to:
  /// **'Music sheet renamed.'**
  String get musicSheetRenamed;

  /// No description provided for @musicSheetRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'The music sheet could not be renamed.'**
  String get musicSheetRenameFailed;

  /// No description provided for @waitForTranslationBeforeDelete.
  ///
  /// In en, this message translates to:
  /// **'Wait for the music sheet to finish converting before deleting it.'**
  String get waitForTranslationBeforeDelete;

  /// No description provided for @musicSheetDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was deleted.'**
  String musicSheetDeleted(String title);

  /// No description provided for @musicSheetDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The music sheet could not be deleted.'**
  String get musicSheetDeleteFailed;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @choosePlayMode.
  ///
  /// In en, this message translates to:
  /// **'Choose play mode'**
  String get choosePlayMode;

  /// No description provided for @sightReading.
  ///
  /// In en, this message translates to:
  /// **'Sight Reading'**
  String get sightReading;

  /// No description provided for @synthesia.
  ///
  /// In en, this message translates to:
  /// **'Synthesia'**
  String get synthesia;

  /// No description provided for @arPractice.
  ///
  /// In en, this message translates to:
  /// **'AR Practice'**
  String get arPractice;

  /// No description provided for @translateBeforeAr.
  ///
  /// In en, this message translates to:
  /// **'Convert the music sheet before starting AR Practice.'**
  String get translateBeforeAr;

  /// No description provided for @translatedMidiMissing.
  ///
  /// In en, this message translates to:
  /// **'The file needed for this practice mode is not ready.'**
  String get translatedMidiMissing;

  /// No description provided for @openArFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open AR Practice.'**
  String get openArFailed;

  /// No description provided for @translateBeforeSynthesia.
  ///
  /// In en, this message translates to:
  /// **'Convert the music sheet before starting Synthesia.'**
  String get translateBeforeSynthesia;

  /// No description provided for @openSynthesiaFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Synthesia.'**
  String get openSynthesiaFailed;

  /// No description provided for @translateBeforeSightReading.
  ///
  /// In en, this message translates to:
  /// **'Convert the music sheet before starting Sight Reading.'**
  String get translateBeforeSightReading;

  /// No description provided for @translatedPracticeFilesMissing.
  ///
  /// In en, this message translates to:
  /// **'The files needed for this practice mode are not ready.'**
  String get translatedPracticeFilesMissing;

  /// No description provided for @openSightReadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Sight Reading.'**
  String get openSightReadingFailed;

  /// No description provided for @recognized.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get recognized;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @recognizedPdfLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The converted sheet could not be loaded. Showing the original sheet instead.'**
  String get recognizedPdfLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumber(int number);

  /// No description provided for @musicSheetHasNoFiles.
  ///
  /// In en, this message translates to:
  /// **'This music sheet does not contain any files.'**
  String get musicSheetHasNoFiles;

  /// No description provided for @fileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be loaded.'**
  String get fileLoadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @translateSheetAgainQuestion.
  ///
  /// In en, this message translates to:
  /// **'Convert this sheet again?'**
  String get translateSheetAgainQuestion;

  /// No description provided for @translateMusicSheetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Convert music sheet?'**
  String get translateMusicSheetQuestion;

  /// No description provided for @retranslateDescription.
  ///
  /// In en, this message translates to:
  /// **'SoundSight will process \"{title}\" again and replace its current converted version.'**
  String retranslateDescription(String title);

  /// No description provided for @translateDescription.
  ///
  /// In en, this message translates to:
  /// **'SoundSight will create a playable digital version of \"{title}\". This may take a few minutes.'**
  String translateDescription(String title);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get translate;

  /// No description provided for @translatingMusicSheet.
  ///
  /// In en, this message translates to:
  /// **'Converting music sheet'**
  String get translatingMusicSheet;

  /// No description provided for @translationLoadingDescription.
  ///
  /// In en, this message translates to:
  /// **'SoundSight is reading the notes. Please wait and keep the app open.'**
  String get translationLoadingDescription;

  /// No description provided for @translationComplete.
  ///
  /// In en, this message translates to:
  /// **'Conversion complete'**
  String get translationComplete;

  /// No description provided for @translationResult.
  ///
  /// In en, this message translates to:
  /// **'SoundSight found {noteCount, plural, =1 {1 note} other {{noteCount} notes}} across {partCount, plural, =1 {1 part} other {{partCount} parts}}.'**
  String translationResult(int noteCount, int partCount);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion failed'**
  String get translationFailed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @translationReady.
  ///
  /// In en, this message translates to:
  /// **'Converted sheet ready'**
  String get translationReady;

  /// No description provided for @translationSummary.
  ///
  /// In en, this message translates to:
  /// **'{noteCount, plural, =1 {1 note} other {{noteCount} notes}} • {partCount, plural, =1 {1 part} other {{partCount} parts}}'**
  String translationSummary(int noteCount, int partCount);

  /// No description provided for @translationFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'The sheet could not be converted. You can try again.'**
  String get translationFailedDescription;

  /// No description provided for @translationProcessingDescription.
  ///
  /// In en, this message translates to:
  /// **'SoundSight is reading the notes.'**
  String get translationProcessingDescription;

  /// No description provided for @translationStartDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a playable digital version for SoundSight\'s practice modes.'**
  String get translationStartDescription;

  /// No description provided for @reconvert.
  ///
  /// In en, this message translates to:
  /// **'Convert Again'**
  String get reconvert;

  /// No description provided for @translationGenericError.
  ///
  /// In en, this message translates to:
  /// **'The music sheet could not be converted.'**
  String get translationGenericError;

  /// No description provided for @translationTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Conversion took too long. Please try again.'**
  String get translationTimedOut;

  /// No description provided for @translationConnectionError.
  ///
  /// In en, this message translates to:
  /// **'SoundSight could not connect. Check your internet connection and try again.'**
  String get translationConnectionError;

  /// No description provided for @translationRejected.
  ///
  /// In en, this message translates to:
  /// **'SoundSight could not read this music sheet. Try using a clearer image or PDF.'**
  String get translationRejected;

  /// No description provided for @translationSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in could not be verified. Restart the app and sign in again.'**
  String get translationSignInAgain;

  /// No description provided for @translationVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email before converting a music sheet.'**
  String get translationVerifyEmail;

  /// No description provided for @translationInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while converting the music sheet. Please try again.'**
  String get translationInvalidResponse;

  /// No description provided for @audioPreview.
  ///
  /// In en, this message translates to:
  /// **'Audio preview'**
  String get audioPreview;

  /// No description provided for @audioLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading audio...'**
  String get audioLoading;

  /// No description provided for @audioPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing converted music'**
  String get audioPlaying;

  /// No description provided for @audioPaused.
  ///
  /// In en, this message translates to:
  /// **'Playback paused'**
  String get audioPaused;

  /// No description provided for @audioIdle.
  ///
  /// In en, this message translates to:
  /// **'Listen to the converted music sheet'**
  String get audioIdle;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @audioPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'The audio preview could not be played.'**
  String get audioPlaybackError;

  /// No description provided for @addSheet.
  ///
  /// In en, this message translates to:
  /// **'Add Sheet'**
  String get addSheet;

  /// No description provided for @deleteAllSelectedFilesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all selected files'**
  String get deleteAllSelectedFilesTooltip;

  /// No description provided for @addYourSheetMusic.
  ///
  /// In en, this message translates to:
  /// **'Add your sheet music'**
  String get addYourSheetMusic;

  /// No description provided for @addSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload one PDF or capture clear photos of a printed sheet.'**
  String get addSheetDescription;

  /// No description provided for @chooseOneMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose one method per sheet'**
  String get chooseOneMethod;

  /// No description provided for @sheetMethodLimits.
  ///
  /// In en, this message translates to:
  /// **'1 PDF (20 MB, 20 pages) or up to 20 captured images (5 MB each). They cannot be combined.'**
  String get sheetMethodLimits;

  /// No description provided for @openingPdf.
  ///
  /// In en, this message translates to:
  /// **'Opening PDF...'**
  String get openingPdf;

  /// No description provided for @uploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get uploadPdf;

  /// No description provided for @uploadPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose 1 PDF, up to 20 MB and 20 pages.'**
  String get uploadPdfDescription;

  /// No description provided for @capturePages.
  ///
  /// In en, this message translates to:
  /// **'Capture Pages'**
  String get capturePages;

  /// No description provided for @capturePagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture up to 20 images, 5 MB each.'**
  String get capturePagesDescription;

  /// No description provided for @captureTips.
  ///
  /// In en, this message translates to:
  /// **'Capture tips'**
  String get captureTips;

  /// No description provided for @captureTipsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get a clearer and more accurate result'**
  String get captureTipsDescription;

  /// No description provided for @captureTipLighting.
  ///
  /// In en, this message translates to:
  /// **'Use good, even lighting.'**
  String get captureTipLighting;

  /// No description provided for @captureTipFlat.
  ///
  /// In en, this message translates to:
  /// **'Place the sheet music flat on a surface.'**
  String get captureTipFlat;

  /// No description provided for @captureTipVisible.
  ///
  /// In en, this message translates to:
  /// **'Keep the entire page visible, straight, and clear.'**
  String get captureTipVisible;

  /// No description provided for @selectedFiles.
  ///
  /// In en, this message translates to:
  /// **'Selected files'**
  String get selectedFiles;

  /// No description provided for @selectedFileInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap to preview • Swipe right to remove'**
  String get selectedFileInstructions;

  /// No description provided for @selectedImageLimit.
  ///
  /// In en, this message translates to:
  /// **'{count} / {maximum}'**
  String selectedImageLimit(int count, int maximum);

  /// No description provided for @onePdf.
  ///
  /// In en, this message translates to:
  /// **'1 PDF'**
  String get onePdf;

  /// No description provided for @selectedPdfMetadata.
  ///
  /// In en, this message translates to:
  /// **'PDF • {size} • {pages}'**
  String selectedPdfMetadata(String size, String pages);

  /// No description provided for @selectedImageMetadata.
  ///
  /// In en, this message translates to:
  /// **'Image • {size}'**
  String selectedImageMetadata(String size);

  /// No description provided for @deleteAllFilesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete all files?'**
  String get deleteAllFilesQuestion;

  /// No description provided for @deleteSelectedFilesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will remove {count, plural, =1 {the selected file} other {all {count} selected files}}.'**
  String deleteSelectedFilesConfirmation(int count);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @removeFileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove file?'**
  String get removeFileQuestion;

  /// No description provided for @removeFileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove {fileName}?'**
  String removeFileConfirmation(String fileName);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @nameYourSheet.
  ///
  /// In en, this message translates to:
  /// **'Name your sheet'**
  String get nameYourSheet;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @sheetSaved.
  ///
  /// In en, this message translates to:
  /// **'Sheet saved'**
  String get sheetSaved;

  /// No description provided for @unableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save'**
  String get unableToSave;

  /// No description provided for @sheetSavedDescription.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was uploaded and saved successfully.'**
  String sheetSavedDescription(String title);

  /// No description provided for @sheetSaveFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'The sheet could not be saved. Check your connection and try again.'**
  String get sheetSaveFailedDescription;

  /// No description provided for @backToSelection.
  ///
  /// In en, this message translates to:
  /// **'Back to selection'**
  String get backToSelection;

  /// No description provided for @saveSheet.
  ///
  /// In en, this message translates to:
  /// **'Save Sheet'**
  String get saveSheet;

  /// No description provided for @savingProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving {percent}%'**
  String savingProgress(int percent);

  /// No description provided for @signInBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in before saving a sheet.'**
  String get signInBeforeSaving;

  /// No description provided for @onlyOnePdf.
  ///
  /// In en, this message translates to:
  /// **'Only one PDF can be uploaded. Delete the selected PDF before choosing another.'**
  String get onlyOnePdf;

  /// No description provided for @deleteImagesBeforePdf.
  ///
  /// In en, this message translates to:
  /// **'Delete all captured images before uploading a PDF.'**
  String get deleteImagesBeforePdf;

  /// No description provided for @selectExactlyOnePdf.
  ///
  /// In en, this message translates to:
  /// **'Select exactly one PDF.'**
  String get selectExactlyOnePdf;

  /// No description provided for @onlyPdfFiles.
  ///
  /// In en, this message translates to:
  /// **'Only PDF files can be uploaded.'**
  String get onlyPdfFiles;

  /// No description provided for @pdfSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'The PDF must be 20 MB or smaller.'**
  String get pdfSizeLimit;

  /// No description provided for @pdfHasNoPages.
  ///
  /// In en, this message translates to:
  /// **'The PDF does not contain any pages.'**
  String get pdfHasNoPages;

  /// No description provided for @pdfPageLimit.
  ///
  /// In en, this message translates to:
  /// **'This PDF has {count} pages. The maximum is {maximum} pages.'**
  String pdfPageLimit(int count, int maximum);

  /// No description provided for @pdfReadFailed.
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be read. Make sure it is a valid, unlocked PDF.'**
  String get pdfReadFailed;

  /// No description provided for @deletePdfBeforeCapture.
  ///
  /// In en, this message translates to:
  /// **'Delete the selected PDF before capturing images.'**
  String get deletePdfBeforeCapture;

  /// No description provided for @imageCountLimit.
  ///
  /// In en, this message translates to:
  /// **'You can only add up to {maximum} images.'**
  String imageCountLimit(int maximum);

  /// No description provided for @capturedImageSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'The captured image is larger than 5 MB. Try capturing it again.'**
  String get capturedImageSizeLimit;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {username}'**
  String homeGreeting(String username);

  /// No description provided for @homeEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing. Great music starts with you.'**
  String get homeEncouragement;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// No description provided for @practiceBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Build your musical skills, improve accuracy, and elevate your performance.'**
  String get practiceBannerDescription;

  /// No description provided for @playerProgress.
  ///
  /// In en, this message translates to:
  /// **'Player Progress'**
  String get playerProgress;

  /// No description provided for @underAssessment.
  ///
  /// In en, this message translates to:
  /// **'Under Assessment'**
  String get underAssessment;

  /// No description provided for @rankLabel.
  ///
  /// In en, this message translates to:
  /// **'{rank} rank'**
  String rankLabel(String rank);

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String levelLabel(int level);

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @xpNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} XP needed'**
  String xpNeeded(int count);

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @captureSheet.
  ///
  /// In en, this message translates to:
  /// **'Capture Sheet'**
  String get captureSheet;

  /// No description provided for @communityCompositions.
  ///
  /// In en, this message translates to:
  /// **'Community Compositions'**
  String get communityCompositions;

  /// No description provided for @communityCompositionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover music shared by other users.'**
  String get communityCompositionsDescription;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @communityCompositionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Community compositions could not be loaded.'**
  String get communityCompositionsLoadFailed;

  /// No description provided for @noCommunityCompositions.
  ///
  /// In en, this message translates to:
  /// **'No community compositions have been shared yet.'**
  String get noCommunityCompositions;

  /// No description provided for @communityPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing \"{title}\".'**
  String communityPlaying(String title);

  /// No description provided for @communityPlaybackStopped.
  ///
  /// In en, this message translates to:
  /// **'Playback stopped.'**
  String get communityPlaybackStopped;

  /// No description provided for @communityNoPlaybackData.
  ///
  /// In en, this message translates to:
  /// **'This version has no playback data. Republish it first.'**
  String get communityNoPlaybackData;

  /// No description provided for @communityPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'The published composition could not be played.'**
  String get communityPlaybackFailed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achievementsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Some badges could not be loaded. Reopen Profile to try again.'**
  String get achievementsLoadError;

  /// No description provided for @viewAchievementDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewAchievementDetails;

  /// No description provided for @achievementDetails.
  ///
  /// In en, this message translates to:
  /// **'Badge details'**
  String get achievementDetails;

  /// No description provided for @achievementProgress.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} badges earned'**
  String achievementProgress(int earned, int total);

  /// No description provided for @badgeFirstMeasure.
  ///
  /// In en, this message translates to:
  /// **'First Measure'**
  String get badgeFirstMeasure;

  /// No description provided for @badgeFirstMeasureDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the skill assessment to discover your SoundSight level.'**
  String get badgeFirstMeasureDescription;

  /// No description provided for @badgeSheetCollector.
  ///
  /// In en, this message translates to:
  /// **'Sheet Collector'**
  String get badgeSheetCollector;

  /// No description provided for @badgeSheetCollectorDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your first music sheet by uploading a file or capturing it with the camera.'**
  String get badgeSheetCollectorDescription;

  /// No description provided for @badgeFirstComposer.
  ///
  /// In en, this message translates to:
  /// **'First Composer'**
  String get badgeFirstComposer;

  /// No description provided for @badgeFirstComposerDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your first composition, whether created manually or from a recording.'**
  String get badgeFirstComposerDescription;

  /// No description provided for @badgeMiddleC.
  ///
  /// In en, this message translates to:
  /// **'Middle C'**
  String get badgeMiddleC;

  /// No description provided for @badgeMiddleCDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete lesson stage 3: The Middle C.'**
  String get badgeMiddleCDescription;

  /// No description provided for @badgeFirstMelody.
  ///
  /// In en, this message translates to:
  /// **'First Melody'**
  String get badgeFirstMelody;

  /// No description provided for @badgeFirstMelodyDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete lesson stage 6: Play Twinkle Twinkle.'**
  String get badgeFirstMelodyDescription;

  /// No description provided for @badgeGrowingMusician.
  ///
  /// In en, this message translates to:
  /// **'Growing Musician'**
  String get badgeGrowingMusician;

  /// No description provided for @badgeGrowingMusicianDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete lesson stage 9: Play Fur Elise.'**
  String get badgeGrowingMusicianDescription;

  /// No description provided for @badgeChordBuilder.
  ///
  /// In en, this message translates to:
  /// **'Chord Builder'**
  String get badgeChordBuilder;

  /// No description provided for @badgeChordBuilderDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete lesson stage 12: Chords.'**
  String get badgeChordBuilderDescription;

  /// No description provided for @badgeMusicNavigator.
  ///
  /// In en, this message translates to:
  /// **'Music Navigator'**
  String get badgeMusicNavigator;

  /// No description provided for @badgeMusicNavigatorDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete lesson stage 15: Nashville Number System.'**
  String get badgeMusicNavigatorDescription;

  /// No description provided for @badgeSoundSightMaster.
  ///
  /// In en, this message translates to:
  /// **'SoundSight Master'**
  String get badgeSoundSightMaster;

  /// No description provided for @badgeSoundSightMasterDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete all 16 lesson stages.'**
  String get badgeSoundSightMasterDescription;

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get badgeUnlocked;

  /// No description provided for @badgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get badgeLocked;

  /// No description provided for @badgeChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get badgeChecking;

  /// No description provided for @badgeEarnedAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Badge unlocked!'**
  String get badgeEarnedAnnouncement;

  /// No description provided for @editProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTooltip;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appAppearance.
  ///
  /// In en, this message translates to:
  /// **'App appearance'**
  String get appAppearance;

  /// No description provided for @assessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assessment;

  /// No description provided for @retryAssessmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Retry Assessment Status'**
  String get retryAssessmentStatus;

  /// No description provided for @loadingAssessment.
  ///
  /// In en, this message translates to:
  /// **'Loading Assessment'**
  String get loadingAssessment;

  /// No description provided for @startAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start Assessment'**
  String get startAssessment;

  /// No description provided for @resumeAssessment.
  ///
  /// In en, this message translates to:
  /// **'Resume Assessment'**
  String get resumeAssessment;

  /// No description provided for @viewAssessmentResults.
  ///
  /// In en, this message translates to:
  /// **'View Assessment Results'**
  String get viewAssessmentResults;

  /// No description provided for @assessmentExpired.
  ///
  /// In en, this message translates to:
  /// **'Assessment Expired'**
  String get assessmentExpired;

  /// No description provided for @assessmentLoadFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the assessment. Tap to try again.'**
  String get assessmentLoadFailedDescription;

  /// No description provided for @assessmentLoadingDescription.
  ///
  /// In en, this message translates to:
  /// **'Checking your current assessment status.'**
  String get assessmentLoadingDescription;

  /// No description provided for @assessmentNotStartedDescription.
  ///
  /// In en, this message translates to:
  /// **'Start whenever you are ready. The timer has not begun.'**
  String get assessmentNotStartedDescription;

  /// No description provided for @assessmentInProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Continue before the active 72-hour deadline.'**
  String get assessmentInProgressDescription;

  /// No description provided for @assessmentCompletedDescription.
  ///
  /// In en, this message translates to:
  /// **'Review your permanent level and section scores.'**
  String get assessmentCompletedDescription;

  /// No description provided for @assessmentExpiredDescription.
  ///
  /// In en, this message translates to:
  /// **'The assessment expired and cannot be retried. Your saved rank is kept; otherwise Beginner is assigned.'**
  String get assessmentExpiredDescription;

  /// No description provided for @updatePersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information.'**
  String get updatePersonalInformation;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailCannotBeChanged;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty.'**
  String get usernameRequired;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save profile changes. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @profilePictureSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Profile picture must be smaller than 5 MB.'**
  String get profilePictureSizeLimit;

  /// No description provided for @saveChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get saveChangesQuestion;

  /// No description provided for @profileSaveConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to update your profile information?'**
  String get profileSaveConfirmation;

  /// No description provided for @uploadingProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Uploading profile picture...'**
  String get uploadingProfilePicture;

  /// No description provided for @savingProfileChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving profile changes...'**
  String get savingProfileChanges;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment.'**
  String get pleaseWait;

  /// No description provided for @myCompositions.
  ///
  /// In en, this message translates to:
  /// **'My Compositions'**
  String get myCompositions;

  /// No description provided for @newComposition.
  ///
  /// In en, this message translates to:
  /// **'New Composition'**
  String get newComposition;

  /// No description provided for @yourPianoPieces.
  ///
  /// In en, this message translates to:
  /// **'Your piano pieces'**
  String get yourPianoPieces;

  /// No description provided for @compositionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create, play, and manage your simple melodies.'**
  String get compositionsDescription;

  /// No description provided for @noCompositions.
  ///
  /// In en, this message translates to:
  /// **'No compositions yet'**
  String get noCompositions;

  /// No description provided for @noCompositionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first piano piece using melodies, chords, and custom measures.'**
  String get noCompositionsDescription;

  /// No description provided for @compositionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your compositions could not be loaded.'**
  String get compositionsLoadError;

  /// No description provided for @signInForCompositions.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your compositions.'**
  String get signInForCompositions;

  /// No description provided for @compositionSavedFilesReady.
  ///
  /// In en, this message translates to:
  /// **'Composition saved and music files are ready.'**
  String get compositionSavedFilesReady;

  /// No description provided for @compositionSavedFilesPending.
  ///
  /// In en, this message translates to:
  /// **'Composition saved safely. Your sheet music and playback files are not ready yet.'**
  String get compositionSavedFilesPending;

  /// No description provided for @compositionSaved.
  ///
  /// In en, this message translates to:
  /// **'Composition saved.'**
  String get compositionSaved;

  /// No description provided for @compositionDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was deleted.'**
  String compositionDeleted(String title);

  /// No description provided for @compositionMusicFilesReady.
  ///
  /// In en, this message translates to:
  /// **'Your music files are ready.'**
  String get compositionMusicFilesReady;

  /// No description provided for @compositionMusicFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Your composition is saved, but the music files still could not be prepared. Try again when the service is available.'**
  String get compositionMusicFilesFailed;

  /// No description provided for @compositionDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The composition could not be deleted.'**
  String get compositionDeleteFailed;

  /// No description provided for @deleteCompositionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete composition?'**
  String get deleteCompositionQuestion;

  /// No description provided for @deleteCompositionConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteCompositionConfirmation(String title);

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @preparingMusicFiles.
  ///
  /// In en, this message translates to:
  /// **'Preparing your music files'**
  String get preparingMusicFiles;

  /// No description provided for @musicFilesNeedUpdating.
  ///
  /// In en, this message translates to:
  /// **'Music files need updating'**
  String get musicFilesNeedUpdating;

  /// No description provided for @musicFilesNotReady.
  ///
  /// In en, this message translates to:
  /// **'Music files are not ready'**
  String get musicFilesNotReady;

  /// No description provided for @musicFilesOutOfDateDescription.
  ///
  /// In en, this message translates to:
  /// **'Your changes are saved, but the available files contain an older version.'**
  String get musicFilesOutOfDateDescription;

  /// No description provided for @musicFilesNotReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your sheet music and playback files are not ready yet.'**
  String get musicFilesNotReadyDescription;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @notSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get notSavedYet;

  /// No description provided for @lastEdited.
  ///
  /// In en, this message translates to:
  /// **'Last edited {date}'**
  String lastEdited(String date);

  /// No description provided for @createYourPianoPiece.
  ///
  /// In en, this message translates to:
  /// **'Create your piano piece'**
  String get createYourPianoPiece;

  /// No description provided for @newCompositionManualDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the starting title, key, tempo, and meter. You can change them later in the composition workspace.'**
  String get newCompositionManualDescription;

  /// No description provided for @newCompositionRecordingDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a title, key, and meter. Tempo and measures will be detected from your performance.'**
  String get newCompositionRecordingDescription;

  /// No description provided for @compositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Composition Title'**
  String get compositionTitle;

  /// No description provided for @compositionTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: My First Song'**
  String get compositionTitleHint;

  /// No description provided for @compositionTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a composition title.'**
  String get compositionTitleRequired;

  /// No description provided for @compositionTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'The title must be 80 characters or fewer.'**
  String get compositionTitleTooLong;

  /// No description provided for @tempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get tempo;

  /// No description provided for @tempoDescription.
  ///
  /// In en, this message translates to:
  /// **'A lower BPM sounds slower. A higher BPM sounds faster.'**
  String get tempoDescription;

  /// No description provided for @tempoRangeHint.
  ///
  /// In en, this message translates to:
  /// **'40 to 200'**
  String get tempoRangeHint;

  /// No description provided for @validTempoRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid tempo.'**
  String get validTempoRequired;

  /// No description provided for @tempoRangeError.
  ///
  /// In en, this message translates to:
  /// **'Tempo must be between 40 and 200 BPM.'**
  String get tempoRangeError;

  /// No description provided for @detectedTempoDescription.
  ///
  /// In en, this message translates to:
  /// **'Tempo and measure count will be detected from how you play.'**
  String get detectedTempoDescription;

  /// No description provided for @compositionSettings.
  ///
  /// In en, this message translates to:
  /// **'Composition Settings'**
  String get compositionSettings;

  /// No description provided for @compositionSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the musical structure for this piece.'**
  String get compositionSettingsDescription;

  /// No description provided for @keySignature.
  ///
  /// In en, this message translates to:
  /// **'Key Signature'**
  String get keySignature;

  /// No description provided for @timeSignature.
  ///
  /// In en, this message translates to:
  /// **'Time Signature'**
  String get timeSignature;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get opening;

  /// No description provided for @openRecorder.
  ///
  /// In en, this message translates to:
  /// **'Open Recorder'**
  String get openRecorder;

  /// No description provided for @startComposing.
  ///
  /// In en, this message translates to:
  /// **'Start Composing'**
  String get startComposing;

  /// No description provided for @signInBeforeCreatingComposition.
  ///
  /// In en, this message translates to:
  /// **'Sign in before creating a composition.'**
  String get signInBeforeCreatingComposition;

  /// No description provided for @compositionDetails.
  ///
  /// In en, this message translates to:
  /// **'Composition Details'**
  String get compositionDetails;

  /// No description provided for @editComposition.
  ///
  /// In en, this message translates to:
  /// **'Edit Composition'**
  String get editComposition;

  /// No description provided for @deleteComposition.
  ///
  /// In en, this message translates to:
  /// **'Delete Composition'**
  String get deleteComposition;

  /// No description provided for @pianoSolo.
  ///
  /// In en, this message translates to:
  /// **'Piano Solo'**
  String get pianoSolo;

  /// No description provided for @keyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get keyLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @editedLabel.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get editedLabel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @listenToComposition.
  ///
  /// In en, this message translates to:
  /// **'Listen to your composition'**
  String get listenToComposition;

  /// No description provided for @playFromBeginning.
  ///
  /// In en, this message translates to:
  /// **'Play from beginning'**
  String get playFromBeginning;

  /// No description provided for @compositionSummary.
  ///
  /// In en, this message translates to:
  /// **'Composition Summary'**
  String get compositionSummary;

  /// No description provided for @measureLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Measure} other {Measures}}'**
  String measureLabel(int count);

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Note} other {Notes}}'**
  String noteLabel(int count);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @musicFilesReady.
  ///
  /// In en, this message translates to:
  /// **'Music files are ready'**
  String get musicFilesReady;

  /// No description provided for @musicFilesReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your sheet music and playback files are ready.'**
  String get musicFilesReadyDescription;

  /// No description provided for @musicFilesPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared {date}.'**
  String musicFilesPrepared(String date);

  /// No description provided for @retryGeneration.
  ///
  /// In en, this message translates to:
  /// **'Retry Generation'**
  String get retryGeneration;

  /// No description provided for @checkingPublicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking publication status...'**
  String get checkingPublicationStatus;

  /// No description provided for @publishingUpdateProgress.
  ///
  /// In en, this message translates to:
  /// **'Publishing Update...'**
  String get publishingUpdateProgress;

  /// No description provided for @unpublishingProgress.
  ///
  /// In en, this message translates to:
  /// **'Unpublishing...'**
  String get unpublishingProgress;

  /// No description provided for @publishingProgress.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get publishingProgress;

  /// No description provided for @publishUpdate.
  ///
  /// In en, this message translates to:
  /// **'Publish Update'**
  String get publishUpdate;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @unpublishComposition.
  ///
  /// In en, this message translates to:
  /// **'Unpublish Composition'**
  String get unpublishComposition;

  /// No description provided for @publishComposition.
  ///
  /// In en, this message translates to:
  /// **'Publish Composition'**
  String get publishComposition;

  /// No description provided for @deletingProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deletingProgress;

  /// No description provided for @compositionHasNoNotes.
  ///
  /// In en, this message translates to:
  /// **'This composition does not have any notes yet.'**
  String get compositionHasNoNotes;

  /// No description provided for @compositionValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'This composition contains invalid data and cannot be played.'**
  String get compositionValidationFailed;

  /// No description provided for @compositionPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'The composition could not be played. Check the piano audio files.'**
  String get compositionPlaybackFailed;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @addNoteBeforePublishing.
  ///
  /// In en, this message translates to:
  /// **'Add at least one note before publishing.'**
  String get addNoteBeforePublishing;

  /// No description provided for @prepareFilesBeforePublishing.
  ///
  /// In en, this message translates to:
  /// **'Prepare the sheet music and playback files before publishing.'**
  String get prepareFilesBeforePublishing;

  /// No description provided for @compositionUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Composition unpublished successfully.'**
  String get compositionUnpublished;

  /// No description provided for @compositionUpdatePublished.
  ///
  /// In en, this message translates to:
  /// **'Composition update published successfully.'**
  String get compositionUpdatePublished;

  /// No description provided for @compositionPublished.
  ///
  /// In en, this message translates to:
  /// **'Composition published successfully.'**
  String get compositionPublished;

  /// No description provided for @compositionUnpublishFailed.
  ///
  /// In en, this message translates to:
  /// **'The composition could not be unpublished.'**
  String get compositionUnpublishFailed;

  /// No description provided for @compositionPublishFailed.
  ///
  /// In en, this message translates to:
  /// **'The composition could not be published. Make sure the backend is running.'**
  String get compositionPublishFailed;

  /// No description provided for @compositionPublishUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your publishing session could not be verified. Please sign out, sign in again, and retry.'**
  String get compositionPublishUnauthorized;

  /// No description provided for @updatedCompositionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The updated composition could not be loaded.'**
  String get updatedCompositionLoadFailed;

  /// No description provided for @prepareLatestFilesBeforeAr.
  ///
  /// In en, this message translates to:
  /// **'Prepare the latest music files before starting AR Practice.'**
  String get prepareLatestFilesBeforeAr;

  /// No description provided for @generatedMidiMissing.
  ///
  /// In en, this message translates to:
  /// **'The generated MIDI file is missing.'**
  String get generatedMidiMissing;

  /// No description provided for @prepareLatestFilesBeforeSightReading.
  ///
  /// In en, this message translates to:
  /// **'Prepare the latest music files before starting Sight Reading.'**
  String get prepareLatestFilesBeforeSightReading;

  /// No description provided for @generatedPracticeFilesMissing.
  ///
  /// In en, this message translates to:
  /// **'The generated MusicXML, MIDI, or MP3 file is missing.'**
  String get generatedPracticeFilesMissing;

  /// No description provided for @publishUpdateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Publish the latest changes to \"{title}\"?'**
  String publishUpdateQuestion(String title);

  /// No description provided for @publishCompositionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Publish \"{title}\"?'**
  String publishCompositionQuestion(String title);

  /// No description provided for @publishUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'A new published version and PDF will be created. Previous versions, likes, comments, and saves will remain.'**
  String get publishUpdateDescription;

  /// No description provided for @publishCompositionDescription.
  ///
  /// In en, this message translates to:
  /// **'A PDF music sheet will be created and shared with other SoundSight users.'**
  String get publishCompositionDescription;

  /// No description provided for @unpublishCompositionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Unpublish composition?'**
  String get unpublishCompositionQuestion;

  /// No description provided for @unpublishCompositionConfirmation.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and all of its published versions will be removed from the community feed.'**
  String unpublishCompositionConfirmation(String title);

  /// No description provided for @unpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublish;

  /// No description provided for @unpublishingComposition.
  ///
  /// In en, this message translates to:
  /// **'Unpublishing composition...'**
  String get unpublishingComposition;

  /// No description provided for @unpublishingCompositionDescription.
  ///
  /// In en, this message translates to:
  /// **'Removing every published version and PDF. Please wait.'**
  String get unpublishingCompositionDescription;

  /// No description provided for @generatedPreview.
  ///
  /// In en, this message translates to:
  /// **'Generated preview'**
  String get generatedPreview;

  /// No description provided for @generatedPreviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Review your sheet music and listen before publishing.'**
  String get generatedPreviewDescription;

  /// No description provided for @compositionPlayback.
  ///
  /// In en, this message translates to:
  /// **'Composition playback'**
  String get compositionPlayback;

  /// No description provided for @loadingComposition.
  ///
  /// In en, this message translates to:
  /// **'Loading your composition...'**
  String get loadingComposition;

  /// No description provided for @playingComposition.
  ///
  /// In en, this message translates to:
  /// **'Playing your composition'**
  String get playingComposition;

  /// No description provided for @listenGeneratedComposition.
  ///
  /// In en, this message translates to:
  /// **'Listen to the generated composition'**
  String get listenGeneratedComposition;

  /// No description provided for @sheetMusic.
  ///
  /// In en, this message translates to:
  /// **'Sheet music'**
  String get sheetMusic;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @sheetMusicLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The sheet music could not be loaded.'**
  String get sheetMusicLoadFailed;

  /// No description provided for @checkConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again.'**
  String get checkConnectionTryAgain;

  /// No description provided for @compositionSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Composition settings'**
  String get compositionSettingsTooltip;

  /// No description provided for @saveCompositionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save composition'**
  String get saveCompositionTooltip;

  /// No description provided for @automaticDurationDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatic follows how long you hold the MIDI keys.'**
  String get automaticDurationDescription;

  /// No description provided for @automaticKeyHoldHelper.
  ///
  /// In en, this message translates to:
  /// **'Automatic uses key hold time.'**
  String get automaticKeyHoldHelper;

  /// No description provided for @pianoKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Piano Keyboard'**
  String get pianoKeyboard;

  /// No description provided for @swipeHorizontally.
  ///
  /// In en, this message translates to:
  /// **'Swipe horizontally'**
  String get swipeHorizontally;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @moveBackUsingDuration.
  ///
  /// In en, this message translates to:
  /// **'Move back using selected duration'**
  String get moveBackUsingDuration;

  /// No description provided for @moveForwardUsingDuration.
  ///
  /// In en, this message translates to:
  /// **'Move forward using selected duration'**
  String get moveForwardUsingDuration;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @insertRest.
  ///
  /// In en, this message translates to:
  /// **'Insert Rest'**
  String get insertRest;

  /// No description provided for @insertRestUsingDuration.
  ///
  /// In en, this message translates to:
  /// **'Insert rest using selected duration'**
  String get insertRestUsingDuration;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @toggleSongOverview.
  ///
  /// In en, this message translates to:
  /// **'Show or hide full-song overview'**
  String get toggleSongOverview;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @savingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingEllipsis;

  /// No description provided for @saveComposition.
  ///
  /// In en, this message translates to:
  /// **'Save Composition'**
  String get saveComposition;

  /// No description provided for @beat.
  ///
  /// In en, this message translates to:
  /// **'beat'**
  String get beat;

  /// No description provided for @beats.
  ///
  /// In en, this message translates to:
  /// **'beats'**
  String get beats;

  /// No description provided for @selectedNotePosition.
  ///
  /// In en, this message translates to:
  /// **'Measure {measure} • Beat {beat} • {duration} {unit}'**
  String selectedNotePosition(
    int measure,
    String beat,
    String duration,
    String unit,
  );

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @tied.
  ///
  /// In en, this message translates to:
  /// **'Tied'**
  String get tied;

  /// No description provided for @addMeasure.
  ///
  /// In en, this message translates to:
  /// **'Add Measure'**
  String get addMeasure;

  /// No description provided for @deleteSelection.
  ///
  /// In en, this message translates to:
  /// **'Delete Selection'**
  String get deleteSelection;

  /// No description provided for @unsupportedPianoKey.
  ///
  /// In en, this message translates to:
  /// **'That piano key is outside the supported A0 to C8 range.'**
  String get unsupportedPianoKey;

  /// No description provided for @selectSingleNoteBeforePlaying.
  ///
  /// In en, this message translates to:
  /// **'Select only one note, or clear the selection, before playing.'**
  String get selectSingleNoteBeforePlaying;

  /// No description provided for @clearSelectedNoteBeforeChord.
  ///
  /// In en, this message translates to:
  /// **'Clear the selected note before entering a chord.'**
  String get clearSelectedNoteBeforeChord;

  /// No description provided for @stopPlaybackBeforeEditing.
  ///
  /// In en, this message translates to:
  /// **'Stop playback before editing the composition.'**
  String get stopPlaybackBeforeEditing;

  /// No description provided for @compositionNoteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This composition now has {count} of the 256 allowed notes.'**
  String compositionNoteLimitReached(int count);

  /// No description provided for @pianoNotePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'The piano note could not be played.'**
  String get pianoNotePlaybackFailed;

  /// No description provided for @measureActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That measure action is not available.'**
  String get measureActionUnavailable;

  /// No description provided for @selectNoteFirst.
  ///
  /// In en, this message translates to:
  /// **'Select at least one note first.'**
  String get selectNoteFirst;

  /// No description provided for @notesCopied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note copied.} other {{count} notes copied.}}'**
  String notesCopied(int count);

  /// No description provided for @selectChordFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a chord first.'**
  String get selectChordFirst;

  /// No description provided for @addNoteBeforePlaying.
  ///
  /// In en, this message translates to:
  /// **'Add at least one note before playing.'**
  String get addNoteBeforePlaying;

  /// No description provided for @compositionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The composition could not be saved.'**
  String get compositionSaveFailed;

  /// No description provided for @chordMode.
  ///
  /// In en, this message translates to:
  /// **'Chord Mode'**
  String get chordMode;

  /// No description provided for @chordNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note} other {{count} notes}}'**
  String chordNoteCount(int count);

  /// No description provided for @allowStacking.
  ///
  /// In en, this message translates to:
  /// **'Allow stacking'**
  String get allowStacking;

  /// No description provided for @chordModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow multiple notes to start on the same beat.'**
  String get chordModeDescription;

  /// No description provided for @chordNotesCombined.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note combined} other {{count} notes combined}}'**
  String chordNotesCombined(int count);

  /// No description provided for @finishChord.
  ///
  /// In en, this message translates to:
  /// **'Finish Chord'**
  String get finishChord;

  /// No description provided for @layerNotes.
  ///
  /// In en, this message translates to:
  /// **'Layer Notes'**
  String get layerNotes;

  /// No description provided for @measureBeatPosition.
  ///
  /// In en, this message translates to:
  /// **'Measure {measure} • Beat {beat}'**
  String measureBeatPosition(int measure, String beat);

  /// No description provided for @independentNotes.
  ///
  /// In en, this message translates to:
  /// **'Independent notes'**
  String get independentNotes;

  /// No description provided for @addNextNoteHere.
  ///
  /// In en, this message translates to:
  /// **'{position} — add the next note here.'**
  String addNextNoteHere(String position);

  /// No description provided for @layerNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add shorter notes while another note continues playing.'**
  String get layerNotesDescription;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @removeTie.
  ///
  /// In en, this message translates to:
  /// **'Remove Tie'**
  String get removeTie;

  /// No description provided for @tieToNext.
  ///
  /// In en, this message translates to:
  /// **'Tie to Next'**
  String get tieToNext;

  /// No description provided for @deleteWholeChord.
  ///
  /// In en, this message translates to:
  /// **'Delete Whole Chord'**
  String get deleteWholeChord;

  /// No description provided for @historyAndEditing.
  ///
  /// In en, this message translates to:
  /// **'History and editing'**
  String get historyAndEditing;

  /// No description provided for @performanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Performance settings'**
  String get performanceSettings;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @performanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust playback and how new notes sound.'**
  String get performanceDescription;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @noteVelocity.
  ///
  /// In en, this message translates to:
  /// **'Note velocity'**
  String get noteVelocity;

  /// No description provided for @fromCursor.
  ///
  /// In en, this message translates to:
  /// **'From cursor'**
  String get fromCursor;

  /// No description provided for @loopMeasure.
  ///
  /// In en, this message translates to:
  /// **'Loop measure'**
  String get loopMeasure;

  /// No description provided for @sustain.
  ///
  /// In en, this message translates to:
  /// **'Sustain'**
  String get sustain;

  /// No description provided for @metronome.
  ///
  /// In en, this message translates to:
  /// **'Metronome'**
  String get metronome;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @pianoRoll.
  ///
  /// In en, this message translates to:
  /// **'Piano Roll'**
  String get pianoRoll;

  /// No description provided for @measureNumber.
  ///
  /// In en, this message translates to:
  /// **'Measure {number}'**
  String measureNumber(int number);

  /// No description provided for @deleteSelectedNote.
  ///
  /// In en, this message translates to:
  /// **'Delete selected note'**
  String get deleteSelectedNote;

  /// No description provided for @deleteSelectedNotes.
  ///
  /// In en, this message translates to:
  /// **'Delete selected notes'**
  String get deleteSelectedNotes;

  /// No description provided for @measures.
  ///
  /// In en, this message translates to:
  /// **'Measures'**
  String get measures;

  /// No description provided for @measure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measure;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalCount(int count);

  /// No description provided for @previousMeasure.
  ///
  /// In en, this message translates to:
  /// **'Previous measure'**
  String get previousMeasure;

  /// No description provided for @nextMeasure.
  ///
  /// In en, this message translates to:
  /// **'Next measure'**
  String get nextMeasure;

  /// No description provided for @previousOctave.
  ///
  /// In en, this message translates to:
  /// **'Previous octave'**
  String get previousOctave;

  /// No description provided for @selectOctave.
  ///
  /// In en, this message translates to:
  /// **'Select octave'**
  String get selectOctave;

  /// No description provided for @octaveNumber.
  ///
  /// In en, this message translates to:
  /// **'Octave {number}'**
  String octaveNumber(int number);

  /// No description provided for @octaveWithRange.
  ///
  /// In en, this message translates to:
  /// **'Octave {number} - {range}'**
  String octaveWithRange(int number, String range);

  /// No description provided for @nextOctave.
  ///
  /// In en, this message translates to:
  /// **'Next octave'**
  String get nextOctave;

  /// No description provided for @viewAllNotes.
  ///
  /// In en, this message translates to:
  /// **'View all notes'**
  String get viewAllNotes;

  /// No description provided for @notesBelowOctave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note below this octave} other {{count} notes below this octave}}'**
  String notesBelowOctave(int count);

  /// No description provided for @notesAboveOctave.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note above this octave} other {{count} notes above this octave}}'**
  String notesAboveOctave(int count);

  /// No description provided for @tapPianoKeyToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap a piano key to add a note'**
  String get tapPianoKeyToAdd;

  /// No description provided for @noNotesInOctave.
  ///
  /// In en, this message translates to:
  /// **'No notes in this octave'**
  String get noNotesInOctave;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @noNotesAdded.
  ///
  /// In en, this message translates to:
  /// **'No notes have been added yet.'**
  String get noNotesAdded;

  /// No description provided for @beatWithNotes.
  ///
  /// In en, this message translates to:
  /// **'Beat {beat}: {notes}'**
  String beatWithNotes(String beat, String notes);

  /// No description provided for @pianoKeySemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Piano key {key}'**
  String pianoKeySemanticLabel(String key);

  /// No description provided for @measureActions.
  ///
  /// In en, this message translates to:
  /// **'Measure actions'**
  String get measureActions;

  /// No description provided for @addMeasureAfter.
  ///
  /// In en, this message translates to:
  /// **'Add measure after'**
  String get addMeasureAfter;

  /// No description provided for @insertMeasureBefore.
  ///
  /// In en, this message translates to:
  /// **'Insert measure before'**
  String get insertMeasureBefore;

  /// No description provided for @duplicateMeasure.
  ///
  /// In en, this message translates to:
  /// **'Duplicate measure'**
  String get duplicateMeasure;

  /// No description provided for @moveMeasureLeft.
  ///
  /// In en, this message translates to:
  /// **'Move measure left'**
  String get moveMeasureLeft;

  /// No description provided for @moveMeasureRight.
  ///
  /// In en, this message translates to:
  /// **'Move measure right'**
  String get moveMeasureRight;

  /// No description provided for @clearMeasure.
  ///
  /// In en, this message translates to:
  /// **'Clear measure'**
  String get clearMeasure;

  /// No description provided for @deleteMeasure.
  ///
  /// In en, this message translates to:
  /// **'Delete measure'**
  String get deleteMeasure;

  /// No description provided for @wholeNote.
  ///
  /// In en, this message translates to:
  /// **'Whole'**
  String get wholeNote;

  /// No description provided for @dottedHalfNote.
  ///
  /// In en, this message translates to:
  /// **'Dotted Half'**
  String get dottedHalfNote;

  /// No description provided for @halfNote.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get halfNote;

  /// No description provided for @dottedQuarterNote.
  ///
  /// In en, this message translates to:
  /// **'Dotted Quarter'**
  String get dottedQuarterNote;

  /// No description provided for @quarterNote.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get quarterNote;

  /// No description provided for @dottedEighthNote.
  ///
  /// In en, this message translates to:
  /// **'Dotted Eighth'**
  String get dottedEighthNote;

  /// No description provided for @eighthNote.
  ///
  /// In en, this message translates to:
  /// **'Eighth'**
  String get eighthNote;

  /// No description provided for @triplet.
  ///
  /// In en, this message translates to:
  /// **'Triplet'**
  String get triplet;

  /// No description provided for @sixteenthNote.
  ///
  /// In en, this message translates to:
  /// **'Sixteenth'**
  String get sixteenthNote;

  /// No description provided for @chooseLengthBeforePiano.
  ///
  /// In en, this message translates to:
  /// **'Choose the length before tapping a piano key.'**
  String get chooseLengthBeforePiano;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @chooseNoteDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose Note Duration'**
  String get chooseNoteDuration;

  /// No description provided for @chooseFixedOrKeyHold.
  ///
  /// In en, this message translates to:
  /// **'Choose a fixed length or let your key hold set it.'**
  String get chooseFixedOrKeyHold;

  /// No description provided for @chooseNextNoteLength.
  ///
  /// In en, this message translates to:
  /// **'Choose how long the next note will be.'**
  String get chooseNextNoteLength;

  /// No description provided for @useKeyHoldTime.
  ///
  /// In en, this message translates to:
  /// **'Use key hold time'**
  String get useKeyHoldTime;

  /// No description provided for @swipeToViewPiano.
  ///
  /// In en, this message translates to:
  /// **'Swipe horizontally to view the piano'**
  String get swipeToViewPiano;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @saveCompositionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save composition?'**
  String get saveCompositionQuestion;

  /// No description provided for @replaceSavedCompositionDescription.
  ///
  /// In en, this message translates to:
  /// **'Your current changes will replace the previously saved version.'**
  String get replaceSavedCompositionDescription;

  /// No description provided for @createCompositionFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your composition and its music files will be created.'**
  String get createCompositionFilesDescription;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditing;

  /// No description provided for @discardUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get discardUnsavedChanges;

  /// No description provided for @discardUnsavedChangesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost if you leave without saving.'**
  String get discardUnsavedChangesDescription;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get switchCamera;

  /// No description provided for @generatingCompositionFiles.
  ///
  /// In en, this message translates to:
  /// **'Generating composition files...'**
  String get generatingCompositionFiles;

  /// No description provided for @keepScreenOpen.
  ///
  /// In en, this message translates to:
  /// **'Please keep this screen open.'**
  String get keepScreenOpen;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @noCameraAvailable.
  ///
  /// In en, this message translates to:
  /// **'No camera is available on this device.'**
  String get noCameraAvailable;

  /// No description provided for @cameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be opened.'**
  String get cameraOpenFailed;

  /// No description provided for @recordingNoteLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'You have captured {current} of the {maximum}-note limit.'**
  String recordingNoteLimitWarning(int current, int maximum);

  /// No description provided for @recordingNoteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'The {maximum}-note limit was reached. Release held keys to finish.'**
  String recordingNoteLimitReached(int maximum);

  /// No description provided for @recordingStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording.'**
  String get recordingStartFailed;

  /// No description provided for @recordingLengthWarning.
  ///
  /// In en, this message translates to:
  /// **'You are close to the maximum recording length.'**
  String get recordingLengthWarning;

  /// No description provided for @recordingLengthReached.
  ///
  /// In en, this message translates to:
  /// **'The maximum recording length was reached.'**
  String get recordingLengthReached;

  /// No description provided for @releaseHeldKeysToFinish.
  ///
  /// In en, this message translates to:
  /// **'Release the held keys to finish the recording.'**
  String get releaseHeldKeysToFinish;

  /// No description provided for @cameraSaveRestarted.
  ///
  /// In en, this message translates to:
  /// **'The camera could not finish saving the video. The camera was restarted.'**
  String get cameraSaveRestarted;

  /// No description provided for @videoRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'The video recording failed.'**
  String get videoRecordingFailed;

  /// No description provided for @noNotesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No notes were recorded'**
  String get noNotesRecorded;

  /// No description provided for @noNotesRecordedDescription.
  ///
  /// In en, this message translates to:
  /// **'Play at least one complete note on the connected MIDI piano before stopping.'**
  String get noNotesRecordedDescription;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record Again'**
  String get recordAgain;

  /// No description provided for @compositionCreated.
  ///
  /// In en, this message translates to:
  /// **'Composition created successfully.'**
  String get compositionCreated;

  /// No description provided for @compositionNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Composition not saved'**
  String get compositionNotSaved;

  /// No description provided for @recordingStillAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your recording is still available. Check your connection and try saving again.'**
  String get recordingStillAvailable;

  /// No description provided for @retrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry Save'**
  String get retrySave;

  /// No description provided for @filesNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Files were not generated'**
  String get filesNotGenerated;

  /// No description provided for @filesNotGeneratedDescription.
  ///
  /// In en, this message translates to:
  /// **'The composition was saved, but its PDF, MIDI, MusicXML, and MP3 could not be created.'**
  String get filesNotGeneratedDescription;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @recordingComplete.
  ///
  /// In en, this message translates to:
  /// **'Recording Complete'**
  String get recordingComplete;

  /// No description provided for @capturedNotes.
  ///
  /// In en, this message translates to:
  /// **'Captured notes'**
  String get capturedNotes;

  /// No description provided for @detectedTempo.
  ///
  /// In en, this message translates to:
  /// **'Detected tempo'**
  String get detectedTempo;

  /// No description provided for @calculatedMeasures.
  ///
  /// In en, this message translates to:
  /// **'Calculated measures'**
  String get calculatedMeasures;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @exploreMusic.
  ///
  /// In en, this message translates to:
  /// **'Explore music'**
  String get exploreMusic;

  /// No description provided for @exploreMusicDescription.
  ///
  /// In en, this message translates to:
  /// **'View music sheets shared by other SoundSight users.'**
  String get exploreMusicDescription;

  /// No description provided for @noPublishedCompositions.
  ///
  /// In en, this message translates to:
  /// **'No published compositions yet'**
  String get noPublishedCompositions;

  /// No description provided for @noPublishedCompositionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Published music sheets from the SoundSight community will appear here.'**
  String get noPublishedCompositionsDescription;

  /// No description provided for @publishedCompositionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Published compositions could not be loaded.'**
  String get publishedCompositionsLoadFailed;

  /// No description provided for @checkConnectionFirestorePermissions.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and Firestore permissions.'**
  String get checkConnectionFirestorePermissions;

  /// No description provided for @signInForPublishedCompositions.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view published compositions.'**
  String get signInForPublishedCompositions;

  /// No description provided for @publishedCompositionUnpublished.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" was unpublished.'**
  String publishedCompositionUnpublished(String title);

  /// No description provided for @signInForSavedSheets.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view saved compositions.'**
  String get signInForSavedSheets;

  /// No description provided for @savedSheetsSignedOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Your saved composition versions will appear here.'**
  String get savedSheetsSignedOutDescription;

  /// No description provided for @savedSheetsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved compositions could not be loaded.'**
  String get savedSheetsLoadFailed;

  /// No description provided for @noSavedSheets.
  ///
  /// In en, this message translates to:
  /// **'No saved compositions yet'**
  String get noSavedSheets;

  /// No description provided for @noSavedSheetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Save a published version to find it here.'**
  String get noSavedSheetsDescription;

  /// No description provided for @publishedBy.
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String publishedBy(String author);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(int version);

  /// No description provided for @compositionMeasureCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 measure} other {{count} measures}}'**
  String compositionMeasureCount(int count);

  /// No description provided for @compositionNoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note} other {{count} notes}}'**
  String compositionNoteCount(int count);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @viewSheet.
  ///
  /// In en, this message translates to:
  /// **'View Sheet'**
  String get viewSheet;

  /// No description provided for @likeUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The like could not be updated.'**
  String get likeUpdateFailed;

  /// No description provided for @savedCompositionUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The saved composition could not be updated.'**
  String get savedCompositionUpdateFailed;

  /// No description provided for @removeSavedSheetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove saved composition?'**
  String get removeSavedSheetQuestion;

  /// No description provided for @saveSheetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save this composition?'**
  String get saveSheetQuestion;

  /// No description provided for @removeSavedSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" version {version} from Saved Compositions?'**
  String removeSavedSheetDescription(String title, int version);

  /// No description provided for @saveSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Save \"{title}\" version {version} so you can find it later in Saved Compositions?'**
  String saveSheetDescription(String title, int version);

  /// No description provided for @recentlyPublished.
  ///
  /// In en, this message translates to:
  /// **'Recently published'**
  String get recentlyPublished;

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String publishedOn(String date);

  /// No description provided for @stopPlaybackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get stopPlaybackTooltip;

  /// No description provided for @playCompositionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play composition'**
  String get playCompositionTooltip;

  /// No description provided for @publishedSightReadingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sight Reading files are unavailable. Ask the owner to publish the composition again.'**
  String get publishedSightReadingUnavailable;

  /// No description provided for @publishedArFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The MIDI file for AR Practice is unavailable. Ask the owner to publish the composition again.'**
  String get publishedArFileUnavailable;

  /// No description provided for @publishedSheetLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The music sheet could not be loaded.'**
  String get publishedSheetLoadFailed;

  /// No description provided for @checkConnectionStoragePermissions.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and Firebase Storage permissions.'**
  String get checkConnectionStoragePermissions;

  /// No description provided for @commentsVersion.
  ///
  /// In en, this message translates to:
  /// **'Comments • V{version}'**
  String commentsVersion(int version);

  /// No description provided for @commentsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Comments could not be loaded.'**
  String get commentsLoadFailed;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @noCommentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share your thoughts.'**
  String get noCommentsDescription;

  /// No description provided for @deleteCommentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteCommentTooltip;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @commentPostFailed.
  ///
  /// In en, this message translates to:
  /// **'The comment could not be posted.'**
  String get commentPostFailed;

  /// No description provided for @deleteCommentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get deleteCommentQuestion;

  /// No description provided for @deleteCommentDescription.
  ///
  /// In en, this message translates to:
  /// **'This comment will be removed permanently.'**
  String get deleteCommentDescription;

  /// No description provided for @commentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The comment could not be deleted.'**
  String get commentDeleteFailed;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 minute ago} other {{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 hour ago} other {{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 day ago} other {{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @namePianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Name this piano setup'**
  String get namePianoSetup;

  /// No description provided for @pianoSetupName.
  ///
  /// In en, this message translates to:
  /// **'Piano setup name'**
  String get pianoSetupName;

  /// No description provided for @pianoSetupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Bedroom Piano'**
  String get pianoSetupNameHint;

  /// No description provided for @enterPianoSetupName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this piano setup.'**
  String get enterPianoSetupName;

  /// No description provided for @searchingForPiano.
  ///
  /// In en, this message translates to:
  /// **'Searching for piano'**
  String get searchingForPiano;

  /// No description provided for @pointCameraAtKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the piano keyboard'**
  String get pointCameraAtKeyboard;

  /// No description provided for @moveFartherBack.
  ///
  /// In en, this message translates to:
  /// **'Move farther back'**
  String get moveFartherBack;

  /// No description provided for @makeMorePianoKeysVisible.
  ///
  /// In en, this message translates to:
  /// **'Make more piano keys visible in the camera'**
  String get makeMorePianoKeysVisible;

  /// No description provided for @keepKeyboardClear.
  ///
  /// In en, this message translates to:
  /// **'Keep the keyboard clear'**
  String get keepKeyboardClear;

  /// No description provided for @moveObjectsOutOfView.
  ///
  /// In en, this message translates to:
  /// **'Move your hands and other objects out of view'**
  String get moveObjectsOutOfView;

  /// No description provided for @holdPhoneSteady.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone steady'**
  String get holdPhoneSteady;

  /// No description provided for @keepCameraStill.
  ///
  /// In en, this message translates to:
  /// **'Keep the camera still for a moment'**
  String get keepCameraStill;

  /// No description provided for @pianoDetected.
  ///
  /// In en, this message translates to:
  /// **'Piano detected'**
  String get pianoDetected;

  /// No description provided for @visibleKeyboardReady.
  ///
  /// In en, this message translates to:
  /// **'The visible keyboard area is ready'**
  String get visibleKeyboardReady;

  /// No description provided for @checkVisibleKeys.
  ///
  /// In en, this message translates to:
  /// **'Check the visible keys'**
  String get checkVisibleKeys;

  /// No description provided for @dragCornersAroundKeys.
  ///
  /// In en, this message translates to:
  /// **'Drag the white corners so they surround the piano keys'**
  String get dragCornersAroundKeys;

  /// No description provided for @selectMiddleC.
  ///
  /// In en, this message translates to:
  /// **'Select Middle C'**
  String get selectMiddleC;

  /// No description provided for @tapMiddleCInCamera.
  ///
  /// In en, this message translates to:
  /// **'Tap Middle C on the piano shown by the camera'**
  String get tapMiddleCInCamera;

  /// No description provided for @connectingToPiano.
  ///
  /// In en, this message translates to:
  /// **'Connecting to your piano'**
  String get connectingToPiano;

  /// No description provided for @pianoConnectionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Piano connection needed'**
  String get pianoConnectionNeeded;

  /// No description provided for @searchingAvailableKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Searching for an available keyboard'**
  String get searchingAvailableKeyboard;

  /// No description provided for @reconnectOrUseManualGuide.
  ///
  /// In en, this message translates to:
  /// **'{status}. Reconnect or use the manual guide.'**
  String reconnectOrUseManualGuide(String status);

  /// No description provided for @middleCFound.
  ///
  /// In en, this message translates to:
  /// **'Middle C found'**
  String get middleCFound;

  /// No description provided for @releaseMiddleCToContinue.
  ///
  /// In en, this message translates to:
  /// **'Release Middle C to continue'**
  String get releaseMiddleCToContinue;

  /// No description provided for @tapSameKeyInCamera.
  ///
  /// In en, this message translates to:
  /// **'Tap the same key in the camera view'**
  String get tapSameKeyInCamera;

  /// No description provided for @findMiddleC.
  ///
  /// In en, this message translates to:
  /// **'Find Middle C'**
  String get findMiddleC;

  /// No description provided for @pressWhiteKeyNearCenter.
  ///
  /// In en, this message translates to:
  /// **'Press any white key near the keyboard center'**
  String get pressWhiteKeyNearCenter;

  /// No description provided for @blackKeyPressed.
  ///
  /// In en, this message translates to:
  /// **'That was a black key. Press a nearby white key.'**
  String get blackKeyPressed;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get right;

  /// No description provided for @moveWhiteKeys.
  ///
  /// In en, this message translates to:
  /// **'Move {count, plural, =1 {1 white key} other {{count} white keys}} {direction}.'**
  String moveWhiteKeys(int count, String direction);

  /// No description provided for @pianoKeysReady.
  ///
  /// In en, this message translates to:
  /// **'Piano keys ready'**
  String get pianoKeysReady;

  /// No description provided for @checkKeyLabels.
  ///
  /// In en, this message translates to:
  /// **'Check that each label is placed on the correct key'**
  String get checkKeyLabels;

  /// No description provided for @middleCSelected.
  ///
  /// In en, this message translates to:
  /// **'Middle C selected'**
  String get middleCSelected;

  /// No description provided for @moveBackForMoreKeys.
  ///
  /// In en, this message translates to:
  /// **'Move farther back if you want to include more keys'**
  String get moveBackForMoreKeys;

  /// No description provided for @connectingToDigitalPiano.
  ///
  /// In en, this message translates to:
  /// **'Connecting to your digital piano'**
  String get connectingToDigitalPiano;

  /// No description provided for @digitalPianoNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Digital piano not connected'**
  String get digitalPianoNotConnected;

  /// No description provided for @connectPianoOrUseManualGuide.
  ///
  /// In en, this message translates to:
  /// **'Connect it to find Middle C, or use the manual guide'**
  String get connectPianoOrUseManualGuide;

  /// No description provided for @releaseMiddleCThenAlign.
  ///
  /// In en, this message translates to:
  /// **'Release it, then use this key to line up the saved shapes'**
  String get releaseMiddleCThenAlign;

  /// No description provided for @useMiddleCAsGuide.
  ///
  /// In en, this message translates to:
  /// **'Use Middle C as your guide'**
  String get useMiddleCAsGuide;

  /// No description provided for @alignSavedC4Shape.
  ///
  /// In en, this message translates to:
  /// **'Line up the saved C4 shape with this key on your piano'**
  String get alignSavedC4Shape;

  /// No description provided for @alignPianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Line up your piano setup'**
  String get alignPianoSetup;

  /// No description provided for @matchSavedShapes.
  ///
  /// In en, this message translates to:
  /// **'Match the saved shapes with the piano, then continue'**
  String get matchSavedShapes;

  /// No description provided for @pianoSetupLoaded.
  ///
  /// In en, this message translates to:
  /// **'Piano setup loaded'**
  String get pianoSetupLoaded;

  /// No description provided for @pianoSetupSaved.
  ///
  /// In en, this message translates to:
  /// **'Piano setup saved'**
  String get pianoSetupSaved;

  /// No description provided for @pianoSetupPreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'This piano setup could not be prepared'**
  String get pianoSetupPreparationFailed;

  /// No description provided for @pianoSetupDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Piano setup'**
  String get pianoSetupDefaultName;

  /// No description provided for @pianoSetupReady.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is ready to use'**
  String pianoSetupReady(String name);

  /// No description provided for @savingPianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Saving your piano setup'**
  String get savingPianoSetup;

  /// No description provided for @keepOpenWhileSavingSetup.
  ///
  /// In en, this message translates to:
  /// **'Keep this screen open until saving is complete'**
  String get keepOpenWhileSavingSetup;

  /// No description provided for @pianoSetupNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Piano setup not saved'**
  String get pianoSetupNotSaved;

  /// No description provided for @loadingPianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Loading your piano setup'**
  String get loadingPianoSetup;

  /// No description provided for @preparingSavedPianoKeys.
  ///
  /// In en, this message translates to:
  /// **'Preparing your saved piano keys'**
  String get preparingSavedPianoKeys;

  /// No description provided for @noRearCameraAvailable.
  ///
  /// In en, this message translates to:
  /// **'No rear camera is available on this device.'**
  String get noRearCameraAvailable;

  /// No description provided for @calibrationCameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'SoundSight could not open the camera. Check the camera permission and try again.'**
  String get calibrationCameraOpenFailed;

  /// No description provided for @recalibrate.
  ///
  /// In en, this message translates to:
  /// **'Recalibrate'**
  String get recalibrate;

  /// No description provided for @useMidiGuide.
  ///
  /// In en, this message translates to:
  /// **'Use MIDI guide'**
  String get useMidiGuide;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @useManualGuide.
  ///
  /// In en, this message translates to:
  /// **'Use manual guide'**
  String get useManualGuide;

  /// No description provided for @adjustVisibleKeys.
  ///
  /// In en, this message translates to:
  /// **'Adjust visible keys'**
  String get adjustVisibleKeys;

  /// No description provided for @savePianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Save piano setup'**
  String get savePianoSetup;

  /// No description provided for @setUpAgain.
  ///
  /// In en, this message translates to:
  /// **'Set up again'**
  String get setUpAgain;

  /// No description provided for @makeChanges.
  ///
  /// In en, this message translates to:
  /// **'Make changes'**
  String get makeChanges;

  /// No description provided for @useAction.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useAction;

  /// No description provided for @keysAreVisible.
  ///
  /// In en, this message translates to:
  /// **'Keys are visible'**
  String get keysAreVisible;

  /// No description provided for @pianoSetupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your piano setup. Check your internet connection and try again.'**
  String get pianoSetupSaveFailed;

  /// No description provided for @needHelpFindingMiddleC.
  ///
  /// In en, this message translates to:
  /// **'Need help finding Middle C?'**
  String get needHelpFindingMiddleC;

  /// No description provided for @middleCHelpSavedAlignment.
  ///
  /// In en, this message translates to:
  /// **'Connect your digital piano with its USB or MIDI cable before positioning the phone. SoundSight will guide you to Middle C, then you can use that key to line up the saved shapes with your piano.'**
  String get middleCHelpSavedAlignment;

  /// No description provided for @middleCHelpNewCalibration.
  ///
  /// In en, this message translates to:
  /// **'Connect your digital piano with its USB or MIDI cable before positioning the phone. After the piano keys are visible, SoundSight will guide you to Middle C.'**
  String get middleCHelpNewCalibration;

  /// No description provided for @manualGuide.
  ///
  /// In en, this message translates to:
  /// **'Manual guide'**
  String get manualGuide;

  /// No description provided for @iKnowMiddleC.
  ///
  /// In en, this message translates to:
  /// **'I know it'**
  String get iKnowMiddleC;

  /// No description provided for @connectPiano.
  ///
  /// In en, this message translates to:
  /// **'Connect piano'**
  String get connectPiano;

  /// No description provided for @digitalPianoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Digital piano not found'**
  String get digitalPianoNotFound;

  /// No description provided for @digitalPianoNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Make sure your digital piano is turned on and its cable is connected to this phone. You can also find Middle C by looking at the black keys.'**
  String get digitalPianoNotFoundDescription;

  /// No description provided for @findMiddleCManually.
  ///
  /// In en, this message translates to:
  /// **'Find Middle C manually'**
  String get findMiddleCManually;

  /// No description provided for @findMiddleCManuallyDescription.
  ///
  /// In en, this message translates to:
  /// **'Near the center of the keyboard, find a group of two black keys. Middle C, sometimes labeled C4, is the white key immediately to the left of that pair. {instruction}'**
  String findMiddleCManuallyDescription(String instruction);

  /// No description provided for @manualGuideSavedAlignment.
  ///
  /// In en, this message translates to:
  /// **'Use Middle C as a reference while positioning the phone until the shapes on screen line up with the piano keys.'**
  String get manualGuideSavedAlignment;

  /// No description provided for @manualGuideBeforeCalibration.
  ///
  /// In en, this message translates to:
  /// **'Position the phone so the piano keys are visible, then tap Middle C on the camera view when asked.'**
  String get manualGuideBeforeCalibration;

  /// No description provided for @manualGuideTapKey.
  ///
  /// In en, this message translates to:
  /// **'Tap that white key in the camera view.'**
  String get manualGuideTapKey;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @digitalPianoDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Your digital piano was disconnected'**
  String get digitalPianoDisconnected;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get searching;

  /// No description provided for @noDigitalPianoFound.
  ///
  /// In en, this message translates to:
  /// **'No digital piano found'**
  String get noDigitalPianoFound;

  /// No description provided for @connectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected: {device}'**
  String connectedDevice(String device);

  /// No description provided for @digitalPianoConnected.
  ///
  /// In en, this message translates to:
  /// **'Digital piano connected'**
  String get digitalPianoConnected;

  /// No description provided for @digitalPianoReadyForCalibration.
  ///
  /// In en, this message translates to:
  /// **'{device} is ready. Keep it connected, then position the phone over the keyboard.'**
  String digitalPianoReadyForCalibration(String device);

  /// No description provided for @digitalPianoReady.
  ///
  /// In en, this message translates to:
  /// **'{device} is ready to use.'**
  String digitalPianoReady(String device);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @songStillLoading.
  ///
  /// In en, this message translates to:
  /// **'The song is still loading. Try again.'**
  String get songStillLoading;

  /// No description provided for @noPlayableKeys.
  ///
  /// In en, this message translates to:
  /// **'no playable keys'**
  String get noPlayableKeys;

  /// No description provided for @remainingNotes.
  ///
  /// In en, this message translates to:
  /// **'{notes}, and {count} more'**
  String remainingNotes(String notes, int count);

  /// No description provided for @morePianoKeysNeeded.
  ///
  /// In en, this message translates to:
  /// **'More piano keys are needed'**
  String get morePianoKeysNeeded;

  /// No description provided for @morePianoKeysDescription.
  ///
  /// In en, this message translates to:
  /// **'This song uses notes from {requiredRange}, but the camera can currently see {calibrationRange}.\n\nKeys outside the camera view: {missingNotes}\n\nMove the phone farther back and set up the piano again, or choose another saved piano setup that shows all of these keys.'**
  String morePianoKeysDescription(
    String requiredRange,
    String calibrationRange,
    String missingNotes,
  );

  /// No description provided for @reviewPianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Review piano setup'**
  String get reviewPianoSetup;

  /// No description provided for @preparePhoneForCalibration.
  ///
  /// In en, this message translates to:
  /// **'Prepare your phone'**
  String get preparePhoneForCalibration;

  /// No description provided for @preparePhoneForCalibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up your phone before calibration so SoundSight can detect the piano accurately.'**
  String get preparePhoneForCalibrationDescription;

  /// No description provided for @mountPhoneSecurely.
  ///
  /// In en, this message translates to:
  /// **'Mount the phone securely on an arm, stand, or stable holder.'**
  String get mountPhoneSecurely;

  /// No description provided for @useLandscapeOrientation.
  ///
  /// In en, this message translates to:
  /// **'Rotate the phone to landscape orientation.'**
  String get useLandscapeOrientation;

  /// No description provided for @keepPianoKeysVisible.
  ///
  /// In en, this message translates to:
  /// **'Position the camera above the keyboard and keep all keys you plan to use visible.'**
  String get keepPianoKeysVisible;

  /// No description provided for @useClearLighting.
  ///
  /// In en, this message translates to:
  /// **'Use even lighting and avoid strong shadows or glare.'**
  String get useClearLighting;

  /// No description provided for @keepPhoneFixed.
  ///
  /// In en, this message translates to:
  /// **'Keep the phone fixed throughout calibration and practice.'**
  String get keepPhoneFixed;

  /// No description provided for @clearKeyboardBeforeDetection.
  ///
  /// In en, this message translates to:
  /// **'Remove hands and other objects while SoundSight detects the keyboard.'**
  String get clearKeyboardBeforeDetection;

  /// No description provided for @calibrationGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Calibration guide'**
  String get calibrationGuideTitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startCalibration.
  ///
  /// In en, this message translates to:
  /// **'Start calibration'**
  String get startCalibration;

  /// No description provided for @calibrationGuideImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This guide image could not be displayed.'**
  String get calibrationGuideImageUnavailable;

  /// No description provided for @calibrationGuideMountTitle.
  ///
  /// In en, this message translates to:
  /// **'Mount and position your phone'**
  String get calibrationGuideMountTitle;

  /// No description provided for @calibrationGuideMountDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure your phone to an arm, stand, or stable holder. Keep it in landscape above the keyboard, with the rear camera facing the keys. Use even lighting, avoid strong shadows, and do not move the phone during calibration.'**
  String get calibrationGuideMountDescription;

  /// No description provided for @calibrationGuideDetectedGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Review the detected key group'**
  String get calibrationGuideDetectedGroupTitle;

  /// No description provided for @calibrationGuideDetectedGroupDescription.
  ///
  /// In en, this message translates to:
  /// **'SoundSight will place a green outline around the group of keys it detected. This outlined group—not every key visible in the camera—is the area the app will use.'**
  String get calibrationGuideDetectedGroupDescription;

  /// No description provided for @calibrationGuideDetectedGroupEmphasis.
  ///
  /// In en, this message translates to:
  /// **'Do not expand the outline to cover all visible keys.'**
  String get calibrationGuideDetectedGroupEmphasis;

  /// No description provided for @calibrationGuideAdjustCornersTitle.
  ///
  /// In en, this message translates to:
  /// **'Fit the corners to that group'**
  String get calibrationGuideAdjustCornersTitle;

  /// No description provided for @calibrationGuideAdjustCornersDescription.
  ///
  /// In en, this message translates to:
  /// **'Drag each white corner so the green outline follows the four outer corners of the detected key group. Include the full length of those keys, but leave any keys outside that group out of the outline.'**
  String get calibrationGuideAdjustCornersDescription;

  /// No description provided for @calibrationGuideAdjustCornersEmphasis.
  ///
  /// In en, this message translates to:
  /// **'Outline only the group SoundSight selected.'**
  String get calibrationGuideAdjustCornersEmphasis;

  /// No description provided for @calibrationGuideMiddleCTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Middle C (C4)'**
  String get calibrationGuideMiddleCTitle;

  /// No description provided for @calibrationGuideMiddleCDescription.
  ///
  /// In en, this message translates to:
  /// **'When the key labels appear, tap C4 in the camera view. It is the white key immediately to the left of a group of two black keys near the middle of the keyboard. Check that the other labels line up before saving.'**
  String get calibrationGuideMiddleCDescription;

  /// No description provided for @pianoSetupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Piano Setup'**
  String get pianoSetupScreenTitle;

  /// No description provided for @deleteAllPianoSetupsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all piano setups'**
  String get deleteAllPianoSetupsTooltip;

  /// No description provided for @preparingSong.
  ///
  /// In en, this message translates to:
  /// **'Preparing song...'**
  String get preparingSong;

  /// No description provided for @newPianoSetup.
  ///
  /// In en, this message translates to:
  /// **'New piano setup'**
  String get newPianoSetup;

  /// No description provided for @choosePianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Choose your piano setup'**
  String get choosePianoSetup;

  /// No description provided for @savedPianoSetup.
  ///
  /// In en, this message translates to:
  /// **'Saved piano setup'**
  String get savedPianoSetup;

  /// No description provided for @pianoSetupLastSaved.
  ///
  /// In en, this message translates to:
  /// **'Last saved {date} at {time}'**
  String pianoSetupLastSaved(String date, String time);

  /// No description provided for @deletePianoSetupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete piano setup?'**
  String get deletePianoSetupQuestion;

  /// No description provided for @deletePianoSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes \"{name}\". This cannot be undone.'**
  String deletePianoSetupDescription(String name);

  /// No description provided for @pianoSetupDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" was deleted.'**
  String pianoSetupDeleted(String name);

  /// No description provided for @pianoSetupDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The piano setup could not be deleted.'**
  String get pianoSetupDeleteFailed;

  /// No description provided for @deleteAllPianoSetupsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete all piano setups?'**
  String get deleteAllPianoSetupsQuestion;

  /// No description provided for @deleteAllPianoSetupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Every saved piano setup will be permanently deleted. This cannot be undone.'**
  String get deleteAllPianoSetupsDescription;

  /// No description provided for @allPianoSetupsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All piano setups were deleted.'**
  String get allPianoSetupsDeleted;

  /// No description provided for @somePianoSetupsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Some piano setups could not be deleted.'**
  String get somePianoSetupsDeleteFailed;

  /// No description provided for @noSavedPianoSetups.
  ///
  /// In en, this message translates to:
  /// **'No saved piano setups yet'**
  String get noSavedPianoSetups;

  /// No description provided for @createPianoSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a piano setup so SoundSight knows where the keys are.'**
  String get createPianoSetupDescription;

  /// No description provided for @loadingYourPianoSetups.
  ///
  /// In en, this message translates to:
  /// **'Loading your piano setups...'**
  String get loadingYourPianoSetups;

  /// No description provided for @pianoSetupsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your piano setups.'**
  String get pianoSetupsLoadFailed;

  /// No description provided for @checkConnectionThenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection, then try again.'**
  String get checkConnectionThenTryAgain;

  /// No description provided for @songPreparationForArFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare this song for AR Practice.'**
  String get songPreparationForArFailed;

  /// No description provided for @selectedPianoSetupLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the selected piano setup.'**
  String get selectedPianoSetupLoadFailed;

  /// No description provided for @synthesiaPerformanceMode.
  ///
  /// In en, this message translates to:
  /// **'Performance Mode'**
  String get synthesiaPerformanceMode;

  /// No description provided for @synthesiaWaitMode.
  ///
  /// In en, this message translates to:
  /// **'Wait Mode'**
  String get synthesiaWaitMode;

  /// No description provided for @synthesiaPerformanceModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Play with the moving timeline while your pitch and timing are evaluated.'**
  String get synthesiaPerformanceModeDescription;

  /// No description provided for @synthesiaWaitModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice at your own pace while the timeline waits for every note or chord.'**
  String get synthesiaWaitModeDescription;

  /// No description provided for @synthesiaPerformanceDetailMovingNotes.
  ///
  /// In en, this message translates to:
  /// **'The falling notes continue moving when a note is missed.'**
  String get synthesiaPerformanceDetailMovingNotes;

  /// No description provided for @synthesiaPerformanceDetailEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Your notes, timing, chords, and held-note lengths are evaluated.'**
  String get synthesiaPerformanceDetailEvaluation;

  /// No description provided for @synthesiaPerformanceDetailSkillTiming.
  ///
  /// In en, this message translates to:
  /// **'Your timing allowance follows your current player level.'**
  String get synthesiaPerformanceDetailSkillTiming;

  /// No description provided for @synthesiaWaitDetailNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'There is no time limit while you practice.'**
  String get synthesiaWaitDetailNoTimeLimit;

  /// No description provided for @synthesiaWaitDetailHoldNotes.
  ///
  /// In en, this message translates to:
  /// **'Hold long notes while later notes and chords continue toward the line.'**
  String get synthesiaWaitDetailHoldNotes;

  /// No description provided for @synthesiaWaitDetailReleaseKeys.
  ///
  /// In en, this message translates to:
  /// **'Release each key after its falling note has been fully consumed.'**
  String get synthesiaWaitDetailReleaseKeys;

  /// No description provided for @synthesiaWaitDetailDragTimeline.
  ///
  /// In en, this message translates to:
  /// **'Drag vertically through the falling-note area to revisit another part of the score.'**
  String get synthesiaWaitDetailDragTimeline;

  /// No description provided for @synthesiaSwitchToModeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode}?'**
  String synthesiaSwitchToModeQuestion(String mode);

  /// No description provided for @synthesiaSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Switch Mode'**
  String get synthesiaSwitchMode;

  /// No description provided for @synthesiaConnectMidiKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Connect your MIDI keyboard'**
  String get synthesiaConnectMidiKeyboard;

  /// No description provided for @synthesiaPerformanceRequiresMidi.
  ///
  /// In en, this message translates to:
  /// **'Performance Mode needs your MIDI keyboard to evaluate the notes you play and their timing.'**
  String get synthesiaPerformanceRequiresMidi;

  /// No description provided for @synthesiaWaitRequiresMidi.
  ///
  /// In en, this message translates to:
  /// **'Wait Mode needs your MIDI keyboard to hear each note and move the timeline forward.'**
  String get synthesiaWaitRequiresMidi;

  /// No description provided for @synthesiaConnectMidi.
  ///
  /// In en, this message translates to:
  /// **'Connect MIDI'**
  String get synthesiaConnectMidi;

  /// No description provided for @synthesiaMidiDisconnected.
  ///
  /// In en, this message translates to:
  /// **'MIDI disconnected'**
  String get synthesiaMidiDisconnected;

  /// No description provided for @synthesiaSearchingMidiPiano.
  ///
  /// In en, this message translates to:
  /// **'Searching for MIDI piano...'**
  String get synthesiaSearchingMidiPiano;

  /// No description provided for @synthesiaNoMidiPianoDetected.
  ///
  /// In en, this message translates to:
  /// **'No MIDI piano detected'**
  String get synthesiaNoMidiPianoDetected;

  /// No description provided for @synthesiaConnectingToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}...'**
  String synthesiaConnectingToDevice(String device);

  /// No description provided for @synthesiaMidiConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'MIDI connection failed.'**
  String get synthesiaMidiConnectionFailed;

  /// No description provided for @synthesiaCouldNotConnectMidiPiano.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the MIDI piano'**
  String get synthesiaCouldNotConnectMidiPiano;

  /// No description provided for @synthesiaConnectionRestoredStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection restored. Start again when you are ready.'**
  String get synthesiaConnectionRestoredStartAgain;

  /// No description provided for @synthesiaConnectionRestoredPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection restored—play this part again.'**
  String get synthesiaConnectionRestoredPlayAgain;

  /// No description provided for @synthesiaNoMp3Preview.
  ///
  /// In en, this message translates to:
  /// **'This score has no MP3 audio preview.'**
  String get synthesiaNoMp3Preview;

  /// No description provided for @synthesiaMp3PlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'The MP3 preview could not be played.'**
  String get synthesiaMp3PlaybackFailed;

  /// No description provided for @synthesiaTryAgainHoldFullLength.
  ///
  /// In en, this message translates to:
  /// **'Try again—hold each key for its full note length.'**
  String get synthesiaTryAgainHoldFullLength;

  /// No description provided for @synthesiaTryHighlightedAgain.
  ///
  /// In en, this message translates to:
  /// **'Try the highlighted note or chord again.'**
  String get synthesiaTryHighlightedAgain;

  /// No description provided for @synthesiaReleaseMistakenNotes.
  ///
  /// In en, this message translates to:
  /// **'Release the mistaken notes, then try this part again.'**
  String get synthesiaReleaseMistakenNotes;

  /// No description provided for @synthesiaReleaseChordPressTogether.
  ///
  /// In en, this message translates to:
  /// **'Release the chord, then press its notes together.'**
  String get synthesiaReleaseChordPressTogether;

  /// No description provided for @synthesiaCorrectNotesKeepHolding.
  ///
  /// In en, this message translates to:
  /// **'Correct notes—keep holding.'**
  String get synthesiaCorrectNotesKeepHolding;

  /// No description provided for @synthesiaNoteHeldTooLong.
  ///
  /// In en, this message translates to:
  /// **'{note} was held too long'**
  String synthesiaNoteHeldTooLong(String note);

  /// No description provided for @synthesiaReleaseAllNoteHeldTooLong.
  ///
  /// In en, this message translates to:
  /// **'Release all keys—{note} was held too long.'**
  String synthesiaReleaseAllNoteHeldTooLong(String note);

  /// No description provided for @synthesiaReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release {notes}'**
  String synthesiaReleaseNotes(String notes);

  /// No description provided for @synthesiaPlayNotes.
  ///
  /// In en, this message translates to:
  /// **'Play {notes}'**
  String synthesiaPlayNotes(String notes);

  /// No description provided for @synthesiaHoldWhilePlaying.
  ///
  /// In en, this message translates to:
  /// **'Hold {heldNotes} while playing {expectedNotes}'**
  String synthesiaHoldWhilePlaying(String heldNotes, String expectedNotes);

  /// No description provided for @synthesiaGetReadyNextNote.
  ///
  /// In en, this message translates to:
  /// **'Get ready for the next note.'**
  String get synthesiaGetReadyNextNote;

  /// No description provided for @synthesiaNoteReleasedTooSoon.
  ///
  /// In en, this message translates to:
  /// **'{note} was released too soon'**
  String synthesiaNoteReleasedTooSoon(String note);

  /// No description provided for @synthesiaReleasedTooSoonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Released too soon—release all keys and try again.'**
  String get synthesiaReleasedTooSoonTryAgain;

  /// No description provided for @synthesiaReleaseAllBeforeMoving.
  ///
  /// In en, this message translates to:
  /// **'Release all keys before moving to another part.'**
  String get synthesiaReleaseAllBeforeMoving;

  /// No description provided for @synthesiaPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get synthesiaPerfect;

  /// No description provided for @synthesiaExerciseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise Completed'**
  String get synthesiaExerciseCompleted;

  /// No description provided for @synthesiaCompletedWithoutMistakes.
  ///
  /// In en, this message translates to:
  /// **'You completed the score without any mistakes.'**
  String get synthesiaCompletedWithoutMistakes;

  /// No description provided for @synthesiaCompletedWithMistakes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {You completed the score with 1 mistake. Review the detailed feedback below.} other {You completed the score with {count} mistakes. Review the detailed feedback below.}}'**
  String synthesiaCompletedWithMistakes(int count);

  /// No description provided for @synthesiaCorrectOnTime.
  ///
  /// In en, this message translates to:
  /// **'Correct on time'**
  String get synthesiaCorrectOnTime;

  /// No description provided for @synthesiaWrongNotes.
  ///
  /// In en, this message translates to:
  /// **'Wrong notes'**
  String get synthesiaWrongNotes;

  /// No description provided for @synthesiaNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Not played'**
  String get synthesiaNotPlayed;

  /// No description provided for @synthesiaPlayedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Played on time'**
  String get synthesiaPlayedOnTime;

  /// No description provided for @synthesiaMusicLength.
  ///
  /// In en, this message translates to:
  /// **'Music length'**
  String get synthesiaMusicLength;

  /// No description provided for @synthesiaCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get synthesiaCompleted;

  /// No description provided for @synthesiaFirstTry.
  ///
  /// In en, this message translates to:
  /// **'First try'**
  String get synthesiaFirstTry;

  /// No description provided for @synthesiaMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get synthesiaMistakes;

  /// No description provided for @synthesiaTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get synthesiaTime;

  /// No description provided for @synthesiaNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get synthesiaNoLimit;

  /// No description provided for @synthesiaScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get synthesiaScoreLabel;

  /// No description provided for @synthesiaSavingResult.
  ///
  /// In en, this message translates to:
  /// **'Saving Synthesia performance result...'**
  String get synthesiaSavingResult;

  /// No description provided for @synthesiaResultSaved.
  ///
  /// In en, this message translates to:
  /// **'Synthesia performance result saved'**
  String get synthesiaResultSaved;

  /// No description provided for @synthesiaResultNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The Synthesia performance result was not saved.'**
  String get synthesiaResultNotSaved;

  /// No description provided for @synthesiaRetrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get synthesiaRetrySave;

  /// No description provided for @synthesiaViewFullResult.
  ///
  /// In en, this message translates to:
  /// **'View full result'**
  String get synthesiaViewFullResult;

  /// No description provided for @synthesiaWhatToWorkOn.
  ///
  /// In en, this message translates to:
  /// **'What to work on'**
  String get synthesiaWhatToWorkOn;

  /// No description provided for @synthesiaHowToImprove.
  ///
  /// In en, this message translates to:
  /// **'How to improve'**
  String get synthesiaHowToImprove;

  /// No description provided for @synthesiaNoRepeatedProblems.
  ///
  /// In en, this message translates to:
  /// **'You did not have any repeated problems.'**
  String get synthesiaNoRepeatedProblems;

  /// No description provided for @synthesiaTroubleWithNoteTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {You had trouble with {note} 1 time.} other {You had trouble with {note} {count} times.}}'**
  String synthesiaTroubleWithNoteTimes(String note, int count);

  /// No description provided for @synthesiaGroupsReleasedEarly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 note group had notes released too soon.} other {{count} note groups had notes released too soon.}}'**
  String synthesiaGroupsReleasedEarly(int count);

  /// No description provided for @synthesiaCorrectGroupsNeedReview.
  ///
  /// In en, this message translates to:
  /// **'{correctCount} note groups were correct, and {reviewCount} need review.'**
  String synthesiaCorrectGroupsNeedReview(int correctCount, int reviewCount);

  /// No description provided for @synthesiaWaitModeNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Wait Mode is unscored practice and is not saved.'**
  String get synthesiaWaitModeNotSaved;

  /// No description provided for @synthesiaSuggestionPerfect.
  ///
  /// In en, this message translates to:
  /// **'Great job! You played every part correctly. Repeat the piece with the same control.'**
  String get synthesiaSuggestionPerfect;

  /// No description provided for @synthesiaSuggestionAlmostPerfect.
  ///
  /// In en, this message translates to:
  /// **'You were very close. Play it once more at the same speed and focus on the highlighted parts.'**
  String get synthesiaSuggestionAlmostPerfect;

  /// No description provided for @synthesiaSuggestionDifficultNote.
  ///
  /// In en, this message translates to:
  /// **'You had trouble with {note}. Practice finding that key slowly before replaying the whole piece.'**
  String synthesiaSuggestionDifficultNote(String note);

  /// No description provided for @synthesiaSuggestionReleasedTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Some notes were released too soon. Keep each key held until enough of its falling note has been consumed.'**
  String get synthesiaSuggestionReleasedTooSoon;

  /// No description provided for @synthesiaSuggestionMissedNotes.
  ///
  /// In en, this message translates to:
  /// **'Some notes reached the line before you played them. Watch one note ahead and keep a steady beat.'**
  String get synthesiaSuggestionMissedNotes;

  /// No description provided for @synthesiaSuggestionPlayedLate.
  ///
  /// In en, this message translates to:
  /// **'You often played after the beat. Look one note ahead so your fingers are ready sooner.'**
  String get synthesiaSuggestionPlayedLate;

  /// No description provided for @synthesiaSuggestionPlayedEarly.
  ///
  /// In en, this message translates to:
  /// **'You often played before the beat. Count steadily and wait for each note to reach the line.'**
  String get synthesiaSuggestionPlayedEarly;

  /// No description provided for @synthesiaSuggestionChordTiming.
  ///
  /// In en, this message translates to:
  /// **'Some chord notes were pressed separately. Practice pressing every key in each chord together.'**
  String get synthesiaSuggestionChordTiming;

  /// No description provided for @synthesiaSuggestionWrongNotes.
  ///
  /// In en, this message translates to:
  /// **'Practice the difficult passage slowly and check each key before returning to full speed.'**
  String get synthesiaSuggestionWrongNotes;

  /// No description provided for @synthesiaSuggestionGeneralPractice.
  ///
  /// In en, this message translates to:
  /// **'Play the difficult parts slowly a few times, then try the complete piece again.'**
  String get synthesiaSuggestionGeneralPractice;

  /// No description provided for @synthesiaUntitledScore.
  ///
  /// In en, this message translates to:
  /// **'Untitled score'**
  String get synthesiaUntitledScore;

  /// No description provided for @synthesiaPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing Synthesia...'**
  String get synthesiaPreparing;

  /// No description provided for @synthesiaScorePreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'The score could not be prepared.'**
  String get synthesiaScorePreparationFailed;

  /// No description provided for @synthesiaStartPerformance.
  ///
  /// In en, this message translates to:
  /// **'Start Performance'**
  String get synthesiaStartPerformance;

  /// No description provided for @synthesiaStartWaitMode.
  ///
  /// In en, this message translates to:
  /// **'Start Wait Mode'**
  String get synthesiaStartWaitMode;

  /// No description provided for @synthesiaWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get synthesiaWait;

  /// No description provided for @synthesiaPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get synthesiaPerformance;

  /// No description provided for @synthesiaControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get synthesiaControls;

  /// No description provided for @synthesiaLoadingMp3Preview.
  ///
  /// In en, this message translates to:
  /// **'Loading MP3 preview'**
  String get synthesiaLoadingMp3Preview;

  /// No description provided for @synthesiaListeningMp3Preview.
  ///
  /// In en, this message translates to:
  /// **'Listening to MP3 preview'**
  String get synthesiaListeningMp3Preview;

  /// No description provided for @synthesiaPracticeInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Practice interrupted'**
  String get synthesiaPracticeInterrupted;

  /// No description provided for @synthesiaPlayHighlightedNoteOrChord.
  ///
  /// In en, this message translates to:
  /// **'Play the highlighted note or chord'**
  String get synthesiaPlayHighlightedNoteOrChord;

  /// No description provided for @synthesiaReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get synthesiaReady;

  /// No description provided for @synthesiaFollowFallingNotes.
  ///
  /// In en, this message translates to:
  /// **'Follow the falling notes'**
  String get synthesiaFollowFallingNotes;

  /// No description provided for @synthesiaMidiOffline.
  ///
  /// In en, this message translates to:
  /// **'MIDI offline'**
  String get synthesiaMidiOffline;

  /// No description provided for @synthesiaCloseControls.
  ///
  /// In en, this message translates to:
  /// **'Close controls'**
  String get synthesiaCloseControls;

  /// No description provided for @synthesiaMidiReconnectPrompt.
  ///
  /// In en, this message translates to:
  /// **'MIDI keyboard not connected. Turn it on or reconnect it, then tap Connect MIDI to try again.'**
  String get synthesiaMidiReconnectPrompt;

  /// No description provided for @synthesiaListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get synthesiaListen;

  /// No description provided for @synthesiaConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get synthesiaConnected;

  /// No description provided for @synthesiaStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get synthesiaStart;

  /// No description provided for @synthesiaRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get synthesiaRestart;

  /// No description provided for @synthesiaReleaseAllKeysToContinue.
  ///
  /// In en, this message translates to:
  /// **'Release all keys to continue'**
  String get synthesiaReleaseAllKeysToContinue;

  /// No description provided for @synthesiaPlayedNotes.
  ///
  /// In en, this message translates to:
  /// **'{feedback} · Played: {notes}'**
  String synthesiaPlayedNotes(String feedback, String notes);

  /// No description provided for @synthesiaNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get synthesiaNone;

  /// No description provided for @synthesiaNoteGroupPosition.
  ///
  /// In en, this message translates to:
  /// **'{time} · Note group {group}'**
  String synthesiaNoteGroupPosition(String time, int group);

  /// No description provided for @synthesiaNoTimeLimitCompact.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get synthesiaNoTimeLimitCompact;

  /// No description provided for @synthesiaTargetDuration.
  ///
  /// In en, this message translates to:
  /// **'Target {duration}'**
  String synthesiaTargetDuration(String duration);

  /// No description provided for @synthesiaNoNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available'**
  String get synthesiaNoNotesAvailable;

  /// No description provided for @synthesiaTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early'**
  String get synthesiaTooEarly;

  /// No description provided for @synthesiaTooLate.
  ///
  /// In en, this message translates to:
  /// **'Too late'**
  String get synthesiaTooLate;

  /// No description provided for @synthesiaWrongNote.
  ///
  /// In en, this message translates to:
  /// **'Wrong note'**
  String get synthesiaWrongNote;

  /// No description provided for @synthesiaCompleteChord.
  ///
  /// In en, this message translates to:
  /// **'Complete the chord'**
  String get synthesiaCompleteChord;

  /// No description provided for @synthesiaChordNotesNotTogether.
  ///
  /// In en, this message translates to:
  /// **'Chord notes were not together'**
  String get synthesiaChordNotesNotTogether;

  /// No description provided for @synthesiaCorrectAfterMistake.
  ///
  /// In en, this message translates to:
  /// **'Correct after mistake'**
  String get synthesiaCorrectAfterMistake;

  /// No description provided for @synthesiaCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get synthesiaCorrect;

  /// No description provided for @synthesiaReleasedTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Released too soon'**
  String get synthesiaReleasedTooSoon;

  /// No description provided for @synthesiaDurationComplete.
  ///
  /// In en, this message translates to:
  /// **'Duration complete'**
  String get synthesiaDurationComplete;

  /// No description provided for @synthesiaTimingMissed.
  ///
  /// In en, this message translates to:
  /// **'Timing missed'**
  String get synthesiaTimingMissed;

  /// No description provided for @synthesiaWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get synthesiaWrong;

  /// No description provided for @synthesiaMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get synthesiaMissed;

  /// No description provided for @sightReadingWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get sightReadingWait;

  /// No description provided for @sightReadingPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get sightReadingPerformance;

  /// No description provided for @sightReadingControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get sightReadingControls;

  /// No description provided for @sightReadingPreparingProgress.
  ///
  /// In en, this message translates to:
  /// **'Preparing progress'**
  String get sightReadingPreparingProgress;

  /// No description provided for @sightReadingPerformanceMode.
  ///
  /// In en, this message translates to:
  /// **'Performance Mode'**
  String get sightReadingPerformanceMode;

  /// No description provided for @sightReadingWaitMode.
  ///
  /// In en, this message translates to:
  /// **'Wait Mode'**
  String get sightReadingWaitMode;

  /// No description provided for @sightReadingPerformanceModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Press Start, then begin when you are ready by playing any MIDI key.'**
  String get sightReadingPerformanceModeDescription;

  /// No description provided for @sightReadingWaitModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice at your own pace while learning how long to hold each note.'**
  String get sightReadingWaitModeDescription;

  /// No description provided for @sightReadingPerformanceDetailNoPause.
  ///
  /// In en, this message translates to:
  /// **'The score does not pause when a note is missed.'**
  String get sightReadingPerformanceDetailNoPause;

  /// No description provided for @sightReadingPerformanceDetailEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Your notes and timing are evaluated against the MIDI timeline.'**
  String get sightReadingPerformanceDetailEvaluation;

  /// No description provided for @sightReadingPerformanceDetailFirstKey.
  ///
  /// In en, this message translates to:
  /// **'Your first key starts the timeline and is evaluated, whether it is correct or wrong.'**
  String get sightReadingPerformanceDetailFirstKey;

  /// No description provided for @sightReadingWaitDetailNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'There is no time limit while you practice.'**
  String get sightReadingWaitDetailNoTimeLimit;

  /// No description provided for @sightReadingWaitDetailHoldLength.
  ///
  /// In en, this message translates to:
  /// **'Hold each key for its written length, then release it when prompted.'**
  String get sightReadingWaitDetailHoldLength;

  /// No description provided for @sightReadingWaitDetailContinuedNotes.
  ///
  /// In en, this message translates to:
  /// **'Some notes continue across later notes; releasing early returns the cursor so you can retry.'**
  String get sightReadingWaitDetailContinuedNotes;

  /// No description provided for @sightReadingSwitchToModeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode}?'**
  String sightReadingSwitchToModeQuestion(String mode);

  /// No description provided for @sightReadingSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Switch Mode'**
  String get sightReadingSwitchMode;

  /// No description provided for @sightReadingConnectMidiKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Connect your MIDI keyboard'**
  String get sightReadingConnectMidiKeyboard;

  /// No description provided for @sightReadingPerformanceRequiresMidi.
  ///
  /// In en, this message translates to:
  /// **'Performance Mode needs your MIDI keyboard to hear the notes you play. Connect it now, then press any key when you are ready to begin.'**
  String get sightReadingPerformanceRequiresMidi;

  /// No description provided for @sightReadingWaitRequiresMidi.
  ///
  /// In en, this message translates to:
  /// **'Wait Mode needs your MIDI keyboard to hear each note and move the cursor forward.'**
  String get sightReadingWaitRequiresMidi;

  /// No description provided for @sightReadingConnectMidi.
  ///
  /// In en, this message translates to:
  /// **'Connect MIDI'**
  String get sightReadingConnectMidi;

  /// No description provided for @sightReadingStartPerformance.
  ///
  /// In en, this message translates to:
  /// **'Start Performance'**
  String get sightReadingStartPerformance;

  /// No description provided for @sightReadingPlayedNotes.
  ///
  /// In en, this message translates to:
  /// **'{feedback} · Played: {notes}'**
  String sightReadingPlayedNotes(String feedback, String notes);

  /// No description provided for @sightReadingHintPlay.
  ///
  /// In en, this message translates to:
  /// **'Hint: play {notes}'**
  String sightReadingHintPlay(String notes);

  /// No description provided for @sightReadingPreparingScore.
  ///
  /// In en, this message translates to:
  /// **'Preparing your score'**
  String get sightReadingPreparingScore;

  /// No description provided for @sightReadingLoadingNotationTimingAudio.
  ///
  /// In en, this message translates to:
  /// **'Loading notation, timing, and audio...'**
  String get sightReadingLoadingNotationTimingAudio;

  /// No description provided for @sightReadingCouldNotPrepareScore.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare this score'**
  String get sightReadingCouldNotPrepareScore;

  /// No description provided for @sightReadingUnknownLoadError.
  ///
  /// In en, this message translates to:
  /// **'An unknown score-loading problem occurred.'**
  String get sightReadingUnknownLoadError;

  /// No description provided for @sightReadingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get sightReadingTryAgain;

  /// No description provided for @sightReadingPressAnyMidiKey.
  ///
  /// In en, this message translates to:
  /// **'Press any MIDI key to begin'**
  String get sightReadingPressAnyMidiKey;

  /// No description provided for @sightReadingNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sightReadingNone;

  /// No description provided for @sightReadingWaitingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get sightReadingWaitingEllipsis;

  /// No description provided for @sightReadingPlayedWithHint.
  ///
  /// In en, this message translates to:
  /// **'Played: {playedNotes} · Hint: play {expectedNotes}'**
  String sightReadingPlayedWithHint(String playedNotes, String expectedNotes);

  /// No description provided for @sightReadingPlayed.
  ///
  /// In en, this message translates to:
  /// **'Played: {notes}'**
  String sightReadingPlayed(String notes);

  /// No description provided for @sightReadingCloseControls.
  ///
  /// In en, this message translates to:
  /// **'Close controls'**
  String get sightReadingCloseControls;

  /// No description provided for @sightReadingMidiReconnectPrompt.
  ///
  /// In en, this message translates to:
  /// **'MIDI keyboard not connected. Turn it on or reconnect it, then tap Connect MIDI to try again.'**
  String get sightReadingMidiReconnectPrompt;

  /// No description provided for @sightReadingListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get sightReadingListen;

  /// No description provided for @sightReadingFollowCursor.
  ///
  /// In en, this message translates to:
  /// **'Follow the moving cursor'**
  String get sightReadingFollowCursor;

  /// No description provided for @sightReadingStartWhenMidiReady.
  ///
  /// In en, this message translates to:
  /// **'Start when your MIDI keyboard is ready'**
  String get sightReadingStartWhenMidiReady;

  /// No description provided for @sightReadingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get sightReadingPlaying;

  /// No description provided for @sightReadingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get sightReadingWaiting;

  /// No description provided for @sightReadingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get sightReadingStart;

  /// No description provided for @sightReadingHoldUntilCursor.
  ///
  /// In en, this message translates to:
  /// **'Hold until the cursor arrives'**
  String get sightReadingHoldUntilCursor;

  /// No description provided for @sightReadingComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get sightReadingComposition;

  /// No description provided for @sightReadingMusicSheet.
  ///
  /// In en, this message translates to:
  /// **'Music Sheet'**
  String get sightReadingMusicSheet;

  /// No description provided for @sightReadingNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get sightReadingNoTimeLimit;

  /// No description provided for @sightReadingReadingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Reading timeline...'**
  String get sightReadingReadingTimeline;

  /// No description provided for @sightReadingTimelineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Timeline unavailable'**
  String get sightReadingTimelineUnavailable;

  /// No description provided for @sightReadingTargetDuration.
  ///
  /// In en, this message translates to:
  /// **'Target {duration}'**
  String sightReadingTargetDuration(String duration);

  /// No description provided for @sightReadingPressAnyKeyToStart.
  ///
  /// In en, this message translates to:
  /// **'Press any key to start'**
  String get sightReadingPressAnyKeyToStart;

  /// No description provided for @sightReadingConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get sightReadingConnected;

  /// No description provided for @sightReadingSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get sightReadingSearching;

  /// No description provided for @sightReadingConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get sightReadingConnecting;

  /// No description provided for @sightReadingConnectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected: {device}'**
  String sightReadingConnectedDevice(String device);

  /// No description provided for @sightReadingSearchingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get sightReadingSearchingEllipsis;

  /// No description provided for @sightReadingConnectingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get sightReadingConnectingEllipsis;

  /// No description provided for @sightReadingNoDeviceDetected.
  ///
  /// In en, this message translates to:
  /// **'No device detected'**
  String get sightReadingNoDeviceDetected;

  /// No description provided for @sightReadingConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get sightReadingConnectionFailed;

  /// No description provided for @sightReadingNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get sightReadingNotConnected;

  /// No description provided for @sightReadingNoMp3Preview.
  ///
  /// In en, this message translates to:
  /// **'The score has no MP3 audio preview.'**
  String get sightReadingNoMp3Preview;

  /// No description provided for @sightReadingPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'The score preview could not be played.'**
  String get sightReadingPlaybackFailed;

  /// No description provided for @sightReadingMusicXmlMissing.
  ///
  /// In en, this message translates to:
  /// **'The MusicXML file is missing.'**
  String get sightReadingMusicXmlMissing;

  /// No description provided for @sightReadingMusicXmlDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The MusicXML file could not be downloaded.'**
  String get sightReadingMusicXmlDownloadFailed;

  /// No description provided for @sightReadingScoreLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The score could not be loaded.'**
  String get sightReadingScoreLoadFailed;

  /// No description provided for @sightReadingScorePreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'The MusicXML could not be prepared for Sight Reading.'**
  String get sightReadingScorePreparationFailed;

  /// No description provided for @sightReadingMidiFileMissing.
  ///
  /// In en, this message translates to:
  /// **'The challenge has no MIDI file.'**
  String get sightReadingMidiFileMissing;

  /// No description provided for @sightReadingMidiTimelineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The MIDI timeline could not be loaded.'**
  String get sightReadingMidiTimelineUnavailable;

  /// No description provided for @sightReadingUntitledScore.
  ///
  /// In en, this message translates to:
  /// **'Untitled score'**
  String get sightReadingUntitledScore;

  /// No description provided for @sightReadingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get sightReadingReady;

  /// No description provided for @sightReadingWaitingForMidi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for MIDI file'**
  String get sightReadingWaitingForMidi;

  /// No description provided for @sightReadingPlayOnTime.
  ///
  /// In en, this message translates to:
  /// **'Play on time'**
  String get sightReadingPlayOnTime;

  /// No description provided for @sightReadingMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get sightReadingMissed;

  /// No description provided for @sightReadingWrongNote.
  ///
  /// In en, this message translates to:
  /// **'Wrong note'**
  String get sightReadingWrongNote;

  /// No description provided for @sightReadingCompleteChord.
  ///
  /// In en, this message translates to:
  /// **'Complete the chord'**
  String get sightReadingCompleteChord;

  /// No description provided for @sightReadingChordNotesNotTogether.
  ///
  /// In en, this message translates to:
  /// **'Chord notes were not together'**
  String get sightReadingChordNotesNotTogether;

  /// No description provided for @sightReadingCorrectAfterMistake.
  ///
  /// In en, this message translates to:
  /// **'Correct after mistake'**
  String get sightReadingCorrectAfterMistake;

  /// No description provided for @sightReadingCorrectNotesKeepHolding.
  ///
  /// In en, this message translates to:
  /// **'Correct notes—keep holding'**
  String get sightReadingCorrectNotesKeepHolding;

  /// No description provided for @sightReadingCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get sightReadingCorrect;

  /// No description provided for @sightReadingReleasedTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Released too soon'**
  String get sightReadingReleasedTooSoon;

  /// No description provided for @sightReadingTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early'**
  String get sightReadingTooEarly;

  /// No description provided for @sightReadingTooLate.
  ///
  /// In en, this message translates to:
  /// **'Too late'**
  String get sightReadingTooLate;

  /// No description provided for @sightReadingWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get sightReadingWrong;

  /// No description provided for @sightReadingKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get sightReadingKeepPlaying;

  /// No description provided for @sightReadingDurationComplete.
  ///
  /// In en, this message translates to:
  /// **'Duration complete'**
  String get sightReadingDurationComplete;

  /// No description provided for @sightReadingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get sightReadingCompleted;

  /// No description provided for @sightReadingKeepHolding.
  ///
  /// In en, this message translates to:
  /// **'Keep holding · {percentage}%'**
  String sightReadingKeepHolding(int percentage);

  /// No description provided for @sightReadingReleaseBeforePlayingAgain.
  ///
  /// In en, this message translates to:
  /// **'Release {note} before playing it again'**
  String sightReadingReleaseBeforePlayingAgain(String note);

  /// No description provided for @sightReadingReleaseHeldTooLong.
  ///
  /// In en, this message translates to:
  /// **'Release {notes}—held too long'**
  String sightReadingReleaseHeldTooLong(String notes);

  /// No description provided for @sightReadingNoteHeldTooLong.
  ///
  /// In en, this message translates to:
  /// **'{note} was held too long'**
  String sightReadingNoteHeldTooLong(String note);

  /// No description provided for @sightReadingNoteReleasedTooSoon.
  ///
  /// In en, this message translates to:
  /// **'{note} was released too soon'**
  String sightReadingNoteReleasedTooSoon(String note);

  /// No description provided for @sightReadingHoldWhilePlayingNext.
  ///
  /// In en, this message translates to:
  /// **'Hold {notes} while playing the next notes'**
  String sightReadingHoldWhilePlayingNext(String notes);

  /// No description provided for @sightReadingHoldWhilePlaying.
  ///
  /// In en, this message translates to:
  /// **'Hold {heldNotes} while playing {expectedNotes}'**
  String sightReadingHoldWhilePlaying(String heldNotes, String expectedNotes);

  /// No description provided for @sightReadingReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release {notes}'**
  String sightReadingReleaseNotes(String notes);

  /// No description provided for @sightReadingReleasedContinue.
  ///
  /// In en, this message translates to:
  /// **'Released—continue with the highlighted note'**
  String get sightReadingReleasedContinue;

  /// No description provided for @sightReadingTryAgainHoldUntilCursor.
  ///
  /// In en, this message translates to:
  /// **'Try again—hold until the cursor reaches the next note'**
  String get sightReadingTryAgainHoldUntilCursor;

  /// No description provided for @sightReadingWaitModeNoXp.
  ///
  /// In en, this message translates to:
  /// **'Wait Mode does not award XP.'**
  String get sightReadingWaitModeNoXp;

  /// No description provided for @sightReadingLessonNoXp.
  ///
  /// In en, this message translates to:
  /// **'This lesson does not award XP.'**
  String get sightReadingLessonNoXp;

  /// No description provided for @sightReadingNoXpImperfect.
  ///
  /// In en, this message translates to:
  /// **'No XP awarded. Complete Performance Mode without mistakes.'**
  String get sightReadingNoXpImperfect;

  /// No description provided for @sightReadingProgressSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Progress could not be saved. Please try again.'**
  String get sightReadingProgressSaveFailed;

  /// No description provided for @sightReadingAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Already completed. XP is only awarded once.'**
  String get sightReadingAlreadyCompleted;

  /// No description provided for @sightReadingRetryRequired.
  ///
  /// In en, this message translates to:
  /// **'Retry Required'**
  String get sightReadingRetryRequired;

  /// No description provided for @sightReadingRetryRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'A hint was shown during this attempt. Please retry and complete the score without reaching five consecutive mistakes.'**
  String get sightReadingRetryRequiredDescription;

  /// No description provided for @sightReadingPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get sightReadingPerfect;

  /// No description provided for @sightReadingPerfectDescription.
  ///
  /// In en, this message translates to:
  /// **'You completed the score without any mistakes or hints.'**
  String get sightReadingPerfectDescription;

  /// No description provided for @sightReadingExerciseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise Completed'**
  String get sightReadingExerciseCompleted;

  /// No description provided for @sightReadingCompletedWithMistakes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {You completed the score with 1 mistake. Review the detailed feedback below.} other {You completed the score with {count} mistakes. Review the detailed feedback below.}}'**
  String sightReadingCompletedWithMistakes(int count);

  /// No description provided for @sightReadingWaitCompletedWithMistakes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {You completed the score with 1 mistake, but you did not need a hint.} other {You completed the score with {count} mistakes, but you did not need a hint.}}'**
  String sightReadingWaitCompletedWithMistakes(int count);

  /// No description provided for @sightReadingCorrectOnTime.
  ///
  /// In en, this message translates to:
  /// **'Correct on time'**
  String get sightReadingCorrectOnTime;

  /// No description provided for @sightReadingWrongNotes.
  ///
  /// In en, this message translates to:
  /// **'Wrong notes'**
  String get sightReadingWrongNotes;

  /// No description provided for @sightReadingNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Not played'**
  String get sightReadingNotPlayed;

  /// No description provided for @sightReadingPlayedOnTime.
  ///
  /// In en, this message translates to:
  /// **'Played on time'**
  String get sightReadingPlayedOnTime;

  /// No description provided for @sightReadingMusicLength.
  ///
  /// In en, this message translates to:
  /// **'Music length'**
  String get sightReadingMusicLength;

  /// No description provided for @sightReadingFirstTry.
  ///
  /// In en, this message translates to:
  /// **'First try'**
  String get sightReadingFirstTry;

  /// No description provided for @sightReadingMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get sightReadingMistakes;

  /// No description provided for @sightReadingHintUsed.
  ///
  /// In en, this message translates to:
  /// **'Hint used'**
  String get sightReadingHintUsed;

  /// No description provided for @sightReadingYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get sightReadingYes;

  /// No description provided for @sightReadingNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get sightReadingNo;

  /// No description provided for @sightReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get sightReadingTime;

  /// No description provided for @sightReadingNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get sightReadingNoLimit;

  /// No description provided for @sightReadingScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get sightReadingScoreLabel;

  /// No description provided for @sightReadingWhatToWorkOn.
  ///
  /// In en, this message translates to:
  /// **'What to work on'**
  String get sightReadingWhatToWorkOn;

  /// No description provided for @sightReadingHowToImprove.
  ///
  /// In en, this message translates to:
  /// **'How to improve'**
  String get sightReadingHowToImprove;

  /// No description provided for @sightReadingNoRepeatedProblems.
  ///
  /// In en, this message translates to:
  /// **'You did not have any repeated problems.'**
  String get sightReadingNoRepeatedProblems;

  /// No description provided for @sightReadingClefDifficulty.
  ///
  /// In en, this message translates to:
  /// **'{clef} was difficult in {errorCount} of {totalCount} note groups.'**
  String sightReadingClefDifficulty(
    String clef,
    int errorCount,
    int totalCount,
  );

  /// No description provided for @sightReadingTroubleWithNoteTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {You had trouble with {note} 1 time.} other {You had trouble with {note} {count} times.}}'**
  String sightReadingTroubleWithNoteTimes(String note, int count);

  /// No description provided for @sightReadingWrongAndMissedGroups.
  ///
  /// In en, this message translates to:
  /// **'{wrongCount} note groups had wrong keys, and {missedCount} were not played.'**
  String sightReadingWrongAndMissedGroups(int wrongCount, int missedCount);

  /// No description provided for @sightReadingSavingResult.
  ///
  /// In en, this message translates to:
  /// **'Saving this practice result...'**
  String get sightReadingSavingResult;

  /// No description provided for @sightReadingResultSaved.
  ///
  /// In en, this message translates to:
  /// **'Practice result saved'**
  String get sightReadingResultSaved;

  /// No description provided for @sightReadingResultNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Result not saved'**
  String get sightReadingResultNotSaved;

  /// No description provided for @sightReadingRetrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get sightReadingRetrySave;

  /// No description provided for @sightReadingViewFullResult.
  ///
  /// In en, this message translates to:
  /// **'View full result'**
  String get sightReadingViewFullResult;

  /// No description provided for @sightReadingTrebleClefDescription.
  ///
  /// In en, this message translates to:
  /// **'Higher-note reading (treble clef)'**
  String get sightReadingTrebleClefDescription;

  /// No description provided for @sightReadingBassClefDescription.
  ///
  /// In en, this message translates to:
  /// **'Lower-note reading (bass clef)'**
  String get sightReadingBassClefDescription;

  /// No description provided for @sightReadingUnknownClefDescription.
  ///
  /// In en, this message translates to:
  /// **'One part of the score'**
  String get sightReadingUnknownClefDescription;

  /// No description provided for @sightReadingOtherClefDescription.
  ///
  /// In en, this message translates to:
  /// **'{clef} clef reading'**
  String sightReadingOtherClefDescription(String clef);

  /// No description provided for @sightReadingSuggestionPerfect.
  ///
  /// In en, this message translates to:
  /// **'Great job! You played every part correctly. Try the same piece a little faster when you feel ready.'**
  String get sightReadingSuggestionPerfect;

  /// No description provided for @sightReadingSuggestionAlmostPerfect.
  ///
  /// In en, this message translates to:
  /// **'You were very close. Play it once more at the same speed, then try it a little faster.'**
  String get sightReadingSuggestionAlmostPerfect;

  /// No description provided for @sightReadingSuggestionBassClef.
  ///
  /// In en, this message translates to:
  /// **'The lower notes in the bass clef were difficult. Practice the left-hand part slowly by itself first.'**
  String get sightReadingSuggestionBassClef;

  /// No description provided for @sightReadingSuggestionTrebleClef.
  ///
  /// In en, this message translates to:
  /// **'The higher notes in the treble clef were difficult. Practice the right-hand part slowly by itself first.'**
  String get sightReadingSuggestionTrebleClef;

  /// No description provided for @sightReadingSuggestionOtherClef.
  ///
  /// In en, this message translates to:
  /// **'The {clef} clef was difficult. Practice that part slowly before playing the whole piece again.'**
  String sightReadingSuggestionOtherClef(String clef);

  /// No description provided for @sightReadingSuggestionDifficultNote.
  ///
  /// In en, this message translates to:
  /// **'You had trouble finding {note}. Practice finding that key slowly, then play it with the notes beside it.'**
  String sightReadingSuggestionDifficultNote(String note);

  /// No description provided for @sightReadingSuggestionReleasedTooSoon.
  ///
  /// In en, this message translates to:
  /// **'Some notes were released too soon. Keep each key held until its full note value is finished.'**
  String get sightReadingSuggestionReleasedTooSoon;

  /// No description provided for @sightReadingSuggestionMissedNotes.
  ///
  /// In en, this message translates to:
  /// **'Some notes passed before you played them. Slow the piece down and count the beat aloud while you practice.'**
  String get sightReadingSuggestionMissedNotes;

  /// No description provided for @sightReadingSuggestionPlayedLate.
  ///
  /// In en, this message translates to:
  /// **'You often played after the beat. Slow down and look one note ahead so your fingers are ready sooner.'**
  String get sightReadingSuggestionPlayedLate;

  /// No description provided for @sightReadingSuggestionPlayedEarly.
  ///
  /// In en, this message translates to:
  /// **'You often played before the beat. Count steadily and wait for the beat before pressing the key.'**
  String get sightReadingSuggestionPlayedEarly;

  /// No description provided for @sightReadingSuggestionChordTiming.
  ///
  /// In en, this message translates to:
  /// **'Some notes in a chord were pressed at different times. Practice pressing all the chord keys together, one hand at a time.'**
  String get sightReadingSuggestionChordTiming;

  /// No description provided for @sightReadingSuggestionGeneralPractice.
  ///
  /// In en, this message translates to:
  /// **'Play the difficult parts slowly a few times, then try the whole piece again at its normal speed.'**
  String get sightReadingSuggestionGeneralPractice;

  /// No description provided for @arPracticePianoPractice.
  ///
  /// In en, this message translates to:
  /// **'Piano practice'**
  String get arPracticePianoPractice;

  /// No description provided for @arPracticeConnectMidiPiano.
  ///
  /// In en, this message translates to:
  /// **'Connect MIDI piano'**
  String get arPracticeConnectMidiPiano;

  /// No description provided for @arPracticeStopWarning.
  ///
  /// In en, this message translates to:
  /// **'Stop returns to the ready screen so you can change modes. This unfinished attempt will not be saved.'**
  String get arPracticeStopWarning;

  /// No description provided for @arPracticeDisconnectedDescription.
  ///
  /// In en, this message translates to:
  /// **'Practice has stopped so disconnected time and missed notes will not count against you.'**
  String get arPracticeDisconnectedDescription;

  /// No description provided for @arPracticeEndAttempt.
  ///
  /// In en, this message translates to:
  /// **'End attempt'**
  String get arPracticeEndAttempt;

  /// No description provided for @arPracticeReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get arPracticeReconnecting;

  /// No description provided for @arPracticeReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get arPracticeReconnect;

  /// No description provided for @arPracticeReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reconnect. Check the cable and piano, then try again.'**
  String get arPracticeReconnectFailed;

  /// No description provided for @arPracticeSwitchToModeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Switch to {mode}?'**
  String arPracticeSwitchToModeQuestion(String mode);

  /// No description provided for @arPracticeWaitModeDescription.
  ///
  /// In en, this message translates to:
  /// **'In Wait Mode, each falling note pauses at the hit line until you play the correct key or chord, hold it for the shown length, and release it. There is no timing pressure before you press the notes.\n\nSwitching modes will reset the current attempt.'**
  String get arPracticeWaitModeDescription;

  /// No description provided for @arPracticePerformanceModeDescription.
  ///
  /// In en, this message translates to:
  /// **'In Performance Mode, the falling notes continue moving with the song. Pitch, timing, and how long you hold each key are evaluated.\n\nSwitching modes will reset the current attempt.'**
  String get arPracticePerformanceModeDescription;

  /// No description provided for @arPracticeSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Switch mode'**
  String get arPracticeSwitchMode;

  /// No description provided for @arPracticeConnectionRestoredTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection restored—play this part again'**
  String get arPracticeConnectionRestoredTryAgain;

  /// No description provided for @arPracticeTryAgainFullLength.
  ///
  /// In en, this message translates to:
  /// **'Try again—hold each key for its full note length'**
  String get arPracticeTryAgainFullLength;

  /// No description provided for @arPracticeSavingResult.
  ///
  /// In en, this message translates to:
  /// **'Saving AR performance result...'**
  String get arPracticeSavingResult;

  /// No description provided for @arPracticeResultSaved.
  ///
  /// In en, this message translates to:
  /// **'AR performance result saved'**
  String get arPracticeResultSaved;

  /// No description provided for @arPracticeResultNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The AR performance result was not saved.'**
  String get arPracticeResultNotSaved;

  /// No description provided for @practiceResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Results'**
  String get practiceResultsTitle;

  /// No description provided for @practiceResultsDeleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all practice results'**
  String get practiceResultsDeleteAllTooltip;

  /// No description provided for @practiceResultsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view practice results'**
  String get practiceResultsSignIn;

  /// No description provided for @practiceResultsSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Completed Performance attempts will appear here.'**
  String get practiceResultsSignInDescription;

  /// No description provided for @practiceResultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Results could not be loaded'**
  String get practiceResultsLoadFailed;

  /// No description provided for @practiceResultsCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get practiceResultsCheckConnection;

  /// No description provided for @practiceResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practice results yet'**
  String get practiceResultsEmpty;

  /// No description provided for @practiceResultsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete a score in Performance Mode to create your first result.'**
  String get practiceResultsEmptyDescription;

  /// No description provided for @practiceResultsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by piece title'**
  String get practiceResultsSearchHint;

  /// No description provided for @practiceResultsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get practiceResultsClearSearch;

  /// No description provided for @practiceResultsAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get practiceResultsAll;

  /// No description provided for @practiceResultsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get practiceResultsFilters;

  /// No description provided for @practiceResultsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching results'**
  String get practiceResultsNoMatches;

  /// No description provided for @practiceResultsNoMatchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search or filters.'**
  String get practiceResultsNoMatchesDescription;

  /// No description provided for @practiceResultsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get practiceResultsClearFilters;

  /// No description provided for @practiceResultsFilterAndSort.
  ///
  /// In en, this message translates to:
  /// **'Filter and sort'**
  String get practiceResultsFilterAndSort;

  /// No description provided for @practiceResultsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get practiceResultsClearAll;

  /// No description provided for @practiceResultsCloseFilters.
  ///
  /// In en, this message translates to:
  /// **'Close filters'**
  String get practiceResultsCloseFilters;

  /// No description provided for @practiceResultsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get practiceResultsDate;

  /// No description provided for @practiceResultsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get practiceResultsAccuracy;

  /// No description provided for @practiceResultsSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get practiceResultsSource;

  /// No description provided for @practiceResultsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get practiceResultsSortBy;

  /// No description provided for @practiceResultsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get practiceResultsReset;

  /// No description provided for @practiceResultsApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get practiceResultsApplyFilters;

  /// No description provided for @practiceResultsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get practiceResultsAllTime;

  /// No description provided for @practiceResultsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get practiceResultsToday;

  /// No description provided for @practiceResultsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get practiceResultsLast7Days;

  /// No description provided for @practiceResultsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get practiceResultsLast30Days;

  /// No description provided for @practiceResultsAllScores.
  ///
  /// In en, this message translates to:
  /// **'All scores'**
  String get practiceResultsAllScores;

  /// No description provided for @practiceResultsBelow75.
  ///
  /// In en, this message translates to:
  /// **'Below 75%'**
  String get practiceResultsBelow75;

  /// No description provided for @practiceResultsAllSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get practiceResultsAllSources;

  /// No description provided for @practiceResultsMusicSheet.
  ///
  /// In en, this message translates to:
  /// **'Music Sheet'**
  String get practiceResultsMusicSheet;

  /// No description provided for @practiceResultsLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get practiceResultsLesson;

  /// No description provided for @practiceResultsComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get practiceResultsComposition;

  /// No description provided for @practiceResultsChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get practiceResultsChallenge;

  /// No description provided for @practiceResultsNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get practiceResultsNewestFirst;

  /// No description provided for @practiceResultsOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get practiceResultsOldestFirst;

  /// No description provided for @practiceResultsHighestAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Highest accuracy'**
  String get practiceResultsHighestAccuracy;

  /// No description provided for @practiceResultsLowestAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Lowest accuracy'**
  String get practiceResultsLowestAccuracy;

  /// No description provided for @practiceResultsSightReading.
  ///
  /// In en, this message translates to:
  /// **'SIGHT READING'**
  String get practiceResultsSightReading;

  /// No description provided for @practiceResultsSynthesia.
  ///
  /// In en, this message translates to:
  /// **'SYNTHESIA'**
  String get practiceResultsSynthesia;

  /// No description provided for @practiceResultsArPerformance.
  ///
  /// In en, this message translates to:
  /// **'AR PERFORMANCE'**
  String get practiceResultsArPerformance;

  /// No description provided for @practiceResultsGeneralSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Practice the difficult parts slowly, then play the piece again.'**
  String get practiceResultsGeneralSuggestion;

  /// No description provided for @practiceResultsCardMetadata.
  ///
  /// In en, this message translates to:
  /// **'{source} · {date} · Score {score}'**
  String practiceResultsCardMetadata(String source, String date, String score);

  /// No description provided for @practiceResultsWrongNotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 wrong note} other {{count} wrong notes}}'**
  String practiceResultsWrongNotesCount(int count);

  /// No description provided for @practiceResultsNotPlayedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 not played} other {{count} not played}}'**
  String practiceResultsNotPlayedCount(int count);

  /// No description provided for @practiceResultsDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete practice result?'**
  String get practiceResultsDeleteQuestion;

  /// No description provided for @practiceResultsDeleteDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes the result for \"{title}\" and its detailed note review. This cannot be undone.'**
  String practiceResultsDeleteDescription(String title);

  /// No description provided for @practiceResultsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The practice result could not be deleted.'**
  String get practiceResultsDeleteFailed;

  /// No description provided for @practiceResultsDeleteAllQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete all practice results?'**
  String get practiceResultsDeleteAllQuestion;

  /// No description provided for @practiceResultsDeleteAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Every saved practice result and its detailed note review will be permanently deleted. This cannot be undone.'**
  String get practiceResultsDeleteAllDescription;

  /// No description provided for @practiceResultsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get practiceResultsDeleteAll;

  /// No description provided for @practiceResultsDeleteAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All practice results were deleted.'**
  String get practiceResultsDeleteAllSuccess;

  /// No description provided for @practiceResultsDeleteAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Some practice results could not be deleted.'**
  String get practiceResultsDeleteAllFailed;

  /// No description provided for @practiceResultsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get practiceResultsJustNow;

  /// No description provided for @practiceResultsPracticeHigherNotes.
  ///
  /// In en, this message translates to:
  /// **'Practice higher notes'**
  String get practiceResultsPracticeHigherNotes;

  /// No description provided for @practiceResultsPracticeLowerNotes.
  ///
  /// In en, this message translates to:
  /// **'Practice lower notes'**
  String get practiceResultsPracticeLowerNotes;

  /// No description provided for @practiceResultsPracticeClef.
  ///
  /// In en, this message translates to:
  /// **'Practice the {clef} clef'**
  String practiceResultsPracticeClef(String clef);

  /// No description provided for @practiceResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Result'**
  String get practiceResultTitle;

  /// No description provided for @practiceResultPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get practiceResultPerformance;

  /// No description provided for @practiceResultSummaryMetadata.
  ///
  /// In en, this message translates to:
  /// **'{source} · {mode} · {date}'**
  String practiceResultSummaryMetadata(String source, String mode, String date);

  /// No description provided for @practiceResultPlayedOnTimePercent.
  ///
  /// In en, this message translates to:
  /// **'{percentage}% played on time'**
  String practiceResultPlayedOnTimePercent(int percentage);

  /// No description provided for @practiceResultCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get practiceResultCorrect;

  /// No description provided for @practiceResultWrongNotes.
  ///
  /// In en, this message translates to:
  /// **'Wrong notes'**
  String get practiceResultWrongNotes;

  /// No description provided for @practiceResultNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Not played'**
  String get practiceResultNotPlayed;

  /// No description provided for @practiceResultMusicLength.
  ///
  /// In en, this message translates to:
  /// **'Music length'**
  String get practiceResultMusicLength;

  /// No description provided for @practiceResultYourTime.
  ///
  /// In en, this message translates to:
  /// **'Your time'**
  String get practiceResultYourTime;

  /// No description provided for @practiceResultWhatToWorkOn.
  ///
  /// In en, this message translates to:
  /// **'What to work on'**
  String get practiceResultWhatToWorkOn;

  /// No description provided for @practiceResultHowEachClefWent.
  ///
  /// In en, this message translates to:
  /// **'How each clef went'**
  String get practiceResultHowEachClefWent;

  /// No description provided for @practiceResultClefDifficulty.
  ///
  /// In en, this message translates to:
  /// **'{clef}: {errorCount} difficult out of {totalCount}'**
  String practiceResultClefDifficulty(
    String clef,
    int errorCount,
    int totalCount,
  );

  /// No description provided for @practiceResultDifficultNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes that were difficult'**
  String get practiceResultDifficultNotes;

  /// No description provided for @practiceResultNoDifficultNotes.
  ///
  /// In en, this message translates to:
  /// **'No individual note caused repeated trouble.'**
  String get practiceResultNoDifficultNotes;

  /// No description provided for @practiceResultNoteDifficulty.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {{note}: difficult 1 time} other {{note}: difficult {count} times}}'**
  String practiceResultNoteDifficulty(String note, int count);

  /// No description provided for @practiceResultOtherKeys.
  ///
  /// In en, this message translates to:
  /// **'Other keys you pressed'**
  String get practiceResultOtherKeys;

  /// No description provided for @practiceResultNoExtraKeys.
  ///
  /// In en, this message translates to:
  /// **'You did not press any extra wrong keys.'**
  String get practiceResultNoExtraKeys;

  /// No description provided for @practiceResultKeyPressed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {{note} pressed 1 time} other {{note} pressed {count} times}}'**
  String practiceResultKeyPressed(String note, int count);

  /// No description provided for @practiceResultHowToImprove.
  ///
  /// In en, this message translates to:
  /// **'How to improve'**
  String get practiceResultHowToImprove;

  /// No description provided for @practiceResultNotesToReview.
  ///
  /// In en, this message translates to:
  /// **'Notes to review ({count})'**
  String practiceResultNotesToReview(int count);

  /// No description provided for @practiceResultReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Only the parts that need more practice'**
  String get practiceResultReviewDescription;

  /// No description provided for @practiceResultErrorLogFailed.
  ///
  /// In en, this message translates to:
  /// **'The detailed error log could not be loaded.'**
  String get practiceResultErrorLogFailed;

  /// No description provided for @practiceResultNoErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors were recorded for this attempt.'**
  String get practiceResultNoErrors;

  /// No description provided for @practiceResultNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get practiceResultNone;

  /// No description provided for @practiceResultNoteGroup.
  ///
  /// In en, this message translates to:
  /// **'Note group {number}'**
  String practiceResultNoteGroup(int number);

  /// No description provided for @practiceResultNoteGroupMeasure.
  ///
  /// In en, this message translates to:
  /// **'Note group {number} · Measure {measure}'**
  String practiceResultNoteGroupMeasure(int number, String measure);

  /// No description provided for @practiceResultIssueSummary.
  ///
  /// In en, this message translates to:
  /// **'{issues} · {clefs} · At {time}'**
  String practiceResultIssueSummary(String issues, String clefs, String time);

  /// No description provided for @practiceResultExpectedAndPlayed.
  ///
  /// In en, this message translates to:
  /// **'The score showed: {expected}   You played: {played}'**
  String practiceResultExpectedAndPlayed(String expected, String played);

  /// No description provided for @practiceResultEventuallyMatched.
  ///
  /// In en, this message translates to:
  /// **'You found the right notes after the first mistake.'**
  String get practiceResultEventuallyMatched;

  /// No description provided for @practiceResultUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This practice result is unavailable.'**
  String get practiceResultUnavailable;

  /// No description provided for @practiceResultTrebleClef.
  ///
  /// In en, this message translates to:
  /// **'Treble clef (higher notes)'**
  String get practiceResultTrebleClef;

  /// No description provided for @practiceResultBassClef.
  ///
  /// In en, this message translates to:
  /// **'Bass clef (lower notes)'**
  String get practiceResultBassClef;

  /// No description provided for @practiceResultAltoClef.
  ///
  /// In en, this message translates to:
  /// **'Alto clef'**
  String get practiceResultAltoClef;

  /// No description provided for @practiceResultTenorClef.
  ///
  /// In en, this message translates to:
  /// **'Tenor clef'**
  String get practiceResultTenorClef;

  /// No description provided for @practiceResultPercussion.
  ///
  /// In en, this message translates to:
  /// **'Percussion'**
  String get practiceResultPercussion;

  /// No description provided for @practiceResultScoreSection.
  ///
  /// In en, this message translates to:
  /// **'Score section'**
  String get practiceResultScoreSection;

  /// No description provided for @practiceResultNoCorrectNote.
  ///
  /// In en, this message translates to:
  /// **'No correct note was played at this point.'**
  String get practiceResultNoCorrectNote;

  /// No description provided for @practiceResultTimingOnBeat.
  ///
  /// In en, this message translates to:
  /// **'Your timing was almost exactly on the beat.'**
  String get practiceResultTimingOnBeat;

  /// No description provided for @practiceResultBeforeBeat.
  ///
  /// In en, this message translates to:
  /// **'You played about {seconds} seconds before the beat.'**
  String practiceResultBeforeBeat(String seconds);

  /// No description provided for @practiceResultAfterBeat.
  ///
  /// In en, this message translates to:
  /// **'You played about {seconds} seconds after the beat.'**
  String practiceResultAfterBeat(String seconds);

  /// No description provided for @practiceResultIssueWrongNote.
  ///
  /// In en, this message translates to:
  /// **'Different key played'**
  String get practiceResultIssueWrongNote;

  /// No description provided for @practiceResultIssueEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early'**
  String get practiceResultIssueEarly;

  /// No description provided for @practiceResultIssueLate.
  ///
  /// In en, this message translates to:
  /// **'Too late'**
  String get practiceResultIssueLate;

  /// No description provided for @practiceResultIssueMissed.
  ///
  /// In en, this message translates to:
  /// **'No note played'**
  String get practiceResultIssueMissed;

  /// No description provided for @practiceResultIssueChordTiming.
  ///
  /// In en, this message translates to:
  /// **'Chord notes not together'**
  String get practiceResultIssueChordTiming;

  /// No description provided for @practiceResultIssueReleasedEarly.
  ///
  /// In en, this message translates to:
  /// **'Released too soon'**
  String get practiceResultIssueReleasedEarly;

  /// No description provided for @assessmentUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the assessment. Please try again.'**
  String get assessmentUnableToLoad;

  /// No description provided for @assessmentUnableToStart.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the assessment. Please try again.'**
  String get assessmentUnableToStart;

  /// No description provided for @assessmentUnableToContinue.
  ///
  /// In en, this message translates to:
  /// **'Unable to continue the assessment. Please try again.'**
  String get assessmentUnableToContinue;

  /// No description provided for @assessmentAcceptBeginnerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Accept Beginner level?'**
  String get assessmentAcceptBeginnerQuestion;

  /// No description provided for @assessmentAcceptBeginnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Based on your answers, at least one required skill is at the Beginner level. Accepting will skip Notation Reading and Piano Execution. This result is permanent and cannot be attempted again.'**
  String get assessmentAcceptBeginnerDescription;

  /// No description provided for @assessmentReviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review Answers'**
  String get assessmentReviewAnswers;

  /// No description provided for @assessmentAcceptBeginner.
  ///
  /// In en, this message translates to:
  /// **'Accept Beginner'**
  String get assessmentAcceptBeginner;

  /// No description provided for @assessmentStartQuestion.
  ///
  /// In en, this message translates to:
  /// **'Start assessment?'**
  String get assessmentStartQuestion;

  /// No description provided for @assessmentStartWarning.
  ///
  /// In en, this message translates to:
  /// **'Your 72-hour deadline will begin immediately. You only receive one attempt. If it expires, your saved rank is kept, or Beginner is assigned if you have no rank yet.'**
  String get assessmentStartWarning;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @assessmentSkillAssessment.
  ///
  /// In en, this message translates to:
  /// **'Skill assessment'**
  String get assessmentSkillAssessment;

  /// No description provided for @assessmentInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment in progress'**
  String get assessmentInProgressTitle;

  /// No description provided for @assessmentCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment completed'**
  String get assessmentCompletedTitle;

  /// No description provided for @assessmentExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment expired'**
  String get assessmentExpiredTitle;

  /// No description provided for @assessmentSkillDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete the assessment to determine your SoundSight Level. Your 72-hour deadline begins only after you press Start.'**
  String get assessmentSkillDescription;

  /// No description provided for @assessmentActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Your assessment has started. Continue before the deadline to receive your SoundSight Level.'**
  String get assessmentActiveDescription;

  /// No description provided for @assessmentCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Your assessment is complete. View your permanent SoundSight Level and section results.'**
  String get assessmentCompleteDescription;

  /// No description provided for @assessmentExpiredFullDescription.
  ///
  /// In en, this message translates to:
  /// **'The assessment was not completed within 72 hours and cannot be attempted again. Your saved rank is kept, or Beginner is assigned if you had no rank.'**
  String get assessmentExpiredFullDescription;

  /// No description provided for @assessmentViewResults.
  ///
  /// In en, this message translates to:
  /// **'View Results'**
  String get assessmentViewResults;

  /// No description provided for @assessmentContinueHome.
  ///
  /// In en, this message translates to:
  /// **'Continue to Home'**
  String get assessmentContinueHome;

  /// No description provided for @assessmentSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get assessmentSkipForNow;

  /// No description provided for @assessmentContinueLater.
  ///
  /// In en, this message translates to:
  /// **'Continue Later'**
  String get assessmentContinueLater;

  /// No description provided for @assessmentTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get assessmentTimeRemaining;

  /// No description provided for @assessmentDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h {minutes}m'**
  String assessmentDurationDays(int days, int hours, int minutes);

  /// No description provided for @assessmentDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String assessmentDurationHours(int hours, int minutes);

  /// No description provided for @assessmentDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String assessmentDurationMinutes(int minutes);

  /// No description provided for @assessmentBeforeYouBegin.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get assessmentBeforeYouBegin;

  /// No description provided for @assessmentReadCarefully.
  ///
  /// In en, this message translates to:
  /// **'Please read the following information carefully.'**
  String get assessmentReadCarefully;

  /// No description provided for @assessmentImportantInformation.
  ///
  /// In en, this message translates to:
  /// **'Important information'**
  String get assessmentImportantInformation;

  /// No description provided for @assessmentLevelExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your SoundSight Level measures your combined sheet-reading and piano-playing ability.'**
  String get assessmentLevelExplanation;

  /// No description provided for @assessmentTimingExplanation.
  ///
  /// In en, this message translates to:
  /// **'Piano timing becomes stricter at each level. Beginner notes may be played up to 500 ms early or late, Intermediate notes up to 350 ms, and Advanced notes up to 250 ms.'**
  String get assessmentTimingExplanation;

  /// No description provided for @assessmentPassingExplanation.
  ///
  /// In en, this message translates to:
  /// **'A notation level requires at least 4 of 6 correct answers in that tier. A piano level requires at least 70% correct note or chord groups. Higher levels also require passing every lower tier.'**
  String get assessmentPassingExplanation;

  /// No description provided for @assessmentChordExplanation.
  ///
  /// In en, this message translates to:
  /// **'For a chord to count as correct, all required keys must be pressed within 200 ms of one another and inside the level\'s timing window.'**
  String get assessmentChordExplanation;

  /// No description provided for @assessmentOneAttempt.
  ///
  /// In en, this message translates to:
  /// **'You only receive one assessment attempt. An expired attempt cannot be restarted.'**
  String get assessmentOneAttempt;

  /// No description provided for @assessmentDeadlineExplanation.
  ///
  /// In en, this message translates to:
  /// **'The assessment must be completed within 72 hours after it starts.'**
  String get assessmentDeadlineExplanation;

  /// No description provided for @assessmentExpirationExplanation.
  ///
  /// In en, this message translates to:
  /// **'If the assessment expires before completion, your saved rank is kept. Beginner is assigned if you have no rank yet.'**
  String get assessmentExpirationExplanation;

  /// No description provided for @assessmentLeaveExplanation.
  ///
  /// In en, this message translates to:
  /// **'You may leave between sections and continue later while the assessment is still active.'**
  String get assessmentLeaveExplanation;

  /// No description provided for @assessmentPreparationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Prepare your MIDI keyboard, internet connection, and a quiet place before continuing.'**
  String get assessmentPreparationExplanation;

  /// No description provided for @assessmentNoTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'No time remaining'**
  String get assessmentNoTimeRemaining;

  /// No description provided for @assessmentContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Assessment'**
  String get assessmentContinue;

  /// No description provided for @returnAction.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnAction;

  /// No description provided for @assessmentBackgroundQuestions.
  ///
  /// In en, this message translates to:
  /// **'Background Questions'**
  String get assessmentBackgroundQuestions;

  /// No description provided for @assessmentExperienceHeading.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your experience'**
  String get assessmentExperienceHeading;

  /// No description provided for @assessmentExperienceDescription.
  ///
  /// In en, this message translates to:
  /// **'These answers help personalize your experience. If you are new to piano or have not learned sheet music, you may accept Beginner level and skip the remaining parts.'**
  String get assessmentExperienceDescription;

  /// No description provided for @assessmentDeadlineContinues.
  ///
  /// In en, this message translates to:
  /// **'Your assessment deadline continues while answering.'**
  String get assessmentDeadlineContinues;

  /// No description provided for @assessmentAnswerEveryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please answer every question before continuing.'**
  String get assessmentAnswerEveryQuestion;

  /// No description provided for @assessmentSaveAnswersFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your answers. Please try again.'**
  String get assessmentSaveAnswersFailed;

  /// No description provided for @assessmentSelectOneAnswer.
  ///
  /// In en, this message translates to:
  /// **'Select one answer.'**
  String get assessmentSelectOneAnswer;

  /// No description provided for @assessmentQuestionPianoExperience.
  ///
  /// In en, this message translates to:
  /// **'How long have you been playing the piano or keyboard?'**
  String get assessmentQuestionPianoExperience;

  /// No description provided for @assessmentQuestionSheetMusicExperience.
  ///
  /// In en, this message translates to:
  /// **'How familiar are you with reading sheet music?'**
  String get assessmentQuestionSheetMusicExperience;

  /// No description provided for @assessmentQuestionLearningMethod.
  ///
  /// In en, this message translates to:
  /// **'How have you mainly learned piano?'**
  String get assessmentQuestionLearningMethod;

  /// No description provided for @assessmentQuestionPrimaryGoal.
  ///
  /// In en, this message translates to:
  /// **'What is your main goal in SoundSight?'**
  String get assessmentQuestionPrimaryGoal;

  /// No description provided for @assessmentOptionNewToPiano.
  ///
  /// In en, this message translates to:
  /// **'I am just starting'**
  String get assessmentOptionNewToPiano;

  /// No description provided for @assessmentOptionUnderOneYear.
  ///
  /// In en, this message translates to:
  /// **'Less than one year'**
  String get assessmentOptionUnderOneYear;

  /// No description provided for @assessmentOptionOneToThreeYears.
  ///
  /// In en, this message translates to:
  /// **'One to three years'**
  String get assessmentOptionOneToThreeYears;

  /// No description provided for @assessmentOptionMoreThanThreeYears.
  ///
  /// In en, this message translates to:
  /// **'More than three years'**
  String get assessmentOptionMoreThanThreeYears;

  /// No description provided for @assessmentOptionNotFamiliar.
  ///
  /// In en, this message translates to:
  /// **'I have not learned sheet music'**
  String get assessmentOptionNotFamiliar;

  /// No description provided for @assessmentOptionBasicFamiliarity.
  ///
  /// In en, this message translates to:
  /// **'I recognize a few notes and symbols'**
  String get assessmentOptionBasicFamiliarity;

  /// No description provided for @assessmentOptionModerateFamiliarity.
  ///
  /// In en, this message translates to:
  /// **'I can read simple sheet music'**
  String get assessmentOptionModerateFamiliarity;

  /// No description provided for @assessmentOptionComfortable.
  ///
  /// In en, this message translates to:
  /// **'I am comfortable reading sheet music'**
  String get assessmentOptionComfortable;

  /// No description provided for @assessmentOptionNoFormalLearning.
  ///
  /// In en, this message translates to:
  /// **'I have not started learning yet'**
  String get assessmentOptionNoFormalLearning;

  /// No description provided for @assessmentOptionTeacher.
  ///
  /// In en, this message translates to:
  /// **'With a piano teacher'**
  String get assessmentOptionTeacher;

  /// No description provided for @assessmentOptionSelfTaught.
  ///
  /// In en, this message translates to:
  /// **'Self-taught'**
  String get assessmentOptionSelfTaught;

  /// No description provided for @assessmentOptionMixedLearning.
  ///
  /// In en, this message translates to:
  /// **'A mixture of lessons and self-study'**
  String get assessmentOptionMixedLearning;

  /// No description provided for @assessmentOptionLearnNotation.
  ///
  /// In en, this message translates to:
  /// **'Learn how to read music notation'**
  String get assessmentOptionLearnNotation;

  /// No description provided for @assessmentOptionImproveSightReading.
  ///
  /// In en, this message translates to:
  /// **'Improve my sight-reading'**
  String get assessmentOptionImproveSightReading;

  /// No description provided for @assessmentOptionImproveCoordination.
  ///
  /// In en, this message translates to:
  /// **'Improve my piano coordination'**
  String get assessmentOptionImproveCoordination;

  /// No description provided for @assessmentOptionTrackProgress.
  ///
  /// In en, this message translates to:
  /// **'Understand and track my current ability'**
  String get assessmentOptionTrackProgress;

  /// No description provided for @assessmentNotationReading.
  ///
  /// In en, this message translates to:
  /// **'Notation Reading'**
  String get assessmentNotationReading;

  /// No description provided for @assessmentNotationSemantics.
  ///
  /// In en, this message translates to:
  /// **'Music notation for the current assessment question'**
  String get assessmentNotationSemantics;

  /// No description provided for @assessmentAnswerEveryNotationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Answer every question before submitting.'**
  String get assessmentAnswerEveryNotationQuestion;

  /// No description provided for @assessmentPleaseAnswerEveryNotationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please answer every notation question.'**
  String get assessmentPleaseAnswerEveryNotationQuestion;

  /// No description provided for @assessmentSaveNotationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your notation answers. Please try again.'**
  String get assessmentSaveNotationFailed;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @assessmentQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String assessmentQuestionProgress(int current, int total);

  /// No description provided for @assessmentAnsweredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 answered} other {{count} answered}}'**
  String assessmentAnsweredCount(int count);

  /// No description provided for @assessmentNotationPromptNote.
  ///
  /// In en, this message translates to:
  /// **'Which note is shown?'**
  String get assessmentNotationPromptNote;

  /// No description provided for @assessmentNotationPromptBeatValue.
  ///
  /// In en, this message translates to:
  /// **'In 4/4 time, how many beats does this note receive?'**
  String get assessmentNotationPromptBeatValue;

  /// No description provided for @assessmentNotationPromptTimeSignature.
  ///
  /// In en, this message translates to:
  /// **'What does this time signature mean?'**
  String get assessmentNotationPromptTimeSignature;

  /// No description provided for @assessmentNotationPromptLedgerNote.
  ///
  /// In en, this message translates to:
  /// **'Which ledger-line note is shown?'**
  String get assessmentNotationPromptLedgerNote;

  /// No description provided for @assessmentNotationPromptAccidental.
  ///
  /// In en, this message translates to:
  /// **'Which note with an accidental is shown?'**
  String get assessmentNotationPromptAccidental;

  /// No description provided for @assessmentNotationPromptMajorKey.
  ///
  /// In en, this message translates to:
  /// **'Which major key signature is shown?'**
  String get assessmentNotationPromptMajorKey;

  /// No description provided for @assessmentNotationPromptIntervalSize.
  ///
  /// In en, this message translates to:
  /// **'What is the size of the written interval?'**
  String get assessmentNotationPromptIntervalSize;

  /// No description provided for @assessmentNotationPromptUpperLedgerNote.
  ///
  /// In en, this message translates to:
  /// **'Which upper ledger-line note is shown?'**
  String get assessmentNotationPromptUpperLedgerNote;

  /// No description provided for @assessmentNotationPromptCompoundMeter.
  ///
  /// In en, this message translates to:
  /// **'How is this compound meter normally felt?'**
  String get assessmentNotationPromptCompoundMeter;

  /// No description provided for @assessmentNotationPromptWrittenInterval.
  ///
  /// In en, this message translates to:
  /// **'What is the written interval?'**
  String get assessmentNotationPromptWrittenInterval;

  /// No description provided for @assessmentNotationPromptRootChord.
  ///
  /// In en, this message translates to:
  /// **'Which root-position chord is shown?'**
  String get assessmentNotationPromptRootChord;

  /// No description provided for @assessmentNotationPromptPassageBeats.
  ///
  /// In en, this message translates to:
  /// **'How many quarter-note beats does this passage contain?'**
  String get assessmentNotationPromptPassageBeats;

  /// No description provided for @assessmentOptionHalfBeat.
  ///
  /// In en, this message translates to:
  /// **'1/2 beat'**
  String get assessmentOptionHalfBeat;

  /// No description provided for @assessmentOptionOneBeat.
  ///
  /// In en, this message translates to:
  /// **'1 beat'**
  String get assessmentOptionOneBeat;

  /// No description provided for @assessmentOptionTwoBeats.
  ///
  /// In en, this message translates to:
  /// **'2 beats'**
  String get assessmentOptionTwoBeats;

  /// No description provided for @assessmentOptionThreeBeats.
  ///
  /// In en, this message translates to:
  /// **'3 beats'**
  String get assessmentOptionThreeBeats;

  /// No description provided for @assessmentOptionFourBeats.
  ///
  /// In en, this message translates to:
  /// **'4 beats'**
  String get assessmentOptionFourBeats;

  /// No description provided for @assessmentOptionFiveBeats.
  ///
  /// In en, this message translates to:
  /// **'5 beats'**
  String get assessmentOptionFiveBeats;

  /// No description provided for @assessmentOptionTwoQuarterBeats.
  ///
  /// In en, this message translates to:
  /// **'Two quarter-note beats per measure'**
  String get assessmentOptionTwoQuarterBeats;

  /// No description provided for @assessmentOptionThreeQuarterBeats.
  ///
  /// In en, this message translates to:
  /// **'Three quarter-note beats per measure'**
  String get assessmentOptionThreeQuarterBeats;

  /// No description provided for @assessmentOptionFourQuarterBeats.
  ///
  /// In en, this message translates to:
  /// **'Four quarter-note beats per measure'**
  String get assessmentOptionFourQuarterBeats;

  /// No description provided for @assessmentOptionFourEighthBeats.
  ///
  /// In en, this message translates to:
  /// **'Four eighth-note beats per measure'**
  String get assessmentOptionFourEighthBeats;

  /// No description provided for @assessmentOptionTwoDottedQuarterBeats.
  ///
  /// In en, this message translates to:
  /// **'Two dotted-quarter beats'**
  String get assessmentOptionTwoDottedQuarterBeats;

  /// No description provided for @assessmentOptionSixQuarterBeats.
  ///
  /// In en, this message translates to:
  /// **'Six quarter-note beats'**
  String get assessmentOptionSixQuarterBeats;

  /// No description provided for @assessmentOptionSecond.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get assessmentOptionSecond;

  /// No description provided for @assessmentOptionThird.
  ///
  /// In en, this message translates to:
  /// **'Third'**
  String get assessmentOptionThird;

  /// No description provided for @assessmentOptionFourth.
  ///
  /// In en, this message translates to:
  /// **'Fourth'**
  String get assessmentOptionFourth;

  /// No description provided for @assessmentOptionFifth.
  ///
  /// In en, this message translates to:
  /// **'Fifth'**
  String get assessmentOptionFifth;

  /// No description provided for @assessmentOptionMajorThird.
  ///
  /// In en, this message translates to:
  /// **'Major third'**
  String get assessmentOptionMajorThird;

  /// No description provided for @assessmentOptionPerfectFourth.
  ///
  /// In en, this message translates to:
  /// **'Perfect fourth'**
  String get assessmentOptionPerfectFourth;

  /// No description provided for @assessmentOptionPerfectFifth.
  ///
  /// In en, this message translates to:
  /// **'Perfect fifth'**
  String get assessmentOptionPerfectFifth;

  /// No description provided for @assessmentOptionMajorSixth.
  ///
  /// In en, this message translates to:
  /// **'Major sixth'**
  String get assessmentOptionMajorSixth;

  /// No description provided for @assessmentPianoExecution.
  ///
  /// In en, this message translates to:
  /// **'Piano Execution'**
  String get assessmentPianoExecution;

  /// No description provided for @assessmentMidiNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get assessmentMidiNotConnected;

  /// No description provided for @assessmentMidiSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get assessmentMidiSearching;

  /// No description provided for @assessmentMidiNotDetected.
  ///
  /// In en, this message translates to:
  /// **'No MIDI device detected'**
  String get assessmentMidiNotDetected;

  /// No description provided for @assessmentMidiConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get assessmentMidiConnecting;

  /// No description provided for @assessmentMidiConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get assessmentMidiConnected;

  /// No description provided for @assessmentMidiConnectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected: {deviceName}'**
  String assessmentMidiConnectedDevice(String deviceName);

  /// No description provided for @assessmentMidiConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get assessmentMidiConnectionFailed;

  /// No description provided for @assessmentMidiConnectError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the MIDI keyboard.'**
  String get assessmentMidiConnectError;

  /// No description provided for @assessmentMidiDisconnected.
  ///
  /// In en, this message translates to:
  /// **'MIDI keyboard disconnected'**
  String get assessmentMidiDisconnected;

  /// No description provided for @assessmentMidiInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The MIDI connection was removed. Reconnect and restart this task.'**
  String get assessmentMidiInterrupted;

  /// No description provided for @assessmentSavePianoFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the piano results. Please try again.'**
  String get assessmentSavePianoFailed;

  /// No description provided for @assessmentTaskProgress.
  ///
  /// In en, this message translates to:
  /// **'Task {current} of {total}'**
  String assessmentTaskProgress(int current, int total);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @assessmentKeysToPlay.
  ///
  /// In en, this message translates to:
  /// **'Keys to play'**
  String get assessmentKeysToPlay;

  /// No description provided for @assessmentWhenToPlay.
  ///
  /// In en, this message translates to:
  /// **'When to play'**
  String get assessmentWhenToPlay;

  /// No description provided for @assessmentMiddleCExplanation.
  ///
  /// In en, this message translates to:
  /// **'C4 is Middle C. The number tells you the piano octave.'**
  String get assessmentMiddleCExplanation;

  /// No description provided for @assessmentTempoCountIn.
  ///
  /// In en, this message translates to:
  /// **'{tempo} BPM • {count}-beat count-in'**
  String assessmentTempoCountIn(int tempo, int count);

  /// No description provided for @assessmentCountIn.
  ///
  /// In en, this message translates to:
  /// **'Count-in'**
  String get assessmentCountIn;

  /// No description provided for @assessmentWaitForGo.
  ///
  /// In en, this message translates to:
  /// **'Wait. Play {keys} when GO appears.'**
  String assessmentWaitForGo(String keys);

  /// No description provided for @assessmentTaskRecorded.
  ///
  /// In en, this message translates to:
  /// **'Task recorded'**
  String get assessmentTaskRecorded;

  /// No description provided for @assessmentStartTaskGuidance.
  ///
  /// In en, this message translates to:
  /// **'Press Start Task when you are ready. Wait through the complete count-in, then play the first shown key or chord with GO. Each scored task can only be performed once in this session.'**
  String get assessmentStartTaskGuidance;

  /// No description provided for @assessmentTaskComplete.
  ///
  /// In en, this message translates to:
  /// **'Task complete'**
  String get assessmentTaskComplete;

  /// No description provided for @assessmentBeatNumber.
  ///
  /// In en, this message translates to:
  /// **'Beat {number}'**
  String assessmentBeatNumber(int number);

  /// No description provided for @assessmentPlayNow.
  ///
  /// In en, this message translates to:
  /// **'Play now: {keys}'**
  String assessmentPlayNow(String keys);

  /// No description provided for @assessmentWaitingMidi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for MIDI input'**
  String get assessmentWaitingMidi;

  /// No description provided for @assessmentHeldKeys.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 key currently held} other {{count} keys currently held}}'**
  String assessmentHeldKeys(int count);

  /// No description provided for @assessmentGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get Ready'**
  String get assessmentGetReady;

  /// No description provided for @assessmentPerforming.
  ///
  /// In en, this message translates to:
  /// **'Performing'**
  String get assessmentPerforming;

  /// No description provided for @assessmentSubmitPianoResults.
  ///
  /// In en, this message translates to:
  /// **'Submit Piano Results'**
  String get assessmentSubmitPianoResults;

  /// No description provided for @assessmentNextTask.
  ///
  /// In en, this message translates to:
  /// **'Next Task'**
  String get assessmentNextTask;

  /// No description provided for @assessmentConnectMidi.
  ///
  /// In en, this message translates to:
  /// **'Connect MIDI'**
  String get assessmentConnectMidi;

  /// No description provided for @assessmentStartTask.
  ///
  /// In en, this message translates to:
  /// **'Start Task'**
  String get assessmentStartTask;

  /// No description provided for @assessmentTaskMiddleCTitle.
  ///
  /// In en, this message translates to:
  /// **'Middle C'**
  String get assessmentTaskMiddleCTitle;

  /// No description provided for @assessmentTaskMiddleCInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C4, which is Middle C.'**
  String get assessmentTaskMiddleCInstruction;

  /// No description provided for @assessmentTaskMiddleCTiming.
  ///
  /// In en, this message translates to:
  /// **'Play C4 once when GO appears.'**
  String get assessmentTaskMiddleCTiming;

  /// No description provided for @assessmentTaskFiveFingerTitle.
  ///
  /// In en, this message translates to:
  /// **'Five-finger pattern'**
  String get assessmentTaskFiveFingerTitle;

  /// No description provided for @assessmentTaskFiveFingerInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C4, D4, E4, F4, and G4 upward.'**
  String get assessmentTaskFiveFingerInstruction;

  /// No description provided for @assessmentTaskNoteEveryClickTiming.
  ///
  /// In en, this message translates to:
  /// **'Play {firstNote} with GO, then play one note on every following click.'**
  String assessmentTaskNoteEveryClickTiming(String firstNote);

  /// No description provided for @assessmentTaskCMajorChordTitle.
  ///
  /// In en, this message translates to:
  /// **'C major chord'**
  String get assessmentTaskCMajorChordTitle;

  /// No description provided for @assessmentTaskCMajorChordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C4, E4, and G4 together.'**
  String get assessmentTaskCMajorChordInstruction;

  /// No description provided for @assessmentTaskChordGoTiming.
  ///
  /// In en, this message translates to:
  /// **'Play the complete chord once when GO appears.'**
  String get assessmentTaskChordGoTiming;

  /// No description provided for @assessmentTaskCMajorScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'C major scale'**
  String get assessmentTaskCMajorScaleTitle;

  /// No description provided for @assessmentTaskCMajorScaleInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play the C major scale upward from C4 to C5.'**
  String get assessmentTaskCMajorScaleInstruction;

  /// No description provided for @assessmentTaskCMajorArpeggioTitle.
  ///
  /// In en, this message translates to:
  /// **'C major arpeggio'**
  String get assessmentTaskCMajorArpeggioTitle;

  /// No description provided for @assessmentTaskCMajorArpeggioInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C4, E4, G4, C5, G4, E4, and C4.'**
  String get assessmentTaskCMajorArpeggioInstruction;

  /// No description provided for @assessmentTaskChordProgressionTitle.
  ///
  /// In en, this message translates to:
  /// **'Chord progression'**
  String get assessmentTaskChordProgressionTitle;

  /// No description provided for @assessmentTaskChordProgressionInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C3-E3-G3, F3-A3-C4, G3-B3-D4, then C3-E3-G3.'**
  String get assessmentTaskChordProgressionInstruction;

  /// No description provided for @assessmentTaskChordEverySecondClickTiming.
  ///
  /// In en, this message translates to:
  /// **'Play the first chord with GO, then one chord every second click.'**
  String get assessmentTaskChordEverySecondClickTiming;

  /// No description provided for @assessmentTaskTwoOctaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-octave scale'**
  String get assessmentTaskTwoOctaveTitle;

  /// No description provided for @assessmentTaskTwoOctaveInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play the C major scale upward from C3 to C5.'**
  String get assessmentTaskTwoOctaveInstruction;

  /// No description provided for @assessmentTaskChordInversionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chord inversions'**
  String get assessmentTaskChordInversionsTitle;

  /// No description provided for @assessmentTaskChordInversionsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C3-E3-G3, E3-G3-C4, G3-C4-E4, then C4-E4-G4.'**
  String get assessmentTaskChordInversionsInstruction;

  /// No description provided for @assessmentTaskParallelScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Parallel scale'**
  String get assessmentTaskParallelScaleTitle;

  /// No description provided for @assessmentTaskParallelScaleInstruction.
  ///
  /// In en, this message translates to:
  /// **'Play C3-C4 through C4-C5 with both hands in parallel motion.'**
  String get assessmentTaskParallelScaleInstruction;

  /// No description provided for @assessmentTaskParallelTiming.
  ///
  /// In en, this message translates to:
  /// **'Play both C keys with GO, then play the next pair on every click.'**
  String get assessmentTaskParallelTiming;

  /// No description provided for @assessmentReview.
  ///
  /// In en, this message translates to:
  /// **'Assessment Review'**
  String get assessmentReview;

  /// No description provided for @assessmentApplyLevelFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to apply your saved skill level. Please try again.'**
  String get assessmentApplyLevelFailed;

  /// No description provided for @assessmentBeginnerShortcutSummary.
  ///
  /// In en, this message translates to:
  /// **'Your background answers show that at least one required skill is entirely new to you. The scored sections were skipped and Beginner was assigned.'**
  String get assessmentBeginnerShortcutSummary;

  /// No description provided for @assessmentNotationSection.
  ///
  /// In en, this message translates to:
  /// **'Notation reading'**
  String get assessmentNotationSection;

  /// No description provided for @assessmentPianoSection.
  ///
  /// In en, this message translates to:
  /// **'Piano execution'**
  String get assessmentPianoSection;

  /// No description provided for @assessmentCorrectScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String assessmentCorrectScore(int correct, int total);

  /// No description provided for @assessmentCorrectGroupsScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct groups'**
  String assessmentCorrectGroupsScore(int correct, int total);

  /// No description provided for @assessmentFinalLevelExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your final level uses the lower of your notation and piano levels. Strength in one required skill cannot hide a weaker required skill.'**
  String get assessmentFinalLevelExplanation;

  /// No description provided for @assessmentYourLevel.
  ///
  /// In en, this message translates to:
  /// **'Your SoundSight Level'**
  String get assessmentYourLevel;

  /// No description provided for @assessmentNoSavedAnswer.
  ///
  /// In en, this message translates to:
  /// **'No saved answer'**
  String get assessmentNoSavedAnswer;

  /// No description provided for @assessmentBackgroundAnswers.
  ///
  /// In en, this message translates to:
  /// **'Background answers'**
  String get assessmentBackgroundAnswers;

  /// No description provided for @assessmentCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get assessmentCorrect;

  /// No description provided for @assessmentCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String assessmentCorrectAnswer(String answer);

  /// No description provided for @assessmentNotationAnswers.
  ///
  /// In en, this message translates to:
  /// **'Notation answers'**
  String get assessmentNotationAnswers;

  /// No description provided for @assessmentNoSavedResult.
  ///
  /// In en, this message translates to:
  /// **'No saved result'**
  String get assessmentNoSavedResult;

  /// No description provided for @assessmentPianoResultDetails.
  ///
  /// In en, this message translates to:
  /// **'{wrong} wrong, {missed} missed, {timing} timing mistakes'**
  String assessmentPianoResultDetails(int wrong, int missed, int timing);

  /// No description provided for @assessmentPianoTaskResults.
  ///
  /// In en, this message translates to:
  /// **'Piano task results'**
  String get assessmentPianoTaskResults;

  /// No description provided for @assessmentResultUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assessment is complete, but its saved result details could not be displayed.'**
  String get assessmentResultUnavailable;

  /// No description provided for @lessonSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to open lessons.'**
  String get lessonSignInRequired;

  /// No description provided for @lessonProgressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Lesson progress could not be loaded. Please try again.'**
  String get lessonProgressLoadFailed;

  /// No description provided for @lessonProgressSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Lesson progress could not be saved. Please try again.'**
  String get lessonProgressSaveFailed;

  /// No description provided for @lessonCompactProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} complete'**
  String lessonCompactProgress(int completed, int total);

  /// No description provided for @lessonAllStagesComplete.
  ///
  /// In en, this message translates to:
  /// **'All stages complete'**
  String get lessonAllStagesComplete;

  /// No description provided for @lessonStageProgress.
  ///
  /// In en, this message translates to:
  /// **'Stage {current} of {total}'**
  String lessonStageProgress(int current, int total);

  /// No description provided for @lessonStagesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} stages completed'**
  String lessonStagesCompleted(int completed, int total);

  /// No description provided for @lessonSavingStageProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving Stage {stage} progress...'**
  String lessonSavingStageProgress(int stage);

  /// No description provided for @lessonStageProgressNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} passed, but progress was not saved.'**
  String lessonStageProgressNotSaved(int stage);

  /// No description provided for @lessonVideoAndQuiz.
  ///
  /// In en, this message translates to:
  /// **'Video + quiz'**
  String get lessonVideoAndQuiz;

  /// No description provided for @lessonPianoPerformance.
  ///
  /// In en, this message translates to:
  /// **'Piano performance'**
  String get lessonPianoPerformance;

  /// No description provided for @lessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lessonCompleted;

  /// No description provided for @lessonCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get lessonCurrent;

  /// No description provided for @lessonLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lessonLocked;

  /// No description provided for @lessonReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get lessonReplay;

  /// No description provided for @lessonStageAndStatus.
  ///
  /// In en, this message translates to:
  /// **'STAGE {stage}  /  {status}'**
  String lessonStageAndStatus(int stage, String status);

  /// No description provided for @lessonStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage}'**
  String lessonStageLabel(int stage);

  /// No description provided for @lessonFinishStageToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Finish Stage {stage} to unlock this stage.'**
  String lessonFinishStageToUnlock(int stage);

  /// No description provided for @lessonRankMilestone.
  ///
  /// In en, this message translates to:
  /// **'Rank milestone'**
  String get lessonRankMilestone;

  /// No description provided for @lessonStageReplayComplete.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} replay complete.'**
  String lessonStageReplayComplete(int stage);

  /// No description provided for @lessonAllStagesCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'All stages complete!'**
  String get lessonAllStagesCompleteMessage;

  /// No description provided for @lessonStageUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} unlocked!'**
  String lessonStageUnlocked(int stage);

  /// No description provided for @lessonAdvancedRankWillNotLower.
  ///
  /// In en, this message translates to:
  /// **'You already have the Advanced rank. Completing this stage will not lower it.'**
  String get lessonAdvancedRankWillNotLower;

  /// No description provided for @lessonIntermediateRankKept.
  ///
  /// In en, this message translates to:
  /// **'You already have the Intermediate rank. Completing this stage will keep it.'**
  String get lessonIntermediateRankKept;

  /// No description provided for @lessonIntermediateAwardedFirstCompletion.
  ///
  /// In en, this message translates to:
  /// **'The Intermediate promotion is awarded on the first completion of this stage.'**
  String get lessonIntermediateAwardedFirstCompletion;

  /// No description provided for @lessonPerfectRunPromotesIntermediate.
  ///
  /// In en, this message translates to:
  /// **'A perfect Performance run promotes you to Intermediate once your progress is saved.'**
  String get lessonPerfectRunPromotesIntermediate;

  /// No description provided for @lessonAdvancedRankKept.
  ///
  /// In en, this message translates to:
  /// **'You already have the Advanced rank. Completing this stage will keep it.'**
  String get lessonAdvancedRankKept;

  /// No description provided for @lessonAdvancedAwardedFirstCompletion.
  ///
  /// In en, this message translates to:
  /// **'The Advanced promotion is awarded on the first completion of this stage.'**
  String get lessonAdvancedAwardedFirstCompletion;

  /// No description provided for @lessonPerfectRunPromotesAdvanced.
  ///
  /// In en, this message translates to:
  /// **'A perfect Performance run in this final stage promotes you to Advanced once your progress is saved.'**
  String get lessonPerfectRunPromotesAdvanced;

  /// No description provided for @lessonStageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage}, {title}, {activity}, {status}'**
  String lessonStageSemantics(
    int stage,
    String title,
    String activity,
    String status,
  );

  /// No description provided for @lessonNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson {number}: {title}'**
  String lessonNumberTitle(int number, String title);

  /// No description provided for @lessonStage1ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'The Canvas'**
  String get lessonStage1ShortTitle;

  /// No description provided for @lessonStage2ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'The Grand Staff'**
  String get lessonStage2ShortTitle;

  /// No description provided for @lessonStage3ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Middle C'**
  String get lessonStage3ShortTitle;

  /// No description provided for @lessonStage4ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Find and Play Middle C'**
  String get lessonStage4ShortTitle;

  /// No description provided for @lessonStage5ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Musical Notes'**
  String get lessonStage5ShortTitle;

  /// No description provided for @lessonStage6ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Play Twinkle Twinkle'**
  String get lessonStage6ShortTitle;

  /// No description provided for @lessonStage7ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Finger Numbers'**
  String get lessonStage7ShortTitle;

  /// No description provided for @lessonStage8ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Accidentals'**
  String get lessonStage8ShortTitle;

  /// No description provided for @lessonStage9ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Play Für Elise'**
  String get lessonStage9ShortTitle;

  /// No description provided for @lessonStage10ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Signatures'**
  String get lessonStage10ShortTitle;

  /// No description provided for @lessonStage11ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sense of Time'**
  String get lessonStage11ShortTitle;

  /// No description provided for @lessonStage11Title.
  ///
  /// In en, this message translates to:
  /// **'Time Signature Performance Test'**
  String get lessonStage11Title;

  /// No description provided for @lessonStage12ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get lessonStage12ShortTitle;

  /// No description provided for @lessonStage13ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Major and Minor Scales'**
  String get lessonStage13ShortTitle;

  /// No description provided for @lessonStage14ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Play the C Minor Scale'**
  String get lessonStage14ShortTitle;

  /// No description provided for @lessonStage15ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Nashville Number System'**
  String get lessonStage15ShortTitle;

  /// No description provided for @lessonStage16ShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Play a Song'**
  String get lessonStage16ShortTitle;

  /// No description provided for @lessonWatchThenQuiz.
  ///
  /// In en, this message translates to:
  /// **'Watch the lesson video, then take the quiz to review it.'**
  String get lessonWatchThenQuiz;

  /// No description provided for @lessonOpenScoreAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Open the sheet music, connect your piano, and play the notes shown.'**
  String get lessonOpenScoreAndPlay;

  /// No description provided for @lessonWatchTopicVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch the lesson video about {topic}.'**
  String lessonWatchTopicVideo(String topic);

  /// No description provided for @lessonPlayWithMovingCursor.
  ///
  /// In en, this message translates to:
  /// **'Connect your piano and play the score in time with its moving cursor.'**
  String get lessonPlayWithMovingCursor;

  /// No description provided for @lessonWatchViewPdfAndQuiz.
  ///
  /// In en, this message translates to:
  /// **'Watch the lesson, view the chord cheat sheet, and take the quiz.'**
  String get lessonWatchViewPdfAndQuiz;

  /// No description provided for @lessonConnectAndPlayScore.
  ///
  /// In en, this message translates to:
  /// **'Connect your piano and play the notes shown on the score.'**
  String get lessonConnectAndPlayScore;

  /// No description provided for @lessonSightReadingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Sight Reading Challenge'**
  String get lessonSightReadingChallenge;

  /// No description provided for @lessonSightReadingChallengeDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect your piano and play the score'**
  String get lessonSightReadingChallengeDescription;

  /// No description provided for @lessonVideoLesson.
  ///
  /// In en, this message translates to:
  /// **'Video lesson'**
  String get lessonVideoLesson;

  /// No description provided for @lessonQuestions.
  ///
  /// In en, this message translates to:
  /// **'Lesson questions'**
  String get lessonQuestions;

  /// No description provided for @lessonSheetMusic.
  ///
  /// In en, this message translates to:
  /// **'Sheet music'**
  String get lessonSheetMusic;

  /// No description provided for @lessonCompressedMusicXmlScore.
  ///
  /// In en, this message translates to:
  /// **'Compressed MusicXML score'**
  String get lessonCompressedMusicXmlScore;

  /// No description provided for @lessonSightReadingScore.
  ///
  /// In en, this message translates to:
  /// **'Sight-reading score'**
  String get lessonSightReadingScore;

  /// No description provided for @lessonFile.
  ///
  /// In en, this message translates to:
  /// **'Lesson file'**
  String get lessonFile;

  /// No description provided for @lessonChordCheatSheet.
  ///
  /// In en, this message translates to:
  /// **'Chord cheat sheet'**
  String get lessonChordCheatSheet;

  /// No description provided for @lessonQuiz.
  ///
  /// In en, this message translates to:
  /// **'Lesson quiz'**
  String get lessonQuiz;

  /// No description provided for @lessonStageQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} Quiz'**
  String lessonStageQuizTitle(int stage);

  /// No description provided for @lessonOpenFromVideoPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open this lesson from the video player.'**
  String get lessonOpenFromVideoPlayer;

  /// No description provided for @lessonQuizLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This lesson quiz could not be loaded.'**
  String get lessonQuizLoadFailed;

  /// No description provided for @lessonPdfLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This lesson PDF could not be loaded.'**
  String get lessonPdfLoadFailed;

  /// No description provided for @lessonSightReadingFilesRequired.
  ///
  /// In en, this message translates to:
  /// **'Sight reading requires a matching MIDI and MusicXML pair.'**
  String get lessonSightReadingFilesRequired;

  /// No description provided for @lessonFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'This lesson file is empty.'**
  String get lessonFileEmpty;

  /// No description provided for @lessonQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String lessonQuestionProgress(int current, int total);

  /// No description provided for @lessonQuizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz complete'**
  String get lessonQuizComplete;

  /// No description provided for @lessonQuizScore.
  ///
  /// In en, this message translates to:
  /// **'Your score: {correct}/{total}'**
  String lessonQuizScore(int correct, int total);

  /// No description provided for @lessonQuizPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect score! The next stage will unlock after progress is saved.'**
  String get lessonQuizPerfect;

  /// No description provided for @lessonQuizRetryGuidance.
  ///
  /// In en, this message translates to:
  /// **'Review your answers below. Retry with the questions in a new order for a perfect score.'**
  String get lessonQuizRetryGuidance;

  /// No description provided for @lessonBackToStages.
  ///
  /// In en, this message translates to:
  /// **'Back to stages'**
  String get lessonBackToStages;

  /// No description provided for @lessonYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer: {answer}'**
  String lessonYourAnswer(String answer);

  /// No description provided for @lessonNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get lessonNoAnswer;

  /// No description provided for @lessonCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String lessonCorrectAnswer(String answer);

  /// No description provided for @lessonVideoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The lesson video could not be loaded.'**
  String get lessonVideoLoadFailed;

  /// No description provided for @lessonPauseVideo.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get lessonPauseVideo;

  /// No description provided for @lessonPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get lessonPlayVideo;

  /// No description provided for @lessonBackToPractice.
  ///
  /// In en, this message translates to:
  /// **'Back to Practice'**
  String get lessonBackToPractice;

  /// No description provided for @lessonStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get lessonStartQuiz;

  /// No description provided for @lessonViewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get lessonViewPdf;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
