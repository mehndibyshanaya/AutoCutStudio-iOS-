# AutoCut Studio — iOS starter project

This is a native SwiftUI iPhone implementation of the supplied Windows app's core alternating-cut logic.

## Included
- Import a video from Photos using the iOS photo picker.
- Set independent keep and remove durations (0.1–30 seconds each; defaults: keep 3 seconds, remove 1 second).
- Keep-first mode: keep the configured duration, remove the configured duration, then repeat.
- Remove-first mode: remove the configured duration, keep the configured duration, then repeat.
- Preview the configured keep/remove cycle before exporting.
- Accurate on-device composition/export to MP4.
- Share/save the finished video through the iOS share sheet.
- Original input video is not modified.

## Important build facts
The supplied Windows project uses Python/PySide6 and FFmpeg. That desktop UI cannot be packaged as an iOS app. This project reimplements its cutting behavior using SwiftUI and AVFoundation.

A real iOS device build requires Apple's iOS SDK/Xcode toolchain on macOS. Since your available computer is Windows 11, the included GitHub Actions workflow builds the unsigned iPhone app on a hosted macOS runner. It packages an unsigned IPA artifact for Sideloadly to sign with your Apple ID.

## Build
1. Create a GitHub repository and upload the contents of this folder.
2. Open the repository's **Actions** tab.
3. Run **Build unsigned iOS IPA** (or push to `main`).
4. Download the `AutoCutStudio-unsigned-IPA` artifact from the workflow run.
5. Extract `AutoCutStudio-unsigned.ipa`.
6. On Windows, install Sideloadly from https://sideloadly.io/.
7. Connect the iPhone by USB, trust the computer, open Sideloadly, drag the IPA in, enter your Apple ID as required, and start sideloading.

Free Apple signing typically expires after 7 days. Sideloadly documents its auto-refresh feature; your iPhone/PC must be available over USB or configured Wi-Fi for refresh.

## Current limitations / testing needed
- This is a first native implementation, not yet device-tested.
- Very large videos may require substantial temporary storage and memory because PhotosPicker transfers a local copy.
- The current version supports configurable alternating keep/remove durations; it does not include a visual timeline, manual trim handles, batch processing, or background export.
- Verify export with portrait, landscape, HDR, slow-motion, and videos with/without audio before relying on it for client work.
- Always keep the original video as backup.
