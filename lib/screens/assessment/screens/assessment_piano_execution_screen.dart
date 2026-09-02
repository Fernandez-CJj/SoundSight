import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/constant.dart';
import '../../midi/services/midi_input_service.dart';
import '../models/assessment_piano_task.dart';
import '../services/assessment_piano_performance_tracker.dart';

/// Called after all piano-execution task results are finalized.
typedef PianoExecutionSubmitCallback = Future<void> Function(
  List<AssessmentPianoTaskResult> results,
);

/// Runs the MIDI-based piano-execution portion of the assessment.
class AssessmentPianoExecutionScreen extends StatefulWidget {
  const AssessmentPianoExecutionScreen({
    super.key,
    required this.onSubmit,
  });

  /// Saves all completed task results and advances the assessment.
  final PianoExecutionSubmitCallback onSubmit;

  @override
  State<AssessmentPianoExecutionScreen> createState() {
    return _AssessmentPianoExecutionScreenState();
  }
}

class _AssessmentPianoExecutionScreenState
    extends State<AssessmentPianoExecutionScreen> {
  /// Reuses the same MIDI connection service as AR and sight reading.
  final MidiInputService _midiInputService = MidiInputService();

  /// Evaluates note attacks for the task currently displayed.
  final AssessmentPianoPerformanceTracker _performanceTracker =
      AssessmentPianoPerformanceTracker();

  /// Measures performance time without reading the phone's date or clock.
  final Stopwatch _performanceStopwatch = Stopwatch();

  /// Stores every finalized task result until section submission.
  final List<AssessmentPianoTaskResult> _taskResults = [];

  StreamSubscription<int>? _noteOnSubscription;
  StreamSubscription<Set<int>>? _activeNotesSubscription;
  StreamSubscription<bool>? _midiConnectionSubscription;
  Timer? _countInTimer;
  Timer? _performanceTimer;
  Timer? _metronomeTimer;

  Set<int> _activeMidiNotes = {};
  int _currentTaskIndex = 0;
  int _remainingCountInBeats = 0;

  /// Starts at one on GO and advances with each performance click.
  int _performanceBeatNumber = 0;

  String _midiStatus = 'Not connected';
  String? _errorMessage;

  bool _isConnecting = false;
  bool _isCountingIn = false;
  bool _isPerforming = false;
  bool _isTaskComplete = false;
  bool _hasStartedSection = false;
  bool _isSubmitting = false;

  AssessmentPianoTask get _currentTask {
    return assessmentPianoTasks[_currentTaskIndex];
  }

  bool get _isLastTask {
    return _currentTaskIndex == assessmentPianoTasks.length - 1;
  }

  bool get _midiIsConnected {
    return _midiStatus.startsWith('Connected:');
  }

  @override
  void initState() {
    super.initState();

    _performanceTracker.loadTask(_currentTask);

    _noteOnSubscription = _midiInputService.noteOnStream.listen(
      _handleNoteOn,
    );

    _activeNotesSubscription = _midiInputService.activeNotesStream.listen(
      _handleActiveNotes,
    );

    _midiConnectionSubscription = _midiInputService.connectionStream.listen(
      _handleMidiConnectionChanged,
    );

    // Search automatically so the user only needs to connect the keyboard.
    unawaited(_connectToMidi());
  }

  /// Finds the first MIDI device and connects using the shared app service.
  Future<void> _connectToMidi() async {
    if (_isConnecting || _isCountingIn || _isPerforming) {
      return;
    }

    setState(() {
      _isConnecting = true;
      _midiStatus = 'Searching...';
      _errorMessage = null;
    });

    try {
      final devices = await _midiInputService.getDevices();

      if (!mounted) {
        return;
      }

      if (devices.isEmpty) {
        setState(() {
          _isConnecting = false;
          _midiStatus = 'No MIDI device detected';
        });

        return;
      }

      final device = devices.first;

      setState(() {
        _midiStatus = 'Connecting...';
      });

      await _midiInputService.connectToDevice(device);

      if (!mounted) {
        return;
      }

      setState(() {
        _isConnecting = false;
        _midiStatus = 'Connected: ${device.name}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConnecting = false;
        _midiStatus = 'Connection failed';
        _errorMessage = 'Unable to connect to the MIDI keyboard.';
      });
    }
  }

  /// Sends MIDI attacks to the tracker only during active performance.
  void _handleNoteOn(int midiNote) {
    if (!mounted || !_isPerforming) {
      return;
    }

    final changed = _performanceTracker.recordNoteOn(
      midiNote,
      _performanceStopwatch.elapsedMilliseconds,
    );

    if (changed) {
      setState(() {});
    }
  }

  /// Keeps a visible snapshot of keys currently held on the MIDI keyboard.
  void _handleActiveNotes(Set<int> notes) {
    if (!mounted) {
      return;
    }

    setState(() {
      _activeMidiNotes = Set<int>.from(notes);
    });
  }

  /// Stops an unfinished task safely when the physical MIDI cable is removed.
  void _handleMidiConnectionChanged(bool connected) {
    if (!mounted) {
      return;
    }

    if (connected) {
      final deviceName = _midiInputService.connectedDevice?.name;

      setState(() {
        _midiStatus = deviceName == null
            ? 'Connected'
            : 'Connected: $deviceName';
        _errorMessage = null;
      });

      return;
    }

    final taskWasInterrupted = _isCountingIn || _isPerforming;

    _countInTimer?.cancel();
    _performanceTimer?.cancel();
    _metronomeTimer?.cancel();
    _performanceStopwatch
      ..stop()
      ..reset();

    if (taskWasInterrupted) {
      // A hardware interruption does not consume or score the current task.
      _performanceTracker.resetAttempt();
    }

    setState(() {
      _activeMidiNotes = {};
      _remainingCountInBeats = 0;
      _performanceBeatNumber = 0;
      _isCountingIn = false;
      _isPerforming = false;
      _midiStatus = 'MIDI keyboard disconnected';

      if (taskWasInterrupted) {
        _isTaskComplete = false;
        _errorMessage =
            'The MIDI connection was removed. Reconnect and restart this task.';
      }
    });
  }

  /// Begins the count-in for the currently displayed task.
  void _startCurrentTask() {
    if (!_midiIsConnected ||
        _isConnecting ||
        _isCountingIn ||
        _isPerforming ||
        _isTaskComplete) {
      return;
    }

    _performanceTracker.loadTask(_currentTask);
    _performanceStopwatch
      ..stop()
      ..reset();

    setState(() {
      _hasStartedSection = true;
      _isCountingIn = true;
      _remainingCountInBeats = _currentTask.countInBeats;
      _performanceBeatNumber = 0;
      _errorMessage = null;
    });

    unawaited(SystemSound.play(SystemSoundType.click));

    final beatDuration = _beatDurationFor(_currentTask);

    _countInTimer?.cancel();
    _countInTimer = Timer.periodic(beatDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingCountInBeats > 1) {
        setState(() {
          _remainingCountInBeats--;
        });

        unawaited(SystemSound.play(SystemSoundType.click));
        return;
      }

      timer.cancel();
      _beginPerformance();
    });
  }

  /// Starts Stopwatch-based task timing after the count-in.
  void _beginPerformance() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isCountingIn = false;
      _isPerforming = true;
      _remainingCountInBeats = 0;
      _performanceBeatNumber = 1;
    });

    _performanceStopwatch
      ..reset()
      ..start();

    unawaited(SystemSound.play(SystemSoundType.click));

    final beatDuration = _beatDurationFor(_currentTask);

    _metronomeTimer?.cancel();
    _metronomeTimer = Timer.periodic(beatDuration, (timer) {
      if (!_isPerforming) {
        timer.cancel();
        return;
      }

      if (mounted) {
        setState(() {
          _performanceBeatNumber++;
        });
      }

      unawaited(SystemSound.play(SystemSoundType.click));
    });

    _performanceTimer?.cancel();
    _performanceTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        if (!mounted || !_isPerforming) {
          timer.cancel();
          return;
        }

        final changed = _performanceTracker.updateElapsedTime(
          _performanceStopwatch.elapsedMilliseconds,
        );

        if (_performanceTracker.isFinished) {
          _finishCurrentTask();
          return;
        }

        if (changed) {
          setState(() {});
        }
      },
    );
  }

  /// Finalizes the current task exactly once and records its result.
  void _finishCurrentTask() {
    if (!_isPerforming) {
      return;
    }

    _performanceStopwatch.stop();
    _performanceTimer?.cancel();
    _metronomeTimer?.cancel();
    _performanceTracker.finalizeRemainingGroups();

    final result = _performanceTracker.buildResult();

    _taskResults.removeWhere((item) => item.taskId == result.taskId);
    _taskResults.add(result);

    setState(() {
      _isPerforming = false;
      _isTaskComplete = true;
    });
  }

  /// Loads the next required task without permitting a replay.
  void _showNextTask() {
    if (!_isTaskComplete || _isLastTask || _isSubmitting) {
      return;
    }

    setState(() {
      _currentTaskIndex++;
      _isTaskComplete = false;
      _activeMidiNotes = {};
      _performanceBeatNumber = 0;
      _errorMessage = null;
    });

    _performanceTracker.loadTask(_currentTask);
  }

  /// Sends all nine immutable results to the assessment service callback.
  Future<void> _submitResults() async {
    if (!_isLastTask ||
        !_isTaskComplete ||
        _isSubmitting ||
        _taskResults.length != assessmentPianoTasks.length) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        List<AssessmentPianoTaskResult>.unmodifiable(_taskResults),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        // Show the real development error while the assessment is being
        // tested. This distinguishes rejected Firestore rules from invalid
        // local results, expiration, authentication, and navigation failures.
        _errorMessage = 'Unable to save the piano results.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Calculates one metronome beat from the task's tempo.
  Duration _beatDurationFor(AssessmentPianoTask task) {
    return Duration(
      microseconds: (Duration.microsecondsPerMinute / task.tempoBpm).round(),
    );
  }

  @override
  void dispose() {
    _countInTimer?.cancel();
    _performanceTimer?.cancel();
    _metronomeTimer?.cancel();
    _performanceStopwatch.stop();
    unawaited(_noteOnSubscription?.cancel());
    unawaited(_activeNotesSubscription?.cancel());
    unawaited(_midiConnectionSubscription?.cancel());
    unawaited(_midiInputService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canLeave = !_hasStartedSection &&
        !_isCountingIn &&
        !_isPerforming &&
        !_isSubmitting;

    return PopScope(
      canPop: canLeave,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Piano Execution'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgress(),
                const SizedBox(height: AppSpacing.md),
                _buildMidiStatus(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildTaskDetails(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: AppTextSizes.body,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _primaryAction(),
                    child: _buildPrimaryButtonChild(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays task number and overall section progress.
  Widget _buildProgress() {
    final taskNumber = _currentTaskIndex + 1;
    final taskCount = assessmentPianoTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Task $taskNumber of $taskCount',
          style: const TextStyle(
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(value: taskNumber / taskCount),
      ],
    );
  }

  /// Displays connection state and a retry action when disconnected.
  Widget _buildMidiStatus() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _midiStatus,
            style: const TextStyle(fontSize: AppTextSizes.body),
          ),
        ),
        if (!_midiIsConnected)
          TextButton(
            onPressed: _isConnecting ? null : _connectToMidi,
            child: const Text('Refresh'),
          ),
      ],
    );
  }

  /// Displays the current task without sheet notation.
  Widget _buildTaskDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _currentTask.title,
          style: const TextStyle(
            fontSize: AppTextSizes.screenTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _currentTask.instruction,
          style: const TextStyle(
            fontSize: AppTextSizes.body,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInstructionBlock(
          title: 'Keys to play',
          description: _currentTask.displayedSequence,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInstructionBlock(
          title: 'When to play',
          description: _currentTask.timingInstruction,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'C4 is Middle C. The number tells you the piano octave.',
          style: TextStyle(
            fontSize: AppTextSizes.label,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${_currentTask.tempoBpm} BPM • '
          '${_currentTask.countInBeats}-beat count-in',
          style: const TextStyle(fontSize: AppTextSizes.label),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isCountingIn)
          Center(
            child: Column(
              children: [
                const Text(
                  'Count-in',
                  style: TextStyle(
                    fontSize: AppTextSizes.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$_remainingCountInBeats',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Wait. Play ${_currentTask.firstGroupLabel} when GO appears.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppTextSizes.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          )
        else if (_isPerforming)
          _buildPerformingState()
        else if (_isTaskComplete)
          const Center(
            child: Text(
              'Task recorded',
              style: TextStyle(
                fontSize: AppTextSizes.sectionTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          const Text(
            'Press Start Task when you are ready. Wait through the complete '
            'count-in, then play the first shown key or chord with GO. Each '
            'scored task can only be performed once in this session.',
            style: TextStyle(
              fontSize: AppTextSizes.body,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  /// Keeps the required keys and timing instructions visually separated.
  Widget _buildInstructionBlock({
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTextSizes.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: const TextStyle(
            fontSize: AppTextSizes.body,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Shows neutral live input information without revealing correctness.
  Widget _buildPerformingState() {
    final sortedNotes = _activeMidiNotes.toList()..sort();
    final nextGroupIndex = _performanceTracker.nextEvaluationIndex;
    final expectedLabel = nextGroupIndex < _currentTask.noteGroups.length
        ? _currentTask.noteGroups[nextGroupIndex].displayLabel
        : 'Task complete';

    return Column(
      children: [
        Text(
          _performanceBeatNumber == 1
              ? 'GO'
              : 'Beat $_performanceBeatNumber',
          style: const TextStyle(
            fontSize: AppTextSizes.sectionTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Play now: $expectedLabel',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          sortedNotes.isEmpty
              ? 'Waiting for MIDI input'
              : '${sortedNotes.length} key(s) currently held',
          style: const TextStyle(fontSize: AppTextSizes.body),
        ),
      ],
    );
  }

  /// Chooses the only valid action for the current task state.
  VoidCallback? _primaryAction() {
    if (_isConnecting || _isCountingIn || _isPerforming || _isSubmitting) {
      return null;
    }

    // A completed task no longer needs a live cable. In particular, Task 9
    // can still save its recorded result after the keyboard is unplugged.
    if (_isTaskComplete) {
      return _isLastTask ? _submitResults : _showNextTask;
    }

    if (!_midiIsConnected) {
      return _connectToMidi;
    }

    return _startCurrentTask;
  }

  /// Builds the primary button label or saving indicator.
  Widget _buildPrimaryButtonChild() {
    if (_isSubmitting || _isConnecting) {
      return const SizedBox(
        width: AppIconSizes.md,
        height: AppIconSizes.md,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isCountingIn) {
      return const Text('Get Ready');
    }

    if (_isPerforming) {
      return const Text('Performing');
    }

    if (!_midiIsConnected) {
      return const Text('Connect MIDI');
    }

    if (!_isTaskComplete) {
      return const Text('Start Task');
    }

    if (_isLastTask) {
      return const Text('Submit Piano Results');
    }

    return const Text('Next Task');
  }
}
