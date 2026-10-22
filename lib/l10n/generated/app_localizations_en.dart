// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerMusicSheets => 'Music Sheets';

  @override
  String get drawerUploadSheet => 'Upload Sheet';

  @override
  String get drawerPractice => 'Practice';

  @override
  String get drawerPracticeResults => 'Practice Results';

  @override
  String get drawerMidi => 'MIDI';

  @override
  String get drawerMic => 'Mic';

  @override
  String get drawerFlyaway => 'Flyaway';

  @override
  String get drawerSavedSheets => 'Saved Sheets';

  @override
  String get drawerComposition => 'Composition';

  @override
  String get drawerPublishedCompositions => 'Published Compositions';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get filipino => 'Filipino';

  @override
  String get logout => 'Logout';

  @override
  String get logoutQuestion => 'Logout?';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get languageSaveFailed =>
      'The language preference could not be saved.';

  @override
  String get pianoPlayer => 'Piano Player';

  @override
  String get notAssessed => 'Not assessed';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get musicSheets => 'Music Sheets';

  @override
  String get addSheetTooltip => 'Add sheet';

  @override
  String get yourLibrary => 'Your library';

  @override
  String get libraryDescription =>
      'Open and manage your uploaded music sheets.';

  @override
  String get noMusicSheets => 'No music sheets yet';

  @override
  String get noMusicSheetsDescription =>
      'Upload images or a PDF to start building your music-sheet library.';

  @override
  String get addMusicSheet => 'Add Music Sheet';

  @override
  String get musicSheetsLoadError => 'Your music sheets could not be loaded.';

  @override
  String get musicSheetsLoadErrorHelp =>
      'Check your connection and Firebase permissions.';

  @override
  String get signInForMusicSheets => 'Sign in to view your music sheets.';

  @override
  String get untitledSheet => 'Untitled Sheet';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get pdf => 'PDF';

  @override
  String get images => 'Images';

  @override
  String addedDate(String date) {
    return 'Added $date';
  }

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get renameSheet => 'Rename sheet';

  @override
  String get sheetTitle => 'Sheet title';

  @override
  String get enterSheetTitle => 'Enter a title for this sheet.';

  @override
  String get save => 'Save';

  @override
  String get deleteSheetQuestion => 'Delete sheet?';

  @override
  String deleteSheetConfirmation(String title) {
    return '\"$title\" and all of its files will be permanently deleted.';
  }

  @override
  String get musicSheetRenamed => 'Music sheet renamed.';

  @override
  String get musicSheetRenameFailed => 'The music sheet could not be renamed.';

  @override
  String get waitForTranslationBeforeDelete =>
      'Wait for the music-sheet translation to finish before deleting it.';

  @override
  String musicSheetDeleted(String title) {
    return '\"$title\" was deleted.';
  }

  @override
  String get musicSheetDeleteFailed => 'The music sheet could not be deleted.';

  @override
  String get play => 'Play';

  @override
  String get choosePlayMode => 'Choose play mode';

  @override
  String get sightReading => 'Sight Reading';

  @override
  String get synthesia => 'Synthesia';

  @override
  String get arPractice => 'AR Practice';

  @override
  String get translateBeforeAr =>
      'Translate the music sheet before starting AR Practice.';

  @override
  String get translatedMidiMissing => 'The translated MIDI file is missing.';

  @override
  String get openArFailed => 'Could not open AR Practice.';

  @override
  String get translateBeforeSynthesia =>
      'Translate the music sheet before starting Synthesia.';

  @override
  String get openSynthesiaFailed => 'Could not open Synthesia.';

  @override
  String get translateBeforeSightReading =>
      'Translate the music sheet before starting Sight Reading.';

  @override
  String get translatedPracticeFilesMissing =>
      'The translated MusicXML, MIDI, or MP3 file is missing.';

  @override
  String get openSightReadingFailed => 'Could not open Sight Reading.';

  @override
  String get recognized => 'Recognized';

  @override
  String get original => 'Original';

  @override
  String get recognizedPdfLoadFailed =>
      'The recognized PDF could not be loaded. Showing the original sheet instead.';

  @override
  String get retry => 'Retry';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get musicSheetHasNoFiles =>
      'This music sheet does not contain any files.';

  @override
  String get fileLoadFailed => 'The file could not be loaded.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get translateSheetAgainQuestion => 'Translate this sheet again?';

  @override
  String get translateMusicSheetQuestion => 'Translate music sheet?';

  @override
  String retranslateDescription(String title) {
    return 'SoundSight will create a new translation for \"$title\" and replace its current MusicXML, MIDI, recognized PDF, and audio preview.';
  }

  @override
  String translateDescription(String title) {
    return 'SoundSight will translate \"$title\" into MusicXML, MIDI, a recognized PDF, and an audio preview. This may take a few minutes.';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get translate => 'Translate';

  @override
  String get translatingMusicSheet => 'Translating music sheet';

  @override
  String get translationLoadingDescription =>
      'Audiveris is reading the notes. Please wait and keep the app open.';

  @override
  String get translationComplete => 'Translation complete';

  @override
  String translationResult(int noteCount, int partCount) {
    String _temp0 = intl.Intl.pluralLogic(
      noteCount,
      locale: localeName,
      other: '$noteCount notes',
      one: '1 note',
    );
    String _temp1 = intl.Intl.pluralLogic(
      partCount,
      locale: localeName,
      other: '$partCount parts',
      one: '1 part',
    );
    return 'SoundSight recognized $_temp0 across $_temp1.';
  }

  @override
  String get done => 'Done';

  @override
  String get translationFailed => 'Translation failed';

  @override
  String get close => 'Close';

  @override
  String get translationReady => 'Translation ready';

  @override
  String translationSummary(int noteCount, int partCount) {
    String _temp0 = intl.Intl.pluralLogic(
      noteCount,
      locale: localeName,
      other: '$noteCount notes',
      one: '1 note',
    );
    String _temp1 = intl.Intl.pluralLogic(
      partCount,
      locale: localeName,
      other: '$partCount parts',
      one: '1 part',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String get translationFailedDescription =>
      'The sheet could not be translated. You can try again.';

  @override
  String get translationProcessingDescription =>
      'Audiveris is recognizing the notes.';

  @override
  String get translationStartDescription =>
      'Create MusicXML, MIDI, a clean PDF, and an audio preview.';

  @override
  String get reconvert => 'Reconvert';

  @override
  String get translationGenericError =>
      'The music sheet could not be translated.';

  @override
  String get translationTimedOut =>
      'Translation took too long. Check the backend and try again.';

  @override
  String get translationConnectionError =>
      'SoundSight could not connect to the translation service.';

  @override
  String get translationRejected =>
      'The translation service could not process this music sheet.';

  @override
  String get translationInvalidResponse =>
      'The translation service returned an invalid response.';

  @override
  String get audioPreview => 'Audio preview';

  @override
  String get audioLoading => 'Loading audio from Firebase...';

  @override
  String get audioPlaying => 'Playing translated music';

  @override
  String get audioPaused => 'Playback paused';

  @override
  String get audioIdle => 'Listen to the translated music sheet';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get audioPlaybackError => 'The audio preview could not be played.';

  @override
  String get addSheet => 'Add Sheet';

  @override
  String get deleteAllSelectedFilesTooltip => 'Delete all selected files';

  @override
  String get addYourSheetMusic => 'Add your sheet music';

  @override
  String get addSheetDescription =>
      'Upload one PDF or capture clear photos of a printed sheet.';

  @override
  String get chooseOneMethod => 'Choose one method per sheet';

  @override
  String get sheetMethodLimits =>
      '1 PDF (20 MB, 20 pages) or up to 20 captured images (5 MB each). They cannot be combined.';

  @override
  String get openingPdf => 'Opening PDF...';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get uploadPdfDescription => 'Choose 1 PDF, up to 20 MB and 20 pages.';

  @override
  String get capturePages => 'Capture Pages';

  @override
  String get capturePagesDescription => 'Capture up to 20 images, 5 MB each.';

  @override
  String get captureTips => 'Capture tips';

  @override
  String get captureTipsDescription => 'Get a clearer and more accurate result';

  @override
  String get captureTipLighting => 'Use good, even lighting.';

  @override
  String get captureTipFlat => 'Place the sheet music flat on a surface.';

  @override
  String get captureTipVisible =>
      'Keep the entire page visible, straight, and clear.';

  @override
  String get selectedFiles => 'Selected files';

  @override
  String get selectedFileInstructions =>
      'Tap to preview • Swipe right to remove';

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
    return 'Image • $size';
  }

  @override
  String get deleteAllFilesQuestion => 'Delete all files?';

  @override
  String deleteSelectedFilesConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'all $count selected files',
      one: 'the selected file',
    );
    return 'This will remove $_temp0.';
  }

  @override
  String get deleteAll => 'Delete All';

  @override
  String get removeFileQuestion => 'Remove file?';

  @override
  String removeFileConfirmation(String fileName) {
    return 'Do you want to remove $fileName?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get nameYourSheet => 'Name your sheet';

  @override
  String get upload => 'Upload';

  @override
  String get sheetSaved => 'Sheet saved';

  @override
  String get unableToSave => 'Unable to save';

  @override
  String sheetSavedDescription(String title) {
    return '\"$title\" was uploaded and saved successfully.';
  }

  @override
  String get sheetSaveFailedDescription =>
      'The sheet could not be saved. Check your connection and try again.';

  @override
  String get backToSelection => 'Back to selection';

  @override
  String get saveSheet => 'Save Sheet';

  @override
  String savingProgress(int percent) {
    return 'Saving $percent%';
  }

  @override
  String get signInBeforeSaving => 'You need to sign in before saving a sheet.';

  @override
  String get onlyOnePdf =>
      'Only one PDF can be uploaded. Delete the selected PDF before choosing another.';

  @override
  String get deleteImagesBeforePdf =>
      'Delete all captured images before uploading a PDF.';

  @override
  String get selectExactlyOnePdf => 'Select exactly one PDF.';

  @override
  String get onlyPdfFiles => 'Only PDF files can be uploaded.';

  @override
  String get pdfSizeLimit => 'The PDF must be 20 MB or smaller.';

  @override
  String get pdfHasNoPages => 'The PDF does not contain any pages.';

  @override
  String pdfPageLimit(int count, int maximum) {
    return 'This PDF has $count pages. The maximum is $maximum pages.';
  }

  @override
  String get pdfReadFailed =>
      'The PDF could not be read. Make sure it is a valid, unlocked PDF.';

  @override
  String get deletePdfBeforeCapture =>
      'Delete the selected PDF before capturing images.';

  @override
  String imageCountLimit(int maximum) {
    return 'You can only add up to $maximum images.';
  }

  @override
  String get capturedImageSizeLimit =>
      'The captured image is larger than 5 MB. Try capturing it again.';

  @override
  String get openProfile => 'Open profile';

  @override
  String homeGreeting(String username) {
    return 'Hello, $username';
  }

  @override
  String get homeEncouragement =>
      'Keep practicing. Great music starts with you.';

  @override
  String get startPractice => 'Start Practice';

  @override
  String get practiceBannerDescription =>
      'Build your musical skills, improve accuracy, and elevate your performance.';

  @override
  String get playerProgress => 'Player Progress';

  @override
  String get underAssessment => 'Under Assessment';

  @override
  String rankLabel(String rank) {
    return '$rank rank';
  }

  @override
  String levelLabel(int level) {
    return 'LEVEL $level';
  }

  @override
  String get experience => 'Experience';

  @override
  String xpNeeded(int count) {
    return '$count XP needed';
  }

  @override
  String get nextLevel => 'Next level';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get captureSheet => 'Capture Sheet';

  @override
  String get communityCompositions => 'Community Compositions';

  @override
  String get communityCompositionsDescription =>
      'Discover music shared by other users.';

  @override
  String get seeAll => 'See All';

  @override
  String get communityCompositionsLoadFailed =>
      'Community compositions could not be loaded.';

  @override
  String get noCommunityCompositions =>
      'No community compositions have been shared yet.';

  @override
  String communityPlaying(String title) {
    return 'Playing \"$title\".';
  }

  @override
  String get communityPlaybackStopped => 'Playback stopped.';

  @override
  String get communityNoPlaybackData =>
      'This version has no playback data. Republish it first.';

  @override
  String get communityPlaybackFailed =>
      'The published composition could not be played.';

  @override
  String get profile => 'Profile';

  @override
  String get editProfileTooltip => 'Edit profile';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get account => 'Account';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get appAppearance => 'App appearance';

  @override
  String get assessment => 'Assessment';

  @override
  String get retryAssessmentStatus => 'Retry Assessment Status';

  @override
  String get loadingAssessment => 'Loading Assessment';

  @override
  String get startAssessment => 'Start Assessment';

  @override
  String get resumeAssessment => 'Resume Assessment';

  @override
  String get viewAssessmentResults => 'View Assessment Results';

  @override
  String get assessmentExpired => 'Assessment Expired';

  @override
  String get assessmentLoadFailedDescription =>
      'Unable to load the assessment. Tap to try again.';

  @override
  String get assessmentLoadingDescription =>
      'Checking your current assessment status.';

  @override
  String get assessmentNotStartedDescription =>
      'Start whenever you are ready. The timer has not begun.';

  @override
  String get assessmentInProgressDescription =>
      'Continue before the active 72-hour deadline.';

  @override
  String get assessmentCompletedDescription =>
      'Review your permanent level and section scores.';

  @override
  String get assessmentExpiredDescription =>
      'Beginner was assigned permanently. No retry is available.';

  @override
  String get updatePersonalInformation => 'Update your personal information.';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get emailCannotBeChanged => 'Email cannot be changed';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get usernameRequired => 'Username cannot be empty.';

  @override
  String get profileSaveFailed =>
      'Unable to save profile changes. Please try again.';

  @override
  String get profilePictureSizeLimit =>
      'Profile picture must be smaller than 5 MB.';

  @override
  String get saveChangesQuestion => 'Save changes?';

  @override
  String get profileSaveConfirmation =>
      'Are you sure you want to update your profile information?';

  @override
  String get uploadingProfilePicture => 'Uploading profile picture...';

  @override
  String get savingProfileChanges => 'Saving profile changes...';

  @override
  String get pleaseWait => 'Please wait a moment.';

  @override
  String get myCompositions => 'My Compositions';

  @override
  String get newComposition => 'New Composition';

  @override
  String get yourPianoPieces => 'Your piano pieces';

  @override
  String get compositionsDescription =>
      'Create, play, and manage your simple melodies.';

  @override
  String get noCompositions => 'No compositions yet';

  @override
  String get noCompositionsDescription =>
      'Create your first piano piece using melodies, chords, and custom measures.';

  @override
  String get compositionsLoadError => 'Your compositions could not be loaded.';

  @override
  String get signInForCompositions => 'Sign in to view your compositions.';

  @override
  String get compositionSavedFilesReady =>
      'Composition saved and music files are ready.';

  @override
  String get compositionSavedFilesPending =>
      'Composition saved safely. Your sheet music and playback files are not ready yet.';

  @override
  String get compositionSaved => 'Composition saved.';

  @override
  String compositionDeleted(String title) {
    return '\"$title\" was deleted.';
  }

  @override
  String get compositionMusicFilesReady => 'Your music files are ready.';

  @override
  String get compositionMusicFilesFailed =>
      'Your composition is saved, but the music files still could not be prepared. Try again when the service is available.';

  @override
  String get compositionDeleteFailed => 'The composition could not be deleted.';

  @override
  String get deleteCompositionQuestion => 'Delete composition?';

  @override
  String deleteCompositionConfirmation(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get manual => 'Manual';

  @override
  String get recording => 'Recording';

  @override
  String get preparingMusicFiles => 'Preparing your music files';

  @override
  String get musicFilesNeedUpdating => 'Music files need updating';

  @override
  String get musicFilesNotReady => 'Music files are not ready';

  @override
  String get musicFilesOutOfDateDescription =>
      'Your changes are saved, but the available files contain an older version.';

  @override
  String get musicFilesNotReadyDescription =>
      'Your sheet music and playback files are not ready yet.';

  @override
  String get view => 'View';

  @override
  String get notSavedYet => 'Not saved yet';

  @override
  String lastEdited(String date) {
    return 'Last edited $date';
  }

  @override
  String get createYourPianoPiece => 'Create your piano piece';

  @override
  String get newCompositionManualDescription =>
      'Choose the starting title, key, tempo, and meter. You can change them later in the composition workspace.';

  @override
  String get newCompositionRecordingDescription =>
      'Choose a title, key, and meter. Tempo and measures will be detected from your performance.';

  @override
  String get compositionTitle => 'Composition Title';

  @override
  String get compositionTitleHint => 'Example: My First Song';

  @override
  String get compositionTitleRequired => 'Enter a composition title.';

  @override
  String get compositionTitleTooLong =>
      'The title must be 80 characters or fewer.';

  @override
  String get tempo => 'Tempo';

  @override
  String get tempoDescription =>
      'A lower BPM sounds slower. A higher BPM sounds faster.';

  @override
  String get tempoRangeHint => '40 to 200';

  @override
  String get validTempoRequired => 'Enter a valid tempo.';

  @override
  String get tempoRangeError => 'Tempo must be between 40 and 200 BPM.';

  @override
  String get detectedTempoDescription =>
      'Tempo and measure count will be detected from how you play.';

  @override
  String get compositionSettings => 'Composition Settings';

  @override
  String get compositionSettingsDescription =>
      'Set the musical structure for this piece.';

  @override
  String get keySignature => 'Key Signature';

  @override
  String get timeSignature => 'Time Signature';

  @override
  String get opening => 'Opening...';

  @override
  String get openRecorder => 'Open Recorder';

  @override
  String get startComposing => 'Start Composing';

  @override
  String get signInBeforeCreatingComposition =>
      'Sign in before creating a composition.';

  @override
  String get compositionDetails => 'Composition Details';

  @override
  String get editComposition => 'Edit Composition';

  @override
  String get deleteComposition => 'Delete Composition';

  @override
  String get pianoSolo => 'Piano Solo';

  @override
  String get keyLabel => 'Key';

  @override
  String get timeLabel => 'Time';

  @override
  String get editedLabel => 'Edited';

  @override
  String get loading => 'Loading';

  @override
  String get paused => 'Paused';

  @override
  String get playing => 'Playing';

  @override
  String get ready => 'Ready';

  @override
  String get listenToComposition => 'Listen to your composition';

  @override
  String get playFromBeginning => 'Play from beginning';

  @override
  String get compositionSummary => 'Composition Summary';

  @override
  String measureLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Measures',
      one: 'Measure',
    );
    return '$_temp0';
  }

  @override
  String noteLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notes',
      one: 'Note',
    );
    return '$_temp0';
  }

  @override
  String get duration => 'Duration';

  @override
  String get musicFilesReady => 'Music files are ready';

  @override
  String get musicFilesReadyDescription =>
      'Your sheet music and playback files are ready.';

  @override
  String musicFilesPrepared(String date) {
    return 'Prepared $date.';
  }

  @override
  String get retryGeneration => 'Retry Generation';

  @override
  String get checkingPublicationStatus => 'Checking publication status...';

  @override
  String get publishingUpdateProgress => 'Publishing Update...';

  @override
  String get unpublishingProgress => 'Unpublishing...';

  @override
  String get publishingProgress => 'Publishing...';

  @override
  String get publishUpdate => 'Publish Update';

  @override
  String get publish => 'Publish';

  @override
  String get unpublishComposition => 'Unpublish Composition';

  @override
  String get publishComposition => 'Publish Composition';

  @override
  String get deletingProgress => 'Deleting...';

  @override
  String get compositionHasNoNotes =>
      'This composition does not have any notes yet.';

  @override
  String get compositionValidationFailed =>
      'This composition contains invalid data and cannot be played.';

  @override
  String get compositionPlaybackFailed =>
      'The composition could not be played. Check the piano audio files.';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get addNoteBeforePublishing =>
      'Add at least one note before publishing.';

  @override
  String get prepareFilesBeforePublishing =>
      'Prepare the sheet music and playback files before publishing.';

  @override
  String get compositionUnpublished => 'Composition unpublished successfully.';

  @override
  String get compositionUpdatePublished =>
      'Composition update published successfully.';

  @override
  String get compositionPublished => 'Composition published successfully.';

  @override
  String get compositionUnpublishFailed =>
      'The composition could not be unpublished.';

  @override
  String get compositionPublishFailed =>
      'The composition could not be published. Make sure the backend is running.';

  @override
  String get compositionPublishUnauthorized =>
      'Your publishing session could not be verified. Please sign out, sign in again, and retry.';

  @override
  String get updatedCompositionLoadFailed =>
      'The updated composition could not be loaded.';

  @override
  String get prepareLatestFilesBeforeAr =>
      'Prepare the latest music files before starting AR Practice.';

  @override
  String get generatedMidiMissing => 'The generated MIDI file is missing.';

  @override
  String get prepareLatestFilesBeforeSightReading =>
      'Prepare the latest music files before starting Sight Reading.';

  @override
  String get generatedPracticeFilesMissing =>
      'The generated MusicXML, MIDI, or MP3 file is missing.';

  @override
  String publishUpdateQuestion(String title) {
    return 'Publish the latest changes to \"$title\"?';
  }

  @override
  String publishCompositionQuestion(String title) {
    return 'Publish \"$title\"?';
  }

  @override
  String get publishUpdateDescription =>
      'A new published version and PDF will be created. Previous versions, likes, comments, and saves will remain.';

  @override
  String get publishCompositionDescription =>
      'A PDF music sheet will be created and shared with other SoundSight users.';

  @override
  String get unpublishCompositionQuestion => 'Unpublish composition?';

  @override
  String unpublishCompositionConfirmation(String title) {
    return '\"$title\" and all of its published versions will be removed from the community feed.';
  }

  @override
  String get unpublish => 'Unpublish';

  @override
  String get unpublishingComposition => 'Unpublishing composition...';

  @override
  String get unpublishingCompositionDescription =>
      'Removing every published version and PDF. Please wait.';

  @override
  String get generatedPreview => 'Generated preview';

  @override
  String get generatedPreviewDescription =>
      'Review your sheet music and listen before publishing.';

  @override
  String get compositionPlayback => 'Composition playback';

  @override
  String get loadingComposition => 'Loading your composition...';

  @override
  String get playingComposition => 'Playing your composition';

  @override
  String get listenGeneratedComposition =>
      'Listen to the generated composition';

  @override
  String get sheetMusic => 'Sheet music';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get sheetMusicLoadFailed => 'The sheet music could not be loaded.';

  @override
  String get checkConnectionTryAgain =>
      'Check your connection, then try again.';

  @override
  String get compositionSettingsTooltip => 'Composition settings';

  @override
  String get saveCompositionTooltip => 'Save composition';

  @override
  String get automaticDurationDescription =>
      'Automatic follows how long you hold the MIDI keys.';

  @override
  String get automaticKeyHoldHelper => 'Automatic uses key hold time.';

  @override
  String get pianoKeyboard => 'Piano Keyboard';

  @override
  String get swipeHorizontally => 'Swipe horizontally';

  @override
  String get back => 'Back';

  @override
  String get forward => 'Forward';

  @override
  String get moveBackUsingDuration => 'Move back using selected duration';

  @override
  String get moveForwardUsingDuration => 'Move forward using selected duration';

  @override
  String get rest => 'Rest';

  @override
  String get insertRest => 'Insert Rest';

  @override
  String get insertRestUsingDuration => 'Insert rest using selected duration';

  @override
  String get overview => 'Overview';

  @override
  String get toggleSongOverview => 'Show or hide full-song overview';

  @override
  String get saving => 'Saving';

  @override
  String get savingEllipsis => 'Saving...';

  @override
  String get saveComposition => 'Save Composition';

  @override
  String get beat => 'beat';

  @override
  String get beats => 'beats';

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
  String get clearSelection => 'Clear selection';

  @override
  String get tied => 'Tied';

  @override
  String get addMeasure => 'Add Measure';

  @override
  String get deleteSelection => 'Delete Selection';

  @override
  String get unsupportedPianoKey =>
      'That piano key is outside the supported A0 to C8 range.';

  @override
  String get selectSingleNoteBeforePlaying =>
      'Select only one note, or clear the selection, before playing.';

  @override
  String get clearSelectedNoteBeforeChord =>
      'Clear the selected note before entering a chord.';

  @override
  String get stopPlaybackBeforeEditing =>
      'Stop playback before editing the composition.';

  @override
  String compositionNoteLimitReached(int count) {
    return 'This composition now has $count of the 256 allowed notes.';
  }

  @override
  String get pianoNotePlaybackFailed => 'The piano note could not be played.';

  @override
  String get measureActionUnavailable =>
      'That measure action is not available.';

  @override
  String get selectNoteFirst => 'Select at least one note first.';

  @override
  String notesCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes copied.',
      one: '1 note copied.',
    );
    return '$_temp0';
  }

  @override
  String get selectChordFirst => 'Select a chord first.';

  @override
  String get addNoteBeforePlaying => 'Add at least one note before playing.';

  @override
  String get compositionSaveFailed => 'The composition could not be saved.';

  @override
  String get chordMode => 'Chord Mode';

  @override
  String chordNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get allowStacking => 'Allow stacking';

  @override
  String get chordModeDescription =>
      'Allow multiple notes to start on the same beat.';

  @override
  String chordNotesCombined(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes combined',
      one: '1 note combined',
    );
    return '$_temp0';
  }

  @override
  String get finishChord => 'Finish Chord';

  @override
  String get layerNotes => 'Layer Notes';

  @override
  String measureBeatPosition(int measure, String beat) {
    return 'Measure $measure • Beat $beat';
  }

  @override
  String get independentNotes => 'Independent notes';

  @override
  String addNextNoteHere(String position) {
    return '$position — add the next note here.';
  }

  @override
  String get layerNotesDescription =>
      'Add shorter notes while another note continues playing.';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get selectAll => 'Select All';

  @override
  String get removeTie => 'Remove Tie';

  @override
  String get tieToNext => 'Tie to Next';

  @override
  String get deleteWholeChord => 'Delete Whole Chord';

  @override
  String get historyAndEditing => 'History and editing';

  @override
  String get performanceSettings => 'Performance settings';

  @override
  String get performance => 'Performance';

  @override
  String get performanceDescription =>
      'Adjust playback and how new notes sound.';

  @override
  String get volume => 'Volume';

  @override
  String get noteVelocity => 'Note velocity';

  @override
  String get fromCursor => 'From cursor';

  @override
  String get loopMeasure => 'Loop measure';

  @override
  String get sustain => 'Sustain';

  @override
  String get metronome => 'Metronome';

  @override
  String get resume => 'Resume';

  @override
  String get playback => 'Playback';

  @override
  String get pianoRoll => 'Piano Roll';

  @override
  String measureNumber(int number) {
    return 'Measure $number';
  }

  @override
  String get deleteSelectedNote => 'Delete selected note';

  @override
  String get deleteSelectedNotes => 'Delete selected notes';

  @override
  String get measures => 'Measures';

  @override
  String get measure => 'Measure';

  @override
  String totalCount(int count) {
    return '$count total';
  }

  @override
  String get previousMeasure => 'Previous measure';

  @override
  String get nextMeasure => 'Next measure';

  @override
  String get previousOctave => 'Previous octave';

  @override
  String get selectOctave => 'Select octave';

  @override
  String octaveNumber(int number) {
    return 'Octave $number';
  }

  @override
  String octaveWithRange(int number, String range) {
    return 'Octave $number - $range';
  }

  @override
  String get nextOctave => 'Next octave';

  @override
  String get viewAllNotes => 'View all notes';

  @override
  String notesBelowOctave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes below this octave',
      one: '1 note below this octave',
    );
    return '$_temp0';
  }

  @override
  String notesAboveOctave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes above this octave',
      one: '1 note above this octave',
    );
    return '$_temp0';
  }

  @override
  String get tapPianoKeyToAdd => 'Tap a piano key to add a note';

  @override
  String get noNotesInOctave => 'No notes in this octave';

  @override
  String get allNotes => 'All Notes';

  @override
  String get noNotesAdded => 'No notes have been added yet.';

  @override
  String beatWithNotes(String beat, String notes) {
    return 'Beat $beat: $notes';
  }

  @override
  String pianoKeySemanticLabel(String key) {
    return 'Piano key $key';
  }

  @override
  String get measureActions => 'Measure actions';

  @override
  String get addMeasureAfter => 'Add measure after';

  @override
  String get insertMeasureBefore => 'Insert measure before';

  @override
  String get duplicateMeasure => 'Duplicate measure';

  @override
  String get moveMeasureLeft => 'Move measure left';

  @override
  String get moveMeasureRight => 'Move measure right';

  @override
  String get clearMeasure => 'Clear measure';

  @override
  String get deleteMeasure => 'Delete measure';

  @override
  String get wholeNote => 'Whole';

  @override
  String get dottedHalfNote => 'Dotted Half';

  @override
  String get halfNote => 'Half';

  @override
  String get dottedQuarterNote => 'Dotted Quarter';

  @override
  String get quarterNote => 'Quarter';

  @override
  String get dottedEighthNote => 'Dotted Eighth';

  @override
  String get eighthNote => 'Eighth';

  @override
  String get triplet => 'Triplet';

  @override
  String get sixteenthNote => 'Sixteenth';

  @override
  String get chooseLengthBeforePiano =>
      'Choose the length before tapping a piano key.';

  @override
  String get automatic => 'Automatic';

  @override
  String get chooseNoteDuration => 'Choose Note Duration';

  @override
  String get chooseFixedOrKeyHold =>
      'Choose a fixed length or let your key hold set it.';

  @override
  String get chooseNextNoteLength => 'Choose how long the next note will be.';

  @override
  String get useKeyHoldTime => 'Use key hold time';

  @override
  String get swipeToViewPiano => 'Swipe horizontally to view the piano';

  @override
  String get apply => 'Apply';

  @override
  String get saveCompositionQuestion => 'Save composition?';

  @override
  String get replaceSavedCompositionDescription =>
      'Your current changes will replace the previously saved version.';

  @override
  String get createCompositionFilesDescription =>
      'Your composition and its music files will be created.';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get discardUnsavedChanges => 'Discard unsaved changes?';

  @override
  String get discardUnsavedChangesDescription =>
      'Your changes will be lost if you leave without saving.';

  @override
  String get discard => 'Discard';

  @override
  String get switchCamera => 'Switch camera';

  @override
  String get generatingCompositionFiles => 'Generating composition files...';

  @override
  String get keepScreenOpen => 'Please keep this screen open.';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get startRecording => 'Start recording';

  @override
  String get noCameraAvailable => 'No camera is available on this device.';

  @override
  String get cameraOpenFailed => 'The camera could not be opened.';

  @override
  String recordingNoteLimitWarning(int current, int maximum) {
    return 'You have captured $current of the $maximum-note limit.';
  }

  @override
  String recordingNoteLimitReached(int maximum) {
    return 'The $maximum-note limit was reached. Release held keys to finish.';
  }

  @override
  String get recordingStartFailed => 'Could not start recording.';

  @override
  String get recordingLengthWarning =>
      'You are close to the maximum recording length.';

  @override
  String get recordingLengthReached =>
      'The maximum recording length was reached.';

  @override
  String get releaseHeldKeysToFinish =>
      'Release the held keys to finish the recording.';

  @override
  String get cameraSaveRestarted =>
      'The camera could not finish saving the video. The camera was restarted.';

  @override
  String get videoRecordingFailed => 'The video recording failed.';

  @override
  String get noNotesRecorded => 'No notes were recorded';

  @override
  String get noNotesRecordedDescription =>
      'Play at least one complete note on the connected MIDI piano before stopping.';

  @override
  String get recordAgain => 'Record Again';

  @override
  String get compositionCreated => 'Composition created successfully.';

  @override
  String get compositionNotSaved => 'Composition not saved';

  @override
  String get recordingStillAvailable =>
      'Your recording is still available. Check your connection and try saving again.';

  @override
  String get retrySave => 'Retry Save';

  @override
  String get filesNotGenerated => 'Files were not generated';

  @override
  String get filesNotGeneratedDescription =>
      'The composition was saved, but its PDF, MIDI, MusicXML, and MP3 could not be created.';

  @override
  String get finish => 'Finish';

  @override
  String get recordingComplete => 'Recording Complete';

  @override
  String get capturedNotes => 'Captured notes';

  @override
  String get detectedTempo => 'Detected tempo';

  @override
  String get calculatedMeasures => 'Calculated measures';

  @override
  String get generate => 'Generate';

  @override
  String get exploreMusic => 'Explore music';

  @override
  String get exploreMusicDescription =>
      'View music sheets shared by other SoundSight users.';

  @override
  String get noPublishedCompositions => 'No published compositions yet';

  @override
  String get noPublishedCompositionsDescription =>
      'Published music sheets from the SoundSight community will appear here.';

  @override
  String get publishedCompositionsLoadFailed =>
      'Published compositions could not be loaded.';

  @override
  String get checkConnectionFirestorePermissions =>
      'Check your connection and Firestore permissions.';

  @override
  String get signInForPublishedCompositions =>
      'Sign in to view published compositions.';

  @override
  String publishedCompositionUnpublished(String title) {
    return '\"$title\" was unpublished.';
  }

  @override
  String get signInForSavedSheets => 'Sign in to view saved sheets.';

  @override
  String get savedSheetsSignedOutDescription =>
      'Your saved composition versions will appear here.';

  @override
  String get savedSheetsLoadFailed => 'Saved sheets could not be loaded.';

  @override
  String get noSavedSheets => 'No saved sheets yet';

  @override
  String get noSavedSheetsDescription =>
      'Save a published version to find it here.';

  @override
  String publishedBy(String author) {
    return 'By $author';
  }

  @override
  String versionLabel(int version) {
    return 'Version $version';
  }

  @override
  String compositionMeasureCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count measures',
      one: '1 measure',
    );
    return '$_temp0';
  }

  @override
  String compositionNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get saved => 'Saved';

  @override
  String get viewSheet => 'View Sheet';

  @override
  String get likeUpdateFailed => 'The like could not be updated.';

  @override
  String get savedCompositionUpdateFailed =>
      'The saved composition could not be updated.';

  @override
  String get removeSavedSheetQuestion => 'Remove saved sheet?';

  @override
  String get saveSheetQuestion => 'Save this sheet?';

  @override
  String removeSavedSheetDescription(String title, int version) {
    return 'Remove \"$title\" version $version from Saved Sheets?';
  }

  @override
  String saveSheetDescription(String title, int version) {
    return 'Save \"$title\" version $version so you can find it later in Saved Sheets?';
  }

  @override
  String get recentlyPublished => 'Recently published';

  @override
  String publishedOn(String date) {
    return 'Published $date';
  }

  @override
  String get stopPlaybackTooltip => 'Stop playback';

  @override
  String get playCompositionTooltip => 'Play composition';

  @override
  String get publishedSightReadingUnavailable =>
      'Sight Reading files are unavailable. Ask the owner to publish the composition again.';

  @override
  String get publishedArFileUnavailable =>
      'The MIDI file for AR Practice is unavailable. Ask the owner to publish the composition again.';

  @override
  String get publishedSheetLoadFailed => 'The music sheet could not be loaded.';

  @override
  String get checkConnectionStoragePermissions =>
      'Check your connection and Firebase Storage permissions.';

  @override
  String commentsVersion(int version) {
    return 'Comments • V$version';
  }

  @override
  String get commentsLoadFailed => 'Comments could not be loaded.';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get noCommentsDescription => 'Be the first to share your thoughts.';

  @override
  String get deleteCommentTooltip => 'Delete comment';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get commentPostFailed => 'The comment could not be posted.';

  @override
  String get deleteCommentQuestion => 'Delete comment?';

  @override
  String get deleteCommentDescription =>
      'This comment will be removed permanently.';

  @override
  String get commentDeleteFailed => 'The comment could not be deleted.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get namePianoSetup => 'Name this piano setup';

  @override
  String get pianoSetupName => 'Piano setup name';

  @override
  String get pianoSetupNameHint => 'Example: Bedroom Piano';

  @override
  String get enterPianoSetupName => 'Enter a name for this piano setup.';

  @override
  String get searchingForPiano => 'Searching for piano';

  @override
  String get pointCameraAtKeyboard => 'Point the camera at the piano keyboard';

  @override
  String get moveFartherBack => 'Move farther back';

  @override
  String get makeMorePianoKeysVisible =>
      'Make more piano keys visible in the camera';

  @override
  String get keepKeyboardClear => 'Keep the keyboard clear';

  @override
  String get moveObjectsOutOfView =>
      'Move your hands and other objects out of view';

  @override
  String get holdPhoneSteady => 'Hold the phone steady';

  @override
  String get keepCameraStill => 'Keep the camera still for a moment';

  @override
  String get pianoDetected => 'Piano detected';

  @override
  String get visibleKeyboardReady => 'The visible keyboard area is ready';

  @override
  String get checkVisibleKeys => 'Check the visible keys';

  @override
  String get dragCornersAroundKeys =>
      'Drag the white corners so they surround the piano keys';

  @override
  String get selectMiddleC => 'Select Middle C';

  @override
  String get tapMiddleCInCamera =>
      'Tap Middle C on the piano shown by the camera';

  @override
  String get connectingToPiano => 'Connecting to your piano';

  @override
  String get pianoConnectionNeeded => 'Piano connection needed';

  @override
  String get searchingAvailableKeyboard =>
      'Searching for an available keyboard';

  @override
  String reconnectOrUseManualGuide(String status) {
    return '$status. Reconnect or use the manual guide.';
  }

  @override
  String get middleCFound => 'Middle C found';

  @override
  String get releaseMiddleCToContinue => 'Release Middle C to continue';

  @override
  String get tapSameKeyInCamera => 'Tap the same key in the camera view';

  @override
  String get findMiddleC => 'Find Middle C';

  @override
  String get pressWhiteKeyNearCenter =>
      'Press any white key near the keyboard center';

  @override
  String get blackKeyPressed =>
      'That was a black key. Press a nearby white key.';

  @override
  String get left => 'left';

  @override
  String get right => 'right';

  @override
  String moveWhiteKeys(int count, String direction) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count white keys',
      one: '1 white key',
    );
    return 'Move $_temp0 $direction.';
  }

  @override
  String get pianoKeysReady => 'Piano keys ready';

  @override
  String get checkKeyLabels =>
      'Check that each label is placed on the correct key';

  @override
  String get middleCSelected => 'Middle C selected';

  @override
  String get moveBackForMoreKeys =>
      'Move farther back if you want to include more keys';

  @override
  String get connectingToDigitalPiano => 'Connecting to your digital piano';

  @override
  String get digitalPianoNotConnected => 'Digital piano not connected';

  @override
  String get connectPianoOrUseManualGuide =>
      'Connect it to find Middle C, or use the manual guide';

  @override
  String get releaseMiddleCThenAlign =>
      'Release it, then use this key to line up the saved shapes';

  @override
  String get useMiddleCAsGuide => 'Use Middle C as your guide';

  @override
  String get alignSavedC4Shape =>
      'Line up the saved C4 shape with this key on your piano';

  @override
  String get alignPianoSetup => 'Line up your piano setup';

  @override
  String get matchSavedShapes =>
      'Match the saved shapes with the piano, then continue';

  @override
  String get pianoSetupLoaded => 'Piano setup loaded';

  @override
  String get pianoSetupSaved => 'Piano setup saved';

  @override
  String get pianoSetupPreparationFailed =>
      'This piano setup could not be prepared';

  @override
  String get pianoSetupDefaultName => 'Piano setup';

  @override
  String pianoSetupReady(String name) {
    return '\"$name\" is ready to use';
  }

  @override
  String get savingPianoSetup => 'Saving your piano setup';

  @override
  String get keepOpenWhileSavingSetup =>
      'Keep this screen open until saving is complete';

  @override
  String get pianoSetupNotSaved => 'Piano setup not saved';

  @override
  String get loadingPianoSetup => 'Loading your piano setup';

  @override
  String get preparingSavedPianoKeys => 'Preparing your saved piano keys';

  @override
  String get noRearCameraAvailable =>
      'No rear camera is available on this device.';

  @override
  String get calibrationCameraOpenFailed =>
      'SoundSight could not open the camera. Check the camera permission and try again.';

  @override
  String get recalibrate => 'Recalibrate';

  @override
  String get useMidiGuide => 'Use MIDI guide';

  @override
  String get connecting => 'Connecting';

  @override
  String get useManualGuide => 'Use manual guide';

  @override
  String get adjustVisibleKeys => 'Adjust visible keys';

  @override
  String get savePianoSetup => 'Save piano setup';

  @override
  String get setUpAgain => 'Set up again';

  @override
  String get makeChanges => 'Make changes';

  @override
  String get useAction => 'Use';

  @override
  String get keysAreVisible => 'Keys are visible';

  @override
  String get pianoSetupSaveFailed =>
      'Could not save your piano setup. Check your internet connection and try again.';

  @override
  String get needHelpFindingMiddleC => 'Need help finding Middle C?';

  @override
  String get middleCHelpSavedAlignment =>
      'Connect your digital piano with its USB or MIDI cable before positioning the phone. SoundSight will guide you to Middle C, then you can use that key to line up the saved shapes with your piano.';

  @override
  String get middleCHelpNewCalibration =>
      'Connect your digital piano with its USB or MIDI cable before positioning the phone. After the piano keys are visible, SoundSight will guide you to Middle C.';

  @override
  String get manualGuide => 'Manual guide';

  @override
  String get iKnowMiddleC => 'I know it';

  @override
  String get connectPiano => 'Connect piano';

  @override
  String get digitalPianoNotFound => 'Digital piano not found';

  @override
  String get digitalPianoNotFoundDescription =>
      'Make sure your digital piano is turned on and its cable is connected to this phone. You can also find Middle C by looking at the black keys.';

  @override
  String get findMiddleCManually => 'Find Middle C manually';

  @override
  String findMiddleCManuallyDescription(String instruction) {
    return 'Near the center of the keyboard, find a group of two black keys. Middle C, sometimes labeled C4, is the white key immediately to the left of that pair. $instruction';
  }

  @override
  String get manualGuideSavedAlignment =>
      'Use Middle C as a reference while positioning the phone until the shapes on screen line up with the piano keys.';

  @override
  String get manualGuideBeforeCalibration =>
      'Position the phone so the piano keys are visible, then tap Middle C on the camera view when asked.';

  @override
  String get manualGuideTapKey => 'Tap that white key in the camera view.';

  @override
  String get gotIt => 'Got it';

  @override
  String get digitalPianoDisconnected => 'Your digital piano was disconnected';

  @override
  String get searching => 'Searching';

  @override
  String get noDigitalPianoFound => 'No digital piano found';

  @override
  String connectedDevice(String device) {
    return 'Connected: $device';
  }

  @override
  String get digitalPianoConnected => 'Digital piano connected';

  @override
  String digitalPianoReadyForCalibration(String device) {
    return '$device is ready. Keep it connected, then position the phone over the keyboard.';
  }

  @override
  String digitalPianoReady(String device) {
    return '$device is ready to use.';
  }

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get songStillLoading => 'The song is still loading. Try again.';

  @override
  String get noPlayableKeys => 'no playable keys';

  @override
  String remainingNotes(String notes, int count) {
    return '$notes, and $count more';
  }

  @override
  String get morePianoKeysNeeded => 'More piano keys are needed';

  @override
  String morePianoKeysDescription(
    String requiredRange,
    String calibrationRange,
    String missingNotes,
  ) {
    return 'This song uses notes from $requiredRange, but the camera can currently see $calibrationRange.\n\nKeys outside the camera view: $missingNotes\n\nMove the phone farther back and set up the piano again, or choose another saved piano setup that shows all of these keys.';
  }

  @override
  String get reviewPianoSetup => 'Review piano setup';

  @override
  String get preparePhoneForCalibration => 'Prepare your phone';

  @override
  String get preparePhoneForCalibrationDescription =>
      'Set up your phone before calibration so SoundSight can detect the piano accurately.';

  @override
  String get mountPhoneSecurely =>
      'Mount the phone securely on an arm, stand, or stable holder.';

  @override
  String get useLandscapeOrientation =>
      'Rotate the phone to landscape orientation.';

  @override
  String get keepPianoKeysVisible =>
      'Position the camera above the keyboard and keep all keys you plan to use visible.';

  @override
  String get useClearLighting =>
      'Use even lighting and avoid strong shadows or glare.';

  @override
  String get keepPhoneFixed =>
      'Keep the phone fixed throughout calibration and practice.';

  @override
  String get clearKeyboardBeforeDetection =>
      'Remove hands and other objects while SoundSight detects the keyboard.';

  @override
  String get calibrationGuideTitle => 'Calibration guide';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get startCalibration => 'Start calibration';

  @override
  String get calibrationGuideImageUnavailable =>
      'This guide image could not be displayed.';

  @override
  String get calibrationGuideMountTitle => 'Mount and position your phone';

  @override
  String get calibrationGuideMountDescription =>
      'Secure your phone to an arm, stand, or stable holder. Keep it in landscape above the keyboard, with the rear camera facing the keys. Use even lighting, avoid strong shadows, and do not move the phone during calibration.';

  @override
  String get calibrationGuideDetectedGroupTitle =>
      'Review the detected key group';

  @override
  String get calibrationGuideDetectedGroupDescription =>
      'SoundSight will place a green outline around the group of keys it detected. This outlined group—not every key visible in the camera—is the area the app will use.';

  @override
  String get calibrationGuideDetectedGroupEmphasis =>
      'Do not expand the outline to cover all visible keys.';

  @override
  String get calibrationGuideAdjustCornersTitle =>
      'Fit the corners to that group';

  @override
  String get calibrationGuideAdjustCornersDescription =>
      'Drag each white corner so the green outline follows the four outer corners of the detected key group. Include the full length of those keys, but leave any keys outside that group out of the outline.';

  @override
  String get calibrationGuideAdjustCornersEmphasis =>
      'Outline only the group SoundSight selected.';

  @override
  String get calibrationGuideMiddleCTitle => 'Select Middle C (C4)';

  @override
  String get calibrationGuideMiddleCDescription =>
      'When the key labels appear, tap C4 in the camera view. It is the white key immediately to the left of a group of two black keys near the middle of the keyboard. Check that the other labels line up before saving.';

  @override
  String get pianoSetupScreenTitle => 'Piano Setup';

  @override
  String get deleteAllPianoSetupsTooltip => 'Delete all piano setups';

  @override
  String get preparingSong => 'Preparing song...';

  @override
  String get newPianoSetup => 'New piano setup';

  @override
  String get choosePianoSetup => 'Choose your piano setup';

  @override
  String get savedPianoSetup => 'Saved piano setup';

  @override
  String pianoSetupLastSaved(String date, String time) {
    return 'Last saved $date at $time';
  }

  @override
  String get deletePianoSetupQuestion => 'Delete piano setup?';

  @override
  String deletePianoSetupDescription(String name) {
    return 'This permanently deletes \"$name\". This cannot be undone.';
  }

  @override
  String pianoSetupDeleted(String name) {
    return '\"$name\" was deleted.';
  }

  @override
  String get pianoSetupDeleteFailed => 'The piano setup could not be deleted.';

  @override
  String get deleteAllPianoSetupsQuestion => 'Delete all piano setups?';

  @override
  String get deleteAllPianoSetupsDescription =>
      'Every saved piano setup will be permanently deleted. This cannot be undone.';

  @override
  String get allPianoSetupsDeleted => 'All piano setups were deleted.';

  @override
  String get somePianoSetupsDeleteFailed =>
      'Some piano setups could not be deleted.';

  @override
  String get noSavedPianoSetups => 'No saved piano setups yet';

  @override
  String get createPianoSetupDescription =>
      'Create a piano setup so SoundSight knows where the keys are.';

  @override
  String get loadingYourPianoSetups => 'Loading your piano setups...';

  @override
  String get pianoSetupsLoadFailed => 'Could not load your piano setups.';

  @override
  String get checkConnectionThenTryAgain =>
      'Check your connection, then try again.';

  @override
  String get songPreparationForArFailed =>
      'Could not prepare this song for AR Practice.';

  @override
  String get selectedPianoSetupLoadFailed =>
      'Could not load the selected piano setup.';

  @override
  String get synthesiaPerformanceMode => 'Performance Mode';

  @override
  String get synthesiaWaitMode => 'Wait Mode';

  @override
  String get synthesiaPerformanceModeDescription =>
      'Play with the moving timeline while your pitch and timing are evaluated.';

  @override
  String get synthesiaWaitModeDescription =>
      'Practice at your own pace while the timeline waits for every note or chord.';

  @override
  String get synthesiaPerformanceDetailMovingNotes =>
      'The falling notes continue moving when a note is missed.';

  @override
  String get synthesiaPerformanceDetailEvaluation =>
      'Your notes, timing, chords, and held-note lengths are evaluated.';

  @override
  String get synthesiaPerformanceDetailSkillTiming =>
      'Your timing allowance follows your current player level.';

  @override
  String get synthesiaWaitDetailNoTimeLimit =>
      'There is no time limit while you practice.';

  @override
  String get synthesiaWaitDetailHoldNotes =>
      'Hold long notes while later notes and chords continue toward the line.';

  @override
  String get synthesiaWaitDetailReleaseKeys =>
      'Release each key after its falling note has been fully consumed.';

  @override
  String get synthesiaWaitDetailDragTimeline =>
      'Drag vertically through the falling-note area to revisit another part of the score.';

  @override
  String synthesiaSwitchToModeQuestion(String mode) {
    return 'Switch to $mode?';
  }

  @override
  String get synthesiaSwitchMode => 'Switch Mode';

  @override
  String get synthesiaConnectMidiKeyboard => 'Connect your MIDI keyboard';

  @override
  String get synthesiaPerformanceRequiresMidi =>
      'Performance Mode needs your MIDI keyboard to evaluate the notes you play and their timing.';

  @override
  String get synthesiaWaitRequiresMidi =>
      'Wait Mode needs your MIDI keyboard to hear each note and move the timeline forward.';

  @override
  String get synthesiaConnectMidi => 'Connect MIDI';

  @override
  String get synthesiaMidiDisconnected => 'MIDI disconnected';

  @override
  String get synthesiaSearchingMidiPiano => 'Searching for MIDI piano...';

  @override
  String get synthesiaNoMidiPianoDetected => 'No MIDI piano detected';

  @override
  String synthesiaConnectingToDevice(String device) {
    return 'Connecting to $device...';
  }

  @override
  String get synthesiaMidiConnectionFailed => 'MIDI connection failed.';

  @override
  String get synthesiaCouldNotConnectMidiPiano =>
      'Could not connect to the MIDI piano';

  @override
  String get synthesiaConnectionRestoredStartAgain =>
      'Connection restored. Start again when you are ready.';

  @override
  String get synthesiaConnectionRestoredPlayAgain =>
      'Connection restored—play this part again.';

  @override
  String get synthesiaNoMp3Preview => 'This score has no MP3 audio preview.';

  @override
  String get synthesiaMp3PlaybackFailed =>
      'The MP3 preview could not be played.';

  @override
  String get synthesiaTryAgainHoldFullLength =>
      'Try again—hold each key for its full note length.';

  @override
  String get synthesiaTryHighlightedAgain =>
      'Try the highlighted note or chord again.';

  @override
  String get synthesiaReleaseMistakenNotes =>
      'Release the mistaken notes, then try this part again.';

  @override
  String get synthesiaReleaseChordPressTogether =>
      'Release the chord, then press its notes together.';

  @override
  String get synthesiaCorrectNotesKeepHolding => 'Correct notes—keep holding.';

  @override
  String synthesiaNoteHeldTooLong(String note) {
    return '$note was held too long';
  }

  @override
  String synthesiaReleaseAllNoteHeldTooLong(String note) {
    return 'Release all keys—$note was held too long.';
  }

  @override
  String synthesiaReleaseNotes(String notes) {
    return 'Release $notes';
  }

  @override
  String synthesiaPlayNotes(String notes) {
    return 'Play $notes';
  }

  @override
  String synthesiaHoldWhilePlaying(String heldNotes, String expectedNotes) {
    return 'Hold $heldNotes while playing $expectedNotes';
  }

  @override
  String get synthesiaGetReadyNextNote => 'Get ready for the next note.';

  @override
  String synthesiaNoteReleasedTooSoon(String note) {
    return '$note was released too soon';
  }

  @override
  String get synthesiaReleasedTooSoonTryAgain =>
      'Released too soon—release all keys and try again.';

  @override
  String get synthesiaReleaseAllBeforeMoving =>
      'Release all keys before moving to another part.';

  @override
  String get synthesiaPerfect => 'Perfect!';

  @override
  String get synthesiaExerciseCompleted => 'Exercise Completed';

  @override
  String get synthesiaCompletedWithoutMistakes =>
      'You completed the score without any mistakes.';

  @override
  String synthesiaCompletedWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You completed the score with $count mistakes. Review the detailed feedback below.',
      one:
          'You completed the score with 1 mistake. Review the detailed feedback below.',
    );
    return '$_temp0';
  }

  @override
  String get synthesiaCorrectOnTime => 'Correct on time';

  @override
  String get synthesiaWrongNotes => 'Wrong notes';

  @override
  String get synthesiaNotPlayed => 'Not played';

  @override
  String get synthesiaPlayedOnTime => 'Played on time';

  @override
  String get synthesiaMusicLength => 'Music length';

  @override
  String get synthesiaCompleted => 'Completed';

  @override
  String get synthesiaFirstTry => 'First try';

  @override
  String get synthesiaMistakes => 'Mistakes';

  @override
  String get synthesiaTime => 'Time';

  @override
  String get synthesiaNoLimit => 'No limit';

  @override
  String get synthesiaScoreLabel => 'SCORE';

  @override
  String get synthesiaSavingResult => 'Saving Synthesia performance result...';

  @override
  String get synthesiaResultSaved => 'Synthesia performance result saved';

  @override
  String get synthesiaResultNotSaved =>
      'The Synthesia performance result was not saved.';

  @override
  String get synthesiaRetrySave => 'Retry save';

  @override
  String get synthesiaViewFullResult => 'View full result';

  @override
  String get synthesiaWhatToWorkOn => 'What to work on';

  @override
  String get synthesiaHowToImprove => 'How to improve';

  @override
  String get synthesiaNoRepeatedProblems =>
      'You did not have any repeated problems.';

  @override
  String synthesiaTroubleWithNoteTimes(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You had trouble with $note $count times.',
      one: 'You had trouble with $note 1 time.',
    );
    return '$_temp0';
  }

  @override
  String synthesiaGroupsReleasedEarly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count note groups had notes released too soon.',
      one: '1 note group had notes released too soon.',
    );
    return '$_temp0';
  }

  @override
  String synthesiaCorrectGroupsNeedReview(int correctCount, int reviewCount) {
    return '$correctCount note groups were correct, and $reviewCount need review.';
  }

  @override
  String get synthesiaWaitModeNotSaved =>
      'Wait Mode is unscored practice and is not saved.';

  @override
  String get synthesiaSuggestionPerfect =>
      'Great job! You played every part correctly. Repeat the piece with the same control.';

  @override
  String get synthesiaSuggestionAlmostPerfect =>
      'You were very close. Play it once more at the same speed and focus on the highlighted parts.';

  @override
  String synthesiaSuggestionDifficultNote(String note) {
    return 'You had trouble with $note. Practice finding that key slowly before replaying the whole piece.';
  }

  @override
  String get synthesiaSuggestionReleasedTooSoon =>
      'Some notes were released too soon. Keep each key held until enough of its falling note has been consumed.';

  @override
  String get synthesiaSuggestionMissedNotes =>
      'Some notes reached the line before you played them. Watch one note ahead and keep a steady beat.';

  @override
  String get synthesiaSuggestionPlayedLate =>
      'You often played after the beat. Look one note ahead so your fingers are ready sooner.';

  @override
  String get synthesiaSuggestionPlayedEarly =>
      'You often played before the beat. Count steadily and wait for each note to reach the line.';

  @override
  String get synthesiaSuggestionChordTiming =>
      'Some chord notes were pressed separately. Practice pressing every key in each chord together.';

  @override
  String get synthesiaSuggestionWrongNotes =>
      'Practice the difficult passage slowly and check each key before returning to full speed.';

  @override
  String get synthesiaSuggestionGeneralPractice =>
      'Play the difficult parts slowly a few times, then try the complete piece again.';

  @override
  String get synthesiaUntitledScore => 'Untitled score';

  @override
  String get synthesiaPreparing => 'Preparing Synthesia...';

  @override
  String get synthesiaScorePreparationFailed =>
      'The score could not be prepared.';

  @override
  String get synthesiaStartPerformance => 'Start Performance';

  @override
  String get synthesiaStartWaitMode => 'Start Wait Mode';

  @override
  String get synthesiaWait => 'Wait';

  @override
  String get synthesiaPerformance => 'Performance';

  @override
  String get synthesiaControls => 'Controls';

  @override
  String get synthesiaLoadingMp3Preview => 'Loading MP3 preview';

  @override
  String get synthesiaListeningMp3Preview => 'Listening to MP3 preview';

  @override
  String get synthesiaPracticeInterrupted => 'Practice interrupted';

  @override
  String get synthesiaPlayHighlightedNoteOrChord =>
      'Play the highlighted note or chord';

  @override
  String get synthesiaReady => 'Ready';

  @override
  String get synthesiaFollowFallingNotes => 'Follow the falling notes';

  @override
  String get synthesiaMidiOffline => 'MIDI offline';

  @override
  String get synthesiaCloseControls => 'Close controls';

  @override
  String get synthesiaMidiReconnectPrompt =>
      'MIDI keyboard not connected. Turn it on or reconnect it, then tap Connect MIDI to try again.';

  @override
  String get synthesiaListen => 'Listen';

  @override
  String get synthesiaConnected => 'Connected';

  @override
  String get synthesiaStart => 'Start';

  @override
  String get synthesiaRestart => 'Restart';

  @override
  String get synthesiaReleaseAllKeysToContinue =>
      'Release all keys to continue';

  @override
  String synthesiaPlayedNotes(String feedback, String notes) {
    return '$feedback · Played: $notes';
  }

  @override
  String get synthesiaNone => 'None';

  @override
  String synthesiaNoteGroupPosition(String time, int group) {
    return '$time · Note group $group';
  }

  @override
  String get synthesiaNoTimeLimitCompact => 'No time limit';

  @override
  String synthesiaTargetDuration(String duration) {
    return 'Target $duration';
  }

  @override
  String get synthesiaNoNotesAvailable => 'No notes available';

  @override
  String get synthesiaTooEarly => 'Too early';

  @override
  String get synthesiaTooLate => 'Too late';

  @override
  String get synthesiaWrongNote => 'Wrong note';

  @override
  String get synthesiaCompleteChord => 'Complete the chord';

  @override
  String get synthesiaChordNotesNotTogether => 'Chord notes were not together';

  @override
  String get synthesiaCorrectAfterMistake => 'Correct after mistake';

  @override
  String get synthesiaCorrect => 'Correct';

  @override
  String get synthesiaReleasedTooSoon => 'Released too soon';

  @override
  String get synthesiaDurationComplete => 'Duration complete';

  @override
  String get synthesiaTimingMissed => 'Timing missed';

  @override
  String get synthesiaWrong => 'Wrong';

  @override
  String get synthesiaMissed => 'Missed';

  @override
  String get sightReadingWait => 'Wait';

  @override
  String get sightReadingPerformance => 'Performance';

  @override
  String get sightReadingControls => 'Controls';

  @override
  String get sightReadingPreparingProgress => 'Preparing progress';

  @override
  String get sightReadingPerformanceMode => 'Performance Mode';

  @override
  String get sightReadingWaitMode => 'Wait Mode';

  @override
  String get sightReadingPerformanceModeDescription =>
      'Press Start, then begin when you are ready by playing any MIDI key.';

  @override
  String get sightReadingWaitModeDescription =>
      'Practice at your own pace while learning how long to hold each note.';

  @override
  String get sightReadingPerformanceDetailNoPause =>
      'The score does not pause when a note is missed.';

  @override
  String get sightReadingPerformanceDetailEvaluation =>
      'Your notes and timing are evaluated against the MIDI timeline.';

  @override
  String get sightReadingPerformanceDetailFirstKey =>
      'Your first key starts the timeline and is evaluated, whether it is correct or wrong.';

  @override
  String get sightReadingWaitDetailNoTimeLimit =>
      'There is no time limit while you practice.';

  @override
  String get sightReadingWaitDetailHoldLength =>
      'Hold each key for its written length, then release it when prompted.';

  @override
  String get sightReadingWaitDetailContinuedNotes =>
      'Some notes continue across later notes; releasing early returns the cursor so you can retry.';

  @override
  String sightReadingSwitchToModeQuestion(String mode) {
    return 'Switch to $mode?';
  }

  @override
  String get sightReadingSwitchMode => 'Switch Mode';

  @override
  String get sightReadingConnectMidiKeyboard => 'Connect your MIDI keyboard';

  @override
  String get sightReadingPerformanceRequiresMidi =>
      'Performance Mode needs your MIDI keyboard to hear the notes you play. Connect it now, then press any key when you are ready to begin.';

  @override
  String get sightReadingWaitRequiresMidi =>
      'Wait Mode needs your MIDI keyboard to hear each note and move the cursor forward.';

  @override
  String get sightReadingConnectMidi => 'Connect MIDI';

  @override
  String get sightReadingStartPerformance => 'Start Performance';

  @override
  String sightReadingPlayedNotes(String feedback, String notes) {
    return '$feedback · Played: $notes';
  }

  @override
  String sightReadingHintPlay(String notes) {
    return 'Hint: play $notes';
  }

  @override
  String get sightReadingPreparingScore => 'Preparing your score';

  @override
  String get sightReadingLoadingNotationTimingAudio =>
      'Loading notation, timing, and audio...';

  @override
  String get sightReadingCouldNotPrepareScore => 'Could not prepare this score';

  @override
  String get sightReadingUnknownLoadError =>
      'An unknown score-loading problem occurred.';

  @override
  String get sightReadingTryAgain => 'Try Again';

  @override
  String get sightReadingPressAnyMidiKey => 'Press any MIDI key to begin';

  @override
  String get sightReadingNone => 'None';

  @override
  String get sightReadingWaitingEllipsis => 'Waiting...';

  @override
  String sightReadingPlayedWithHint(String playedNotes, String expectedNotes) {
    return 'Played: $playedNotes · Hint: play $expectedNotes';
  }

  @override
  String sightReadingPlayed(String notes) {
    return 'Played: $notes';
  }

  @override
  String get sightReadingCloseControls => 'Close controls';

  @override
  String get sightReadingMidiReconnectPrompt =>
      'MIDI keyboard not connected. Turn it on or reconnect it, then tap Connect MIDI to try again.';

  @override
  String get sightReadingListen => 'Listen';

  @override
  String get sightReadingFollowCursor => 'Follow the moving cursor';

  @override
  String get sightReadingStartWhenMidiReady =>
      'Start when your MIDI keyboard is ready';

  @override
  String get sightReadingPlaying => 'Playing';

  @override
  String get sightReadingWaiting => 'Waiting';

  @override
  String get sightReadingStart => 'Start';

  @override
  String get sightReadingHoldUntilCursor => 'Hold until the cursor arrives';

  @override
  String get sightReadingComposition => 'Composition';

  @override
  String get sightReadingMusicSheet => 'Music Sheet';

  @override
  String get sightReadingNoTimeLimit => 'No time limit';

  @override
  String get sightReadingReadingTimeline => 'Reading timeline...';

  @override
  String get sightReadingTimelineUnavailable => 'Timeline unavailable';

  @override
  String sightReadingTargetDuration(String duration) {
    return 'Target $duration';
  }

  @override
  String get sightReadingPressAnyKeyToStart => 'Press any key to start';

  @override
  String get sightReadingConnected => 'Connected';

  @override
  String get sightReadingSearching => 'Searching';

  @override
  String get sightReadingConnecting => 'Connecting';

  @override
  String sightReadingConnectedDevice(String device) {
    return 'Connected: $device';
  }

  @override
  String get sightReadingSearchingEllipsis => 'Searching...';

  @override
  String get sightReadingConnectingEllipsis => 'Connecting...';

  @override
  String get sightReadingNoDeviceDetected => 'No device detected';

  @override
  String get sightReadingConnectionFailed => 'Connection failed';

  @override
  String get sightReadingNotConnected => 'Not connected';

  @override
  String get sightReadingNoMp3Preview => 'The score has no MP3 audio preview.';

  @override
  String get sightReadingPlaybackFailed =>
      'The score preview could not be played.';

  @override
  String get sightReadingMusicXmlMissing => 'The MusicXML file is missing.';

  @override
  String get sightReadingMusicXmlDownloadFailed =>
      'The MusicXML file could not be downloaded.';

  @override
  String get sightReadingScoreLoadFailed => 'The score could not be loaded.';

  @override
  String get sightReadingScorePreparationFailed =>
      'The MusicXML could not be prepared for Sight Reading.';

  @override
  String get sightReadingMidiFileMissing => 'The challenge has no MIDI file.';

  @override
  String get sightReadingMidiTimelineUnavailable =>
      'The MIDI timeline could not be loaded.';

  @override
  String get sightReadingUntitledScore => 'Untitled score';

  @override
  String get sightReadingReady => 'Ready';

  @override
  String get sightReadingWaitingForMidi => 'Waiting for MIDI file';

  @override
  String get sightReadingPlayOnTime => 'Play on time';

  @override
  String get sightReadingMissed => 'Missed';

  @override
  String get sightReadingWrongNote => 'Wrong note';

  @override
  String get sightReadingCompleteChord => 'Complete the chord';

  @override
  String get sightReadingChordNotesNotTogether =>
      'Chord notes were not together';

  @override
  String get sightReadingCorrectAfterMistake => 'Correct after mistake';

  @override
  String get sightReadingCorrectNotesKeepHolding =>
      'Correct notes—keep holding';

  @override
  String get sightReadingCorrect => 'Correct';

  @override
  String get sightReadingReleasedTooSoon => 'Released too soon';

  @override
  String get sightReadingTooEarly => 'Too early';

  @override
  String get sightReadingTooLate => 'Too late';

  @override
  String get sightReadingWrong => 'Wrong';

  @override
  String get sightReadingKeepPlaying => 'Keep playing';

  @override
  String get sightReadingDurationComplete => 'Duration complete';

  @override
  String get sightReadingCompleted => 'Completed';

  @override
  String sightReadingKeepHolding(int percentage) {
    return 'Keep holding · $percentage%';
  }

  @override
  String sightReadingReleaseBeforePlayingAgain(String note) {
    return 'Release $note before playing it again';
  }

  @override
  String sightReadingReleaseHeldTooLong(String notes) {
    return 'Release $notes—held too long';
  }

  @override
  String sightReadingNoteHeldTooLong(String note) {
    return '$note was held too long';
  }

  @override
  String sightReadingNoteReleasedTooSoon(String note) {
    return '$note was released too soon';
  }

  @override
  String sightReadingHoldWhilePlayingNext(String notes) {
    return 'Hold $notes while playing the next notes';
  }

  @override
  String sightReadingHoldWhilePlaying(String heldNotes, String expectedNotes) {
    return 'Hold $heldNotes while playing $expectedNotes';
  }

  @override
  String sightReadingReleaseNotes(String notes) {
    return 'Release $notes';
  }

  @override
  String get sightReadingReleasedContinue =>
      'Released—continue with the highlighted note';

  @override
  String get sightReadingTryAgainHoldUntilCursor =>
      'Try again—hold until the cursor reaches the next note';

  @override
  String get sightReadingWaitModeNoXp => 'Wait Mode does not award XP.';

  @override
  String get sightReadingLessonNoXp => 'This lesson does not award XP.';

  @override
  String get sightReadingNoXpImperfect =>
      'No XP awarded. Complete Performance Mode without mistakes.';

  @override
  String get sightReadingProgressSaveFailed =>
      'Progress could not be saved. Please try again.';

  @override
  String get sightReadingAlreadyCompleted =>
      'Already completed. XP is only awarded once.';

  @override
  String get sightReadingRetryRequired => 'Retry Required';

  @override
  String get sightReadingRetryRequiredDescription =>
      'A hint was shown during this attempt. Please retry and complete the score without reaching five consecutive mistakes.';

  @override
  String get sightReadingPerfect => 'Perfect!';

  @override
  String get sightReadingPerfectDescription =>
      'You completed the score without any mistakes or hints.';

  @override
  String get sightReadingExerciseCompleted => 'Exercise Completed';

  @override
  String sightReadingCompletedWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You completed the score with $count mistakes. Review the detailed feedback below.',
      one:
          'You completed the score with 1 mistake. Review the detailed feedback below.',
    );
    return '$_temp0';
  }

  @override
  String sightReadingWaitCompletedWithMistakes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You completed the score with $count mistakes, but you did not need a hint.',
      one:
          'You completed the score with 1 mistake, but you did not need a hint.',
    );
    return '$_temp0';
  }

  @override
  String get sightReadingCorrectOnTime => 'Correct on time';

  @override
  String get sightReadingWrongNotes => 'Wrong notes';

  @override
  String get sightReadingNotPlayed => 'Not played';

  @override
  String get sightReadingPlayedOnTime => 'Played on time';

  @override
  String get sightReadingMusicLength => 'Music length';

  @override
  String get sightReadingFirstTry => 'First try';

  @override
  String get sightReadingMistakes => 'Mistakes';

  @override
  String get sightReadingHintUsed => 'Hint used';

  @override
  String get sightReadingYes => 'Yes';

  @override
  String get sightReadingNo => 'No';

  @override
  String get sightReadingTime => 'Time';

  @override
  String get sightReadingNoLimit => 'No limit';

  @override
  String get sightReadingScoreLabel => 'SCORE';

  @override
  String get sightReadingWhatToWorkOn => 'What to work on';

  @override
  String get sightReadingHowToImprove => 'How to improve';

  @override
  String get sightReadingNoRepeatedProblems =>
      'You did not have any repeated problems.';

  @override
  String sightReadingClefDifficulty(
    String clef,
    int errorCount,
    int totalCount,
  ) {
    return '$clef was difficult in $errorCount of $totalCount note groups.';
  }

  @override
  String sightReadingTroubleWithNoteTimes(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You had trouble with $note $count times.',
      one: 'You had trouble with $note 1 time.',
    );
    return '$_temp0';
  }

  @override
  String sightReadingWrongAndMissedGroups(int wrongCount, int missedCount) {
    return '$wrongCount note groups had wrong keys, and $missedCount were not played.';
  }

  @override
  String get sightReadingSavingResult => 'Saving this practice result...';

  @override
  String get sightReadingResultSaved => 'Practice result saved';

  @override
  String get sightReadingResultNotSaved => 'Result not saved';

  @override
  String get sightReadingRetrySave => 'Retry save';

  @override
  String get sightReadingViewFullResult => 'View full result';

  @override
  String get sightReadingTrebleClefDescription =>
      'Higher-note reading (treble clef)';

  @override
  String get sightReadingBassClefDescription =>
      'Lower-note reading (bass clef)';

  @override
  String get sightReadingUnknownClefDescription => 'One part of the score';

  @override
  String sightReadingOtherClefDescription(String clef) {
    return '$clef clef reading';
  }

  @override
  String get sightReadingSuggestionPerfect =>
      'Great job! You played every part correctly. Try the same piece a little faster when you feel ready.';

  @override
  String get sightReadingSuggestionAlmostPerfect =>
      'You were very close. Play it once more at the same speed, then try it a little faster.';

  @override
  String get sightReadingSuggestionBassClef =>
      'The lower notes in the bass clef were difficult. Practice the left-hand part slowly by itself first.';

  @override
  String get sightReadingSuggestionTrebleClef =>
      'The higher notes in the treble clef were difficult. Practice the right-hand part slowly by itself first.';

  @override
  String sightReadingSuggestionOtherClef(String clef) {
    return 'The $clef clef was difficult. Practice that part slowly before playing the whole piece again.';
  }

  @override
  String sightReadingSuggestionDifficultNote(String note) {
    return 'You had trouble finding $note. Practice finding that key slowly, then play it with the notes beside it.';
  }

  @override
  String get sightReadingSuggestionReleasedTooSoon =>
      'Some notes were released too soon. Keep each key held until its full note value is finished.';

  @override
  String get sightReadingSuggestionMissedNotes =>
      'Some notes passed before you played them. Slow the piece down and count the beat aloud while you practice.';

  @override
  String get sightReadingSuggestionPlayedLate =>
      'You often played after the beat. Slow down and look one note ahead so your fingers are ready sooner.';

  @override
  String get sightReadingSuggestionPlayedEarly =>
      'You often played before the beat. Count steadily and wait for the beat before pressing the key.';

  @override
  String get sightReadingSuggestionChordTiming =>
      'Some notes in a chord were pressed at different times. Practice pressing all the chord keys together, one hand at a time.';

  @override
  String get sightReadingSuggestionGeneralPractice =>
      'Play the difficult parts slowly a few times, then try the whole piece again at its normal speed.';

  @override
  String get arPracticePianoPractice => 'Piano practice';

  @override
  String get arPracticeConnectMidiPiano => 'Connect MIDI piano';

  @override
  String get arPracticeStopWarning =>
      'Stop returns to the ready screen so you can change modes. This unfinished attempt will not be saved.';

  @override
  String get arPracticeChooseNotation => 'Choose notation';

  @override
  String get arPracticeChooseNotationDescription =>
      'Select how you want the music to appear during practice.';

  @override
  String get arPracticeNotes => 'Notes';

  @override
  String get arPracticeNumberNotation => 'Number notation';

  @override
  String get arPracticeDisconnectedDescription =>
      'Practice has stopped so disconnected time and missed notes will not count against you.';

  @override
  String get arPracticeEndAttempt => 'End attempt';

  @override
  String get arPracticeReconnecting => 'Reconnecting...';

  @override
  String get arPracticeReconnect => 'Reconnect';

  @override
  String get arPracticeReconnectFailed =>
      'Could not reconnect. Check the cable and piano, then try again.';

  @override
  String arPracticeSwitchToModeQuestion(String mode) {
    return 'Switch to $mode?';
  }

  @override
  String get arPracticeWaitModeDescription =>
      'In Wait Mode, each falling note pauses at the hit line until you play the correct key or chord, hold it for the shown length, and release it. There is no timing pressure before you press the notes.\n\nSwitching modes will reset the current attempt.';

  @override
  String get arPracticePerformanceModeDescription =>
      'In Performance Mode, the falling notes continue moving with the song. Pitch, timing, and how long you hold each key are evaluated.\n\nSwitching modes will reset the current attempt.';

  @override
  String get arPracticeSwitchMode => 'Switch mode';

  @override
  String get arPracticeConnectionRestoredTryAgain =>
      'Connection restored—play this part again';

  @override
  String get arPracticeTryAgainFullLength =>
      'Try again—hold each key for its full note length';

  @override
  String get arPracticeSavingResult => 'Saving AR performance result...';

  @override
  String get arPracticeResultSaved => 'AR performance result saved';

  @override
  String get arPracticeResultNotSaved =>
      'The AR performance result was not saved.';

  @override
  String get arPracticeNumberNotationVideoFailed =>
      'The number notation video could not be opened.';

  @override
  String get practiceResultsTitle => 'Practice Results';

  @override
  String get practiceResultsDeleteAllTooltip => 'Delete all practice results';

  @override
  String get practiceResultsSignIn => 'Sign in to view practice results';

  @override
  String get practiceResultsSignInDescription =>
      'Completed Performance attempts will appear here.';

  @override
  String get practiceResultsLoadFailed => 'Results could not be loaded';

  @override
  String get practiceResultsCheckConnection =>
      'Check your connection and try again.';

  @override
  String get practiceResultsEmpty => 'No practice results yet';

  @override
  String get practiceResultsEmptyDescription =>
      'Complete a score in Performance Mode to create your first result.';

  @override
  String get practiceResultsSearchHint => 'Search by piece title';

  @override
  String get practiceResultsClearSearch => 'Clear search';

  @override
  String get practiceResultsAll => 'ALL';

  @override
  String get practiceResultsFilters => 'Filters';

  @override
  String get practiceResultsNoMatches => 'No matching results';

  @override
  String get practiceResultsNoMatchesDescription =>
      'Try changing your search or filters.';

  @override
  String get practiceResultsClearFilters => 'Clear Filters';

  @override
  String get practiceResultsFilterAndSort => 'Filter and sort';

  @override
  String get practiceResultsClearAll => 'Clear all';

  @override
  String get practiceResultsCloseFilters => 'Close filters';

  @override
  String get practiceResultsDate => 'Date';

  @override
  String get practiceResultsAccuracy => 'Accuracy';

  @override
  String get practiceResultsSource => 'Source';

  @override
  String get practiceResultsSortBy => 'Sort by';

  @override
  String get practiceResultsReset => 'Reset';

  @override
  String get practiceResultsApplyFilters => 'Apply Filters';

  @override
  String get practiceResultsAllTime => 'All time';

  @override
  String get practiceResultsToday => 'Today';

  @override
  String get practiceResultsLast7Days => 'Last 7 days';

  @override
  String get practiceResultsLast30Days => 'Last 30 days';

  @override
  String get practiceResultsAllScores => 'All scores';

  @override
  String get practiceResultsBelow75 => 'Below 75%';

  @override
  String get practiceResultsAllSources => 'All sources';

  @override
  String get practiceResultsMusicSheet => 'Music Sheet';

  @override
  String get practiceResultsComposition => 'Composition';

  @override
  String get practiceResultsChallenge => 'Challenge';

  @override
  String get practiceResultsNewestFirst => 'Newest first';

  @override
  String get practiceResultsOldestFirst => 'Oldest first';

  @override
  String get practiceResultsHighestAccuracy => 'Highest accuracy';

  @override
  String get practiceResultsLowestAccuracy => 'Lowest accuracy';

  @override
  String get practiceResultsSightReading => 'SIGHT READING';

  @override
  String get practiceResultsSynthesia => 'SYNTHESIA';

  @override
  String get practiceResultsArPerformance => 'AR PERFORMANCE';

  @override
  String get practiceResultsGeneralSuggestion =>
      'Practice the difficult parts slowly, then play the piece again.';

  @override
  String practiceResultsCardMetadata(String source, String date, String score) {
    return '$source · $date · Score $score';
  }

  @override
  String practiceResultsWrongNotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wrong notes',
      one: '1 wrong note',
    );
    return '$_temp0';
  }

  @override
  String practiceResultsNotPlayedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not played',
      one: '1 not played',
    );
    return '$_temp0';
  }

  @override
  String get practiceResultsDeleteQuestion => 'Delete practice result?';

  @override
  String practiceResultsDeleteDescription(String title) {
    return 'This removes the result for \"$title\" and its detailed note review. This cannot be undone.';
  }

  @override
  String get practiceResultsDeleteFailed =>
      'The practice result could not be deleted.';

  @override
  String get practiceResultsDeleteAllQuestion => 'Delete all practice results?';

  @override
  String get practiceResultsDeleteAllDescription =>
      'Every saved practice result and its detailed note review will be permanently deleted. This cannot be undone.';

  @override
  String get practiceResultsDeleteAll => 'Delete All';

  @override
  String get practiceResultsDeleteAllSuccess =>
      'All practice results were deleted.';

  @override
  String get practiceResultsDeleteAllFailed =>
      'Some practice results could not be deleted.';

  @override
  String get practiceResultsJustNow => 'Just now';

  @override
  String get practiceResultsPracticeHigherNotes => 'Practice higher notes';

  @override
  String get practiceResultsPracticeLowerNotes => 'Practice lower notes';

  @override
  String practiceResultsPracticeClef(String clef) {
    return 'Practice the $clef clef';
  }

  @override
  String get practiceResultTitle => 'Practice Result';

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
    return '$percentage% played on time';
  }

  @override
  String get practiceResultCorrect => 'Correct';

  @override
  String get practiceResultWrongNotes => 'Wrong notes';

  @override
  String get practiceResultNotPlayed => 'Not played';

  @override
  String get practiceResultMusicLength => 'Music length';

  @override
  String get practiceResultYourTime => 'Your time';

  @override
  String get practiceResultWhatToWorkOn => 'What to work on';

  @override
  String get practiceResultHowEachClefWent => 'How each clef went';

  @override
  String practiceResultClefDifficulty(
    String clef,
    int errorCount,
    int totalCount,
  ) {
    return '$clef: $errorCount difficult out of $totalCount';
  }

  @override
  String get practiceResultDifficultNotes => 'Notes that were difficult';

  @override
  String get practiceResultNoDifficultNotes =>
      'No individual note caused repeated trouble.';

  @override
  String practiceResultNoteDifficulty(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$note: difficult $count times',
      one: '$note: difficult 1 time',
    );
    return '$_temp0';
  }

  @override
  String get practiceResultOtherKeys => 'Other keys you pressed';

  @override
  String get practiceResultNoExtraKeys =>
      'You did not press any extra wrong keys.';

  @override
  String practiceResultKeyPressed(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$note pressed $count times',
      one: '$note pressed 1 time',
    );
    return '$_temp0';
  }

  @override
  String get practiceResultHowToImprove => 'How to improve';

  @override
  String practiceResultNotesToReview(int count) {
    return 'Notes to review ($count)';
  }

  @override
  String get practiceResultReviewDescription =>
      'Only the parts that need more practice';

  @override
  String get practiceResultErrorLogFailed =>
      'The detailed error log could not be loaded.';

  @override
  String get practiceResultNoErrors =>
      'No errors were recorded for this attempt.';

  @override
  String get practiceResultNone => 'None';

  @override
  String practiceResultNoteGroup(int number) {
    return 'Note group $number';
  }

  @override
  String practiceResultNoteGroupMeasure(int number, String measure) {
    return 'Note group $number · Measure $measure';
  }

  @override
  String practiceResultIssueSummary(String issues, String clefs, String time) {
    return '$issues · $clefs · At $time';
  }

  @override
  String practiceResultExpectedAndPlayed(String expected, String played) {
    return 'The score showed: $expected   You played: $played';
  }

  @override
  String get practiceResultEventuallyMatched =>
      'You found the right notes after the first mistake.';

  @override
  String get practiceResultUnavailable =>
      'This practice result is unavailable.';

  @override
  String get practiceResultTrebleClef => 'Treble clef (higher notes)';

  @override
  String get practiceResultBassClef => 'Bass clef (lower notes)';

  @override
  String get practiceResultAltoClef => 'Alto clef';

  @override
  String get practiceResultTenorClef => 'Tenor clef';

  @override
  String get practiceResultPercussion => 'Percussion';

  @override
  String get practiceResultScoreSection => 'Score section';

  @override
  String get practiceResultNoCorrectNote =>
      'No correct note was played at this point.';

  @override
  String get practiceResultTimingOnBeat =>
      'Your timing was almost exactly on the beat.';

  @override
  String practiceResultBeforeBeat(String seconds) {
    return 'You played about $seconds seconds before the beat.';
  }

  @override
  String practiceResultAfterBeat(String seconds) {
    return 'You played about $seconds seconds after the beat.';
  }

  @override
  String get practiceResultIssueWrongNote => 'Different key played';

  @override
  String get practiceResultIssueEarly => 'Too early';

  @override
  String get practiceResultIssueLate => 'Too late';

  @override
  String get practiceResultIssueMissed => 'No note played';

  @override
  String get practiceResultIssueChordTiming => 'Chord notes not together';

  @override
  String get practiceResultIssueReleasedEarly => 'Released too soon';
}
