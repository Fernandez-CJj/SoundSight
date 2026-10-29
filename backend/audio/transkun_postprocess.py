"""Conservative timing correction for piano MIDI produced by Transkun."""

from bisect import bisect_left, bisect_right

import numpy as np


def _infer_grid(notes):
    starts = np.array([note.start for note in notes])
    if len(starts) < 25:
        return None, 0.0

    for grid in (0.5, 0.375, 1 / 3, 0.25, 0.2, 0.1875, 1 / 6, 0.125):
        phase = np.angle(np.mean(np.exp(2j * np.pi * starts / grid))) * grid / (2 * np.pi)
        error = np.abs((starts - phase + grid / 2) % grid - grid / 2)
        if np.mean(error < 0.025) > 0.88:
            return grid, float(phase)
    return None, 0.0


def correct_note_timing(midi):
    notes = sorted(
        (note for instrument in midi.instruments if not instrument.is_drum
         for note in instrument.notes),
        key=lambda note: (note.start, note.pitch),
    )
    grid, phase = _infer_grid(notes)
    if grid is None:
        return 0

    starts = [note.start for note in notes]
    durations = np.array([note.end - note.start for note in notes])
    nearest_grid = np.maximum(grid, np.round(durations / grid) * grid)
    already_aligned = np.mean(np.abs(durations - nearest_grid) < 0.05) >= 0.65
    short_articulation = np.quantile(durations, 0.75) / grid < 0.65
    adjusted = 0

    if not already_aligned and not short_articulation:
        starts_by_pitch = {}
        for note in notes:
            starts_by_pitch.setdefault(note.pitch, []).append(note.start)

        for note in notes:
            local_left = bisect_left(starts, note.start - 1.0)
            local_right = bisect_right(starts, note.start + 1.0)
            if (local_right - local_left >= 8 and
                    np.quantile(durations[local_left:local_right], 0.75) / grid < 0.65):
                continue

            left = bisect_left(starts, note.start - 0.025)
            right = bisect_right(starts, note.start + 0.025)
            same_onset = notes[left:right]
            highest_pitch = max(other.pitch for other in same_onset)
            raw_duration = note.end - note.start
            target = max(raw_duration, grid, np.ceil((raw_duration - 0.02) / grid) * grid)

            if grid <= 0.25 and (
                len(same_onset) >= 3 or
                (len(same_onset) == 2 and note.pitch < highest_pitch)
            ):
                target = max(target, 2 * grid)

            if grid <= 0.25 and note.pitch == highest_pitch:
                next_upper = float("inf")
                for other in notes[bisect_right(starts, note.start + 0.04):]:
                    if other.start - note.start > 2 * grid + 0.03:
                        break
                    if other.pitch >= note.pitch - 12:
                        next_upper = other.start
                        break
                interval = next_upper - note.start
                if grid / 4 <= interval <= 2 * grid + 0.03:
                    target = max(0.03, interval - 0.001)

            same_pitch_starts = starts_by_pitch[note.pitch]
            next_index = bisect_right(same_pitch_starts, note.start + 0.025)
            next_same = (same_pitch_starts[next_index]
                         if next_index < len(same_pitch_starts) else float("inf"))
            new_end = min(note.start + target, next_same - 0.001)
            if abs(new_end - note.end) > 0.0005:
                note.end = max(note.start + 0.001, new_end)
                adjusted += 1

    first_start = starts[0]
    delay = phase if 0.035 <= first_start <= 0.075 and 0.035 <= phase <= 0.075 else 0.0
    if delay:
        for instrument in midi.instruments:
            for note in instrument.notes:
                note.start = max(0.0, note.start - delay)
                note.end = max(note.start + 0.001, note.end - delay)
            for event in instrument.control_changes:
                event.time = max(0.0, event.time - delay)
            for event in instrument.pitch_bends:
                event.time = max(0.0, event.time - delay)

    return adjusted
