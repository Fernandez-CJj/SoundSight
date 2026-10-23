# Adding a practice stage

Keep each stage's files together in the matching asset folder and Dart file:

- `assets/practice/stage_1/` goes with `stage_1.dart`
- `assets/practice/stage_2/` goes with `stage_2.dart`
- Continue with the same number for later stages.

To add a stage, copy the next numbered folder and Dart definition. Put its video,
quiz text, or sight-reading files in that folder, add the folder under
`flutter.assets` in `pubspec.yaml`, then list those asset paths in the
`PracticeStage.assets` field. Set `circleText` to change the circle label.
Set `description` to choose the text shown in the confirmation dialog when the
user taps the stage circle.

A video and its quiz belong in the same folder and the same `assets` list, with
the video listed first and its quiz listed second. The player pairs them in
that order and opens the quiz from **Start Quiz**.

Finally, import the stage file in `stages.dart` and add its stage variable to
`practiceStages`. Only stages in that list appear on the practice map. A folder
and Dart definition can be prepared in advance without registering the stage.
Fully stop and relaunch the app after adding or moving assets.
