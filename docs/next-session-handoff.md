# Next-session handoff

Use this file as the compact starting context for the next coding session.

## Current product state

- Android-first Flutter app: VideoFuse.
- Frame-selection milestone is complete.
- The next focus is merging multiple videos into one ordered MP4.
- Source media stays on-device; no account, backend, or upload flow exists.

## Important project paths

- `mobile-app/lib/main.dart` — app screens and frame-selection UI.
- `mobile-app/lib/processing_service.dart` — Flutter method-channel processing API and in-memory thumbnail cache.
- `mobile-app/android/app/src/main/kotlin/com/videofuse/app/MainActivity.kt` — Android processing implementation.
- `mobile-app/android/app/build.gradle.kts` — Android dependencies, including Media3 frame inspection.
- `docs/milestone-2-video-merging.md` — merging goal and acceptance criteria.
- `core-processing/README.md` — processing conventions and output expectations.

## Existing processing behavior

- Coarse cache previews are created on Android's background processing executor
  through `MediaMetadataRetriever` with nearest-sync seeking. This uses the
  platform codec (normally hardware accelerated where the device supports the
  source codec); it does not move video bytes or decode work into Dart.
- The custom-frame grid is cache-only after the cache exists: it selects the
  nearest cached tile for highlighting instead of inserting an uncached slider
  timestamp and waiting for a decoder seek.
- Frame cache is in memory and keyed by source path plus timestamp.
- Detailed surrounding previews use one native contiguous 61-frame
  `getFramesAtIndex` request (30 before and after), scaled to 240x135. Devices
  below API 28, or decoder failures, fall back to timestamp seeking. Exact frame
  decoding happens only when saving a selected frame, at original resolution.
- Extracted frames are saved through Android Downloads using the method channel.
- Frame saves use full-resolution `MediaMetadataRetriever.getFrameAtTime`; the
  UI preview may scale the image, but the exported PNG does not.
- Video selection uses the native Android `ACTION_OPEN_DOCUMENT` bridge and returns
  persisted content URIs plus metadata; do not reintroduce `file_selector`, which
  serializes the entire selected file as bytes through Flutter.
- Stitching is exposed as `ProcessingService.stitchVideos(...)` and native `stitchVideos(...)`, but it still needs a production-quality implementation.

## Current baseline and known build note

- The cache/detail regression was fixed: the grid no longer seeks for an
  uncached slider timestamp, and the detail strip uses a contiguous native
  frame request with a timestamp-seek fallback.
- A Kotlin logging-line quoting error reported by VS Code was corrected in
  `MainActivity.kt`; the cascading unresolved-reference errors came from that
  parser failure. The Built-in Kotlin migration message is only a deprecation
  warning.
- `flutter analyze` and `flutter test` pass. After pulling this handoff into a
  new session, rebuild the Android APK before testing on the phone.

## Frame-performance diagnostics

- Flutter logs are timestamped as `[VideoFuse][ISO-8601][Processing|Grid|Detail]`.
  They report cache hit/miss counts, native request start/completion, stale UI
  results, frame counts, selected frame index, and elapsed milliseconds.
- Android logs use the `VideoFuse` tag and include elapsed realtime timestamps,
  request parameters, contiguous-frame metadata/counts, and any fallback cause.
- To capture a run: `adb logcat -v threadtime -s VideoFuse:D flutter:D *:S`.

## Next implementation tasks

1. Start with `docs/milestone-2-video-merging.md` and audit the current native
   stitch implementation before changing the UI.
2. Replace the prototype merge path with a reliable ordered merge implementation.
3. Handle differing codecs, resolutions, orientations, frame rates, and audio tracks.
4. Keep processing off the UI thread and report progress/cancellation.
5. Preserve the reorder shown in the Stitch Videos screen and export a playable MP4.
6. Add save/share completion handling and test two/three clips, mixed media
   properties, audio, and failed/unsupported input.

## Verification commands

```powershell
cd mobile-app
flutter pub get
flutter analyze
flutter test
flutter run
```

Build/install an APK:

```powershell
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If Gradle cannot find Java, configure Android Studio's bundled JDK as `JAVA_HOME`.

## Documentation rule

Update `docs/milestone-2-video-merging.md`, `README.md`, and the decision/core-processing
notes when merging behavior or output guarantees change.
