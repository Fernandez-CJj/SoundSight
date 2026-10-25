# Adding a practice stage

Keep each stage's files together in its matching asset folder. Define all
stages in `stages.dart` using the `PracticeStage` model:

- `assets/practice/stage_1/` goes with the stage numbered `1` in the list.
- `assets/practice/stage_2/` goes with the stage numbered `2` in the list.
- Continue with the same number for later stages.

To add a stage, create the next numbered folder and add a `PracticeStage` entry
to `practiceStages` in `stages.dart`. Put its video,
quiz text, or sight-reading files in that folder, add the folder under
`flutter.assets` in `pubspec.yaml`, then list those asset paths in the
`PracticeStage.assets` field. The map card uses `title` and shows its activity
type from those assets. Set `description` to choose the text shown in the stage
details dialog.

A video and its quiz belong in the same folder and the same `assets` list, with
the video listed first and its quiz listed second. The player pairs them in
that order and opens the quiz from **Start Quiz**.

Keep the English quiz path in `PracticeStage.assets`. For Filipino, add a file
beside it using the same filename with `_fil` before `.txt`, for example
`lesson 1 quiz.txt` and `lesson 1 quiz_fil.txt`. Keep the parser markers (`Q:`,
`A)` through `D)`, and `*` before the correct option) unchanged in both files;
only the visible question and option text should be translated. English is the
fallback for every locale other than Filipino.

Only entries in `practiceStages` appear on the practice map. Keep entries in
stage number order so the displayed sequence matches saved progress.
Fully stop and relaunch the app after adding or moving assets.

The user profile's `practiceLevel` is the highest unlocked stage. It starts at
`1` and reaches `17` after stage 16 is passed. A video stage passes with a
perfect quiz score. A sight-reading stage passes only after a perfect run in
Performance mode; Wait mode is available for practice.
Every completed lesson Performance run is saved to Practice Results, including
runs with mistakes. Wait-mode practice and video quiz scores are not saved there.
