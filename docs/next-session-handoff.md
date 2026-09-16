# Next-session handoff

Use this file as the compact starting context for the next coding session.

## Current product state

- Android-first Flutter app: VideoFuse.
- Frame selection and Milestone 2 — Video Merging are complete.
- Merge Videos supports persisted Android document URIs; add, remove, reorder,
  and select clips; three representative previews; media inspection;
  output-resolution choices; real progress; cancellation; foreground background
  handling; editable Downloads filenames; save; and share.
- Compatible same-resolution clips selected as `Same as source` use the
  compressed-sample fast path. Other exports use AndroidX Media3 Transformer
  normalization with preserved audio and fit-to-frame presentation.
- The merge, save, and linear-progress UI flow was verified on a physical
  Android device on 2026-09-16.
- Source media stays on-device; no account, backend, or upload flow exists.

## Important project paths

- `mobile-app/lib/main.dart` — app bootstrap, routing, and home UI.
- `mobile-app/lib/frame_selection_screen.dart` — frame-selection screen.
- `mobile-app/lib/frame_selection_widgets.dart` — frame preview widgets and time input formatter.
- `mobile-app/lib/merge_videos_screen.dart` — Merge Videos selection, export, and result UI.
- `mobile-app/lib/models/selected_video.dart` — shared selected-video model.
- `mobile-app/lib/services/processing_service.dart` — Flutter method/Event-channel processing API and thumbnail cache.
- `mobile-app/android/app/src/main/kotlin/com/videofuse/app/MainActivity.kt` — Android media processing implementation.
- `mobile-app/android/app/src/main/kotlin/com/videofuse/app/MergeForegroundService.kt` — foreground export notification service.
- `mobile-app/android/app/build.gradle.kts` — Android and Media3 dependencies.
- `docs/milestone-2-video-merging.md` — completed merge-milestone record.
- `docs/milestone-3-video-editor.md` — next milestone scope and acceptance criteria.
- `core-processing/README.md` — processing conventions and output expectations.

## Start here: Milestone 3 — Video Editor

Video Editor is its own pipeline, not a merge-result-only feature. Begin with
submilestone 3.1 by adding a home-screen `Edit video` action that opens the
native picker for one existing video, plus a shared editor route that also
accepts a completed merge output. The first implementation should provide:

1. A video player with play/pause, elapsed/total time, and a draggable timeline scrubber.
2. Playback-rate control (0.25x, 0.5x, 1x, 1.5x, 2x), normal seek jumps, and
   previous/next decoded-frame controls while paused.
3. Double-tap video fullscreen toggle, plus explicit accessible controls.
4. Two inputs to the same editor route: a selected source URI or a completed
   merge output. Neither input may be changed in place; export produces a new
   MP4.

Do not implement range editing, ripple delete, copy/paste, undo/redo, or edited
export until submilestone 3.1 playback is usable and verified. Those belong to
submilestones 3.2–3.4 in `docs/milestone-3-video-editor.md`.

## Existing processing notes

- Video selection uses native `ACTION_OPEN_DOCUMENT` and persisted `content://`
  URIs. Do not reintroduce byte-based Flutter file picking.
- Merge thumbnails use Android `MediaMetadataRetriever`; the detailed
  frame-selection strip uses one contiguous native 61-frame request where
  supported, with timestamp-seek fallback.
- Merge progress is delivered through a native EventChannel. Fast copy reports
  processed-duration progress; Media3 reports `Transformer.getProgress`.
- Native merge cancellation cleans up temporary output. The foreground `dataSync`
  service runs while export is active.

## Baseline and verification

- `flutter analyze` and `flutter test` pass.
- Android debug Kotlin compilation passes.
- Rebuild the Android APK before phone testing. If Gradle cannot find Java,
  configure Android Studio's bundled JDK as `JAVA_HOME`.

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

## Documentation rule

Update `docs/milestone-3-video-editor.md`, `README.md`, and the decision/core-processing
notes when editor behavior, editing guarantees, or export behavior changes.
