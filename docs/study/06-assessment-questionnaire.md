# Feature 06: Assessment start and questionnaire

[Checklist](README.md) | [Previous](05-email-verification-and-profile-creation.md) | [Next](07-assessment-notation-piano-and-results.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L62' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:62-153</a><br/>Use supplied progress or load it<br/>When the user starts or resumes, call the service<br/>Button action: assessment_entry_screen.dart:858-872"]
    B["02. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L44' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:44-69</a><br/>Create the first attempt or return the saved one<br/>Creation and 3-day deadline: assessment_attempt_service.dart:525-583"]
    C["03. <a href='../../lib/screens/assessment/models/assessment_attempt.dart#L69' style='text-decoration:underline'>lib/screens/assessment/models<br/>assessment_attempt.dart:69-200</a><br/>Read the saved section, answers, deadline and results"]
    ROUTE["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L518' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:518-570</a><br/>Open the saved section; Resume skips finished sections"]
    D["04. <a href='../../lib/screens/assessment/screens/assessment_introduction_screen.dart#L49' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_introduction_screen.dart:49-110</a><br/>Show instructions and count down the remaining time<br/>Continue button: assessment_introduction_screen.dart:242-260"]
    CONTINUE["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L157' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:157-209</a><br/>Continue calls back to the entry screen<br/>Ask the service to save the questionnaire section"]
    E["05. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L103' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:103-142</a><br/>Remember that the user reached the questionnaire"]
    F["06. <a href='../../lib/screens/assessment/screens/assessment_questionnaire_screen.dart#L49' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_questionnaire_screen.dart:49-127</a><br/>Restore supplied answers, check every answer, then call onSubmit<br/>Selections stay in memory until submitted: assessment_questionnaire_screen.dart:256-266"]
    G["07. <a href='../../lib/screens/assessment/models/assessment_questionnaire.dart#L2' style='text-decoration:underline'>lib/screens/assessment/models<br/>assessment_questionnaire.dart:2-135</a><br/>Define the four questions and answer options<br/>Beginner condition: new to piano OR unfamiliar with sheet music"]
    CALLBACK["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L215' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:215-291</a><br/>Receive submitted answers and choose the next step"]
    ELIGIBLE{"Do the answers match the Beginner condition?"}
    CONFIRM["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L294' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:294-368</a><br/>Ask the user to accept Beginner placement or review answers"]
    H{"Did the user accept the Beginner placement option?"}
    I["08. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L203' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:203-256</a><br/>Finish the assessment with Beginner placement"]
    J["09. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L148' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:148-199</a><br/>Save the answers and continue to reading notes"]
    K["Save progress in users/UID/assessment/current<br/>An expired attempt is finalized instead of starting over"]
    COMMIT["<a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L437' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:437-465</a><br/>Save completion, award the first-assessment badge<br/>Update profile skill level only if it improves"]
    RESULTS["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L237' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:237-256</a><br/>After saving Beginner completion, open Results"]
    NOTES["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L259' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:259-278</a><br/>After saving the questionnaire, open note reading<br/>Continue with Feature 07"]
    LATER["Resume the saved note-reading or piano section<br/>Continue with Feature 07"]
    FINAL["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L858' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:858-872</a><br/>A completed attempt opens Results<br/>An expired attempt continues to Home"]
    A -- "Start or Resume" --> B
    A -- "Already completed or expired" --> FINAL
    B -. "Read the saved assessment details" .-> C
    B --> ROUTE
    ROUTE -- Introduction --> D --> CONTINUE --> E
    E -- "Return saved attempt; entry opens questionnaire" --> F
    ROUTE -- Questionnaire --> F
    ROUTE -- "Note reading or piano" --> LATER
    F -. "Read the available questions" .-> G
    F -- "Valid answers: onSubmit" --> CALLBACK --> ELIGIBLE
    ELIGIBLE -- Yes --> CONFIRM --> H
    ELIGIBLE -- No --> J
    H -- Yes --> I --> COMMIT --> RESULTS
    H -- "No; review answers" --> F
    J --> NOTES
    B -. "Save progress" .-> K
    I -. "Save completion" .-> K
    J -. "Save the answers" .-> K```
