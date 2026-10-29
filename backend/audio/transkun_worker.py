"""Run with the separate Python 3.11 environment, not the FastAPI interpreter."""

import json
from pathlib import Path
import subprocess
import sys

import pretty_midi

from transkun_postprocess import correct_note_timing


def main():
    if len(sys.argv) != 3:
        raise SystemExit("Usage: transkun_worker.py input.wav output.mid")
    if sys.version_info[:2] != (3, 11):
        raise RuntimeError("The Transkun worker requires Python 3.11.")

    source = Path(sys.argv[1])
    output = Path(sys.argv[2])
    raw = output.with_name("raw_transkun.mid")
    command = [
        sys.executable, "-m", "transkun.transcribe",
        str(source), str(raw), "--device", "cpu",
    ]
    result = subprocess.run(
        command, capture_output=True, text=True, timeout=12 * 60, check=False,
    )
    if result.returncode != 0 or not raw.is_file():
        raise RuntimeError("Transkun could not transcribe this recording.")

    midi = pretty_midi.PrettyMIDI(str(raw))
    notes = [
        note
        for instrument in midi.instruments if not instrument.is_drum
        for note in instrument.notes
    ]
    if not notes:
        raise ValueError("No piano notes were found in this recording.")

    adjusted = correct_note_timing(midi)
    midi.write(str(output))
    print(json.dumps({"noteCount": len(notes), "adjustedNoteCount": adjusted}))


if __name__ == "__main__":
    main()
