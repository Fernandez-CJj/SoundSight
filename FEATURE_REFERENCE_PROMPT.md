# Reusable Feature Reference Prompt

```text
Review how the [FEATURE NAME] feature currently works in my project.

Create a file named [FEATURE_NAME]_REFERENCE.md inside [FEATURE FOLDER].

Make the reference simple and easy for a beginner to understand, but do not leave out important details. Base everything on the current code and do not invent behavior.

Include only the sections that apply to the feature:

1. The feature's purpose.
2. The complete user flow from beginning to end.
3. What information is temporarily stored in the screen's memory.
4. When information is saved permanently.
5. The Firebase collection or document paths used.
6. Which fields are created and which existing fields are updated.
7. How the app validates the information.
8. How Firestore Rules protect the information.
9. How scores, levels, statuses, or other results are calculated.
10. How skip, resume, expiration, failure, and retry behavior work.
11. What happens after the feature is completed.
12. One simple example when it helps explain the logic.

Clearly distinguish between:

- temporary local information;
- information saved in Firebase;
- client-side validation;
- Firestore Rules validation;
- created fields and updated fields.

Use short headings, short paragraphs, and simple lists. Avoid unnecessary technical terms and large code blocks. If a technical term is necessary, explain it in plain language.

Do not modify the feature code. Only create the reference file. Do not run formatting, analysis, or tests.
```
