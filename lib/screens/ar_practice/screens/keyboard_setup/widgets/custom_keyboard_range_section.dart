import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../models/piano_note.dart';

// Displays the custom-range card and its first-note and last-note fields.
// The chosen notes remain stored by the parent screen through the callbacks.
class CustomKeyboardRangeSection extends StatelessWidget {
  const CustomKeyboardRangeSection({
    super.key,
    required this.isSelected,
    required this.pianoNotes,
    required this.firstNote,
    required this.lastNote,
    required this.errorMessage,
    required this.onCustomRangeSelected,
    required this.onFirstNoteChanged,
    required this.onLastNoteChanged,
  });

  final bool isSelected;
  final List<PianoNote> pianoNotes;
  final PianoNote? firstNote;
  final PianoNote? lastNote;
  final String? errorMessage;
  final VoidCallback onCustomRangeSelected;
  final void Function(PianoNote? selectedNote) onFirstNoteChanged;
  final void Function(PianoNote? selectedNote) onLastNoteChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selecting this card reveals the two note dropdowns below it.
        Card(
          child: ListTile(
            title: const Text('Custom keyboard range'),
            subtitle: const Text(
              'Choose the first and last note manually.',
            ),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
            ),
            onTap: onCustomRangeSelected,
          ),
        ),
        // Keeps the custom fields hidden while a default profile is selected.
        Visibility(
          visible: isSelected,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(16.0),
              const Text('First note'),
              DropdownButton<PianoNote>(
                value: firstNote,
                isExpanded: true,
                hint: const Text('Select the first note'),
                items: createNoteMenuItems(),
                onChanged: onFirstNoteChanged,
              ),
              const Gap(16.0),
              const Text('Last note'),
              DropdownButton<PianoNote>(
                value: lastNote,
                isExpanded: true,
                hint: const Text('Select the last note'),
                items: createNoteMenuItems(),
                onChanged: onLastNoteChanged,
              ),
              Visibility(
                visible: errorMessage != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(8.0),
                    Text(errorMessage ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Converts every PianoNote into an item that a dropdown can display.
  // Each item shows the note name while keeping its complete PianoNote value.
  List<DropdownMenuItem<PianoNote>> createNoteMenuItems() {
    List<DropdownMenuItem<PianoNote>> noteMenuItems = [];

    for (PianoNote pianoNote in pianoNotes) {
      DropdownMenuItem<PianoNote> menuItem = DropdownMenuItem<PianoNote>(
        value: pianoNote,
        child: Text(pianoNote.noteName),
      );

      noteMenuItems.add(menuItem);
    }

    return noteMenuItems;
  }
}
