# Project study checklist

**Current:** Feature 20 - Manual composition.

**Next:** Feature 21 - Recorded composition, after manual-composition questions are resolved.

Features 06, 07, 10, 12, 13 and 18 are skipped for now and remain unchecked.

Each feature has **one diagram in one file**, with code links and start/end line ranges.
Open a feature and press **Ctrl+Shift+V** in VS Code. Click the underlined file path inside a diagram box to open the code.
All files stay directly in `docs/study/`. Use Previous and Next to move between features.

## Features

- [x] [01. App startup](01-app-startup.md)
- [x] [02. Choosing the first screen](02-initial-screen-selection.md)
- [x] [03. Login](03-login.md)
- [x] [04. Registration](04-registration.md)
- [x] [05. Email verification and profile creation](05-email-verification-and-profile-creation.md)
- [ ] [06. Assessment start and questionnaire](06-assessment-questionnaire.md)
- [ ] [07. Note reading, piano assessment and results](07-assessment-notation-piano-and-results.md)
- [x] [08. Home and navigation](08-home-and-navigation.md)
- [x] [09. Feature tutorials](09-feature-tutorials.md)
- [ ] [10. Profile and editing](10-profile-editing.md)
- [x] [11. Appearance, language and logout](11-appearance-language-and-logout.md)
- [ ] [12. Sheet selection and preview](12-sheet-selection-and-preview.md)
- [ ] [13. Saving uploaded sheets](13-sheet-upload-and-saving.md)
- [x] [14. Submitting sheet-recognition requests](14-sheet-recognition-requests.md)
- [x] [15. Recognizing sheets and saving results](15-sheet-recognition-processing.md)
- [x] [16. Audio and video uploads](16-audio-and-video-uploads.md)
- [x] [17. Audio transcription](17-audio-transcription.md)
- [ ] [18. Music-sheet collection and viewer](18-sheet-collection-and-viewer.md)
- [x] [19. Music library](19-music-library.md)
- [ ] [20. Manual composition](20-manual-composition.md)
- [ ] [21. Recorded composition](21-recorded-composition.md)
- [ ] [22. Composition file generation](22-composition-file-generation.md)
- [ ] [23. Publishing and unpublishing compositions](23-composition-publishing.md)
- [ ] [24. Community compositions and playback](24-community-compositions-and-playback.md)
- [ ] [25. MIDI connection](25-midi-connection.md)
- [ ] [26. Finding piano keys with the camera](26-piano-key-detection.md)
- [ ] [27. Matching notes to keys and saving the piano setup](27-piano-key-mapping-and-saving.md)
- [ ] [28. Choosing a practice mode](28-practice-mode-selection.md)
- [ ] [29. Sight Reading](29-sight-reading.md)
- [ ] [30. Synthesia](30-synthesia.md)
- [ ] [31. AR practice](31-ar-practice.md)
- [ ] [32. Flyaway practice](32-flyaway-practice.md)
- [ ] [33. Lessons and progress](33-lessons-and-progress.md)
- [ ] [34. Practice results](34-practice-results.md)
- [ ] [35. Achievements and badges](35-achievements-and-badges.md)
- [ ] [36. Setting up processing notifications](36-notification-device-registration.md)
- [ ] [37. Processing-result notifications](37-processing-result-notifications.md)
- [ ] [38. Admin application](38-admin-application.md)
- [ ] [39. Landing website](39-landing-website.md)

## Code-review format

1. Follow the diagram's order, including calls into other files and returns to the caller.
2. Explain each code group in simple words: what starts it, what it does, and what happens next.
3. Include the packages, saved data and relevant error handling.
4. Give a short explanation to say during the review.

Revisit shared files whenever needed. Finish one feature before moving on.
