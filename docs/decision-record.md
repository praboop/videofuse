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
