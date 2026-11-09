# Feature 02: Choosing the first screen

[Checklist](README.md) | [Previous](01-app-startup.md) | [Next](03-login.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/main.dart#L142' style='text-decoration:underline'>lib/main.dart:142-149</a><br/>Start checking which screen to show"]
    B["02. <a href='../../lib/main.dart#L151' style='text-decoration:underline'>lib/main.dart:151-161</a><br/>Keep the first loading screen visible for at least 3 seconds"]
    C["03. <a href='../../lib/main.dart#L163' style='text-decoration:underline'>lib/main.dart:163-170</a><br/>Check whether an account is already signed in"]
    D{"Is someone signed in?"}
    E["<a href='../../lib/screens/auth/screens/login_screen.dart#L16' style='text-decoration:underline'>lib/screens/auth/screens/login_screen.dart:16-30</a><br/>Show Login; continue with Feature 03"]
    F["<a href='../../lib/main.dart#L174' style='text-decoration:underline'>lib/main.dart:174-183</a><br/>Ask Firebase for the latest account details"]
    G{"Has the email address been verified?"}
    H["<a href='../../lib/screens/auth/screens/email_verification_screen.dart#L19' style='text-decoration:underline'>lib/screens/auth/screens/email_verification_screen.dart:19-38</a><br/>Show Email Verification; continue with Feature 05"]
    I["04. <a href='../../lib/main.dart#L185' style='text-decoration:underline'>lib/main.dart:185-186</a><br/>Refresh proof of sign-in and request the profile"]
    J["05. <a href='../../lib/screens/auth/services/registration_profile_service.dart#L11' style='text-decoration:underline'>lib/screens/auth/services/registration_profile_service.dart:11-13</a><br/>Read this user's saved profile"]
    K{"Does the user already have a profile?"}
    L["<a href='../../lib/screens/auth/services/registration_profile_service.dart#L16' style='text-decoration:underline'>lib/screens/auth/services/registration_profile_service.dart:16-51</a><br/>Create the missing profile after email verification"]
    M["06. <a href='../../lib/main.dart#L195' style='text-decoration:underline'>lib/main.dart:195-195</a><br/>Request the user's saved assessment"]
    N["07. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L75' style='text-decoration:underline'>lib/screens/assessment/services/assessment_attempt_service.dart:75-97</a><br/>Load assessment progress and handle an expired assessment"]
    O{"Is the assessment completed or expired?"}
    P["<a href='../../lib/screens/homescreen/screens/home_screen.dart#L28' style='text-decoration:underline'>lib/screens/homescreen/screens/home_screen.dart:28-35</a><br/>Show Home"]
    Q["<a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L19' style='text-decoration:underline'>lib/screens/assessment/screens/assessment_entry_screen.dart:19-42</a><br/>Show the assessment entry screen"]
    R["<a href='../../lib/main.dart#L224' style='text-decoration:underline'>lib/main.dart:224-261</a><br/>Show loading, an error, or the chosen screen"]
    S["<a href='../../lib/screens/auth/screens/auth_loading_screen.dart#L45' style='text-decoration:underline'>lib/screens/auth/screens/auth_loading_screen.dart:45-153</a><br/>Show the loading animation while the check runs"]
    T["<a href='../../lib/screens/auth/screens/auth_connection_error_screen.dart#L19' style='text-decoration:underline'>lib/screens/auth/screens/auth_connection_error_screen.dart:19-183</a><br/>Explain the connection problem and offer Retry or Sign out"]
    U["<a href='../../lib/main.dart#L206' style='text-decoration:underline'>lib/main.dart:206-210</a><br/>Try choosing the first screen again"]
    V["<a href='../../lib/main.dart#L212' style='text-decoration:underline'>lib/main.dart:212-220</a><br/>Sign out, then check the starting screen again"]
    A --> B --> C --> D
    A -. "Waits for the screen decision" .-> R
    D -- No --> E
    D -- Yes --> F
    F -- "User no longer exists" --> E
    F -- "User still exists" --> G
    G -- No --> H
    G -- Yes --> I --> J --> K
    K -- No --> L --> M
    K -- Yes --> M
    M --> N --> O
    O -- Yes --> P
    O -- No --> Q
    R -- Waiting --> S
    R -- Error --> T
    T -- Retry --> U --> C
    T -- "Sign out" --> V --> C```
