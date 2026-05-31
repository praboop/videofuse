# VideoFuse Mobile App

This directory contains the Flutter Android app for VideoFuse.

## Run

```sh
flutter run
```

## Test

```sh
flutter test
```

## Android App Identity

- App label: `VideoFuse`
- Application ID: `com.videofuse.app`
- First target: Android

## MVP Screens

- Home
- Extract Last Frame
- Stitch Videos
- Processing Progress
- Export Result

## Baseline Packages

- `file_selector`
- `permission_handler`
- `path_provider`
- `share_plus`

## Dependency Note

An FFmpeg package is intentionally not locked in yet. `ffmpeg_kit_flutter_new` forced older Android plugin dependencies that failed the debug build under the current Flutter/Android toolchain. Keep all media commands behind a processing service so Milestone 1 can choose a compatible FFmpeg adapter deliberately.
