# Feature 03: Login

[Checklist](README.md) | [Previous](02-initial-screen-selection.md) | [Next](04-registration.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/auth/screens/login_screen.dart#L58' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:58-82</a><br/>Build the login screen"]
    B["02. <a href='../../lib/screens/auth/widgets/auth_screen_layout.dart#L12' style='text-decoration:underline'>lib/screens/auth/widgets/auth_screen_layout.dart:12-52</a><br/>Arrange the shared background and login layout"]
    C["03. <a href='../../lib/screens/auth/widgets/login_form.dart#L9' style='text-decoration:underline'>lib/screens/auth/widgets/login_form.dart:9-208</a><br/>Collect and check the email and password<br/>Also: login_form.dart:87-97, login_form.dart:105-115"]
    D["04. <a href='../../lib/screens/auth/widgets/app_text_form_field.dart#L27' style='text-decoration:underline'>lib/screens/auth/widgets/app_text_form_field.dart:27-94</a><br/>Show reusable text boxes"]
    E["05. <a href='../../lib/screens/auth/widgets/login_form.dart#L132' style='text-decoration:underline'>lib/screens/auth/widgets/login_form.dart:132-132</a><br/>Run the login action when the button is tapped"]
    F["06. <a href='../../lib/screens/auth/screens/login_screen.dart#L70' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:70-74</a><br/>Check the entered details, then start signing in<br/>Also: login_screen.dart:86-256"]
    G["<a href='../../lib/screens/auth/dialogs/login_dialogs.dart#L7' style='text-decoration:underline'>lib/screens/auth/dialogs/login_dialogs.dart:7-56</a><br/>Show the signing-in message"]
    H["07. <a href='../../lib/screens/auth/screens/login_screen.dart#L91' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:91-97</a><br/>Sign in through Firebase and refresh the account details<br/>Also: login_screen.dart:97-97"]
    I{"<a href='../../lib/screens/auth/screens/login_screen.dart#L105' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:105-127</a><br/>Has the email address been verified?"}
    J["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L19' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:19-38</a><br/>Open Email Verification; continue with Feature 05"]
    K["08. <a href='../../lib/screens/auth/screens/login_screen.dart#L129' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:129-144</a><br/>Refresh sign-in proof, load or create the profile, then restore the language<br/>Also: login_screen.dart:133-136"]
    L["<a href='../../lib/screens/auth/services/registration_profile_service.dart#L11' style='text-decoration:underline'>lib/screens/auth/services/registration_profile_service.dart:11-13</a><br/>Read or create the user's profile<br/>Also: registration_profile_service.dart:16-51"]
    M["09. <a href='../../lib/screens/auth/screens/login_screen.dart#L147' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:147-164</a><br/>Load assessment progress and use the saved settings"]
    N{"Is the assessment completed or expired?"}
    O["<a href='../../lib/screens/auth/screens/login_screen.dart#L170' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:170-170</a><br/>Open Home"]
    P["<a href='../../lib/screens/auth/screens/login_screen.dart#L175' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:175-178</a><br/>Open the assessment entry screen"]
    Q["<a href='../../lib/screens/auth/dialogs/login_dialogs.dart#L58' style='text-decoration:underline'>lib/screens/auth/dialogs/login_dialogs.dart:58-132</a><br/>Explain why signing in or preparing the account failed"]
    R["<a href='../../lib/screens/auth/screens/register_screen.dart#L36' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:36-74</a><br/>Open Registration; continue with Feature 04"]
    A --> B --> C
    C -. "Builds inputs" .-> D
    C --> E --> F --> G --> H --> I
    I -- No --> J
    I -- Yes --> K
    K -. "Load or create the profile" .-> L
    K --> M --> N
    N -- Yes --> O
    N -- No --> P
    CLEAN["<a href='../../lib/screens/auth/screens/login_screen.dart#L258' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:258-270</a><br/>If sign-in succeeded but account setup failed, sign out before showing the error"]
    H -- "Sign-in failed" --> CLEAN
    K -- "Could not finish preparing the account" --> CLEAN
    M -- "Could not finish preparing the account" --> CLEAN
    CLEAN --> Q
    C -- "Register link:191 → login_screen.dart:75" --> R```
