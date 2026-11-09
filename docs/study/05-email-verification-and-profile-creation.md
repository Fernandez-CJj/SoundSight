# Feature 05: Email verification and profile creation

[Checklist](README.md) | [Previous](04-registration.md) | [Next](06-assessment-questionnaire.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/auth/screens/email_verification_screen.dart#L54' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:54-67</a><br/>Prepare the email-verification screen"]
    B["02. <a href='../../lib/screens/auth/screens/email_verification_screen.dart#L635' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:635-643</a><br/>Check immediately, then check again every 5 seconds"]
    C["03. <a href='../../lib/screens/auth/screens/email_verification_screen.dart#L383' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:383-530</a><br/>Ask Firebase whether the email has been verified<br/>Also: email_verification_screen.dart:414-414"]
    D{"Has the email been verified?"}
    E["04. <a href='../../lib/screens/auth/screens/email_verification_screen.dart#L421' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:421-424</a><br/>Ask the profile service to prepare the user's profile"]
    F["05. <a href='../../lib/screens/auth/services/registration_profile_service.dart#L16' style='text-decoration:underline'>lib/screens/auth/services/registration_profile_service.dart:16-51</a><br/>Require a verified account before saving a profile<br/>Also: registration_profile_service.dart:27-50"]
    G{"Does this user already have a saved profile?"}
    H["<a href='../../lib/screens/auth/services/registration_profile_service.dart#L34' style='text-decoration:underline'>lib/screens/auth/services/registration_profile_service.dart:34-49</a><br/>Save the starting username, email, language, theme, level and XP"]
    I["Keep the existing profile"]
    J["06. <a href='../../lib/screens/auth/screens/email_verification_screen.dart#L426' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:426-435</a><br/>Read the profile and saved assessment<br/>Also: email_verification_screen.dart:434-434"]
    K["07. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L75' style='text-decoration:underline'>lib/screens/assessment/services/assessment_attempt_service.dart:75-97</a><br/>Load assessment progress"]
    L{"Is the assessment completed or expired?"}
    M["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L450' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:450-450</a><br/>Open Home"]
    N["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L453' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:453-456</a><br/>Open the assessment entry screen"]
    O["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L532' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:532-600</a><br/>Send another verification email and start the resend countdown<br/>Also: email_verification_screen.dart:616-632"]
    P["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L645' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:645-736</a><br/>Try to cancel registration and delete the unverified account"]
    Q["<a href='../../lib/screens/auth/dialogs/email_verification_dialogs.dart#L5' style='text-decoration:underline'>lib/screens/auth/dialogs/email_verification_dialogs.dart:5-26</a><br/>If a fresh sign-in is required, explain it and return to Login"]
    R["<a href='../../lib/screens/auth/dialogs/email_verification_dialogs.dart#L28' style='text-decoration:underline'>lib/screens/auth/dialogs/email_verification_dialogs.dart:28-43</a><br/>Show success, failure or cancellation messages"]
    S["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L70' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:70-75</a><br/>Stop the timers when this screen closes"]
    T["<a href='../../firestore.rules#L167' style='text-decoration:underline'>firestore.rules:167-175</a><br/>Firebase checks who may create or read this profile<br/>Also: firestore.rules:267-280"]
    U["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L78' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:78-84</a><br/>Pause checks when the app is in the background<br/>Check again when the user returns"]
    V["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L730' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:730-735</a><br/>After cancellation, return to Register"]
    W["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L393' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:393-401</a><br/>If nobody is signed in, return to Register"]
    A --> B --> C --> D
    D -- "Not yet; next timer check" --> C
    D -- Yes --> E --> F --> G
    G -- No --> H --> J
    G -- Yes --> I --> J
    H -. "Firestore enforces access rules" .-> T
    J --> K --> L
    L -- Yes --> M
    L -- No --> N
    A -- "User taps Resend" --> O
    O -. "Success or failure message" .-> R
    C -. "Check error message" .-> R
    C -- "No signed-in user" --> W
    A -- "User taps Back" --> P
    P -- "Recent authentication required" --> Q
    P -- "Other cancellation failure" --> R
    P -- "Account deleted, or no signed-in user" --> V
    A -. "App goes into background or returns" .-> U
    A -. "When widget is removed" .-> S```
