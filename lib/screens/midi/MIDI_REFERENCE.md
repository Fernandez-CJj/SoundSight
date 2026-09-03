# MIDI Feature Reference

This document describes the MIDI feature as it currently works.

## 1. Purpose

The MIDI feature lets the user connect a MIDI device, such as a digital piano, and see the names of the keys that are currently being held.

It is a live note identifier. It does not record a performance, create a music sheet, calculate a score, or save detected notes.

The feature uses the `flutter_midi_command` package. Android uses the local `flutter_midi_command_android` package configured in `pubspec.yaml`.

## 2. Complete user flow

1. The user opens **MIDI** from the drawer.
2. The app immediately asks the MIDI plugin for available devices.
3. If no device is found, the screen shows **No MIDI device detected**.
4. If at least one device is found, the screen displays the first device's name.
5. The user can tap **Refresh Device** to request the device list again.
6. The user taps **Connect**.
7. The app connects only to the first device in the list.
8. The user presses one or more piano keys.
9. The app displays the active note names in MIDI-number order, such as `C4 + E4 + G4`.
10. Releasing a key removes its name from the display.
11. When no keys are held, the screen displays **Press a piano key**.
12. Leaving the screen disconnects its device and closes its MIDI listeners.

There is also a `NoteInputScreen` in the folder with two choices:

- **MIDI Connection**, which opens the MIDI note identifier; and
- a disabled **Microphone - Coming Soon** button.

The current drawer opens `MidiNoteIdentifierScreen` directly, so the input-choice screen is not part of the drawer flow.

## 3. Temporary local information

All MIDI information is temporary and exists only in memory.

### MIDI service memory

- the currently selected MIDI device;
- the set of MIDI numbers for keys that are still held;
- the MIDI data subscription;
- the selected device's connection-state subscription;
- the device setup-change subscription;
- whether the service has been disposed; and
- broadcast streams for active notes, individual Note On events, and connection changes.

### MIDI screen memory

- the latest list of detected devices;
- the set of active MIDI notes shown on screen; and
- the subscription that listens for active-note changes.

The screen currently listens only to the active-note stream. The service also exposes Note On and connection streams for other code, but this screen does not use them.

## 4. Permanent information

The MIDI folder does not save anything permanently.

It does not use:

- Firebase Authentication;
- Firestore;
- Firebase Storage;
- a local database; or
- a saved file.

Closing the MIDI screen loses the displayed device list and active notes.

## 5. How MIDI messages are handled

The service handles two main MIDI messages.

### Note On

A Note On message with velocity greater than `0` means a key was pressed.

The service:

- adds the MIDI note number to the active-note set; and
- sends that note number through the separate Note On stream.

### Note Off

A Note Off message means a key was released, so the note number is removed from the active-note set.

Some MIDI devices send Note On with velocity `0` instead of Note Off. The service treats that message as a released key too.

The active-note stream sends a new set only when the held-note set actually changes.

Messages from a device other than the service's currently selected device are ignored.

## 6. How MIDI numbers become note names

MIDI uses one number for every musical key. The converter calculates the pitch name with:

```text
note position = MIDI number remainder 12
octave = MIDI number divided by 12, rounded down, minus 1
```

The note position selects one of these twelve names:

```text
C, C#, D, D#, E, F, F#, G, G#, A, A#, B
```

The current converter always uses sharp names. For example, it displays `C#` rather than `Db`.

Examples:

- MIDI `60` becomes `C4`.
- MIDI `61` becomes `C#4`.
- MIDI `69` becomes `A4`.

The screen sorts held MIDI numbers before displaying them. Therefore, a low C, E, and G chord is displayed from the lowest note to the highest note.

## 7. Device connection and replacement

When connecting:

- an already active MIDI-data listener is cancelled;
- an old connection-state listener is cancelled;
- a different previously connected device is disconnected;
- the new device becomes the selected device;
- its connection-state listener is started before the native connection request; and
- MIDI-data listening begins after connection succeeds.

If connection fails, the service removes the selected device, reports a disconnected state through its connection stream, and passes the error back to the caller.

The current screen does not catch that connection error or display its own friendly error message.

## 8. Disconnection, failure, and retry behavior

### Physical disconnection

The service watches both:

- the selected device's direct connection state; and
- global MIDI setup changes, used as a fallback for USB removal.

When Android reports that a device disappeared, the service refreshes the device list and checks whether the selected device still exists.

After confirmed disconnection:

- the selected device is cleared;
- held notes are cleared;
- an empty active-note set is sent if notes were held; and
- `false` is sent through the connection stream.

The current identifier screen does not subscribe to the connection stream and does not automatically replace its displayed `midiDevices` list. Its device label may therefore remain visible until the user taps **Refresh Device**.

### Retry

- **Refresh Device** requests a fresh list of devices.
- **Connect** can be pressed again after a device is available.
- There is no automatic connection retry.

### Expiration and resume

There is no expiration, saved session, or resume behavior. A new screen visit starts with a new MIDI service and requests the device list again.

## 9. Cleanup after the screen closes

When the MIDI service is disposed, it:

- prevents further events from being added;
- disconnects the selected device if it is still connected;
- cancels MIDI, connection, and setup subscriptions; and
- closes all three broadcast streams.

This prevents the screen's MIDI connection and listeners from remaining active after navigation.

## 10. Simple example

Suppose the connected piano sends these messages:

```text
Note On: 60, velocity 90
Note On: 64, velocity 85
Note On: 67, velocity 88
```

The active set becomes `{60, 64, 67}`, and the screen displays:

```text
C4 + E4 + G4
```

If MIDI `64` sends Note Off, the active set becomes `{60, 67}`, and the screen changes to:

```text
C4 + G4
```

Nothing from this example is saved after the screen closes.
