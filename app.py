import os
import json
import subprocess
import glob
import music21
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
from PIL import Image
from io import BytesIO

app = FastAPI()

OUTPUT_FOLDER = "./omr_output"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# --- Helper functions for high-precision timing conversion ---
def get_tempo_boundaries(score, default_bpm=120):
    """Extracts tempo marks and their offset boundaries from the music21 score."""
    try:
        boundaries = score.metronomeMarkBoundaries()
    except Exception:
        boundaries = []
        
    if not boundaries:
        default_mm = music21.tempo.MetronomeMark(number=default_bpm)
        boundaries = [(0.0, float('inf'), default_mm)]
        
    return boundaries

def beats_to_seconds(beat_offset, boundaries):
    """Converts a quarter-note beat offset into absolute real-time seconds."""
    time_seconds = 0.0
    for start, end, mm in boundaries:
        bpm = mm.number or 120.0
        if beat_offset >= start:
            segment_end = min(beat_offset, end)
            beats_in_segment = segment_end - start
            time_seconds += (beats_in_segment * 60.0) / bpm
        else:
            break
    return round(time_seconds, 3)


@app.get("/")
def home():
    return {"status": "Local SoundSight Audiveris CPU Backend Is Online"}

@app.post("/process-sheet")
async def process_sheet(file: UploadFile = File(...)):
    input_path = os.path.join(OUTPUT_FOLDER, file.filename)
    is_pdf = file.filename.lower().endswith('.pdf')
    
    try:
        print(f"\n[INFO] File accepted: {file.filename}")
        file_bytes = await file.read()
        
        if is_pdf:
            print("[INFO] Document type is PDF. Staging file directly for Audiveris native parser...")
            with open(input_path, "wb") as f:
                f.write(file_bytes)
        else:
            print("[INFO] Document type is Image. Checking dimensions...")
            img = Image.open(BytesIO(file_bytes))
            width, height = img.size
            
            MIN_TARGET_WIDTH = 2500
            if width < MIN_TARGET_WIDTH:
                scale_factor = MIN_TARGET_WIDTH / width
                new_width = int(width * scale_factor)
                new_height = int(height * scale_factor)
                
                print(f"[INFO] Image resolution too low. Upscaling to {new_width}x{new_height}...")
                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                
            img.convert("RGB").save(input_path, "JPEG", quality=95)
            print(f"[INFO] Ready for Audiveris parsing: {input_path}")
        
        audiveris_executable = r"C:\Program Files\Audiveris\Audiveris.exe"

        if not os.path.exists(audiveris_executable):
            raise HTTPException(
                status_code=500, 
                detail="Audiveris.exe not found. Please verify it is installed in C:\\Program Files\\Audiveris\\"
            )

        # 3. Run Audiveris in silent headless batch mode
        cmd = [
            audiveris_executable,
            "-batch",
            "-export",
            "-option", "org.audiveris.omr.text.TextPlugin.enabled=true",
            "-option", "org.audiveris.omr.text.TextRecog.enabled=true",
            "-option", "org.audiveris.omr.text.LyricsPlugin.enabled=false", 
            "-option", "org.audiveris.omr.image.Dpi=300",
            "-output", os.path.abspath(OUTPUT_FOLDER),
            os.path.abspath(input_path)
        ]
        
        print(f"[DEBUG] Launching structural analysis: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        base_name = os.path.splitext(file.filename)[0]
        search_pattern = os.path.join(OUTPUT_FOLDER, "**", f"{base_name}.mxl")
        generated_files = glob.glob(search_pattern, recursive=True)

        if not generated_files:
            print(f"[ERROR] Audiveris STDOUT:\n{result.stdout}")
            print(f"[ERROR] Audiveris STDERR:\n{result.stderr}")
            raise HTTPException(status_code=500, detail="Audiveris failed to extract musical structures.")

        xml_file_path = generated_files[0]
        # 5. Compile notes using Music21
        print(f"[INFO] Compiling note matrix data...")
        score = music21.converter.parse(xml_file_path)
        
        # --- MUSIC21 OMR POST-PROCESSING PIPELINE ---
        # Filters structural layout errors, such as small clef tails misparsed as note symbols
        print("[INFO] Executing structural layout filters on streaming parts...")
        for part in score.parts:
            for measure in part.getElementsByClass(music21.stream.Measure):
                # Inspect measure for clef shifts
                clef_changes = measure.getElementsByClass(music21.clef.Clef)
                if clef_changes:
                    all_notes = list(measure.notes)
                    for note_el in all_notes:
                        # Target half notes (quarter length 2.0) matching clef change offset boundaries
                        if note_el.quarterLength == 2.0:
                            # Safely purge the orphan note element from both container hierarchies
                            if note_el.isChord:
                                measure.remove(note_el)
                            elif note_el.isNote:
                                measure.remove(note_el)
                            print(f"[CLEANUP] Stripped structural layout artifact at offset {note_el.offset}")

        # Build our high-precision tempo map
        tempo_boundaries = get_tempo_boundaries(score, default_bpm=120)
        
        # --- MIDI GENERATION ---
        midi_file_path = os.path.join(OUTPUT_FOLDER, f"{base_name}.mid")
        print(f"[INFO] Compiling MIDI data stream...")
        
        try:
            score.write('midi', fp=midi_file_path, expandRepeats=False)
        except Exception as midi_err:
            print(f"[WARN] Standard MIDI write failed: {midi_err}")
            print(f"[INFO] Running structural sweep to purge broken layout markers...")
            
            for part in score.parts:
                part.removeByClass(music21.bar.Repeat)
                part.removeByClass(music21.repeat.RepeatExpression)
                
                for measure in part.getElementsByClass(music21.stream.Measure):
                    measure.removeByClass(music21.bar.Repeat)
                    measure.removeByClass(music21.repeat.RepeatExpression)
                    
                    if measure.leftBarline and isinstance(measure.leftBarline, music21.bar.Repeat):
                        measure.leftBarline = music21.bar.Barline('regular')
                    if measure.rightBarline and isinstance(measure.rightBarline, music21.bar.Repeat):
                        measure.rightBarline = music21.bar.Barline('regular')
            
            score.write('midi', fp=midi_file_path)
            
        print(f"[INFO] Successfully saved MIDI file to: {midi_file_path}")

        notes_array = []
        
        # Parse each hand/staff independently
        for part_index, part in enumerate(score.parts):
            hand = "right" if part_index == 0 else "left"
            flat_part = part.flatten()
            
            for el in flat_part.notes:
                beat_offset = float(el.offset)
                beat_duration = float(el.quarterLength)
                
                # Convert beats to real-world seconds based on score tempo
                timestamp_seconds = beats_to_seconds(beat_offset, tempo_boundaries)
                duration_seconds = beats_to_seconds(beat_offset + beat_duration, tempo_boundaries) - timestamp_seconds
                
                if el.isNote:
                    notes_array.append({
                        "note": str(el.nameWithOctave),
                        "timestamp_seconds": timestamp_seconds,
                        "duration_seconds": round(duration_seconds, 3),
                        "beat_offset": round(beat_offset, 2),
                        "beat_duration": round(beat_duration, 2),
                        "hand": hand
                    })
                elif el.isChord:
                    for pitch in el.pitches:
                        notes_array.append({
                            "note": str(pitch.nameWithOctave),
                            "timestamp_seconds": timestamp_seconds,
                            "duration_seconds": round(duration_seconds, 3),
                            "beat_offset": round(beat_offset, 2),
                            "beat_duration": round(beat_duration, 2),
                            "hand": hand
                        })

        # Sort notes logically by real-world play time
        notes_array.sort(key=lambda x: x["timestamp_seconds"])

        json_file_path = os.path.join(OUTPUT_FOLDER, f"{base_name}.json")
        with open(json_file_path, "w", encoding="utf-8") as json_file:
            json.dump(notes_array, json_file, indent=4)
        print(f"[INFO] Successfully saved note matrix JSON to: {json_file_path}")

        if os.path.exists(input_path):
            os.remove(input_path)

        return {
            "status": "Success", 
            "engine": "Audiveris Local",
            "midi_path": os.path.abspath(midi_file_path),
            "notes": notes_array
        }

    except Exception as e:
        if os.path.exists(input_path):
            os.remove(input_path)
        print(f"[ERROR] Operational Failure: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/download-midi/{filename}")
def download_midi(filename: str):
    file_path = os.path.join(OUTPUT_FOLDER, f"{filename}.mid")
    if os.path.exists(file_path):
        return FileResponse(path=file_path, media_type='audio/midi', filename=f"{filename}.mid")
    raise HTTPException(status_code=404, detail="MIDI file not found.")
