# VideoFuse

VideoFuse is a lightweight, privacy-focused mobile utility app for AI video creators.

The first Android MVP is intentionally narrow:
- Extract and save a selected frame from a video
- Stitch multiple videos into one MP4 export

See [`videofuse_product_strategy_and_mvp_plan.md`](videofuse_product_strategy_and_mvp_plan.md) for product strategy and the detailed milestone plan.

## Repository Structure

```text
/videofuse
  /mobile-app        Flutter Android app workspace
  /core-processing   Processing notes and reusable command specs
  /docs              Product, architecture, and delivery documentation
  /assets            App/store asset source files
  /design            Design notes, tokens, and UI references
```

## Current Status

Milestone 0 (foundation) and the frame-selection milestone are complete.
The next development focus is the video merging/stitching workflow.

For a compact implementation handoff when starting a new coding session, see
[`docs/next-session-handoff.md`](docs/next-session-handoff.md).

The Flutter Android app has been scaffolded in `/mobile-app`.

Run the app with:

```sh
cd mobile-app
flutter run
```

Run tests with:

```sh
cd mobile-app
flutter test
```

Build the Android debug APK with:

```sh
cd mobile-app
flutter build apk --debug
```

## MVP Development Defaults

- Platform: Android first
- App framework: Flutter
- Processing: on-device FFmpeg-based processing
- Backend: none for MVP
- Account/login: none for MVP
- Monetization: deferred until core workflows are validated
- First release channel: Play Store closed beta before public launch
