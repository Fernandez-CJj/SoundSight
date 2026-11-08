"""Process a queued composition generation and return artifacts for commit."""


def process(job, suffix):
    owner, target = job["owner"], job["target"]
    from composition.repositories.private_composition_repository import loadOwnedComposition, CURRENT_GENERATED_FILES_VERSION
    from composition.services.generation_service import generateCompositionFiles
    from composition.repositories.public_profile_repository import getPublicProfile
    composition = loadOwnedComposition(target, owner)
    paths = generateCompositionFiles(composition, getPublicProfile(owner)["username"], suffix)
    fields = {**paths, "generatedFilesVersion": CURRENT_GENERATED_FILES_VERSION}
    if composition.recordingSchemaVersion == 1:
        fields.update(tempo=composition.tempo, measureCount=composition.measureCount,
                      performanceDurationUs=composition.performanceDurationUs,
                      performanceNotes=[
                          {"midiNumber": note.midiNumber, "velocity": note.velocity,
                           "startTimeUs": note.startTimeUs, "durationUs": note.durationUs}
                          for note in composition.performanceNotes
                      ])
    # Timing normalization is part of generation, not an edit by the user.
    return {"fields": fields, "paths": list(paths.values())}
