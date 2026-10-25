"""In-memory, single-pitch piano recognition for streamed PCM16 audio."""

import math
from collections import deque

import numpy as np
from scipy.fft import rfft
from scipy.signal.windows import hann


class SingleNoteDetector:
    """Convert arbitrary mono PCM chunks into calibrated piano note events."""

    FRAME_SIZE = 8192
    HOP_SIZE = 1024
    FFT_SIZE = 32768
    FIRST_NOTE = 48  # C3
    LAST_NOTE = 84  # C6

    def __init__(self, sample_rate: int, sensitivity: int = 100) -> None:
        """Initialize recognition thresholds for Android's selected sensitivity."""
        self.sample_rate = sample_rate
        self._threshold_scale = 100.0 / sensitivity
        self._noise_multiplier = 2.0 + (100 - sensitivity) * 0.0125
        self._buffer = bytearray()
        self._frame_start = 0
        self._window = hann(self.FRAME_SIZE, sym=False).astype(np.float32)
        self._window_scale = 2.0 / float(self._window.sum())
        self._noise_spectrum = np.zeros(self.FFT_SIZE // 2 + 1)
        self._noise_rms = 0.0
        self._calibration_frames = 0
        self._calibrated = False
        self._candidate_note = None
        self._candidate_frames = 0
        self._recent_spectra = deque(maxlen=5)
        self._recent_rms = deque(maxlen=5)
        self._active_note = None
        self._suppressed_note = None
        self._active_peak_score = 0.0
        self._active_confidence = 0.0
        self._quiet_frames = 0
        self._last_attack_sample = 0

    def feed(self, audio: bytes) -> list[dict]:
        """Append PCM bytes and return messages from each complete analysis frame."""
        self._buffer.extend(audio)
        messages = []
        frame_bytes = self.FRAME_SIZE * 2
        hop_bytes = self.HOP_SIZE * 2

        while len(self._buffer) >= frame_bytes:
            samples = np.frombuffer(
                self._buffer[:frame_bytes], dtype="<i2"
            ).astype(np.float32) / 32768.0
            del self._buffer[:hop_bytes]
            capture_position = self._frame_start + self.FRAME_SIZE
            self._frame_start += self.HOP_SIZE
            messages.extend(self._analyze_frame(samples, capture_position))

        return messages

    def _analyze_frame(self, samples: np.ndarray, position: int) -> list[dict]:
        """Calibrate ambient sound or update one active piano pitch."""
        rms = float(np.sqrt(np.mean(samples * samples)))
        spectrum = np.abs(rfft(samples * self._window, n=self.FFT_SIZE))
        spectrum *= self._window_scale

        if not self._calibrated:
            self._noise_spectrum += spectrum
            self._noise_rms += rms
            self._calibration_frames += 1
            if position < int(self.sample_rate * 1.2):
                return []
            self._noise_spectrum /= self._calibration_frames
            self._noise_rms /= self._calibration_frames
            self._calibrated = True
            return [{
                "type": "calibration",
                "state": "ready",
                "noiseRms": round(self._noise_rms, 5),
            }]

        residual = np.maximum(
            spectrum - self._noise_spectrum * self._noise_multiplier, 0.0
        )
        reference = self._recent_spectra[0] if len(self._recent_spectra) == 5 else 0.0
        reference_rms = self._recent_rms[0] if len(self._recent_rms) == 5 else rms
        onset = np.maximum(residual - reference * 1.15, 0.0)
        self._recent_spectra.append(residual)
        self._recent_rms.append(rms)
        messages = []

        if self._active_note is None:
            note, score, confidence = self._best_note(residual, rms)
            if note == self._suppressed_note:
                onset_note, _, _ = self._best_note(onset, rms)
                if onset_note != note or rms < reference_rms * 1.25:
                    note = None
            self._confirm_candidate(note)
            if note is not None and self._candidate_frames >= 2:
                messages.extend(self._attack(note, score, confidence, rms, position))
                self._candidate_note = None
                self._candidate_frames = 0
        else:
            new_note, new_score, confidence = self._best_note(onset, rms)
            self._confirm_candidate(new_note)
            if (
                new_note is not None
                and self._candidate_frames >= 2
                and position - self._last_attack_sample > self.sample_rate * 0.17
                and (
                    new_note != self._active_note
                    or rms >= reference_rms * 1.25
                )
            ):
                if new_note != self._active_note:
                    messages.extend(self._release(position))
                messages.extend(
                    self._attack(new_note, new_score, confidence, rms, position)
                )
                self._candidate_note = None
                self._candidate_frames = 0

            if self._active_note is not None:
                active_score, _ = self._score_note(residual, self._active_note)
                self._active_peak_score = max(
                    active_score, self._active_peak_score * 0.995
                )
                quiet = (
                    rms < max(0.003, self._noise_rms * 1.35)
                    or active_score < max(
                        0.0012 * self._threshold_scale,
                        self._active_peak_score * 0.16,
                    )
                )
                self._quiet_frames = self._quiet_frames + 1 if quiet else 0
                if self._quiet_frames >= 5:
                    messages.extend(self._release(position))
                    self._candidate_note = None
                    self._candidate_frames = 0

        return messages

    def _confirm_candidate(self, note: int | None) -> None:
        """Require the same proposed pitch in adjacent overlapping frames."""
        if note is None:
            self._candidate_note = None
            self._candidate_frames = 0
        elif note == self._candidate_note:
            self._candidate_frames += 1
        else:
            self._candidate_note = note
            self._candidate_frames = 1

    def _best_note(self, spectrum: np.ndarray, rms: float) -> tuple:
        """Choose the strongest C3-C6 pitch with fundamental and harmonic support."""
        minimum_rms = max(0.0018, self._noise_rms * 1.1) * self._threshold_scale
        if rms < minimum_rms:
            return None, 0.0, 0.0

        strongest_bin = float(np.max(spectrum))
        if strongest_bin < 0.0008 * self._threshold_scale:
            return None, 0.0, 0.0

        candidates = []
        for note in range(self.FIRST_NOTE, self.LAST_NOTE + 1):
            score, partials = self._score_note(spectrum, note)
            fundamental = partials[0]
            if (
                fundamental >= max(
                    0.0005 * self._threshold_scale, strongest_bin * 0.11
                )
                and score >= max(
                    0.0014 * self._threshold_scale, strongest_bin * 0.58
                )
            ):
                candidates.append((score, note, partials))

        if not candidates:
            return None, 0.0, 0.0
        candidates.sort(reverse=True)
        score, note, partials = candidates[0]
        runner_up = candidates[1][0] if len(candidates) > 1 else 0.0
        separation = max(0.0, (score - runner_up) / score)
        harmonic_support = min(1.0, sum(partials[1:]) / (partials[0] + 1e-9))
        confidence = min(0.99, 0.52 + 0.32 * separation + 0.14 * harmonic_support)
        return note, score, confidence

    def _score_note(self, spectrum: np.ndarray, note: int) -> tuple:
        """Measure a candidate's fundamental and first three piano harmonics."""
        frequency = 440.0 * 2.0 ** ((note - 69) / 12.0)
        partials = [
            self._band_peak(spectrum, frequency * harmonic)
            for harmonic in range(1, 5)
        ]
        score = (
            partials[0]
            + 0.65 * partials[1]
            + 0.4 * partials[2]
            + 0.25 * partials[3]
        )
        return score, partials

    def _band_peak(self, spectrum: np.ndarray, frequency: float) -> float:
        """Read the strongest FFT bin near one expected harmonic frequency."""
        center = frequency * self.FFT_SIZE / self.sample_rate
        radius = max(2, int(frequency * 0.012 * self.FFT_SIZE / self.sample_rate))
        start = max(1, int(center) - radius)
        stop = min(len(spectrum), int(center) + radius + 2)
        if start >= stop:
            return 0.0
        return float(np.max(spectrum[start:stop]))

    def _attack(
        self, note: int, score: float, confidence: float, rms: float, position: int
    ) -> list[dict]:
        """Emit a confirmed attack and the complete active-note snapshot."""
        self._active_note = note
        self._active_peak_score = score
        self._active_confidence = confidence
        self._last_attack_sample = position
        self._quiet_frames = 0
        ratio = rms / max(0.003, self._noise_rms)
        velocity = max(1, min(127, int(38 + 30 * math.log10(max(1.0, ratio)))))
        return [
            {
                "type": "note_on",
                "noteNumber": note,
                "confidence": round(confidence, 3),
                "estimatedVelocity": velocity,
                "capturePosition": position,
            },
            {"type": "active_notes", "notes": [note], "capturePosition": position},
        ]

    def _release(self, position: int) -> list[dict]:
        """Emit an acoustic release and an empty active-note snapshot."""
        note = self._active_note
        if note is None:
            return []
        self._active_note = None
        self._suppressed_note = note
        self._active_peak_score = 0.0
        confidence = self._active_confidence
        self._active_confidence = 0.0
        return [
            {
                "type": "note_off",
                "noteNumber": note,
                "confidence": round(confidence, 3),
                "estimatedVelocity": 0,
                "capturePosition": position,
            },
            {"type": "active_notes", "notes": [], "capturePosition": position},
        ]
