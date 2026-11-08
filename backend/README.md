# SoundSight backend teaching checklist

This is our teaching plan, based on the current source. Checkboxes mean
**explained together**, not merely inspected while preparing this document.
All teaching checkboxes start unchecked.

## Coverage and how we will learn

Every project-owned file under `backend/` has a file lesson, including package
markers and tests. The two root Windows launchers are included too. Generated
runtime files and installed environments have their own section below; their
formats and lifecycle are covered separately from project source code.

For each file, we will open the actual current source and work from its first
line to its last line in small blocks. A short purpose summary does not complete
a lesson. Large files will take multiple sessions.

- [ ] Explain each import, where it comes from, and why this file needs it.
- [ ] Explain module-level constants, configuration, data structures and any
  code executed immediately on import.
- [ ] Explain every function/class, its parameters, types, fields, defaults,
  decorators, local variables, nested helpers and return values.
- [ ] Explain each condition, loop, comprehension, lambda, SQL statement,
  context manager, exception path and finally block in the source.
- [ ] Identify the caller and the next file called; distinguish data returned
  to Python from JSON sent to the app and changes persisted to storage.
- [ ] Walk a concrete input through the code, including a normal result and an
  applicable failure/retry path. Use temporary files and mocked services for
  examples that would otherwise modify real data.
- [ ] Let you explain the flow back or ask follow-up questions before marking
  the file lesson complete. Record partial progress under the relevant file.

## Reviewed map of the active backend

```text
Start Backend.cmd
  -> start-all.ps1
     -> start-backend.ps1 -> uvicorn main:app -> API routes + request logging
     -> start-worker.ps1  -> jobs.worker -> jobs.runner -> jobs.processors

App request -> protocol/authentication -> jobs.routes.submit
  -> inspect target and source revision -> SQLite reservation -> Firebase activation
  -> HTTP 202 with job ID/state

Worker claims job -> Firebase processing state -> isolated runner process
  -> composition / OMR / audio job_processor.process
  -> generated files in Firebase Storage + returned fields/paths
  -> SQLite finishing -> Firebase conditional final commit -> SQLite terminal state
  -> notification delivery + eventual cleanup

App observes Firestore processingJobs and also polls GET /jobs/{jobId}.
Publishing and unpublishing use their own synchronous composition routes.

Start Quick Tunnel.cmd -> start-tunnel.ps1 -> quick_tunnel.py
  -> verify local readiness -> start Cloudflare -> verify public readiness
  -> update Firebase appConfig/backend with the new address
```

The important distinction is that producing files, saving the public result,
and sending a notification are separate steps. `202` means accepted; a `200`
progress response can still describe a running job. Local `admitting` and
`finishing` states are mapped into public states by `public_job`.

The current dispatchers call the three `services/job_processor.py` files.
`convertMusicSheet` and `transcribe_audio` are alternate direct workflows; no
current registered route calls them. They and their helpers remain in the
teaching plan. The standalone OMR request model and composition save helpers
also receive explicit lessons rather than being silently skipped.

## File-by-file lessons

The numbered file lessons are in teaching order. Each symbol below is a
code-walkthrough checkpoint, including nested functions and class methods.
The shared completion rules above apply to every line around those symbols too.

## 1. Starting the backend and finding the entry points

### File 01: [README.md](README.md)

- [ ] File lesson complete: `README.md`.

Code walkthrough: How to use this checklist, its coverage rules, and when a lesson can be checked off.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 02: [../Start Backend.cmd](../Start%20Backend.cmd)

- [x] File lesson complete: `../Start Backend.cmd`.

Code walkthrough: Every batch command: @echo off, setlocal, %~dp0, PowerShell flags, errorlevel, pause, and endlocal. Follow the jump into start-all.ps1.

- [x] Explain every line, argument, option, assignment and exit path in this file.

### File 03: [requirements.txt](requirements.txt)

- [ ] File lesson complete: `requirements.txt`.

Code walkthrough: Explain each dependency individually: fastapi, uvicorn[standard], music21, firebase-admin, Pillow, and imageio-ffmpeg; distinguish direct dependencies from installed transitive packages.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 04: [start-all.ps1](start-all.ps1)

- [ ] File lesson complete: `start-all.ps1`.

Code walkthrough: Parameters and defaults; required-file checks; credential path resolution; PowerShell discovery; CheckOnly; the service loop; -NoLogo/-NoProfile/-NoExit; command arguments; visible child windows; startup messages; failure exit codes.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 05: [start-backend.ps1](start-backend.ps1)

- [ ] File lesson complete: `start-backend.ps1`.

Code walkthrough: Mandatory credentials, bind address and port; working directory; GOOGLE_APPLICATION_CREDENTIALS; window title; the exact Python executable; -u; uvicorn main:app; one API worker; --no-access-log; process exit status.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 06: [start-worker.ps1](start-worker.ps1)

- [ ] File lesson complete: `start-worker.ps1`.

Code walkthrough: Compare this launcher with the API launcher, then explain -m jobs.worker and why the worker remains a separate process. The removed banner is not part of the execution flow.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 07: [main.py](main.py)

- [ ] File lesson complete: `main.py`.

Code walkthrough: Import order and its initialization effects; configure_logging; app metadata; all router registrations; middleware registration; why importing main:app starts an API application rather than a conversion.

- [ ] Explain module-level definitions: `app`.
- [ ] Trace every top-level statement in execution order.

### File 08: [core/routes.py](core/routes.py)

- [ ] File lesson complete: `core/routes.py`.

Code walkthrough: Trace the root response and every health field, including worker heartbeat availability, waiting capacity, processing count, awaitingSync, Audiveris detection, and jobProtocol. Explain what the health response does and does not check.

- [ ] Explain module-level definitions: `router`.
- [ ] Function/method `root`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `health`: explain its actual code, inputs, branches and effects.

## 2. Firebase access and authentication

### File 09: [core/integrations/firebase_service.py](core/integrations/firebase_service.py)

- [ ] File lesson complete: `core/integrations/firebase_service.py`.

Code walkthrough: Module-level Firebase initialization, the selected bucket, Application Default Credentials, the cached database variable, and the distinction between Firestore documents and Storage blobs.

- [ ] Explain module-level definitions: `firebaseApp`, `database`.
- [ ] Function/method `getDatabase`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `getStorageBucket`: explain its actual code, inputs, branches and effects.

### File 10: [core/auth_service.py](core/auth_service.py)

- [ ] File lesson complete: `core/auth_service.py`.

Code walkthrough: Header injection through Depends; Bearer parsing; verification and clock skew; every token-error branch and HTTP status; email verification; UID extraction; diagnostic messages without exposing token values.

- [ ] Explain module-level definitions: `logger`.
- [ ] Function/method `_invalidTokenReason`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `requireVerifiedFirebaseUser`: explain its actual code, inputs, branches and effects.

## 3. Receiving requests and accepting durable jobs

### File 11: [jobs/routes.py](jobs/routes.py)

- [ ] File lesson complete: `jobs/routes.py`.

Code walkthrough: Every registered HTTP route; protocol and idempotency headers; submit retry behavior; source inspection; reservation and activation; error-to-HTTP mapping; cancellation; Device fields; notification registration. Trace one POST from dependencies through its 202 JSON response.

- [ ] Explain module-level definitions: `router`.
- [ ] Function/method `protocol`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `submit`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `recognize`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `transcribe`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `generate`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `get_job`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `cancel_job`: explain its actual code, inputs, branches and effects.
- [ ] Class `Device`: explain its actual code, inputs, branches and effects. Fields: `token`, `language`.
- [ ] Function/method `register_device`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `unregister_device`: explain its actual code, inputs, branches and effects.

### File 12: [jobs/repositories/store.py](jobs/repositories/store.py)

- [ ] File lesson complete: `jobs/repositories/store.py`.

Code walkthrough: Every SQL table, index, query and transaction; JSON serialization; ownership; idempotency; the two-active-jobs-per-user and twenty-waiting-jobs limits; single-job execution; cancellation; recovery; heartbeat; device ownership; durable notification retries. Split this file into several lessons.

- [ ] Explain module-level definitions: `ACTIVE`, `TERMINAL`.
- [ ] Class `ClosingConnection`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `ClosingConnection.__exit__`: explain its actual code, inputs, branches and effects.
- [ ] Class `QueueError`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `QueueError.__init__`: explain its actual code, inputs, branches and effects.
- [ ] Class `Store`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.__init__`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.connect`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.transaction`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.decode`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.get`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.existing`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.reserve`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.ready`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.abandon`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.pending`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.claim`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.finish`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.cancel`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.recover`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.commit_terminal`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.heartbeat`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.cleanup_jobs`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.cleanup_done`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.health`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.available`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.register`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.unregister`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.deliveries`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.delivery_done`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `Store.delivery_retry`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `public_job`: explain its actual code, inputs, branches and effects.

### File 13: [jobs/repositories/firebase_bridge.py](jobs/repositories/firebase_bridge.py)

- [ ] File lesson complete: `jobs/repositories/firebase_bridge.py`.

Code walkthrough: CONTENT and OUTPUTS; source revision hashing; target and processingJobs document paths; source validation and Storage generations; transaction wrappers; activeJobId; activation; processing; conditional final commit; preserving previous successful outputs; terminal-state lookup.

- [ ] Explain module-level definitions: `CONTENT`, `OUTPUTS`.
- [ ] Function/method `revision`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `refs`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `status_field`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `inspect_target`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_activate`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `activate`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_processing`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `processing`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `check_sources`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_complete`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `complete`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `terminal_status`: explain its actual code, inputs, branches and effects.

## 4. Executing jobs, saving results, and recovering

### File 14: [jobs/process_guard.py](jobs/process_guard.py)

- [ ] File lesson complete: `jobs/process_guard.py`.

Code walkthrough: Windows ctypes structures, process Job Objects and child cleanup; subprocess parameters and stdin authorization; non-Windows branches; the one-worker file lock; both close methods. Explain every nested structure and field.

- [ ] Class `ProcessTree`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `ProcessTree.__init__`: explain its actual code, inputs, branches and effects.
- [ ] Class `ProcessTree.__init__.Basic`: explain its actual code, inputs, branches and effects.
- [ ] Class `ProcessTree.__init__.IO`: explain its actual code, inputs, branches and effects.
- [ ] Class `ProcessTree.__init__.Extended`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `ProcessTree.close`: explain its actual code, inputs, branches and effects.
- [ ] Class `WorkerLock`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `WorkerLock.__init__`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `WorkerLock.close`: explain its actual code, inputs, branches and effects.

### File 15: [jobs/worker.py](jobs/worker.py)

- [ ] File lesson complete: `jobs/worker.py`.

Code walkthrough: Startup and logging; lock acquisition; signal handlers; all four nested maintenance/synchronization loops; admission and final-state reconciliation; recovery; heartbeat; deadlines; selecting work; per-attempt files and scratch directories; child environment; subprocess launch; timeout and startup errors; finally cleanup. Trace Completed and saved back to the committed state.

- [ ] Explain module-level definitions: `log`, `DEADLINES`.
- [ ] Function/method `describe_job`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `synchronize`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `main`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `main.local_cleanup_loop`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `main.sync_loop`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `main.notification_loop`: explain its actual code, inputs, branches and effects.

### File 16: [jobs/runner.py](jobs/runner.py)

- [ ] File lesson complete: `jobs/runner.py`.

Code walkthrough: The __main__ guard; stdin run gate; argv job ID; deferred imports; job lookup; dispatch; successful local finishing state; safe public errors versus detailed attempt tracebacks.

- [ ] Function/method `main`: explain its actual code, inputs, branches and effects.

### File 17: [jobs/processors.py](jobs/processors.py)

- [ ] File lesson complete: `jobs/processors.py`.

Code walkthrough: Validate saved source generations; build the unique job/attempt suffix; lazy imports; dispatch each of the three job kinds; returned fields/paths; inspect the fallback branch as it is written.

- [ ] Function/method `execute`: explain its actual code, inputs, branches and effects.

### File 18: [jobs/services/notifications.py](jobs/services/notifications.py)

- [ ] File lesson complete: `jobs/services/notifications.py`.

Code walkthrough: Read due deliveries; choose English/Filipino text; construct the FCM notification and data payload; Android options; acknowledge delivery; remove invalid registrations; retry failures.

- [ ] Function/method `deliver`: explain its actual code, inputs, branches and effects.

### File 19: [jobs/services/artifact_cleanup.py](jobs/services/artifact_cleanup.py)

- [ ] File lesson complete: `jobs/services/artifact_cleanup.py`.

Code walkthrough: Retention constants and filename patterns; symlink/junction and root checks; nested terminal-job cache; eligibility of each log and scratch folder; dry_run; deletion branches; retries; why active and unknown jobs are retained.

- [ ] Explain module-level definitions: `log`, `FAILED_LOG_RETENTION_SECONDS`, `LOG_NAME`, `WORK_NAME`.
- [ ] Function/method `safe_child`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `cleanup_local_artifacts`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `cleanup_local_artifacts.terminal_job`: explain its actual code, inputs, branches and effects.

## 5. Understanding requests, responses, and logs

### File 20: [core/logging_setup.py](core/logging_setup.py)

- [ ] File lesson complete: `core/logging_setup.py`.

Code walkthrough: Both logging classes; record copying; console filtering; full file tracebacks; SOUNDSIGHT_LOG_DIR; formatter and handler dictionaries; file rotation; logger propagation; disabling duplicate Uvicorn access messages.

- [ ] Class `ConsoleActivityFilter`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `ConsoleActivityFilter.filter`: explain its actual code, inputs, branches and effects.
- [ ] Class `ConsoleFormatter`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `ConsoleFormatter.format`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `configure_logging`: explain its actual code, inputs, branches and effects.

### File 21: [core/request_logging.py](core/request_logging.py)

- [ ] File lesson complete: `core/request_logging.py`.

Code walkthrough: Every action/status/state mapping; identifier cleanup; ASGI scope/receive/send; non-HTTP pass-through; nested capture_send; the bounded response buffer; exception behavior; allowed job metadata; elapsed time; log levels; quiet successful health checks; bounded repeated-state tracking.

- [ ] Explain module-level definitions: `log`, `_ACTIONS`, `_RESPONSES`, `_STATES`.
- [ ] Function/method `_clean`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_action`: explain its actual code, inputs, branches and effects.
- [ ] Class `RequestLoggingMiddleware`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestLoggingMiddleware.__init__`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestLoggingMiddleware.__call__`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestLoggingMiddleware.__call__.capture_send`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestLoggingMiddleware._record`: explain its actual code, inputs, branches and effects.

## 6. Shared music conversion tools

### File 22: [core/integrations/musescore_service.py](core/integrations/musescore_service.py)

- [ ] File lesson complete: `core/integrations/musescore_service.py`.

Code walkthrough: The installed executable path and every conversion command; MusicXML, PDF, MIDI and MP3 differences; subprocess return codes and timeouts; missing/empty-file checks; FFmpeg filters; fade duration; atomic replacement and temporary-file cleanup.

- [ ] Explain module-level definitions: `MUSESCORE_PATH`.
- [ ] Function/method `isMuseScoreInstalled`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `exportMusicXml`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `exportPdf`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `exportMidi`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `exportMp3`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `trimMp3ToDuration`: explain its actual code, inputs, branches and effects.

## 7. Composition generation, timing, and publishing

### File 23: [composition/models/composition_models.py](composition/models/composition_models.py)

- [ ] File lesson complete: `composition/models/composition_models.py`.

Code walkthrough: Every annotated field, default, Literal and Field constraint in all three Pydantic models. Compare a manual note with a recorded performance note and distinguish beats, MIDI numbers, velocity scales and microseconds.

- [ ] Class `CompositionNoteRequest`: explain its actual code, inputs, branches and effects. Fields: `id`, `pitch`, `octave`, `midiNumber`, `measureIndex`, `startBeat`, `durationBeats`, `velocity`, `tieToNext`.
- [ ] Class `RecordedPerformanceNoteRequest`: explain its actual code, inputs, branches and effects. Fields: `midiNumber`, `velocity`, `startTimeUs`, `durationUs`.
- [ ] Class `CompositionRequest`: explain its actual code, inputs, branches and effects. Fields: `id`, `ownerId`, `title`, `creationMethod`, `tempo`, `key`, `beatsPerMeasure`, `beatUnit`, `measureCount`, `notes`, `recordingSchemaVersion`, `performanceNotes`, `performanceDurationUs`.

### File 24: [composition/repositories/private_composition_repository.py](composition/repositories/private_composition_repository.py)

- [ ] File lesson complete: `composition/repositories/private_composition_repository.py`.

Code walkthrough: Owned document lookup; legacy noteId normalization; Pydantic compatibility branch; note/schema/duration limits; recorded timing normalization; generated-file version checks. Also explain the save helpers that are not called by the current queued generation path.

- [ ] Explain module-level definitions: `CURRENT_GENERATED_FILES_VERSION`.
- [ ] Function/method `getOwnedCompositionReference`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `loadOwnedComposition`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `saveGeneratedFilePaths`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `saveGenerationStatus`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `generatedFilesAreCurrent`: explain its actual code, inputs, branches and effects.

### File 25: [composition/repositories/public_profile_repository.py](composition/repositories/public_profile_repository.py)

- [ ] File lesson complete: `composition/repositories/public_profile_repository.py`.

Code walkthrough: User document lookup, username validation, fallbacks, and the exact public profile fields returned to generation and publishing.

- [ ] Function/method `getPublicProfile`: explain its actual code, inputs, branches and effects.

### File 26: [composition/services/job_processor.py](composition/services/job_processor.py)

- [ ] File lesson complete: `composition/services/job_processor.py`.

Code walkthrough: Read the owned composition and author; call generation with an attempt suffix; add generated-file version; return normalized timing metadata when applicable; defer final public state to the Firebase bridge.

- [ ] Function/method `process`: explain its actual code, inputs, branches and effects.

### File 27: [composition/services/generation_service.py](composition/services/generation_service.py)

- [ ] File lesson complete: `composition/services/generation_service.py`.

Code walkthrough: Manual versus recording branch; create the score; use a temporary directory; export/normalize MusicXML; create PDF; select the MIDI writer; create and trim MP3; upload; return Storage paths and unwind the temporary directory.

- [ ] Function/method `generateCompositionFiles`: explain its actual code, inputs, branches and effects.

### File 28: [composition/processing/score_builder.py](composition/processing/score_builder.py)

- [ ] File lesson complete: `composition/processing/score_builder.py`.

Code walkthrough: Build music21 metadata, treble and bass staves, the key/time/tempo, measure count and piano staff group. Trace the split at MIDI 60 and the manual versus recorded note-writing branches.

- [ ] Function/method `create_basic_score`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createPianoStaff`: explain its actual code, inputs, branches and effects.

### File 29: [composition/processing/music_writer.py](composition/processing/music_writer.py)

- [ ] File lesson complete: `composition/processing/music_writer.py`.

Code walkthrough: Trace every manual notation helper: beat units, ties and continuations, rests, chords, grouping simultaneous notes, assigning voices, filling measures, and selecting notes for each staff.

- [ ] Function/method `getStartBeat`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `getTieType`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createMusicNote`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addRest`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `groupMeasureNotes`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `assignGroupsToVoices`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createManualMusicalObject`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addGroupsToContainer`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addMeasureMusic`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addCompositionMusic`: explain its actual code, inputs, branches and effects.

### File 30: [composition/processing/performance_timing.py](composition/processing/performance_timing.py)

- [ ] File lesson complete: `composition/processing/performance_timing.py`.

Code walkthrough: Every constant and rhythmic candidate; time-to-measure arithmetic; candidate-tempo scoring; fallback cases; readability tradeoffs; maximum measures; and mutations made to the recorded composition.

- [ ] Explain module-level definitions: `MINIMUM_TEMPO`, `MAXIMUM_TEMPO`, `FALLBACK_TEMPO`, `MAXIMUM_MEASURES`, `COMMON_QUARTER_LENGTHS`.
- [ ] Function/method `calculatePerformanceEndUs`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `calculateMeasureCount`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `nearestRhythmicValue`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `tempoThatFitsDuration`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `detectNotationTempo`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `normalizeRecordedCompositionTiming`: explain its actual code, inputs, branches and effects.

### File 31: [composition/processing/performance_music_writer.py](composition/processing/performance_music_writer.py)

- [ ] File lesson complete: `composition/processing/performance_music_writer.py`.

Code walkthrough: Dataclass fields and timing constants; microseconds-to-ticks and Fraction conversion; notation rounding; grouping; gap cleanup; voice assignment; note/chord construction; measure splits and ties; rests; staff filtering. Keep notation simplification distinct from the MIDI playback data.

- [ ] Explain module-level definitions: `TICKS_PER_QUARTER`, `NOTATION_TICK_STEP`.
- [ ] Class `PerformanceNoteGroup`: explain its actual code, inputs, branches and effects. Fields: `startTick`, `endTick`, `midiNumbers`, `velocities`.
- [ ] Function/method `microsecondsToTicks`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `ticksToQuarterLength`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `roundNotationTick`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createPerformanceGroups`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `simplifySequentialTiming`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `closeSmallNotationGaps`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `assignGroupsToVoices`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createMusicalObject`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addRestToVoice`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addVoiceToStaff`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addEmptyStaffRests`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `addPerformanceMusic`: explain its actual code, inputs, branches and effects.

### File 32: [composition/processing/performance_midi_writer.py](composition/processing/performance_midi_writer.py)

- [ ] File lesson complete: `composition/processing/performance_midi_writer.py`.

Code walkthrough: Dataclass fields; all timing conversions; variable-length MIDI numbers; denominator validation; channel allocation and overlap; manual tie merging; event ordering; bytearray/struct encoding; MIDI header/track/meta events; both writers and returned duration. Use a small concrete note sequence and inspect its bytes.

- [ ] Explain module-level definitions: `TICKS_PER_QUARTER`, `PIANO_CHANNELS`.
- [ ] Class `PerformanceMidiExport`: explain its actual code, inputs, branches and effects. Fields: `midiPath`, `durationSeconds`.
- [ ] Function/method `microsecondsToMidiTicks`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `compositionBeatsToMidiTicks`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `encodeVariableLength`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `denominatorPower`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `assignChannels`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createManualMidiNotes`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `saveManualMidi`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `savePerformanceMidi`: explain its actual code, inputs, branches and effects.

### File 33: [composition/processing/file_exporter.py](composition/processing/file_exporter.py)

- [ ] File lesson complete: `composition/processing/file_exporter.py`.

Code walkthrough: Write the MusicXML file; walk XML nodes; identify incompatible tuplet metadata; explain every XML helper and bitwise power-of-two check; write/validate/replace the normalized file; finally cleanup.

- [ ] Function/method `saveMusicXml`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `normalizeManualMusicXmlForMuseScore`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `localName`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `directChild`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `childInteger`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `isPowerOfTwo`: explain its actual code, inputs, branches and effects.

### File 34: [composition/repositories/composition_storage_repository.py](composition/repositories/composition_storage_repository.py)

- [ ] File lesson complete: `composition/repositories/composition_storage_repository.py`.

Code walkthrough: Explain every private/public Storage path and MIME type; validate source and destination paths; upload with attempt suffixes; copy versioned public files; metadata/download tokens; rollback partial uploads/copies; delete current and legacy published files.

- [ ] Function/method `copyPublishedCompositionFiles`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `deleteStoragePaths`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `uploadCompositionFiles`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `deletePublishedCompositionFiles`: explain its actual code, inputs, branches and effects.

### File 35: [composition/repositories/published_composition_repository.py](composition/repositories/published_composition_repository.py)

- [ ] File lesson complete: `composition/repositories/published_composition_repository.py`.

Code walkthrough: Calculate the next version; build the publication fields; serialize manual/recording data; write the post and version documents in a batch; preserve source timestamps and author fields.

- [ ] Function/method `getNextPublishedVersion`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `saveCompositionPost`: explain its actual code, inputs, branches and effects.

### File 36: [composition/routes.py](composition/routes.py)

- [ ] File lesson complete: `composition/routes.py`.

Code walkthrough: Trace synchronous publishing and unpublishing separately from queued generation: authentication; ownership and current-file checks; public profile; version selection; copying files; saving the post; rollback; response fields; every HTTP error branch.

- [ ] Explain module-level definitions: `logger`, `router`.
- [ ] Function/method `publish_composition`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `unpublish_composition`: explain its actual code, inputs, branches and effects.

### File 37: [composition/services/unpublish_service.py](composition/services/unpublish_service.py)

- [ ] File lesson complete: `composition/services/unpublish_service.py`.

Code walkthrough: Check post existence and ownership; delete public artifacts, version documents, likes, comments and saved references; remove the post; explain return values and how the route maps them to HTTP responses.

- [ ] Function/method `unpublishComposition`: explain its actual code, inputs, branches and effects.

## 8. Recognizing uploaded sheet music

### File 38: [omr/repositories/music_sheet_repository.py](omr/repositories/music_sheet_repository.py)

- [ ] File lesson complete: `omr/repositories/music_sheet_repository.py`.

Code walkthrough: Read the owned sheet; validate type, file count, page numbers and expected Storage paths; distinguish image pages from the single PDF; inspect every rejection branch.

- [ ] Function/method `validateMusicSheetSources`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `getMusicSheet`: explain its actual code, inputs, branches and effects.

### File 39: [omr/services/job_processor.py](omr/services/job_processor.py)

- [ ] File lesson complete: `omr/services/job_processor.py`.

Code walkthrough: Trace the active queued OMR pipeline: reload sheet, create folders, generation-matched downloads, prepare input, Audiveris, extract/normalize/validate, export three additional formats, upload, return fields/paths, and always remove scratch files.

- [ ] Function/method `process`: explain its actual code, inputs, branches and effects.

### File 40: [omr/processing/omr_source_service.py](omr/processing/omr_source_service.py)

- [ ] File lesson complete: `omr/processing/omr_source_service.py`.

Code walkthrough: Create input/output folders; order image pages; check supported extensions; download the expected Storage generations; reuse PDF input or combine images with Pillow; close images; remove the temporary job directory.

- [ ] Function/method `createOmrJobFolders`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `downloadMusicSheetFiles`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `prepareAudiverisInput`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createImagePdf`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `deleteOmrJobFolder`: explain its actual code, inputs, branches and effects.

### File 41: [omr/processing/audiveris_service.py](omr/processing/audiveris_service.py)

- [ ] File lesson complete: `omr/processing/audiveris_service.py`.

Code walkthrough: Every installed-program path; availability checks; Java/classpath and batch arguments; output-directory handling; the thirty-minute timeout; return code checks; recursive output discovery.

- [ ] Explain module-level definitions: `AUDIVERIS_FOLDER`, `AUDIVERIS_PATH`, `AUDIVERIS_JAVA_PATH`, `AUDIVERIS_APP_FOLDER`.
- [ ] Function/method `isAudiverisInstalled`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `convertToMusicXml`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `findMusicXml`: explain its actual code, inputs, branches and effects.

### File 42: [omr/processing/music_xml_extractor.py](omr/processing/music_xml_extractor.py)

- [ ] File lesson complete: `omr/processing/music_xml_extractor.py`.

Code walkthrough: Treat compressed MusicXML as a ZIP container; locate META-INF/container.xml; parse the declared score path; reject absolute/traversal paths; read nonempty score bytes; write the extracted file; explain all exception mappings.

- [ ] Explain module-level definitions: `MUSIC_XML_CONTAINER_PATH`.
- [ ] Function/method `extractMusicXml`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `findRootFilePath`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `validateRootFilePath`: explain its actual code, inputs, branches and effects.

### File 43: [omr/processing/music_xml_piano_normalizer.py](omr/processing/music_xml_piano_normalizer.py)

- [ ] File lesson complete: `omr/processing/music_xml_piano_normalizer.py`.

Code walkthrough: Every piano/MIDI constant; XML namespace handling; part names and abbreviations; score and MIDI instruments; referenced instrument IDs; all creation/search/removal helpers; output validation and atomic replacement. Walk a before/after XML fragment through every applicable function.

- [ ] Explain module-level definitions: `PIANO_PART_NAME`, `PIANO_PART_ABBREVIATION`, `PIANO_INSTRUMENT_NAME`, `PIANO_INSTRUMENT_SOUND`, `PIANO_MIDI_BANK`, `PIANO_MIDI_CHANNEL`, `PIANO_MIDI_PROGRAM`.
- [ ] Function/method `normalizeMusicXmlForPiano`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `normalizePartLabels`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `normalizePartInstruments`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `normalizeScoreInstrument`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `normalizeMidiInstrument`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `collectReferencedInstrumentIds`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createScoreInstrument`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `findChildById`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `directChild`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `directChildren`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `removeDirectChildren`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createChild`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `createChildAfter`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `qualifiedName`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `namespaceFor`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `localName`: explain its actual code, inputs, branches and effects.

### File 44: [omr/processing/music_xml_validator.py](omr/processing/music_xml_validator.py)

- [ ] File lesson complete: `omr/processing/music_xml_validator.py`.

Code walkthrough: Read the score with music21, reject missing/unreadable/empty scores, and derive the returned part and note counts.

- [ ] Function/method `validateMusicXml`: explain its actual code, inputs, branches and effects.

### File 45: [omr/repositories/omr_storage_repository.py](omr/repositories/omr_storage_repository.py)

- [ ] File lesson complete: `omr/repositories/omr_storage_repository.py`.

Code walkthrough: Check every generated file; build each recognized artifact path and MIME type; distinguish preview audio; apply the attempt suffix; upload each artifact; rollback partially uploaded files; return the field mapping.

- [ ] Function/method `validateGeneratedFile`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `uploadOmrFiles`: explain its actual code, inputs, branches and effects.

### File 46: [omr/models/music_sheet_models.py](omr/models/music_sheet_models.py)

- [ ] File lesson complete: `omr/models/music_sheet_models.py`.

Code walkthrough: Explain the ownerId model field and BaseModel. Locate its references and distinguish this standalone schema from the current route, whose owner comes from verified authentication.

- [ ] Class `OmrConversionRequest`: explain its actual code, inputs, branches and effects. Fields: `ownerId`.

### File 47: [omr/repositories/omr_status_repository.py](omr/repositories/omr_status_repository.py)

- [ ] File lesson complete: `omr/repositories/omr_status_repository.py`.

Code walkthrough: Explain all direct Firestore status/timestamp/output updates and failure message handling. Compare this alternate path with the active queued Firebase bridge rather than skipping it.

- [ ] Function/method `setOmrProcessing`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `setOmrCompleted`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `setOmrFailed`: explain its actual code, inputs, branches and effects.

### File 48: [omr/services/omr_conversion_service.py](omr/services/omr_conversion_service.py)

- [ ] File lesson complete: `omr/services/omr_conversion_service.py`.

Code walkthrough: Walk through the complete alternate direct-conversion workflow and its try/except/finally blocks. Show that the current job dispatcher calls job_processor.process instead; compare where status is committed.

- [ ] Function/method `convertMusicSheet`: explain its actual code, inputs, branches and effects.

## 9. Transcribing piano audio

### File 49: [transkun_inference_requirements.txt](transkun_inference_requirements.txt)

- [ ] File lesson complete: `transkun_inference_requirements.txt`.

Code walkthrough: Explain every package and the setuptools constraint; the inference-only dependency set; why Transkun is installed separately with --no-deps; and why this environment is separate from the API interpreter.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 50: [audio/services/transcription_service.py](audio/services/transcription_service.py)

- [ ] File lesson complete: `audio/services/transcription_service.py`.

Code walkthrough: Explain every constant, exception, helper, Firestore transaction and subprocess path. Cover source ownership/size/duration, processing leases, attempt IDs, previous results, MP3-to-WAV conversion and worker validation. Walk the full alternate transcribe_audio function, including partial-upload cleanup and restoring/failing state, even though the active queue reuses only its helpers.

- [ ] Explain module-level definitions: `MAX_SOURCE_BYTES`, `MAX_DURATION_MS`, `PROCESSING_LEASE`, `WORKER_TIMEOUT_SECONDS`, `ENGINE`.
- [ ] Class `TranscriptionConflict`: explain its actual code, inputs, branches and effects.
- [ ] Class `TranscriptionUnavailable`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_worker_python`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_sheet_reference`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_validate_source`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_started_at`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_claim`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_finish`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_fail`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_decode_mp3`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_run_worker`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `transcribe_audio`: explain its actual code, inputs, branches and effects.

### File 51: [audio/services/job_processor.py](audio/services/job_processor.py)

- [ ] File lesson complete: `audio/services/job_processor.py`.

Code walkthrough: Trace the active queued audio pipeline: validate saved source, download its exact generation, enforce size/duration, decode WAV, invoke the isolated worker, export MusicXML/PDF, upload three outputs, reuse source MP3 for preview, and return fields without committing final state.

- [ ] Function/method `process`: explain its actual code, inputs, branches and effects.

### File 52: [audio/workers/transkun_worker.py](audio/workers/transkun_worker.py)

- [ ] File lesson complete: `audio/workers/transkun_worker.py`.

Code walkthrough: Explain its script-local import, argv and Python 3.11 checks, transkun.transcribe subprocess and CPU mode, raw MIDI parsing, non-drum notes, empty-note errors, timing correction, final MIDI write and JSON stdout contract.

- [ ] Function/method `main`: explain its actual code, inputs, branches and effects.

### File 53: [audio/workers/transkun_postprocess.py](audio/workers/transkun_postprocess.py)

- [ ] File lesson complete: `audio/workers/transkun_postprocess.py`.

Code walkthrough: Explain NumPy/bisect and every numerical threshold; infer a rhythmic grid; preserve short articulation; inspect chord and melody rules; constrain repeated pitches; compensate eligible initial delay; shift control and bend events; align near-simultaneous chord onsets; count adjustments.

- [ ] Explain module-level definitions: `_ONSET_SNAP_WINDOW_SECONDS`.
- [ ] Function/method `_align_near_simultaneous_onsets`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `_infer_grid`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `correct_note_timing`: explain its actual code, inputs, branches and effects.

## 10. Exposing the local backend through the tunnel

### File 54: [../Start Quick Tunnel.cmd](../Start%20Quick%20Tunnel.cmd)

- [ ] File lesson complete: `../Start Quick Tunnel.cmd`.

Code walkthrough: Every batch command and path, then follow the handoff to start-tunnel.ps1. Compare this process with starting the API and worker.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 55: [start-tunnel.ps1](start-tunnel.ps1)

- [ ] File lesson complete: `start-tunnel.ps1`.

Code walkthrough: Program and credential defaults; required interpreter; quoted argument array; CheckOnly forwarding; calling quick_tunnel.py; exit status and error handling.

- [ ] Explain every line, argument, option, assignment and exit path in this file.

### File 56: [quick_tunnel.py](quick_tunnel.py)

- [ ] File lesson complete: `quick_tunnel.py`.

Code walkthrough: Every constant and CLI argument; local/public health requests; readiness checks; Firebase project check; tunnel lock; ProcessTree; nested output-reader thread; URL regex and queue; deadlines; publish appConfig/backend only after health succeeds; save the local URL; keep-alive and finally cleanup.

- [ ] Explain module-level definitions: `ROOT`, `PROJECT`, `LOCAL_URL`, `CONFIG_DOCUMENT`, `TUNNEL_URL`.
- [ ] Function/method `health`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `run`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `run.read_output`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `main`: explain its actual code, inputs, branches and effects.

## 11. Understanding the automated checks

### File 57: [tests/test_activity_logging.py](tests/test_activity_logging.py)

- [ ] File lesson complete: `tests/test_activity_logging.py`.

Code walkthrough: Explain the test imports, RecordCollector, every fixture, every mock and patch, temporary directories and subprocess, each HTTP assertion, payload preservation, redaction checks, stream/size cases, quiet health/status checks, and worker success/failure ordering. Explain what these nine tests do not prove about real Firebase and converters.

- [ ] Explain module-level definitions: `ROOT`.
- [ ] Class `RecordCollector`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RecordCollector.__init__`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RecordCollector.emit`: explain its actual code, inputs, branches and effects.
- [ ] Class `RequestActivityTests`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.setUp`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.setUp.recognize`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.setUp.health`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.setUp.job`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.setUp.job.chunks`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.setUp.explode`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.tearDown`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.test_submission_explains_acceptance_and_preserves_payload`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.test_repeated_poll_is_routine_but_state_changes_are_visible`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.test_health_failures_are_visible`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.test_unexpected_metadata_large_and_streamed_responses_are_preserved`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `RequestActivityTests.test_unhandled_exception_is_reported_without_changing_500`: explain its actual code, inputs, branches and effects.
- [ ] Class `LogDestinationTests`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `LogDestinationTests.test_console_is_concise_and_file_retains_routine_requests_and_tracebacks`: explain its actual code, inputs, branches and effects.
- [ ] Class `WorkerActivityTests`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `WorkerActivityTests._store`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `WorkerActivityTests.test_completion_is_reported_after_results_are_committed`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `WorkerActivityTests.test_failed_commit_does_not_report_success`: explain its actual code, inputs, branches and effects.
- [ ] Function/method `WorkerActivityTests.test_failed_job_reports_its_reason`: explain its actual code, inputs, branches and effects.

## 12. Python package files: none omitted

For each file below, open its entire contents, explain its comment or empty
body, package/import behavior and the containing folder. These files have no
conversion functions; that is still an explicit lesson.

- [ ] File 58: [audio/__init__.py](audio/__init__.py) - explain every existing line and its package role.
- [ ] File 59: [audio/services/__init__.py](audio/services/__init__.py) - explain every existing line and its package role.
- [ ] File 60: [audio/workers/__init__.py](audio/workers/__init__.py) - explain every existing line and its package role.
- [ ] File 61: [composition/__init__.py](composition/__init__.py) - explain every existing line and its package role.
- [ ] File 62: [composition/models/__init__.py](composition/models/__init__.py) - explain every existing line and its package role.
- [ ] File 63: [composition/processing/__init__.py](composition/processing/__init__.py) - explain every existing line and its package role.
- [ ] File 64: [composition/repositories/__init__.py](composition/repositories/__init__.py) - explain every existing line and its package role.
- [ ] File 65: [composition/services/__init__.py](composition/services/__init__.py) - explain every existing line and its package role.
- [ ] File 66: [core/__init__.py](core/__init__.py) - explain every existing line and its package role.
- [ ] File 67: [core/integrations/__init__.py](core/integrations/__init__.py) - explain every existing line and its package role.
- [ ] File 68: [jobs/__init__.py](jobs/__init__.py) - explain every existing line and its package role.
- [ ] File 69: [jobs/repositories/__init__.py](jobs/repositories/__init__.py) - explain every existing line and its package role.
- [ ] File 70: [jobs/services/__init__.py](jobs/services/__init__.py) - explain every existing line and its package role.
- [ ] File 71: [omr/__init__.py](omr/__init__.py) - explain every existing line and its package role.
- [ ] File 72: [omr/models/__init__.py](omr/models/__init__.py) - explain every existing line and its package role.
- [ ] File 73: [omr/processing/__init__.py](omr/processing/__init__.py) - explain every existing line and its package role.
- [ ] File 74: [omr/repositories/__init__.py](omr/repositories/__init__.py) - explain every existing line and its package role.
- [ ] File 75: [omr/services/__init__.py](omr/services/__init__.py) - explain every existing line and its package role.

## 13. Generated files and installed environments

These are accounted for separately because their contents change as programs
run or packages are installed. We will explain the files and their producers,
readers and formats, rather than treat generated binary data or third-party
library implementations as project-written Python lessons. This is the stated
boundary of the source checklist, not an unlisted exclusion.

- [ ] `data/jobs.sqlite3`: inspect the schema from `Store.__init__`; explain each
  table, persisted job state, delivery entry and the relationship to Firestore.
- [ ] SQLite `-wal` / `-shm` companions if present: relate them to WAL mode and
  why one database can involve multiple runtime files.
- [ ] `data/jobs.worker.lock`: explain how WorkerLock uses the file to prevent
  a second supervisor from owning the same queue.
- [ ] `data/<job-id>-<attempt>.log`: explain stdout/stderr redirection, error
  details, attempt correlation, success cleanup and seven-day failure retention.
- [ ] `data/logs/api.log` and rotated backups: explain every field in sample
  request/response lines, quiet console filtering and retained diagnostic data.
- [ ] `data/logs/worker.log` and rotated backups: follow startup, processing,
  final commits and retry messages; relate them to attempt logs.
- [ ] `data/work/<job-id>-<attempt>/` and every current file in a chosen attempt:
  explain its producing conversion step, format, consumer and cleanup condition.
  Inventory the actual contents at lesson time so newly generated files are covered.
- [ ] `data/public-backend-url.txt`: explain who writes the file and how it
  relates to the address published in Firebase.
- [ ] `data/quick-tunnel.log`: explain captured cloudflared output and URL discovery.
- [ ] `data/quick-tunnel.lock`: explain why tunnel ownership has a separate lock.
- [ ] `__pycache__/` wherever present: explain `.pyc` bytecode, version suffixes,
  automatic generation and its distinction from the editable `.py` source.
- [ ] `venv/pyvenv.cfg`: explain every key in the actual file and the API
  interpreter it identifies. Review the installed environment rather than
  assuming all machines have the same version.
- [ ] `transkun_venv/pyvenv.cfg`: explain every key, the separate Python 3.11
  requirement checked by the worker, and why one interpreter is not reused.
- [ ] Both environments' `Scripts/`, `Lib/site-packages/`, `Include/`, `share/`
  and environment metadata: identify executables, activation scripts, installed
  libraries, distribution metadata and bundled assets. Explain installation and
  how an import resolves to a package file. Dependencies are not our authored source.
- [ ] Environment `.gitignore` files when present: explain their complete
  contents and why installed files are treated differently from project sources.
- [ ] At the end, inventory `data/` and environment top-level contents again;
  add any new runtime file type before declaring this section complete.

## 14. Connections outside the backend directory

These supporting files explain the app/backend boundary; they do not replace
the complete backend source inventory above.

- [ ] [firebase.json](../firebase.json): the rules-file configuration and generated
  platform configuration, identifying which entries concern server behavior.
- [ ] [.firebaserc](../.firebaserc): the selected Firebase project and its relationship
  to the project/bucket checks in server code.
- [ ] [firestore.rules](../firestore.rules): inspect the actual processingJobs,
  activeJobId and appConfig/backend rules and their relationship to client access.
- [ ] [storage.rules](../storage.rules): inspect source/output ownership, file
  validation, active-job edit locks and published-file read rules. Explain the
  distinction between authenticated client rules and privileged Admin SDK access.
- [ ] [BackendConfig](../lib/constants/backend_config.dart): explain backend
  address discovery and requests that retry after the tunnel address changes.
- [ ] [ProcessingJobService](../lib/services/processing_job_service.dart): trace
  Bearer/protocol/idempotency headers, saved retry keys, the accepted response,
  Firestore subscription, five-second status polling and cancellation.
- [ ] Follow all three thin Flutter callers into the corresponding Python route:
  [composition generation](../lib/screens/composition/services/composition_generation_service.dart),
  [sheet recognition](../lib/screens/music_sheet/services/music_sheet_omr_service.dart), and
  [audio transcription](../lib/screens/music_sheet/services/music_sheet_transcription_service.dart).
- [ ] Explain the external service-account JSON's role, its path in the launchers,
  and how credentials are consumed, using field names and placeholders rather
  than displaying private key values.
- [ ] Explain the installed MuseScore, Audiveris/Java, FFmpeg, Cloudflare and
  Transkun programs, which source invokes each one, and what each invocation returns.
- [ ] [Project .gitignore](../.gitignore): explain how backend environments,
  runtime data and generated artifacts relate to tracked project source.

## 15. End-to-end code traces and completion check

- [ ] Trace one composition job through the exact files, objects, HTTP response,
  local SQL state changes, generated artifacts and final Firestore updates.
- [ ] Repeat for one image/PDF recognition job and one MP3 transcription job;
  explain which processing steps are shared and which change.
- [ ] Trace publishing, versioning and unpublishing, including partial-copy rollback.
- [ ] Trace a repeated idempotency key after a lost response; show why a second
  accepted job is not created for the same request.
- [ ] Trace cancellation, ownership rejection, worker-offline rejection and a
  source changed between acceptance and processing.
- [ ] Trace a child-process failure, a timeout, an interrupted worker restart,
  retry limits, a Firebase save retry and a notification delivery retry.
- [ ] Read an API log and worker log together and identify acceptance, actual
  processing, result commitment and notification delivery as separate events.
- [ ] Review alternate direct-conversion functions against the active queue;
  identify the differing ownership/status/recovery responsibilities in their code.
- [ ] Re-inventory project files and class/function definitions after code changes;
  add new lessons before marking the entire backend explanation complete.
- [ ] Confirm every file and code checkpoint has been taught, questions answered,
  and remaining unfinished topics recorded. A reviewed filename alone is not completion.

## Progress notes

Current teaching position: File 03, `requirements.txt`.

Session 1 covers the checklist's completion rules and the launcher's five lines:
command echoing, local environment scope, PowerShell and its flags, absolute
script-path expansion, exit-code handling, and restoring the environment.
The user confirmed that the launcher explanation, including `%~dp0`, is clear
and requested the next lesson. File 02 is complete.

Session 2 covers the six lines of `requirements.txt`, package installation,
the `standard` extra, installation names versus import names, direct versus
transitive dependencies, and the absence of version pins. File 03 remains
unchecked pending discussion. Next in the planned file order: `start-all.ps1`.

After each session, record the file, the last block/function explained, concrete
examples used, questions still open and the next checkpoint. Check individual
symbol boxes as we finish their code, then the file box only after the whole
source has been covered.
