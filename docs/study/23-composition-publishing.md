# Feature 23: Publishing and unpublishing compositions

[Checklist](README.md) | [Previous](22-composition-file-generation.md) | [Next](24-community-compositions-and-playback.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/composition/screens/composition_details_screen.dart#L1280' style='text-decoration:underline'>lib/screens/composition/screens<br/>composition_details_screen.dart:1280-1376</a><br/>Confirm sharing, updating a shared song, or removing it from the community"]
    B["02. <a href='../../lib/screens/composition/services/composition_publish_service.dart#L120' style='text-decoration:underline'>lib/screens/composition/services<br/>composition_publish_service.dart:120-143</a><br/>Send the sharing request with proof of sign-in"]
    C["03. <a href='../../backend/composition/routes.py#L22' style='text-decoration:underline'>backend/composition<br/>routes.py:22-99</a><br/>Check the verified owner and that the song's music files are ready"]
    D["04. <a href='../../backend/composition/repositories/composition_storage_repository.py#L7' style='text-decoration:underline'>backend/composition/repositories<br/>composition_storage_repository.py:7-105</a><br/>Copy the score and audio into a separate shared version"]
    E["05. <a href='../../backend/composition/repositories/published_composition_repository.py#L6' style='text-decoration:underline'>backend/composition/repositories<br/>published_composition_repository.py:6-26</a><br/>Choose the next version number for this shared song"]
    F["06. <a href='../../backend/composition/repositories/published_composition_repository.py#L29' style='text-decoration:underline'>backend/composition/repositories<br/>published_composition_repository.py:29-141</a><br/>Save the community post and the shared version's details"]
    G["07. <a href='../../lib/screens/composition/services/composition_publish_service.dart#L145' style='text-decoration:underline'>lib/screens/composition/services<br/>composition_publish_service.dart:145-164</a><br/>Send the request to stop sharing the song"]
    H["08. <a href='../../backend/composition/services/unpublish_service.py#L5' style='text-decoration:underline'>backend/composition/services<br/>unpublish_service.py:5-60</a><br/>Remove the community post, saved versions and their shared files"]
    I["Community posts are in compositionPosts/ID<br/>Shared files are in published_compositions/owner/ID<br/>Sharing calls the API directly instead of joining the processing queue"]
    A -- Publish --> B --> C --> E --> D --> F --> I
    A -- Unpublish --> G --> H
    H -. "Remove public copy" .-> I```
