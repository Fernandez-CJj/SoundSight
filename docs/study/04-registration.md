# Feature 04: Registration

[Checklist](README.md) | [Previous](03-login.md) | [Next](05-email-verification-and-profile-creation.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/auth/screens/register_screen.dart#L36' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:36-74</a><br/>Build the registration screen"]
    B["02. <a href='../../lib/screens/auth/widgets/register_form.dart#L9' style='text-decoration:underline'>lib/screens/auth/widgets/register_form.dart:9-351</a><br/>Collect username, email, password and password confirmation"]
    C["<a href='../../lib/screens/auth/widgets/app_text_form_field.dart#L27' style='text-decoration:underline'>lib/screens/auth/widgets/app_text_form_field.dart:27-94</a><br/>Show reusable text boxes and check the entered details<br/>Also: register_form.dart:98-103, register_form.dart:111-121, register_form.dart:129-151, register_form.dart:191-201"]
    D["03. <a href='../../lib/screens/auth/widgets/register_form.dart#L284' style='text-decoration:underline'>lib/screens/auth/widgets/register_form.dart:284-284</a><br/>Run registration when Create Account is tapped"]
    E["04. <a href='../../lib/screens/auth/screens/register_screen.dart#L62' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:62-66</a><br/>Check the form and required agreement before continuing<br/>Also: register_screen.dart:85-173"]
    F["05. <a href='../../lib/screens/auth/dialogs/register_dialogs.dart#L76' style='text-decoration:underline'>lib/screens/auth/dialogs/register_dialogs.dart:76-175</a><br/>Ask the user to confirm, then show the creating-account message<br/>Also: register_dialogs.dart:332-381"]
    G["06. <a href='../../lib/screens/auth/screens/register_screen.dart#L175' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:175-220</a><br/>Create the account, or resume an eligible unverified registration"]
    H["07. <a href='../../lib/screens/auth/screens/register_screen.dart#L92' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:92-95</a><br/>Save the username and send the verification email<br/>Also: register_screen.dart:95-95"]
    I["08. <a href='../../lib/screens/auth/screens/register_screen.dart#L131' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:131-138</a><br/>Open Email Verification; continue with Feature 05"]
    J["<a href='../../lib/screens/auth/dialogs/register_dialogs.dart#L258' style='text-decoration:underline'>lib/screens/auth/dialogs/register_dialogs.dart:258-330</a><br/>Explain why registration failed"]
    K["<a href='../../lib/screens/auth/screens/register_screen.dart#L96' style='text-decoration:underline'>lib/screens/auth/screens/register_screen.dart:96-122</a><br/>If the email could not be sent, sign out so the account can be retried later"]
    L["<a href='../../lib/screens/auth/dialogs/register_dialogs.dart#L7' style='text-decoration:underline'>lib/screens/auth/dialogs/register_dialogs.dart:7-74</a><br/>Ask the user to accept the required agreement"]
    M["<a href='../../lib/screens/auth/dialogs/register_dialogs.dart#L383' style='text-decoration:underline'>lib/screens/auth/dialogs/register_dialogs.dart:383-408</a><br/>Show the Terms or Privacy Policy<br/>Also: register_dialogs.dart:410-436"]
    A --> B
    B -. "Builds inputs" .-> C
    B --> D --> E
    E -- "Valid and agreed" --> F
    E -- "Agreement missing" --> L
    F -- Confirm --> G --> H
    SUCCESS["<a href='../../lib/screens/auth/dialogs/register_dialogs.dart#L177' style='text-decoration:underline'>lib/screens/auth/dialogs/register_dialogs.dart:177-256</a><br/>Show that the account was created, then continue to email verification"]
    H -- "Email sent" --> SUCCESS --> I
    H -- "Email sending failed" --> K --> J
    G -- "Account creation failed" --> J
    B -. "Terms or Privacy links" .-> M```
