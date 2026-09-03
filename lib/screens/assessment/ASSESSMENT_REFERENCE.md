# Assessment Reference

## Main flow

1. The user presses **Start Assessment**.
2. Firestore creates or loads their one assessment attempt.
3. The 72-hour deadline starts using Firestore server time.
4. The user answers the Background Questions.
5. A self-reported complete beginner goes directly to Results.
6. Other users continue to Notation Reading.
7. After Notation Reading, they complete Piano Execution.
8. The Results screen shows the saved assessment result.
9. Pressing **Done** copies the final level to the user's profile.

The user only receives one attempt. If an unfinished attempt expires, the final level becomes Beginner and the user cannot try again.

## Where the assessment is stored

The complete attempt is stored in one Firestore document:

```text
users/{uid}/assessment/current
```

An atomic update means all fields in one update are saved together, or none of them are saved.

## Background Questions

There are four questions. Selected answers stay temporarily in the screen's memory until the user presses **Submit**.

If the user closes the screen before submitting, those unsaved selections are lost.

After Submit, the answers are saved in:

```text
questionnaireAnswers
```

If `piano_experience` is `new_to_piano` or `sheet_music_experience` is `not_familiar`, the app asks for confirmation. After confirmation, it saves:

```text
placementMethod: selfReportedBeginner
finalSkillLevel: beginner
status: completed
currentSection: results
```

The user skips Notation Reading and Piano Execution.

Otherwise, the answers are saved and `currentSection` becomes `notationReading`.

## Notation Reading

There are 18 questions:

- 6 Beginner
- 6 Intermediate
- 6 Advanced

Answers stay temporarily in memory until Submit. After Submit, Firestore stores two new fields:

```text
notationReadingAnswers
notationReadingScore
```

It also changes `currentSection` to `pianoExecution` and updates the server timestamps.

The user must get at least 4 out of 6 correct in a tier.

- Advanced notation: pass Beginner, Intermediate, and Advanced
- Intermediate notation: pass Beginner and Intermediate
- Beginner notation: fail Beginner or Intermediate

The tiers are cumulative, meaning a higher level also requires passing all lower levels.

## Piano Execution

There are 9 tasks, but scoring uses the individual expected notes or chords inside each task.

One expected single note is one group. One expected chord or two-hand pair is also one group, even though several keys are pressed.

### Beginner

- Middle C: 1 group
- Five-finger pattern: 5 groups
- C major chord: 1 group
- Total: 7 groups
- Passing score: at least 5 out of 7

### Intermediate

- C major scale: 8 groups
- C major arpeggio: 7 groups
- Chord progression: 4 groups
- Total: 19 groups
- Passing score: at least 14 out of 19

### Advanced

- Two-octave scale: 15 groups
- Chord inversions: 4 groups
- Parallel scale: 8 groups
- Total: 27 groups
- Passing score: at least 19 out of 27

Each group becomes `correct`, `wrong`, or `missed`. Correct notes must also be played within the allowed timing window.

- Advanced piano: pass Beginner, Intermediate, and Advanced
- Intermediate piano: pass Beginner and Intermediate
- Beginner piano: fail Beginner or Intermediate

All nine task results stay in memory until **Submit Piano Results** is pressed. Closing the app before submission loses the unsaved piano results.

After submission, Firestore stores the task results, piano score, notation level, piano level, final level, completion status, and server timestamps.

## Final skill level

The final level is always the lower of the notation and piano levels.

```text
Notation: Beginner
Piano: Advanced
Final: Beginner
```

This prevents strong piano playing from hiding weak sheet-music reading.

## Validation

Validation happens in three places:

1. The screen checks that the user completed the required questions or tasks.
2. The assessment service validates the IDs and counts and calculates the scores.
3. Firestore Rules check the authenticated owner, deadline, section order, allowed fields, score totals, calculated levels, and server timestamps.

Notation Rules verify that the saved score matches the saved answers. Piano Rules verify the required task IDs and that the total score is internally consistent.

## Results and profile update

Piano submission first saves the completed assessment document. The Results screen then displays the saved answers and scores.

When the user presses **Done**, the app copies the assessment's saved `finalSkillLevel` into:

```text
users/{uid}.skillLevel
```

If that profile update fails, it can be retried without repeating the assessment because the completed assessment result is already saved.
