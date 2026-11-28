from typing import Literal

from pydantic import BaseModel, Field

MAX_COMPOSITION_NOTES = 768


class OriginalRecordingSettingsRequest(BaseModel):
    tempo: int = Field(ge=40, le=200)
    key: str
    beatsPerMeasure: int = Field(ge=1, le=12)
    beatUnit: Literal[4, 8]
    measureCount: int = Field(ge=1, le=128)


class CompositionNoteRequest(BaseModel):
    id: str
    pitch: str

    octave: int = Field(
        ge=0,
        le=8,
    )

    midiNumber: int = Field(
        ge=21,
        le=108,
    )

    measureIndex: int = Field(
        ge=0,
    )

    startBeat: float = Field(
        ge=0,
    )

    durationBeats: float = Field(
        gt=0,
    )

    velocity: float = Field(
        ge=0,
        le=1,
    )

    tieToNext: bool = False


class RecordedPerformanceNoteRequest(BaseModel):
    midiNumber: int = Field(ge=21, le=108)
    velocity: int = Field(ge=1, le=127)
    startTimeUs: int = Field(ge=0)
    durationUs: int = Field(gt=0)


class CompositionRequest(BaseModel):
    id: str = ""
    ownerId: str
    title: str
    creationMethod: Literal["manual", "recording"] = "manual"
    contentMode: Literal["performance", "score"] | None = None
    originalRecordingSettings: OriginalRecordingSettingsRequest | None = None

    tempo: int = Field(
        ge=40,
        le=200,
    )

    key: str

    beatsPerMeasure: int = Field(
        ge=1,
        le=12,
    )

    beatUnit: int

    measureCount: int = Field(
        ge=1,
        le=128,
    )

    notes: list[CompositionNoteRequest] = Field(
        default_factory=list, max_length=MAX_COMPOSITION_NOTES
    )
    recordingSchemaVersion: int | None = None
    performanceNotes: list[RecordedPerformanceNoteRequest] = Field(
        default_factory=list, max_length=MAX_COMPOSITION_NOTES
    )
    performanceDurationUs: int | None = Field(default=None, gt=0)

    @property
    def effectiveContentMode(self):
        if self.contentMode is not None:
            return self.contentMode
        return "performance" if (
            self.creationMethod == "recording" and self.recordingSchemaVersion == 1
        ) else "score"

    @property
    def usesPerformanceRecording(self):
        return self.effectiveContentMode == "performance"
