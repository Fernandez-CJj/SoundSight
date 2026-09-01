import 'dart:convert';

String buildOsmdLoadingHtml() {
  return '''
<!DOCTYPE html>
<html>
  <body style="margin: 0; background: white;"></body>
</html>
''';
}

String buildMusicSheetHtml(String musicXml) {
  final encodedMusicXml = jsonEncode(musicXml);

  return '''
<!DOCTYPE html>
<html>
  <head>
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0"
    >

    <style>
      html,
      body {
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
        overflow: hidden;
      }

      #sheet-viewport {
        width: 100%;
        height: 100%;
        overflow-x: auto;
        overflow-y: hidden;
        touch-action: none;
        overscroll-behavior: none;
        scrollbar-width: none;
      }

      #sheet-viewport::-webkit-scrollbar {
        display: none;
      }

      #osmd-container {
        min-height: 100%;
      }
    </style>
  </head>
  <body>
    <div id="sheet-viewport">
      <div id="osmd-container"></div>
    </div>

    <script
      src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@2.1.1/build/opensheetmusicdisplay.min.js">
    </script>

    <script>
      const musicXml = $encodedMusicXml;
      const normalCursorColor = "#33e02f";

      let osmd = null;

      function sendCurrentExpectedNotes() {
        const notes = osmd.cursor.NotesUnderCursor();
        const pitchValues = [];

        notes.forEach((note) => {
          if (!note || !note.Pitch) {
            return;
          }

          pitchValues.push({
            halfTone: note.Pitch.getHalfTone(),
            octave: note.Pitch.Octave,
            fundamentalNote: note.Pitch.FundamentalNote,
            midi: note.Pitch.getHalfTone() + 12
          });
        });

        ExpectedNotes.postMessage(
          JSON.stringify(pitchValues)
        );
      }

      function setCursorColor(color) {
        if (!osmd || !osmd.cursor) {
          return;
        }

        osmd.cursor.CursorOptions.color = color;
        osmd.cursor.update();
      }

      function keepCursorVisible() {
  const cursorElement =
      osmd.cursor.cursorElement;

  if (!cursorElement) {
    return;
  }

  cursorElement.scrollIntoView({
    behavior: "smooth",
    block: "nearest",
    inline: "center"
  });
}

function advanceCursor() {
  if (!osmd || !osmd.cursor) {
    return;
  }

  const cursorElement =
      osmd.cursor.cursorElement;

  if (cursorElement) {
    cursorElement.style.transition = "none";
  }

  const foundPlayablePosition =
      advanceToNextPlayablePosition();

  if (!foundPlayablePosition) {
  osmd.cursor.hide();

  ExpectedNotes.postMessage(
    JSON.stringify([])
  );

  ScoreCompleted.postMessage(
    "completed"
  );

  return;
}

  setCursorColor(normalCursorColor);

  requestAnimationFrame(
    keepCursorVisible
  );

  sendCurrentExpectedNotes();
}

function slideCursorToNextNote(durationMilliseconds) {
  if (!osmd || !osmd.cursor) {
    return;
  }

  const cursorElement =
      osmd.cursor.cursorElement;

  if (!cursorElement) {
    return;
  }

  const safeDuration = Math.max(
    0,
    Number(durationMilliseconds) || 0
  );

  cursorElement.style.transition =
      "left " + safeDuration + "ms linear, " +
      "top " + safeDuration + "ms linear";

  const foundPlayablePosition =
      advanceToNextPlayablePosition();

  if (!foundPlayablePosition) {
    return;
  }

  setCursorColor(normalCursorColor);

  requestAnimationFrame(
    keepCursorVisible
  );

  sendCurrentExpectedNotes();
}

function hideCursorForCompletion() {
  if (!osmd || !osmd.cursor) {
    return;
  }

  osmd.cursor.hide();

  ExpectedNotes.postMessage(
    JSON.stringify([])
  );
}

function advanceToNextPlayablePosition() {
  while (!osmd.cursor.Iterator.EndReached) {
    osmd.cursor.next();
    osmd.cursor.update();

    if (osmd.cursor.Iterator.EndReached) {
      return false;
    }

    const notes =
        osmd.cursor.NotesUnderCursor();

    const hasPlayableNotes =
        notes.some(
      (note) => note && note.Pitch
    );

    if (hasPlayableNotes) {
      return true;
    }
  }

  return false;
}

function countPlayablePositions() {
  const iterator =
      osmd.cursor.Iterator.clone();

  let playablePositionCount = 0;
  let visitedPositionCount = 0;

  const maximumPositionCount = 100000;

  while (
    !iterator.EndReached &&
    visitedPositionCount < maximumPositionCount
  ) {
    const voiceEntries =
        iterator.CurrentVoiceEntries || [];

    const hasPlayableNotes =
        voiceEntries.some((voiceEntry) => {
      const notes =
          voiceEntry && voiceEntry.Notes
          ? voiceEntry.Notes
          : [];

      return notes.some(
        (note) => note && note.Pitch
      );
    });

    if (hasPlayableNotes) {
      playablePositionCount++;
    }

    iterator.moveToNext();
    visitedPositionCount++;
  }

  return playablePositionCount;
}

      function fitScoreToViewportHeight() {
  const viewport =
      document.getElementById(
        "sheet-viewport"
      );

  const scoreSvg =
      document.querySelector(
        "#osmd-container svg"
      );

  if (!viewport || !scoreSvg) {
    return;
  }

  const availableHeight =
      viewport.clientHeight;

  const scoreHeight =
      scoreSvg.getBoundingClientRect()
          .height;

  if (scoreHeight <= availableHeight) {
    return;
  }

  const fitRatio =
      availableHeight / scoreHeight;

  osmd.Zoom = Math.max(
    0.4,
    osmd.Zoom * fitRatio * 0.95
  );

  osmd.render();
}

      async function renderScore() {
        try {
          if (typeof opensheetmusicdisplay === "undefined") {
            throw new Error(
              "The sheet music renderer could not be loaded."
            );
          }

          osmd =
              new opensheetmusicdisplay.OpenSheetMusicDisplay(
            "osmd-container",
            {
              renderSingleHorizontalStaffline: true,
              drawCredits: false,
              drawingParameters: "compacttight"
            }
          );

          await osmd.load(musicXml);
          osmd.Zoom = 0.75;
          osmd.render();
          fitScoreToViewportHeight();
          osmd.cursor.show();
          setCursorColor(normalCursorColor);
osmd.cursor.update();

const totalPlayablePositions =
    countPlayablePositions();

ScoreTotal.postMessage(
  totalPlayablePositions.toString()
);

const initialNotes =
    osmd.cursor.NotesUnderCursor();

const initialPositionHasNotes =
    initialNotes.some(
  (note) => note && note.Pitch
);

if (!initialPositionHasNotes) {
  const foundPlayablePosition =
      advanceToNextPlayablePosition();

  if (!foundPlayablePosition) {
    osmd.cursor.hide();

    ExpectedNotes.postMessage(
      JSON.stringify([])
    );

    ScoreCompleted.postMessage(
      "completed"
    );

    ScoreRendered.postMessage(
      "rendered"
    );

    return;
  }
}

sendCurrentExpectedNotes();
ScoreRendered.postMessage(
  "rendered"
);
        } catch (error) {
          ScoreRenderFailed.postMessage(
            String(error)
          );
        }
      }

      renderScore();
    </script>
  </body>
</html>
''';
}
