import 'dart:convert';

String buildOsmdLoadingHtml() {
  return '''
<!DOCTYPE html>
<html>
  <body style="margin: 0; background: white;"></body>
</html>
''';
}

String buildMusicSheetHtml(
  String musicXml, {
  bool preserveRestOnlyStaves = false,
}) {
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
      const preserveRestOnlyStaves = $preserveRestOnlyStaves;
      const normalCursorColor = "#33e02f";

      let osmd = null;
      let removedRestOnlyPartCount = 0;
      let mergedSequentialPartCount = 0;
      let waitCursorTransitionPending = false;
      let waitCursorTransitionHasNext = false;
      let scoreResizeObserver = null;
      let scoreLayoutFrame = null;

      function getLocalName(element) {
        return element.localName ||
            element.nodeName.split(":").pop();
      }

      function getDirectChildren(parent, localName) {
        return Array.from(parent.children).filter(
          (child) => getLocalName(child) === localName
        );
      }

      function getDescendants(parent, localName) {
        return Array.from(
          parent.getElementsByTagName("*")
        ).filter(
          (element) => getLocalName(element) === localName
        );
      }

      function noteContainsPlayablePitch(noteElement) {
        return Array.from(noteElement.children).some(
          (child) => {
            const childName = getLocalName(child);

            return childName === "pitch" ||
                childName === "unpitched";
          }
        );
      }

      function partContainsPlayableNotes(partElement) {
        return getDescendants(
          partElement,
          "note"
        ).some(noteContainsPlayablePitch);
      }

      function getFirstChildText(parent, localName) {
        const child = getDirectChildren(
          parent,
          localName
        )[0];

        return child && child.textContent
          ? child.textContent.trim()
          : "";
      }

      function getPartClefSignature(partElement) {
        const clef = getDescendants(
          partElement,
          "clef"
        )[0];

        if (!clef) {
          return "";
        }

        return getFirstChildText(clef, "sign") + ":" +
            getFirstChildText(clef, "line");
      }

      function summarizePartMeasures(partElement) {
        let staffIsVisible = true;

        return getDirectChildren(
          partElement,
          "measure"
        ).map((measureElement, index) => {
          const staffDetails = getDescendants(
            measureElement,
            "staff-details"
          );

          staffDetails.forEach((detailsElement) => {
            const printObject = detailsElement.getAttribute(
              "print-object"
            );

            if (printObject === "yes") {
              staffIsVisible = true;
            } else if (printObject === "no") {
              staffIsVisible = false;
            }
          });

          const playableNoteCount = getDescendants(
            measureElement,
            "note"
          ).filter((noteElement) => {
            return noteElement.getAttribute("print-object") !== "no" &&
                noteContainsPlayablePitch(noteElement);
          }).length;

          return {
            element: measureElement,
            number: measureElement.getAttribute("number") ||
                String(index + 1),
            visible: staffIsVisible,
            playableNoteCount: playableNoteCount
          };
        });
      }

      function partFragmentsCanShareStaff(
        baseSummary,
        donorSummary,
        occupiedMeasureIndices
      ) {
        if (
          baseSummary.clefSignature === "" ||
          baseSummary.clefSignature !== donorSummary.clefSignature ||
          baseSummary.measures.length !== donorSummary.measures.length ||
          !baseSummary.hasHiddenMeasures ||
          !donorSummary.hasHiddenMeasures
        ) {
          return false;
        }

        let donorHasPlayableMeasure = false;

        for (
          let index = 0;
          index < baseSummary.measures.length;
          index++
        ) {
          const baseMeasure = baseSummary.measures[index];
          const donorMeasure = donorSummary.measures[index];

          if (baseMeasure.number !== donorMeasure.number) {
            return false;
          }

          const baseHasNotes =
              baseMeasure.playableNoteCount > 0;
          const donorHasNotes =
              donorMeasure.playableNoteCount > 0;

          if (donorHasNotes) {
            donorHasPlayableMeasure = true;

            if (
              occupiedMeasureIndices.has(index) ||
              !donorMeasure.visible ||
              baseMeasure.visible
            ) {
              return false;
            }
          }

          if (
            baseHasNotes &&
            (!baseMeasure.visible || donorMeasure.visible)
          ) {
            return false;
          }
        }

        return donorHasPlayableMeasure;
      }

      function createPartFragmentSummary(partElement) {
        const measures = summarizePartMeasures(
          partElement
        );

        return {
          element: partElement,
          id: (partElement.getAttribute("id") || "").trim(),
          clefSignature: getPartClefSignature(partElement),
          measures: measures,
          playableMeasureCount: measures.filter(
            (measure) => measure.playableNoteCount > 0
          ).length,
          hasHiddenMeasures: measures.some(
            (measure) => !measure.visible
          )
        };
      }

      function mergeSequentialPartFragments(scoreRoot) {
        const partSummaries = getDirectChildren(
          scoreRoot,
          "part"
        ).map(createPartFragmentSummary).filter(
          (summary) => summary.playableMeasureCount > 0
        ).sort((first, second) => {
          return second.playableMeasureCount -
              first.playableMeasureCount;
        });

        if (partSummaries.length < 2) {
          return new Set();
        }

        const baseSummary = partSummaries[0];
        const occupiedMeasureIndices = new Set();
        const removedPartIds = new Set();

        baseSummary.measures.forEach((measure, index) => {
          if (measure.playableNoteCount > 0) {
            occupiedMeasureIndices.add(index);
          }
        });

        partSummaries.slice(1).forEach((donorSummary) => {
          if (!partFragmentsCanShareStaff(
            baseSummary,
            donorSummary,
            occupiedMeasureIndices
          )) {
            return;
          }

          donorSummary.measures.forEach((donorMeasure, index) => {
            if (donorMeasure.playableNoteCount === 0) {
              return;
            }

            const currentBaseMeasure = getDirectChildren(
              baseSummary.element,
              "measure"
            )[index];
            const replacementMeasure =
                donorMeasure.element.cloneNode(true);

            baseSummary.element.replaceChild(
              replacementMeasure,
              currentBaseMeasure
            );
            occupiedMeasureIndices.add(index);
          });

          if (donorSummary.id !== "") {
            removedPartIds.add(donorSummary.id);
          }

          donorSummary.element.remove();
          mergedSequentialPartCount++;
        });

        return removedPartIds;
      }

      function removeEmptyPartGroups(partList) {
        const activeGroups = [];
        const emptyGroupPairs = [];

        Array.from(partList.children).forEach((child) => {
          const childName = getLocalName(child);

          if (childName === "score-part") {
            activeGroups.forEach((group) => {
              group.partCount++;
            });
            return;
          }

          if (childName !== "part-group") {
            return;
          }

          const groupType = child.getAttribute("type") || "";
          const groupNumber = child.getAttribute("number") || "1";

          if (groupType === "start") {
            activeGroups.push({
              number: groupNumber,
              start: child,
              partCount: 0
            });
            return;
          }

          if (groupType !== "stop") {
            return;
          }

          let matchingIndex = -1;

          for (
            let index = activeGroups.length - 1;
            index >= 0;
            index--
          ) {
            if (activeGroups[index].number === groupNumber) {
              matchingIndex = index;
              break;
            }
          }

          if (matchingIndex < 0) {
            return;
          }

          const activeGroup = activeGroups.splice(
            matchingIndex,
            1
          )[0];

          if (activeGroup.partCount === 0) {
            emptyGroupPairs.push([
              activeGroup.start,
              child
            ]);
          }
        });

        emptyGroupPairs.forEach((groupPair) => {
          groupPair[0].remove();
          groupPair[1].remove();
        });
      }

      function prepareMusicXmlForSightReading(xmlText) {
        const parser = new DOMParser();
        const xmlDocument = parser.parseFromString(
          xmlText,
          "application/xml"
        );
        const parserErrors = getDescendants(
          xmlDocument,
          "parsererror"
        );

        if (parserErrors.length > 0) {
          throw new Error(
            "The MusicXML could not be prepared for Sight Reading."
          );
        }

        const scoreRoot = xmlDocument.documentElement;
        mergedSequentialPartCount = 0;
        const removedPartIds = mergeSequentialPartFragments(
          scoreRoot
        );
        const scoreParts = getDirectChildren(
          scoreRoot,
          "part"
        );
        const playableParts = scoreParts.filter(
          partContainsPlayableNotes
        );

        if (
          playableParts.length === 0
        ) {
          removedRestOnlyPartCount = 0;
          return xmlText;
        }

        removedRestOnlyPartCount =
            scoreParts.length - playableParts.length;

        scoreParts.forEach((partElement) => {
          if (partContainsPlayableNotes(partElement)) {
            return;
          }

          const partId = (
            partElement.getAttribute("id") || ""
          ).trim();

          if (partId !== "") {
            removedPartIds.add(partId);
          }

          partElement.remove();
        });

        if (removedPartIds.size === 0) {
          return xmlText;
        }

        const partList = getDirectChildren(
          scoreRoot,
          "part-list"
        )[0];

        if (partList) {
          getDirectChildren(
            partList,
            "score-part"
          ).forEach((scorePartElement) => {
            const partId = (
              scorePartElement.getAttribute("id") || ""
            ).trim();

            if (removedPartIds.has(partId)) {
              scorePartElement.remove();
            }
          });

          removeEmptyPartGroups(partList);
        }

        return new XMLSerializer().serializeToString(
          xmlDocument
        );
      }

      function clefNameFromElement(clefElement) {
        if (!clefElement) {
          return "unknown";
        }

        const sign = getFirstChildText(clefElement, "sign")
            .toUpperCase();
        const line = getFirstChildText(clefElement, "line");

        if (sign === "G") {
          return "treble";
        }

        if (sign === "F") {
          return "bass";
        }

        if (sign === "C" && line === "3") {
          return "alto";
        }

        if (sign === "C" && line === "4") {
          return "tenor";
        }

        if (sign === "PERCUSSION") {
          return "percussion";
        }

        return "unknown";
      }

      function pitchElementToMidi(noteElement) {
        const pitch = getDirectChildren(noteElement, "pitch")[0];
        const unpitched = getDirectChildren(noteElement, "unpitched")[0];
        const pitchSource = pitch || unpitched;

        if (!pitchSource) {
          return null;
        }

        const stepName = pitch
          ? "step"
          : "display-step";
        const octaveName = pitch
          ? "octave"
          : "display-octave";
        const step = getFirstChildText(pitchSource, stepName)
            .toUpperCase();
        const octave = Number(
          getFirstChildText(pitchSource, octaveName)
        );
        const alterText = getFirstChildText(pitchSource, "alter");
        const alter = alterText === "" ? 0 : Number(alterText);
        const semitones = {
          C: 0,
          D: 2,
          E: 4,
          F: 5,
          G: 7,
          A: 9,
          B: 11
        };

        if (!(step in semitones) || !Number.isFinite(octave)) {
          return null;
        }

        return (octave + 1) * 12 + semitones[step] + alter;
      }

      function buildScorePositionMetadata(xmlText) {
        const parser = new DOMParser();
        const documentForAnalysis = parser.parseFromString(
          xmlText,
          "application/xml"
        );
        const scoreRoot = documentForAnalysis.documentElement;
        const groupedPositions = new Map();
        let globalStaffOffset = 0;

        getDirectChildren(scoreRoot, "part").forEach((partElement) => {
          let divisions = 1;
          let declaredStaffCount = 1;
          const activeClefs = {};
          const measures = getDirectChildren(partElement, "measure");

          const staffNumbers = getDescendants(partElement, "staff")
              .map((element) => Number(element.textContent || "1"))
              .filter(Number.isFinite);
          const clefNumbers = getDescendants(partElement, "clef")
              .map((element) => Number(element.getAttribute("number") || "1"))
              .filter(Number.isFinite);
          const stavesElements = getDescendants(partElement, "staves");

          if (stavesElements.length > 0) {
            const parsedStaffCount = Number(
              stavesElements[0].textContent || "1"
            );

            if (Number.isFinite(parsedStaffCount)) {
              declaredStaffCount = Math.max(
                declaredStaffCount,
                parsedStaffCount
              );
            }
          }

          if (staffNumbers.length > 0) {
            declaredStaffCount = Math.max(
              declaredStaffCount,
              ...staffNumbers
            );
          }

          if (clefNumbers.length > 0) {
            declaredStaffCount = Math.max(
              declaredStaffCount,
              ...clefNumbers
            );
          }

          measures.forEach((measureElement, measureIndex) => {
            let measureCursor = 0;
            let previousNoteOnset = 0;
            const measureNumber = measureElement.getAttribute("number") ||
                String(measureIndex + 1);

            Array.from(measureElement.children).forEach((child) => {
              const childName = getLocalName(child);

              if (childName === "attributes") {
                const divisionsText = getFirstChildText(
                  child,
                  "divisions"
                );
                const parsedDivisions = Number(divisionsText);

                if (Number.isFinite(parsedDivisions) && parsedDivisions > 0) {
                  divisions = parsedDivisions;
                }

                getDirectChildren(child, "clef").forEach((clefElement) => {
                  const staffNumber = Number(
                    clefElement.getAttribute("number") || "1"
                  );
                  activeClefs[staffNumber] = clefNameFromElement(
                    clefElement
                  );
                });
                return;
              }

              if (childName === "backup" || childName === "forward") {
                const duration = Number(
                  getFirstChildText(child, "duration") || "0"
                ) / divisions;

                if (Number.isFinite(duration)) {
                  measureCursor += childName === "backup"
                    ? -duration
                    : duration;
                }
                return;
              }

              if (childName !== "note") {
                return;
              }

              const isChord = getDirectChildren(child, "chord").length > 0;
              const onset = isChord ? previousNoteOnset : measureCursor;
              const duration = Number(
                getFirstChildText(child, "duration") || "0"
              ) / divisions;

              if (!isChord) {
                previousNoteOnset = onset;
              }

              if (
                noteContainsPlayablePitch(child) &&
                child.getAttribute("print-object") !== "no"
              ) {
                const hasTieStop = getDirectChildren(child, "tie").some(
                  (tieElement) => tieElement.getAttribute("type") === "stop"
                );
                const midiNote = pitchElementToMidi(child);

                if (!hasTieStop && midiNote !== null) {
                  const staffNumber = Number(
                    getFirstChildText(child, "staff") || "1"
                  );
                  const onsetKey = Math.round(onset * 1000000);
                  const key = String(measureIndex) + ":" + String(onsetKey);

                  if (!groupedPositions.has(key)) {
                    groupedPositions.set(key, {
                      measureIndex: measureIndex,
                      onset: onset,
                      measureNumber: measureNumber,
                      midiNotes: new Set(),
                      clefs: new Set(),
                      staffNumbers: new Set()
                    });
                  }

                  const position = groupedPositions.get(key);
                  position.midiNotes.add(Math.round(midiNote));
                  position.clefs.add(
                    activeClefs[staffNumber] || "unknown"
                  );
                  position.staffNumbers.add(
                    globalStaffOffset + staffNumber
                  );
                }
              }

              if (!isChord && Number.isFinite(duration)) {
                measureCursor += duration;
              }
            });
          });

          globalStaffOffset += declaredStaffCount;
        });

        return Array.from(groupedPositions.values())
            .sort((first, second) => {
              if (first.measureIndex !== second.measureIndex) {
                return first.measureIndex - second.measureIndex;
              }

              return first.onset - second.onset;
            })
            .map((position, index) => {
              return {
                positionIndex: index,
                measureNumber: position.measureNumber,
                midiNotes: Array.from(position.midiNotes).sort(
                  (first, second) => first - second
                ),
                clefs: Array.from(position.clefs),
                staffNumbers: Array.from(position.staffNumbers).sort(
                  (first, second) => first - second
                )
              };
            });
      }

      function noteIsPlayable(note) {
        if (!note) {
          return false;
        }

        const sourceNote =
            note.sourceNote ||
            note.SourceNote ||
            note;
        const tie = sourceNote.NoteTie;

        if (tie) {
          const tieStartNote =
              tie.StartNote ||
              (tie.Notes && tie.Notes.length > 0
                ? tie.Notes[0]
                : null);

          if (tieStartNote && tieStartNote !== sourceNote) {
            return false;
          }
        }

        if (note.PrintObject === false) {
          return false;
        }

        if (typeof note.isRest === "function") {
          return !note.isRest() && Boolean(note.Pitch);
        }

        if (note.IsRest === true || note.isRest === true) {
          return false;
        }

        return Boolean(note.Pitch);
      }

      function noteIsVisibleAndPlayable(note, staff) {
        if (
          note &&
          note.ParentStaff &&
          note.ParentStaff !== staff
        ) {
          return false;
        }

        return noteIsPlayable(note);
      }

      function staffContainsPlayableNotes(staff) {
        const voices = staff && staff.Voices
          ? staff.Voices
          : [];

        return voices.some((voice) => {
          const voiceEntries = voice && voice.VoiceEntries
            ? voice.VoiceEntries
            : [];

          return voiceEntries.some((voiceEntry) => {
            const notes = voiceEntry && voiceEntry.Notes
              ? voiceEntry.Notes
              : [];

            return notes.some(
              (note) => noteIsVisibleAndPlayable(note, staff)
            );
          });
        });
      }

      function configureOsmdStaffVisibility() {
        const staves =
            osmd && osmd.Sheet && osmd.Sheet.Staves
          ? osmd.Sheet.Staves
          : [];
        const playableStaffStates = staves.map(
          staffContainsPlayableNotes
        );
        const playableStaffCount = playableStaffStates.filter(
          Boolean
        ).length;

        if (playableStaffCount === 0) {
          return {
            staffCount: staves.length,
            playableStaffCount: 0,
            hiddenStaffCount: 0
          };
        }

        if (preserveRestOnlyStaves) {
          staves.forEach((staff) => {
            staff.Visible = true;
          });

          return {
            staffCount: staves.length,
            playableStaffCount: playableStaffCount,
            hiddenStaffCount: 0
          };
        }

        let hiddenStaffCount = 0;

        staves.forEach((staff, index) => {
          const shouldBeVisible = playableStaffStates[index];

          staff.Visible = shouldBeVisible;

          if (!shouldBeVisible) {
            hiddenStaffCount++;
          }
        });

        return {
          staffCount: staves.length,
          playableStaffCount: playableStaffCount,
          hiddenStaffCount: hiddenStaffCount
        };
      }

      function sendScoreDiagnostics(staffDiagnostics) {
        ScoreDiagnostics.postMessage(
          JSON.stringify({
            removedRestOnlyPartCount:
                removedRestOnlyPartCount,
            mergedSequentialPartCount:
                mergedSequentialPartCount,
            staffCount: staffDiagnostics.staffCount,
            playableStaffCount:
                staffDiagnostics.playableStaffCount,
            hiddenStaffCount:
                staffDiagnostics.hiddenStaffCount
          })
        );
      }

      function getCurrentExpectedNotes() {
        const notes = osmd.cursor.NotesUnderCursor();
        const pitchValues = [];

        notes.forEach((note) => {
          if (!noteIsPlayable(note)) {
            return;
          }

          pitchValues.push({
            halfTone: note.Pitch.getHalfTone(),
            octave: note.Pitch.Octave,
            fundamentalNote: note.Pitch.FundamentalNote,
            midi: note.Pitch.getHalfTone() + 12
          });
        });

        return pitchValues;
      }

      function sendCurrentExpectedNotes() {
        const pitchValues = getCurrentExpectedNotes();

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

function moveCursorToPlayablePosition(positionIndex) {
  if (!osmd || !osmd.cursor) {
    return false;
  }

  const targetIndex = Math.max(
    0,
    Number(positionIndex) || 0
  );

  osmd.cursor.reset();
  osmd.cursor.show();
  osmd.cursor.update();

  let currentNotes =
      osmd.cursor.NotesUnderCursor();

  if (!currentNotes.some(noteIsPlayable)) {
    if (!advanceToNextPlayablePosition()) {
      return false;
    }
  }

  let currentIndex = 0;

  while (currentIndex < targetIndex) {
    if (!advanceToNextPlayablePosition()) {
      return false;
    }

    currentIndex++;
  }

  return true;
}

function beginWaitCursorHold(durationMilliseconds, positionIndex) {
  if (!osmd || !osmd.cursor || waitCursorTransitionPending) {
    return;
  }

  waitCursorTransitionPending = true;
  waitCursorTransitionHasNext = false;

  const cursorElement =
      osmd.cursor.cursorElement;

  if (cursorElement) {
    const safeDuration = Math.max(
      0,
      Number(durationMilliseconds) || 0
    );

    cursorElement.style.transition =
        "left " + safeDuration + "ms linear, " +
        "top " + safeDuration + "ms linear";
  }

  waitCursorTransitionHasNext =
      advanceToNextPlayablePosition();

  if (waitCursorTransitionHasNext) {
    requestAnimationFrame(keepCursorVisible);
  } else {
    if (cursorElement) {
      cursorElement.style.transition = "none";
    }

    moveCursorToPlayablePosition(positionIndex);
  }
}

function completeWaitCursorHold() {
  if (!osmd || !osmd.cursor || !waitCursorTransitionPending) {
    return;
  }

  waitCursorTransitionPending = false;
  const hasNext = waitCursorTransitionHasNext;
  waitCursorTransitionHasNext = false;

  const cursorElement =
      osmd.cursor.cursorElement;

  if (cursorElement) {
    cursorElement.style.transition = "none";
  }

  if (!hasNext) {
    osmd.cursor.hide();
    ExpectedNotes.postMessage(JSON.stringify([]));
    ScoreCompleted.postMessage("completed");
    return;
  }

  setCursorColor(normalCursorColor);
  requestAnimationFrame(keepCursorVisible);
  sendCurrentExpectedNotes();
}

function cancelWaitCursorHold(positionIndex) {
  if (!osmd || !osmd.cursor) {
    return;
  }

  waitCursorTransitionPending = false;
  waitCursorTransitionHasNext = false;

  const cursorElement =
      osmd.cursor.cursorElement;

  if (cursorElement) {
    cursorElement.style.transition =
        "left 180ms ease-out, top 180ms ease-out";
  }

  moveCursorToPlayablePosition(positionIndex);
  setCursorColor("#e53935");
  requestAnimationFrame(keepCursorVisible);
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

function completePerformanceCursor() {
  if (!osmd || !osmd.cursor) {
    return;
  }

  const cursorElement =
      osmd.cursor.cursorElement;

  if (cursorElement) {
    cursorElement.style.transition = "none";
  }

  setCursorColor(normalCursorColor);
  osmd.cursor.update();

  ExpectedNotes.postMessage(
    JSON.stringify([])
  );

  requestAnimationFrame(
    keepCursorVisible
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
        notes.some(noteIsPlayable);

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

      return notes.some(noteIsPlayable);
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

      function centerScoreVertically() {
  const viewport =
      document.getElementById(
        "sheet-viewport"
      );

  const scoreContainer =
      document.getElementById(
        "osmd-container"
      );

  const scoreSvg =
      document.querySelector(
        "#osmd-container svg"
      );

  if (!viewport || !scoreContainer || !scoreSvg) {
    return;
  }

  scoreContainer.style.boxSizing = "border-box";
  scoreContainer.style.paddingTop = "0px";
  scoreContainer.style.paddingBottom = "0px";

  const availableHeight = viewport.clientHeight;
  const scoreHeight = scoreSvg.getBoundingClientRect().height;
  const verticalSpace = Math.max(
    0,
    availableHeight - scoreHeight
  );
  const centeredPadding = verticalSpace / 2;

  scoreContainer.style.paddingTop =
      centeredPadding + "px";
  scoreContainer.style.paddingBottom =
      centeredPadding + "px";
}

      function scheduleScoreVerticalCentering() {
        if (scoreLayoutFrame !== null) {
          cancelAnimationFrame(scoreLayoutFrame);
        }

        scoreLayoutFrame = requestAnimationFrame(() => {
          scoreLayoutFrame = null;
          centerScoreVertically();
        });
      }

      function observeScoreViewport() {
        const viewport = document.getElementById(
          "sheet-viewport"
        );

        if (!viewport) {
          return;
        }

        if (typeof ResizeObserver !== "undefined") {
          scoreResizeObserver = new ResizeObserver(
            scheduleScoreVerticalCentering
          );
          scoreResizeObserver.observe(viewport);
        }

        window.addEventListener(
          "resize",
          scheduleScoreVerticalCentering
        );
        scheduleScoreVerticalCentering();
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

          const sightReadingMusicXml = preserveRestOnlyStaves
            ? musicXml
            : prepareMusicXmlForSightReading(musicXml);
          const scorePositionMetadata =
              buildScorePositionMetadata(
            sightReadingMusicXml
          );

          await osmd.load(sightReadingMusicXml);
          const staffDiagnostics = configureOsmdStaffVisibility();
          sendScoreDiagnostics(staffDiagnostics);
          osmd.Zoom = 0.9;
          osmd.render();
          fitScoreToViewportHeight();
          centerScoreVertically();
          osmd.cursor.show();
          setCursorColor(normalCursorColor);
osmd.cursor.update();
observeScoreViewport();

const totalPlayablePositions =
    countPlayablePositions();

ScoreTotal.postMessage(
  totalPlayablePositions.toString()
);

ScorePositions.postMessage(
  JSON.stringify(scorePositionMetadata)
);

const initialNotes =
    osmd.cursor.NotesUnderCursor();

const initialPositionHasNotes =
    initialNotes.some(noteIsPlayable);

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
