# Microphone Piano Input Implementation Checklist

This checklist defines how to add microphone-based piano recognition to
SoundSight as an alternative to a MIDI connection. Work through the phases in
order. Implementation and user validation are tracked separately. A phase is
validated only when the user reports that its tests and exit criteria pass.

Platform scope: **Android only.** iOS microphone permissions, lifecycle work,
and device validation are intentionally out of scope for this project.

## Working agreement: coding only for Codex

This agreement applies to every phase and takes precedence over any testing,
analysis, verification, benchmarking, or formatting instructions below.

- Codex performs coding only: implement the current step and make code fixes
  based on results supplied by the user.
- Codex must not run tests, static analysis, linters, formatters, builds,
  benchmarks, or automated verification commands. This includes `flutter test`,
  `flutter analyze`, `dart analyze`, `dart format`, and `git diff --check`.
- Codex may read the relevant source files as needed to make code changes.
  No separate analysis or formatting pass is performed.
- The existing `lib/screens/midi/` feature is read-only reference material.
  Codex must not edit, move, rename, wrap, or refactor MIDI files while
  implementing microphone/audio input unless the user explicitly requests a
  separate MIDI change.
- All testing, analysis, formatting, device checks, accuracy measurements,
  and validation in this checklist are the user's responsibility.
- The user tests the app directly on their phone. Manual phone testing and
  user-reported results are the validation gate for each implementation step.
- Automated tests and fixtures listed below are optional reference work, not
  prerequisites for proceeding. Codex should not create additional automated
  tests or fixtures unless the user explicitly requests them.
- After each implementation step, Codex lists the changes and provides concise
  instructions for the user to test, explicitly stating that checks were not
  run by Codex.
- After each implementation step, Codex must reproduce the complete phone test
  list for that step directly in the chat response. The user should not need to
  open this checklist or another file to find the required checks.
- The user runs the app on their phone and reports observed behavior and any
  errors. Logs are useful when available but are not required. Codex uses that
  feedback to implement the next correction or step.
- Mark coding tasks complete when implemented. Leave test and validation
  checkboxes unchecked until the user confirms their results. Do not advance
  past a validation gate that depends on results the user has not supplied.
- When the user requests faster progress, Codex may combine tightly related
  tasks into one small end-to-end batch. The user then validates the complete
  batch on the Android phone before the next batch begins.

The target is **microphone behavior compatible with SoundSight's expectations**:
the microphone feature should provide note attacks, active-note snapshots,
release events, readiness state, and cleanup behavior from audio while leaving
the existing MIDI implementation unchanged.

Microphone recognition cannot observe every physical fact that MIDI reports.
In particular, key release, velocity, and sustain-pedal state must be inferred
from sound. Features that require accurate note duration stay MIDI-only until
their microphone validation gates pass.

## Code organization requirements

Apply these rules to every implementation step:

- Do not over-engineer the implementation. Use the simplest code and file
  structure that satisfies the current step, and avoid unnecessary
  abstractions, wrappers, folders, configuration layers, or premature support
  for features that are not being implemented yet.
- Follow existing project naming and folder conventions. Group related code
  under its feature folder, then separate files by responsibility:
  - `models/`: event types, enums, configuration, and data objects;
  - `services/`: input sources, device lifecycle, audio capture, and processing;
  - `screens/`: screen layout and coordination of user interactions;
  - `widgets/`: reusable UI components;
  - `utils/`: small shared helpers that do not own feature state.
- Keep MIDI hardware handling, microphone capture, note detection, and scoring
  in separate components. Screens should call services rather than contain
  audio-processing or device-management implementations.
- Place microphone contracts, models, services, screens, and widgets under the
  microphone feature folder. Do not move MIDI models into it or make microphone
  services depend on MIDI implementation files.
- Use focused files with descriptive names. Split files when they contain
  distinct responsibilities; avoid unnecessary folders or one-line wrappers.
- Add a concise Dart documentation comment (`///`) immediately above each new
  or modified method or function, including private methods and lifecycle
  overrides. Explain its purpose in plain language and mention important
  inputs, return values, side effects, or timing/lifecycle behavior when useful.
  Keep comments accurate as the implementation changes and avoid simply
  repeating the method name.
- Place test code under `test/`, mirroring the relevant `lib/` feature paths.
  The user remains responsible for running those tests.
- Create only the folders needed for the current step. Preserve existing
  public interfaces where practical and update imports when moving code.
- Organize newly added code and files touched by the current step without
  expanding the work into an unrelated project-wide restructure.

## 1. Current MIDI behavior to preserve

`MidiInputService` currently owns the connected MIDI device and publishes four
broadcast streams:

| MIDI output | Meaning | Current consumers |
| --- | --- | --- |
| `noteOnStream` | Every received note attack as a MIDI number | Assessment, Synthesia, sight reading, calibration |
| `noteEventStream` | Note-on and note-off events with velocity | Synthesia, sight reading, composition recording/editor, calibration |
| `activeNotesStream` | Immutable set of notes currently held | All live piano modes and keyboard highlighting |
| `connectionStream` | Whether the selected source is usable | All modes that must interrupt safely |

Important MIDI semantics:

- Note On with velocity greater than zero emits a note event and a note-on
  event, then adds the pitch to the active set.
- Note On with velocity zero is treated as Note Off.
- Note Off emits a note event and removes the pitch from the active set.
- A new active-note snapshot is emitted only if the set changes.
- Events from devices other than the selected device are ignored.
- Disconnection clears all active notes before reporting the source unusable.
- Disposal disconnects hardware, cancels subscriptions, and closes streams.
- Event timestamps are currently assigned by each consuming screen when it
  receives the event; the MIDI event itself contains no timestamp.
- MIDI control-change messages, including sustain pedal (CC64), are currently
  ignored.
- MIDI channel identity is not retained. Active notes are keyed only by pitch.
- Repeated Note On messages can reach `noteOnStream`/`noteEventStream` even if
  the pitch is already present in the active set.

### Consumer requirements

| Feature | Attack required | Active set required | Release required | Velocity required | Microphone risk |
| --- | --- | --- | --- | --- | --- |
| Assessment | Yes | Display only | No | No | Low |
| Performance scoring | Yes | Sometimes | Yes for duration | No | Medium |
| Synthesia wait mode | Yes | Exact chord/layer matching | Yes | No | High |
| Sight-reading wait mode | Yes | Exact chord/layer matching | Yes | No | High |
| Piano calibration practice | Yes | Exact chord/layer matching | Yes | No | High |
| Composition recording | Yes | Stop/held-note logic | Yes | Yes | Very high |
| Manual composition MIDI step | Yes | Indirectly | Yes | Yes | Very high |

## 2. Definition of microphone parity

The shared microphone source must eventually provide:

- `noteOn`: a new acoustic attack was detected for a pitch;
- `noteOff`: acoustic evidence for the pitch ended;
- `activeNotes`: all pitches currently considered acoustically active;
- `velocity`: an estimated 1–127 value, explicitly marked as estimated;
- `confidence`: detector confidence from 0.0–1.0;
- `capturedAt`: monotonic capture time before inference delay;
- source state: starting, calibrating, ready, degraded, interrupted, stopped,
  or failed;
- signal quality: too quiet, usable, clipping, or too noisy;
- deterministic cleanup that emits an empty active set before stopping.

Terminology:

- **Chord:** notes attacked within the configured chord window.
- **Layer:** a new note or chord added while earlier notes remain active.
- **Carried note:** a note allowed to continue across the next score group.
- **Repeated note:** a new attack of a pitch that was previously released, or
  a clearly detected re-attack while its acoustic tail is still present.

Known limits that the UI and stored results must disclose:

- microphone `activeNotes` means acoustically active, not physically held;
- microphone note-off follows decay and may occur after physical key release;
- sustain pedal makes physical key release impossible to infer from audio;
- estimated acoustic velocity is not MIDI key velocity;
- recognition accuracy depends on piano tuning, room, device, position, and
  competing sounds.

## 3. Phase 0 — baseline and scope

- [ ] Preserve the existing dirty worktree; make microphone work in isolated
      files and small integration commits.
- [x] Confirm target platform: Android only.
- [ ] Define MVP recognition range. Recommended: MIDI 48–84 (`C3–C6`).
- [ ] Define MVP polyphony. Recommended: single notes and chords up to 3 notes.
- [ ] Define MVP pedal policy. Recommended: sustain pedal unsupported/off.
- [ ] Select the first integration feature. Recommended: assessment only.
- [ ] Keep MIDI as the default/high-accuracy option.
- [ ] Add an input-source label to results: `midi` or `microphone`.
- [ ] Add a feature flag so microphone scoring can be disabled without
      removing the implementation.

### Initial performance targets

- [ ] Clean single-note attack recall at least 95% in the supported range.
- [ ] Clean single-note false-positive rate no more than 1 per minute.
- [ ] Clean major/minor triad completion at least 90%.
- [ ] Background-noise-only false-positive rate no more than 1 per minute.
- [ ] P95 note-on delivery latency no more than 200 ms on supported devices.
- [ ] No UI frame stalls caused by audio processing or inference.
- [ ] No stuck active notes after stop, interruption, or permission loss.

## 4. Phase 1 — microphone event foundation

Create the microphone-owned models and processing service without changing the
MIDI feature. Audio capture and note recognition will feed this foundation in
later phases.

Step 1 status: microphone foundation code prepared. No tests, analyzer,
formatter, build, or verification commands have been run by Codex.

- [x] Restore the MIDI files changed during the earlier approach.
- [x] Remove the temporary MIDI note processor created by Codex.
- [x] Add `MicrophoneNoteEvent` with attack/release type, piano note number,
      estimated velocity, confidence, and capture time.
- [x] Add microphone lifecycle and signal-quality models.
- [x] Add `MicrophoneNoteEventProcessor` under the microphone `services/`
      folder.
- [x] Provide microphone-owned note-on, note-event, active-note, lifecycle,
      and signal-quality streams.
- [x] Support chords and layers by retaining an independent active-note set.
- [x] Clear active microphone notes when input stops, fails, or is interrupted.
- [x] Keep the microphone foundation independent from MIDI implementation files.

Implementation files:

- `lib/screens/micNiKen/models/microphone_note_event.dart`
- `lib/screens/micNiKen/models/microphone_input_state.dart`
- `lib/screens/micNiKen/services/microphone_note_event_processor.dart`

### Phone test list

There is no phone-visible behavior in Step 1 because PCM capture is not wired
yet. The first phone test begins with microphone capture in Phase 3.

### Exit criteria

- [x] Microphone event code is organized under the microphone feature.
- [x] No microphone service imports or changes the MIDI implementation.
- [x] User confirms the project opens on their Android phone.

## 5. Phase 2 — microphone input service contract

- [x] Add a microphone-specific note event model.
- [x] Include piano note number, estimated velocity, confidence, and capture
      time.
- [x] Add microphone lifecycle and signal-quality models.
- [x] Expose note-on, note-event, active-note, state, and quality streams.
- [x] Expose the current immutable active-note set.
- [x] Add microphone `start`, `stop`, and `dispose` lifecycle operations around
      the future PCM capture service.
- [x] Add expected-note/context updates for score-aware recognition.
- [x] Wire the microphone service into `MicrophoneScreen` after PCM capture is
      implemented.

### Exit criteria

- [x] Microphone capture can feed the service without importing MIDI code.
- [x] The microphone screen can observe state, signal quality, and active notes.

## 6. Phase 3 — microphone PCM capture and lifecycle

- [x] Add a maintained Flutter package that provides raw PCM streaming.
- [x] Capture mono PCM16, initially at 44.1 kHz.
- [ ] Verify the actual device sample rate instead of assuming the requested
      rate was honored.
- [x] Keep iOS microphone configuration out of scope for this Android-only app.
- [x] Confirm Android `RECORD_AUDIO` is declared and request it at runtime.
- [ ] Implement permission denied, permanently denied, and restricted states.
- [x] Implement a simple PCM frame buffer; plugin callbacks may contain
      arbitrary chunk sizes and do not define analysis-frame boundaries.
- [x] Run pitch-detection work outside the UI isolate.
- [x] Stop capture on navigation and when the Android app leaves the foreground.
- [ ] Handle Android calls and audio-route interruptions explicitly.
- [ ] Resume only after the screen confirms that resuming is safe.
- [x] Emit an empty active-note set before interruption/stopped state.
- [ ] Prevent MIDI and microphone services from owning the same feature at the
      same time.
- [ ] Test rapid start/stop/start and dispose during startup.

### Exit criteria

- [x] A diagnostic screen displays live RMS/peak level without dropped UI
      frames.
- [x] No PCM is written to disk or uploaded unless a future feature explicitly
      requests and discloses recording.
- [x] Microphone resources are always released after leaving the feature.

### Android phone test list for the PCM capture step

- [x] Run the app on the Android phone and open **Microphone Piano Input**.
- [x] Tap **Start listening** and allow microphone permission when prompted.
- [x] Confirm the status changes to **Listening**.
- [ ] Stay quiet and confirm the meters remain low and may show **too quiet**.
- [x] Speak, clap, or play the piano and confirm both meters move.
- [ ] Play or speak very loudly near the phone and optionally confirm clipping
      guidance appears.
- [x] Tap **Stop listening** and confirm both meters reset.
- [x] Tap **Start listening** again and confirm capture works a second time.
- [x] While listening, background the app and return; confirm capture stopped
      and can be started again manually.
- [x] Leave the microphone screen and confirm Android's microphone indicator
      turns off; reopen the screen and confirm it still works.
- [ ] If practical, deny microphone permission and confirm a useful permission
      message is shown without a crash.

User result: PCM capture, meters, start/stop, restart, and cleanup work on the
Android phone. The electric fan keeps the raw level above the quiet threshold;
adaptive noise calibration remains planned for Phase 4. Permission-denial and
optional clipping checks remain unconfirmed. Codex did not run tests, analysis,
formatting, builds, or automated verification.

## 7. Phase 4 — calibration and signal-quality gate

- [x] Add an initial 3-second whole-signal ambient RMS baseline. This is the
      simple first calibration step; per-band calibration remains below.
- [ ] Add a 3–5 second silence calibration to estimate per-band noise floor.
- [x] Detect input that is too quiet relative to the ambient baseline.
- [x] Detect clipping/saturation.
- [ ] Estimate signal-to-noise ratio.
- [ ] Add a short played-note check to verify piano audibility.
- [ ] Allow an A4/tuning-offset check; do not assume every acoustic piano is
      exactly A4 = 440 Hz.
- [ ] Store only non-sensitive calibration values locally where useful.
- [ ] Invalidate calibration after audio-route changes.
- [ ] Show actionable guidance:
  - [ ] move the device closer;
  - [ ] uncover the microphone;
  - [ ] increase keyboard volume;
  - [x] reduce room noise;
  - [ ] use wired headphones for SoundSight playback;
  - [ ] use a natural piano sound;
  - [ ] turn sustain off for MVP exercises.
- [ ] Block scoring when the signal is unusable rather than scoring silence as
      mistakes.

### Android phone test list for initial noise calibration

- [ ] Open **Microphone Piano Input** and tap **Start listening**.
- [ ] Keep the room quiet for three seconds while the status says
      **Calibrating**. A steady fan may remain on so it becomes part of the
      measured ambient baseline.
- [ ] Confirm the status changes to **Listening** or
      **Listening with limited quality** after calibration.
- [ ] With only the fan running, confirm the raw meters may move but the quality
      does not continually report the fan as a usable foreground signal.
- [ ] Play the piano after calibration and confirm sufficiently louder sound is
      reported as usable.
- [ ] Stop and start listening again, then confirm a fresh three-second
      calibration occurs.
- [ ] Leave the screen and confirm Android's microphone indicator turns off.

Coding status: initial ambient-level calibration is prepared for Android phone
testing. Per-frequency noise calibration and piano-specific filtering are not
implemented yet. Codex did not run tests, analysis, formatting, builds, or
automated verification.

## 8. Phase 5 — score-aware single-note detector

Start with expected-note verification, not unrestricted transcription.

- [x] Add a monophonic YIN feasibility detector using the existing
      `pitch_detector_dart` dependency.
- [x] Convert detected frequencies to the nearest piano note number.
- [x] Gate pitch analysis behind calibrated usable-signal quality.
- [ ] Convert expected MIDI numbers to frequencies using A4 tuning.
- [ ] Implement windowing and a spectral representation (FFT, multi-resolution
      FFT, or constant-Q transform).
- [ ] Normalize against the calibrated noise floor.
- [ ] Score the fundamental and multiple harmonics for each candidate pitch.
- [ ] Evaluate the expected pitch plus adjacent semitones and octave-confusable
      alternatives.
- [ ] Detect attacks using spectral flux/energy rise, not steady energy alone.
- [ ] Use separate attack-on, active, and release thresholds.
- [x] Add hysteresis and minimum confirmation frames.
- [ ] Preserve capture timestamps and compensate measured detector latency.
- [x] Map frame loudness to a conservative estimated velocity and keep confidence
      available separately.
- [x] Suppress notes outside the MVP range C3–C6 rather than misclassifying them.
- [x] Keep feasibility thresholds together as named constants.

### Android phone test list for the single-note feasibility batch

- [ ] Start listening and remain quiet for the three-second calibration.
- [ ] Keep the electric fan running during calibration, then wait with only the
      fan for at least 30 seconds and record any false piano notes.
- [ ] Play middle C (`C4`) alone and confirm the active note shows `C4`.
- [ ] Release `C4` and confirm the active note returns to `none` shortly after
      the sound decays.
- [ ] Test `C3`, `C4`, `C5`, and `C6` individually.
- [ ] Test several black keys and confirm sharp-note names are correct.
- [ ] Test soft, medium, and loud single notes.
- [ ] Play the same note repeatedly and confirm each new attack can be observed.
- [ ] Speak and clap near the phone, then record any false piano notes.
- [ ] Play a chord only as an observation; this detector is monophonic, so chord
      accuracy is not part of this batch's pass criteria.
- [ ] Watch for visible UI lag, delayed notes, stuck active notes, or crashes.
- [ ] Stop listening and leave the screen; confirm the active note clears and
      Android's microphone indicator turns off.

Coding status: the first end-to-end single-note feasibility batch is prepared
for Android phone testing. Chord and layer recognition are intentionally not
implemented by this monophonic detector. Codex did not run tests, analysis,
formatting, builds, or automated verification.

### Single-note tests

- [ ] Every natural and accidental pitch in the supported range.
- [ ] Soft, medium, and loud attacks.
- [ ] Staccato and legato notes.
- [ ] Repeated same-note attacks.
- [ ] Chromatic passages.
- [ ] Octave jumps.
- [ ] Slightly detuned acoustic-piano recordings.
- [ ] Multiple digital-piano voices, with unsupported voices clearly rejected
      or marked degraded.

### Exit criteria

- [ ] Initial accuracy and latency targets pass for clean single notes.
- [ ] No event is emitted solely from steady background hum.
- [ ] The assessment tracker can consume microphone attacks without code that
      special-cases pitch scoring.

## 9. Phase 6 — chords, layers, carried notes, and re-attacks

- [ ] Replace single-dominant-pitch assumptions with multi-label scoring.
- [ ] Maintain independent evidence and state for every supported pitch.
- [ ] Prevent one strong fundamental/harmonic series from fabricating octave
      notes.
- [ ] Require distinct evidence for every member of a chord.
- [ ] Allow attacks within the configured chord window to form one chord.
- [ ] Preserve earlier active notes when a new layer is attacked.
- [ ] Support carried notes allowed by the current score context.
- [ ] Reject unexpected notes even when all expected notes are present.
- [ ] Detect re-attacks while an earlier acoustic tail remains when onset
      evidence is sufficiently strong.
- [ ] Define a release timeout for weak/stuck acoustic tails.
- [ ] Clear all state on seeking, retrying, source interruption, or exercise
      reset.

### Chord/layer test matrix

- [ ] Major, minor, diminished, and augmented triads.
- [ ] Close-position and spread triads.
- [ ] Root-position and inversions.
- [ ] Two notes sharing strong harmonics.
- [ ] Same chord attacked softly and loudly.
- [ ] Rolled chord inside and outside the allowed chord window.
- [ ] Hold C, add E, add G, then release G/E/C in different orders.
- [ ] Hold a bass note while playing changing upper chords.
- [ ] Expected chord plus one wrong note.
- [ ] Repeated chord after complete release.
- [ ] Repeated pitch before its acoustic tail fully decays.

### Exit criteria

- [ ] `activeNotes` contains the complete accepted chord/layer, not only the
      loudest note.
- [ ] Each accepted attack generates one note-on event.
- [ ] False octave and missing-inner-note rates meet the MVP targets.

## 10. Phase 7 — background-noise and echo resilience

Create labeled test fixtures and live tests for:

- [ ] silence and microphone self-noise;
- [ ] white, pink, and brown noise at multiple SNRs;
- [ ] fan and air-conditioner hum;
- [ ] traffic and outdoor noise;
- [ ] nearby speech and laughter;
- [ ] singing or humming a target pitch;
- [ ] television and unrelated music;
- [ ] phone notifications and ringtones;
- [ ] claps, taps, knocks, and dropped objects;
- [ ] metronome clicks;
- [ ] SoundSight backing tracks from the device speaker;
- [ ] SoundSight backing tracks through wired headphones;
- [ ] different device-to-piano distances and orientations;
- [ ] acoustic piano, keyboard speakers, and wired audio-interface input.

Noise-handling tasks:

- [ ] Continuously update the noise estimate only during trusted non-playing
      periods.
- [ ] Do not let loud transients permanently raise thresholds.
- [ ] Add a transient classifier/gate for obvious non-piano attacks if needed.
- [ ] Limit candidate pitches using score context without hiding clear wrong
      notes.
- [ ] Duck or disable backing audio during early MVP tests.
- [ ] Recommend wired headphones when backing audio is enabled.
- [ ] If speaker playback must be supported, evaluate reference-signal echo
      suppression using the exact audio SoundSight is playing.
- [ ] Do not assume speech-oriented OS noise suppression will preserve piano
      harmonics; benchmark processed and unprocessed capture modes.
- [ ] Transition to `degraded` state when noise makes scoring unreliable.

### Exit criteria

- [ ] Noise-only fixtures meet the false-positive target.
- [ ] Moderate-noise fixtures meet the agreed recall target.
- [ ] Backing-track behavior is explicitly supported, degraded, or blocked—no
      undefined mode.

## 11. Phase 8 — integrate features in risk order

### 8A. Assessment

- [ ] Add MIDI/Microphone source selection and automatic fallback prompt.
- [ ] Require microphone calibration before starting.
- [ ] Feed corrected capture timestamps to assessment scoring.
- [ ] Use a separately configured microphone chord/timing tolerance initially.
- [ ] Persist the input source and detector version with the result.
- [ ] Interrupt without consuming the task if microphone input fails.
- [ ] A/B-test the same performances through MIDI and microphone.

### 8B. Performance-mode attack scoring

- [ ] Enable only after assessment targets pass.
- [ ] Validate fast passages, wrong notes, and repeated notes.
- [ ] Keep duration scoring disabled until note-off accuracy passes.

### 8C. Wait modes and visual keyboard highlighting

- [ ] Validate exact active-set matching.
- [ ] Validate carried notes and release-to-retry behavior.
- [ ] Prevent acoustic tails from blocking retries indefinitely.
- [ ] Clearly handle sustain-pedal use.

### 8D. Composition recording and manual composition entry

- [ ] Enable last because these features depend on accurate release duration
      and velocity.
- [ ] Validate paired note-on/note-off events with no unmatched notes.
- [ ] Validate chord-window behavior and independently released notes.
- [ ] Define whether estimated velocity is acceptable for saved compositions.
- [ ] Keep MIDI-only if duration or velocity quality is insufficient.

## 12. Phase 9 — optional on-device ML recognizer

Use this phase when the score-aware detector reaches its accuracy ceiling.

- [ ] Benchmark Spotify Basic Pitch TFLite as a transcription prototype.
- [ ] Do not ship it unchanged for live scoring without proving latency; its
      standard model window is approximately two seconds.
- [ ] Define a streaming model with two 88-key outputs:
  - [ ] onset probability;
  - [ ] active-frame probability.
- [ ] Prefer causal/limited-lookahead architecture for bounded latency.
- [ ] Train with aligned piano audio and MIDI labels.
- [ ] Augment training data with room responses, device responses, noise,
      backing tracks, tuning offsets, piano voices, and gain variation.
- [ ] Keep training, validation, and device-recorded test pianos separate.
- [ ] Export and benchmark float and quantized TFLite models.
- [ ] Run inference through the existing `flutter_litert` dependency.
- [ ] Verify CPU/GPU fallback and numerical consistency on real devices.
- [ ] Record model version and thresholds with diagnostic results.
- [ ] Review code, model, and dataset licenses before distribution.

## 13. Automated test plan

- [ ] Pure unit tests for frequency mapping, framing, window overlap, noise
      floor, onset hysteresis, active state, release state, and latency
      compensation.
- [ ] Optional microphone contract tests are created only if the user requests
      them.
- [ ] Golden event-sequence tests using checked-in short PCM/WAV fixtures.
- [ ] Tests for arbitrary PCM chunk boundaries.
- [ ] Tests for missing, duplicated, and out-of-order detector frames.
- [ ] Tests for pause/resume, interruption, source switch, and disposal.
- [ ] Tests for permission denied and permission revoked.
- [ ] Widget tests for setup, calibration, degraded state, and retry UI.
- [ ] Integration tests that feed recognized events into assessment scoring.
- [ ] Regression corpus with expected note-on/off times and allowed tolerance.
- [ ] Produce precision, recall, F1, false positives/minute, and latency
      percentiles per fixture category.

## 14. Real-device test matrix

- [ ] At least one low/mid-range Android phone.
- [ ] At least one recent Android phone.
- [ ] Acoustic upright piano.
- [ ] Acoustic grand piano when available.
- [ ] At least two digital keyboards using built-in speakers.
- [ ] Quiet room, normal room, and noisy room.
- [ ] Device close to the piano and at realistic lesson distance.
- [ ] Internal microphone, wired headset route, and external audio input where
      supported.
- [ ] Thermal test for a complete practice session.
- [ ] Battery and memory test for a complete practice session.

## 15. Release and privacy gates

- [ ] Explain why microphone permission is needed before the OS prompt.
- [ ] State whether audio remains on-device.
- [ ] Do not retain raw audio by default.
- [ ] Provide an obvious stop/listening indicator.
- [ ] Provide manual MIDI/microphone switching.
- [ ] Fall back safely when the microphone is unavailable or unreliable.
- [ ] Localize all new user-facing strings.
- [ ] Update accessibility labels and screen-reader announcements.
- [ ] Add troubleshooting documentation.
- [ ] Add third-party notices for any bundled code/model/data requiring them.
- [ ] Keep a remote/feature-flag kill switch for microphone scoring.

## 16. Recommended implementation order

1. Microphone event models and processing service.
2. Microphone lifecycle and expected-note contract.
3. PCM capture diagnostic screen.
4. Calibration and signal-quality gate.
5. Score-aware single-note detection.
6. Assessment-only microphone integration.
7. Chord and layer detection.
8. Noise/backing-track hardening.
9. Performance and wait modes.
10. Composition features only after release/velocity validation.
11. Streaming ML model if DSP/template recognition is insufficient.

## 17. Reference material

- Existing SoundSight MIDI behavior: `lib/screens/midi/MIDI_REFERENCE.md`
- MIDI service: `lib/screens/midi/services/midi_input_service.dart`
- Current microphone placeholder:
  `lib/screens/micNiKen/microphone_screen.dart`
- Assessment input consumer:
  `lib/screens/assessment/screens/assessment_piano_execution_screen.dart`
- Simply/MusicSense public architecture:
  <https://medium.com/hellosimply/a-look-under-the-hood-of-simply-piano-part-2-3ba3cafa1bbf>
- Spotify Basic Pitch:
  <https://github.com/spotify/basic-pitch>
- Google Onsets and Frames:
  <https://magenta.tensorflow.org/onsets-frames>

