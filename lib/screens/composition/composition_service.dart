import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soundsight/screens/composition/composition.dart';
import 'package:soundsight/screens/composition/composition_options.dart';
import 'package:soundsight/screens/composition/piano_note.dart';

class CompositionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<List<Composition>> getUserCompositions(String ownerId) {
    return firestore
        .collection('compositions')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final compositions = <Composition>[];

          for (final document in snapshot.docs) {
            final composition = Composition.fromMap(
              document.id,
              document.data(),
            );

            compositions.add(composition);
          }

          compositions.sort((first, second) {
            final firstDate = first.updatedAt ?? first.createdAt;
            final secondDate = second.updatedAt ?? second.createdAt;

            if (firstDate == null && secondDate == null) return 0;
            if (firstDate == null) return 1;
            if (secondDate == null) return -1;

            return secondDate.compareTo(firstDate);
          });

          return compositions;
        });
  }

  Future<Composition?> getComposition(String compositionId) async {
    final document = await firestore
        .collection('compositions')
        .doc(compositionId)
        .get();

    final data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    return Composition.fromMap(document.id, data);
  }

  Future<String> createComposition(Composition composition) async {
    final validationError = validateComposition(composition);
    if (validationError != null) throw StateError(validationError);

    final document = firestore.collection('compositions').doc();
    final compositionData = composition.toMap();

    compositionData.addAll({
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await document.set(compositionData);

    return document.id;
  }

  Future<void> updateComposition(Composition composition) async {
    if (composition.id.isEmpty) {
      throw StateError('The composition does not have an ID.');
    }

    final validationError = validateComposition(composition);
    if (validationError != null) throw StateError(validationError);

    final compositionData = composition.toMap();

    compositionData['updatedAt'] = FieldValue.serverTimestamp();

    await firestore
        .collection('compositions')
        .doc(composition.id)
        .update(compositionData);
  }

  Future<void> deleteComposition(String compositionId) async {
    if (compositionId.isEmpty) {
      throw StateError('The composition does not have an ID.');
    }

    await firestore.collection('compositions').doc(compositionId).delete();
  }

  String? validateComposition(Composition composition) {
    if (composition.ownerId.trim().isEmpty) {
      return 'Sign in before saving a composition.';
    }
    if (composition.title.trim().isEmpty || composition.title.length > 80) {
      return 'The title must contain 1 to 80 characters.';
    }
    if (!compositionKeySignatures.contains(composition.keySignature)) {
      return 'Choose a supported key signature.';
    }
    if (composition.tempo < 40 || composition.tempo > 200) {
      return 'Tempo must be from 40 to 200 BPM.';
    }
    final timeSignature =
        '${composition.beatsPerMeasure}/${composition.beatUnit}';
    if (!compositionTimeSignatures.contains(timeSignature)) {
      return 'Choose a supported time signature.';
    }
    if (composition.measureCount < 1 || composition.measureCount > 128) {
      return 'A composition can contain up to 128 measures.';
    }
    if (composition.notes.length > 256) {
      return 'A composition can contain up to 256 notes.';
    }

    final noteIds = <String>{};

    for (final note in composition.notes) {
      if (note.id.isEmpty || !noteIds.add(note.id)) {
        return 'Every note must have a unique ID.';
      }
      if (!PianoNote.isValidMidi(note.midiNumber)) {
        return 'A note is outside the 88-key piano range.';
      }

      final pianoNote = PianoNote.fromMidi(note.midiNumber);
      if (note.pitch != pianoNote.pitch || note.octave != pianoNote.octave) {
        return 'A stored note has mismatched pitch information.';
      }
      if (note.measureIndex < 0 ||
          note.measureIndex >= composition.measureCount) {
        return 'A note points to an unavailable measure.';
      }
      if (note.startBeat < 0 ||
          note.durationBeats <= 0 ||
          note.startBeat + note.durationBeats >
              composition.beatsPerMeasure + 0.001) {
        return 'A note extends outside its measure.';
      }
      if (note.velocity < 0 || note.velocity > 1) {
        return 'Note velocity must be between 0 and 1.';
      }
    }

    for (var firstIndex = 0;
        firstIndex < composition.notes.length;
        firstIndex++) {
      final first = composition.notes[firstIndex];

      for (var secondIndex = firstIndex + 1;
          secondIndex < composition.notes.length;
          secondIndex++) {
        final second = composition.notes[secondIndex];
        if (first.measureIndex != second.measureIndex ||
            first.midiNumber != second.midiNumber) {
          continue;
        }

        final overlaps =
            first.startBeat < second.startBeat + second.durationBeats &&
            first.startBeat + first.durationBeats > second.startBeat;
        if (overlaps) {
          return 'The same piano key cannot overlap itself.';
        }
      }
    }

    for (final note in composition.notes) {
      if (!note.tieToNext) continue;

      final noteEnd =
          (note.measureIndex * composition.beatsPerMeasure) +
          note.startBeat +
          note.durationBeats;
      final hasContinuation = composition.notes.any((candidate) {
        final candidateStart =
            (candidate.measureIndex * composition.beatsPerMeasure) +
            candidate.startBeat;
        return candidate.id != note.id &&
            candidate.midiNumber == note.midiNumber &&
            (candidateStart - noteEnd).abs() < 0.001;
      });
      if (!hasContinuation) {
        return 'A tied note does not have a matching continuation.';
      }
    }

    return null;
  }
}
