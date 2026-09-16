# VideoFuse Decision Record

This file records early product and technical decisions so implementation can proceed without re-litigating Milestone 0 choices.

## DR-001: Android-First MVP

Decision:
Build the first release for Android.

Rationale:
- Android gives the fastest practical path to a Play Store beta.
- It reduces launch overhead for a solo developer.
- Flutter keeps future iOS support open without requiring iOS release work in the MVP.

## DR-002: Narrow MVP Scope

Decision:
The first MVP includes only:
- Extract and save a first, last, or custom frame
- Stitch videos
- Export/share outputs

Rationale:
- These two utilities directly support AI creator continuity and clip assembly workflows.
- A narrow MVP reduces media-processing QA risk.
- Broader utilities can be added after export reliability is proven.

## DR-007: Frame Selection Milestone

Decision:
Treat frame selection as a complete milestone before expanding the merging workflow.

Included behavior:
- First and last frame previews.
- Cached timeline thumbnails with detected video frame rate.
- Custom frame selection with detailed surrounding frames.
- Timestamped frame saving through the Android Downloads flow.

Status:
Completed and verified on a physical Android device.

## DR-003: Flutter App Framework

Decision:
Use Flutter for the mobile app.

Rationale:
- It matches the product strategy.
- It supports fast utility-focused UI development.
- It keeps the future iOS path open.

Alternative considered:
Native Android with Kotlin.

Reason not chosen:
Native Android may provide tighter platform integration, but it would increase future cross-platform cost.

## DR-004: On-Device Processing

Decision:
Perform video processing on device for the MVP.

Rationale:
- Supports privacy-first positioning.
- Avoids cloud infrastructure cost.
- Enables offline operation.

## DR-005: Defer Monetization

Decision:
Do not implement subscriptions, ads, or watermarking in the first technical MVP.

Rationale:
- Core workflow reliability should be validated first.
- Billing and ad integrations add QA overhead.
- Trust is important for a privacy-focused utility.

## DR-006: Default Output Choices

Decision:
Use PNG for extracted frames and MP4 for stitched video exports.

Rationale:
- PNG is lossless and useful for AI continuity workflows.
- MP4 is the safest Android playback and sharing format.

## DR-008: Media3 Transformer for Merge Export

Decision:
Use AndroidX Media3 Transformer for the first production merge pipeline.

Rationale:
- It provides a native composition API for sequential multi-asset export.
- It can re-encode incompatible source media to a single MP4 instead of
  relying on unsafe sample-copy concatenation.
- It keeps processing on-device and runs the transcode asynchronously.

Output defaults:
- MP4 container
- H.264/AVC video
- AAC audio when audio is present
- 1920x1080 output canvas using Media3 `Presentation.LAYOUT_SCALE_TO_FIT`
  (aspect ratio is preserved with letterboxing)
- Transformer normalization is used when source tracks are not compatible;
  audio and video transmuxing are disabled for that path
- App-cache temporary output until the save/share milestone

Known limitations:
- Crossfades and advanced transitions are out of scope.
- Actual device support still requires physical Android playback testing.

## DR-009: Observable, Cancellable Merge Jobs

Decision:
Expose native merge progress through a Flutter event stream, cancel both native
merge paths through one active-job boundary, and run an Android foreground
`dataSync` service for the duration of an export.

Rationale:
- Long-running transcodes need an actual percentage rather than an
  indeterminate loading state.
- Users must be able to abandon either a compressed-sample merge or a Media3
  normalized export without affecting their source clips.
- A foreground service keeps the active export eligible to continue during
  ordinary backgrounding, while still respecting Android's execution policy.

Cancellation boundary:
- Fast-copy export stops before the next compressed sample is written.
- Media3 export delegates cancellation to `Transformer.cancel`.
- In both cases, the temporary output is removed and the selected clips remain
  available for retry.
