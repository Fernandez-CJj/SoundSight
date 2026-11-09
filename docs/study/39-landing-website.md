# Feature 39: Landing website

[Checklist](README.md) | [Previous](38-admin-application.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../landing-page/index.html#L34' style='text-decoration:underline'>landing-page<br/>index.html:34-44</a><br/>Show the website menu and page sections"]
    B["02. <a href='../../landing-page/styles.css#L2' style='text-decoration:underline'>landing-page<br/>styles.css:2-23</a><br/>Style the page for different screen sizes"]
    C["03. <a href='../../landing-page/config.js#L2' style='text-decoration:underline'>landing-page<br/>config.js:2-8</a><br/>Keep the app download link, version, Android requirement, size and checksum"]
    D["04. <a href='../../landing-page/script.js#L4' style='text-decoration:underline'>landing-page<br/>script.js:4-4</a><br/>Show the app version and download details on the page"]
    E["05. <a href='../../landing-page/index.html#L42' style='text-decoration:underline'>landing-page<br/>index.html:42-42</a><br/>The visitor clicks Download"]
    F["06. <a href='../../landing-page/script.js#L16' style='text-decoration:underline'>landing-page<br/>script.js:16-24</a><br/>Open the download window and remember which button was used"]
    G["07. <a href='../../landing-page/index.html#L239' style='text-decoration:underline'>landing-page<br/>index.html:239-248</a><br/>Show download information and the installation guide link"]
    H["08. <a href='../../landing-page/script.js#L57' style='text-decoration:underline'>landing-page<br/>script.js:57-57</a><br/>Check that the configured download link uses HTTPS"]
    I{"Is there a valid download link?"}
    J["09. <a href='../../landing-page/script.js#L62' style='text-decoration:underline'>landing-page<br/>script.js:62-62</a><br/>Make the app download link available"]
    K["Download the APK from the configured GitHub release<br/>The user follows the Android installation instructions"]
    L["Keep downloading unavailable and show installation guidance"]
    M["10. <a href='../../landing-page/script.js#L25' style='text-decoration:underline'>landing-page<br/>script.js:25-32</a><br/>Close the download window and return keyboard focus"]
    N["11. <a href='../../landing-page/script.js#L74' style='text-decoration:underline'>landing-page<br/>script.js:74-84</a><br/>Update the menu as the visitor scrolls through page sections"]
    O["12. <a href='../../landing-page/script.js#L148' style='text-decoration:underline'>landing-page<br/>script.js:148-167</a><br/>Animate sections as they appear, unless reduced motion is preferred"]
    P["This is an HTML, CSS and JavaScript website<br/>Browsing it and downloading the app do not need the Python backend"]
    A --> D
    B -. "Page styling" .-> A
    C --> D
    D --> H --> I
    I -- Yes --> J
    I -- No --> L
    A --> E --> F --> G
    G -- "Enabled download link" --> J --> K
    G -- Close --> M
    A -. "Scrolling" .-> N
    A -. "Scrolling" .-> O
    A -. "How the website runs" .-> P```
