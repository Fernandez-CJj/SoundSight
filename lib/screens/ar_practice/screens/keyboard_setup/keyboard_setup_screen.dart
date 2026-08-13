import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../models/piano_note.dart';
import '../../models/keyboard_profile.dart';
import '../../services/arcore_compatibility_service.dart';
import '../../services/camera_permission_service.dart';
import 'widgets/custom_keyboard_range_section.dart';
import 'widgets/default_keyboard_profile_list.dart';
import '../calibration_camera/calibration_camera_screen.dart';

// Collects the user's physical keyboard range.
// The user can select a standard profile or choose two note endpoints to create
// a custom profile before checking ARCore and camera permission.
class KeyboardSetupScreen extends StatefulWidget {
  const KeyboardSetupScreen({super.key});

  @override
  State<KeyboardSetupScreen> createState() => _KeyboardSetupScreenState();
}

class _KeyboardSetupScreenState extends State<KeyboardSetupScreen> {
  // Provides data for the standard profile cards and custom note dropdowns.
  final List<KeyboardProfile> defaultProfiles = [
    KeyboardProfile.keys49,
    KeyboardProfile.keys61,
    KeyboardProfile.keys76,
    KeyboardProfile.keys88,
  ];
  final List<PianoNote> pianoNotes = createPianoNotes();

  // Stores the custom endpoints until both notes form a valid profile.
  PianoNote? customFirstNote;
  PianoNote? customLastNote;

  // Stores the complete chosen profile and whether custom fields are visible.
  KeyboardProfile? selectedProfile;
  bool isCustomRangeSelected = false;

  // Provides the native ARCore compatibility check and its current screen state.
  final ArCoreCompatibilityService arCoreCompatibilityService =
      ArCoreCompatibilityService();

  bool isCheckingArCore = false;
  // Prevents more than one calibration screen from opening at the same time.
  bool isCalibrationScreenOpen = false;
  ArCoreAvailabilityStatus? arCoreAvailabilityStatus;

  // Provides the methods used to check and request camera permission.
  final CameraPermissionService cameraPermissionService =
      CameraPermissionService();

  @override
  Widget build(BuildContext context) {
    String? customRangeError = validateCustomRange();

    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Shows the minimum camera conditions before calibration starts.
            // This remains basic until the later design stage.
            Text(
              'Choose your keyboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(8.0),
            const Text(
              'Select the number of physical keys so SoundSight can map '
              'each key to the correct note.',
            ),
            const Gap(24.0),
            const Text(
              'Before calibration',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const Gap(8.0),
            const Text(
              '• Use the rear main camera.\n'
              '• Rotate your phone to landscape.\n'
              '• Keep the camera at standard 1× zoom.\n'
              '• Do not zoom during calibration.',
            ),
            const Gap(24.0),
            const Text(
              'Default keyboard sizes',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const Gap(8.0),
            DefaultKeyboardProfileList(
              profiles: defaultProfiles,
              selectedProfile: selectedProfile,
              onProfileSelected: selectDefaultProfile,
            ),
            CustomKeyboardRangeSection(
              isSelected: isCustomRangeSelected,
              pianoNotes: pianoNotes,
              firstNote: customFirstNote,
              lastNote: customLastNote,
              errorMessage: customRangeError,
              onCustomRangeSelected: selectCustomRange,
              onFirstNoteChanged: changeCustomFirstNote,
              onLastNoteChanged: changeCustomLastNote,
            ),
            const Gap(24.0),
            // Disables Continue until a profile is ready and while ARCore is
            // being checked. The label shows when Android is still checking.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedProfile == null || isCheckingArCore
                    ? null
                    : checkArCoreCompatibility,
                child: Text(
                  isCheckingArCore ? 'Checking ARCore...' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stores a standard profile and hides the custom-range fields.
  void selectDefaultProfile(KeyboardProfile profile) {
    setState(() {
      selectedProfile = profile;
      isCustomRangeSelected = false;
    });
  }

  // Shows the custom fields and restores a valid custom profile when available.
  void selectCustomRange() {
    setState(() {
      selectedProfile = createCustomProfile();
      isCustomRangeSelected = true;
    });
  }

  // Stores a new first note and rebuilds the custom profile when it is valid.
  void changeCustomFirstNote(PianoNote? selectedNote) {
    setState(() {
      customFirstNote = selectedNote;
      selectedProfile = createCustomProfile();
    });
  }

  // Stores a new last note and rebuilds the custom profile when it is valid.
  void changeCustomLastNote(PianoNote? selectedNote) {
    setState(() {
      customLastNote = selectedNote;
      selectedProfile = createCustomProfile();
    });
  }

  // Returns null when the custom range is valid or a readable error otherwise.
  String? validateCustomRange() {
    PianoNote? firstNote = customFirstNote;
    PianoNote? lastNote = customLastNote;

    if (firstNote == null) {
      return 'Select the first note.';
    }

    if (lastNote == null) {
      return 'Select the last note.';
    }

    if (firstNote.midiNumber >= lastNote.midiNumber) {
      return 'The last note must be higher than the first note.';
    }

    return null;
  }

  // Creates a custom KeyboardProfile only after both endpoints are safe.
  // The key count includes both the first note and the last note.
  KeyboardProfile? createCustomProfile() {
    PianoNote? firstNote = customFirstNote;
    PianoNote? lastNote = customLastNote;

    if (firstNote == null || lastNote == null) {
      return null;
    }

    if (firstNote.midiNumber >= lastNote.midiNumber) {
      return null;
    }

    int keyCount = lastNote.midiNumber - firstNote.midiNumber + 1;

    KeyboardProfile customProfile = KeyboardProfile(
      name: 'Custom $keyCount Keys',
      keyCount: keyCount,
      firstNote: firstNote.noteName,
      lastNote: lastNote.noteName,
      firstMidiNumber: firstNote.midiNumber,
      lastMidiNumber: lastNote.midiNumber,
    );

    if (customProfile.isRangeValid() == false) {
      return null;
    }

    return customProfile;
  }

  // Runs the ARCore check and ignores a stale result if the profile changes.
  Future<void> checkArCoreCompatibility() async {
    KeyboardProfile? keyboardProfile = selectedProfile;

    if (keyboardProfile == null || isCheckingArCore) {
      return;
    }

    setState(() {
      isCheckingArCore = true;
      arCoreAvailabilityStatus = null;
    });

    ArCoreAvailabilityStatus availabilityStatus =
        await arCoreCompatibilityService.checkAvailability();

    if (mounted == false) {
      return;
    }

    if (selectedProfile != keyboardProfile) {
      setState(() {
        isCheckingArCore = false;
        arCoreAvailabilityStatus = null;
      });

      return;
    }

    setState(() {
      arCoreAvailabilityStatus = availabilityStatus;
      isCheckingArCore = false;
    });

    await handleArCoreAvailability(availabilityStatus, keyboardProfile);
  }

  // Converts each unsuccessful ARCore result into a readable message.
  String getArCoreAvailabilityMessage(
    ArCoreAvailabilityStatus availabilityStatus,
  ) {
    if (availabilityStatus == ArCoreAvailabilityStatus.supportedInstalled) {
      return 'ARCore is ready.';
    }

    if (availabilityStatus == ArCoreAvailabilityStatus.supportedNotInstalled) {
      return 'Google Play Services for AR is not installed.';
    }

    if (availabilityStatus == ArCoreAvailabilityStatus.supportedNeedsUpdate) {
      return 'Google Play Services for AR needs to be updated.';
    }

    if (availabilityStatus == ArCoreAvailabilityStatus.unsupported) {
      return 'This device does not support ARCore. '
          'You can continue using SoundSight without AR.';
    }

    if (availabilityStatus == ArCoreAvailabilityStatus.checking) {
      return 'ARCore support is still being checked. Try again.';
    }

    if (availabilityStatus == ArCoreAvailabilityStatus.timedOut) {
      return 'The ARCore check timed out. '
          'Check your internet connection and try again.';
    }

    return 'SoundSight could not check ARCore compatibility.';
  }

  // Checks camera permission when ARCore is supported.
  // Unsupported ARCore results keep this screen open and display a message.
  Future<void> handleArCoreAvailability(
    ArCoreAvailabilityStatus availabilityStatus,
    KeyboardProfile keyboardProfile,
  ) async {
    if (availabilityStatus == ArCoreAvailabilityStatus.supportedInstalled) {
      CameraPermissionResult permissionResult =
          await checkAndRequestCameraPermission();

      if (mounted == false) {
        return;
      }

      await handleCameraPermissionResult(permissionResult, keyboardProfile);
      return;
    }

    String message = getArCoreAvailabilityMessage(availabilityStatus);

    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  // Reads camera permission and requests it only when it is currently denied.
  Future<CameraPermissionResult> checkAndRequestCameraPermission() async {
    CameraPermissionResult permissionResult = await cameraPermissionService
        .checkCameraPermission();

    if (permissionResult == CameraPermissionResult.denied) {
      permissionResult = await cameraPermissionService
          .requestCameraPermission();
    }

    return permissionResult;
  }

  // Continues only when camera permission is granted.
  // Every unsuccessful result keeps the screen open and displays a message.
  Future<void> handleCameraPermissionResult(
    CameraPermissionResult permissionResult,
    KeyboardProfile keyboardProfile,
  ) async {
    if (permissionResult == CameraPermissionResult.granted) {
      if (isCalibrationScreenOpen) {
        return;
      }

      isCalibrationScreenOpen = true;

      try {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return CalibrationCameraScreen(keyboardProfile: keyboardProfile);
            },
          ),
        );
      } finally {
        isCalibrationScreenOpen = false;
      }

      return;
    }

    String message;
    SnackBarAction? settingsAction;

    if (permissionResult == CameraPermissionResult.denied) {
      message = 'Camera permission is required to start calibration.';
    } else if (permissionResult == CameraPermissionResult.permanentlyDenied) {
      message = 'Camera permission is blocked. Enable it in Android settings.';

      settingsAction = SnackBarAction(
        label: 'Settings',
        onPressed: () async {
          await cameraPermissionService.openCameraPermissionSettings();
        },
      );
    } else if (permissionResult == CameraPermissionResult.restricted) {
      message = 'Camera access is restricted by the device.';
    } else {
      message = 'SoundSight could not check camera permission.';
    }

    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), action: settingsAction),
    );
  }
}
