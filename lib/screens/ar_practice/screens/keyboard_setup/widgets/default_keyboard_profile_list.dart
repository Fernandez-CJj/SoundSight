import 'package:flutter/material.dart';
import '../../../models/keyboard_profile.dart';

// Displays every standard keyboard profile as a selectable card.
// The selected profile and tap behavior remain controlled by the parent screen.
class DefaultKeyboardProfileList extends StatelessWidget {
  const DefaultKeyboardProfileList({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileSelected,
  });

  final List<KeyboardProfile> profiles;
  final KeyboardProfile? selectedProfile;
  final void Function(KeyboardProfile profile) onProfileSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profiles.length,
      itemBuilder: (BuildContext context, int index) {
        KeyboardProfile profile = profiles[index];
        bool isSelected = selectedProfile == profile;
        String noteRange = profile.getNoteRange();
        String midiRange =
            'MIDI ${profile.firstMidiNumber} - ${profile.lastMidiNumber}';

        return Card(
          child: ListTile(
            title: Text(profile.name),
            subtitle: Text('$noteRange\n$midiRange'),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
            ),
            onTap: () {
              onProfileSelected(profile);
            },
          ),
        );
      },
    );
  }
}
