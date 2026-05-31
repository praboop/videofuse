# VideoFuse — Product Strategy & MVP Plan

## Brand
**Product Name:** VideoFuse

## Positioning
VideoFuse is a lightweight, fast, privacy-focused mobile utility app designed for AI creators and video workflow users.

Unlike heavy video editors, VideoFuse focuses on:
- fast utility workflows
- minimal UI friction
- no bloated editing experience
- AI workflow support
- quick media operations
- batch processing

Core philosophy:
> "Do small video workflow tasks extremely well."

---

# Target Users

## Primary Audience
AI-assisted content creators using tools like:
- Runway
- Pika
- Veo
- Kling
- Stable Diffusion video workflows
- AI-generated short clips

## Secondary Audience
General users needing lightweight utilities:
- social media creators
- YouTube Shorts creators
- TikTok creators
- Instagram Reels creators
- meme creators
- students
- small businesses

---

# Core Differentiators

VideoFuse should differentiate itself from apps like CapCut by focusing on:

- lightweight experience
- minimal ads or no ads
- extremely fast workflows
- offline-first operations
- no account required initially
- privacy-friendly processing
- batch utilities
- workflow simplicity
- low-cost subscription

VideoFuse is NOT trying to become a full video editor.

Avoid:
- complex timelines
- advanced cinematic editing
- social feed integration
- template marketplace
- creator social network features

---

# Initial MVP Goal

The MVP should solve 3 very common AI creator workflow problems:

1. Extract last frame from videos
2. Stitch multiple clips together quickly
3. Batch process media operations

The app should feel:
- instant
- simple
- reliable
- utility-focused

---

# MVP Functionalities

## 1. Extract Last Frame

### Description
Extract the last frame from one or multiple videos.

### Use Cases
- AI continuity workflows
- thumbnail generation
- storyboard preparation
- frame reference extraction
- scene continuation

### Inputs
- single video
- multiple videos

### Outputs
- PNG/JPEG images
- optional ZIP export

### MVP Requirements
- fast extraction
- preserve quality
- batch mode
- save to gallery
- share/export

---

## 2. Stitch Multiple Videos

### Description
Merge multiple clips into one video.

### Use Cases
- combining AI-generated clips
- quick social uploads
- assembling generated scenes
- batch clip compilation

### MVP Requirements
- preserve order
- drag-and-drop reorder
- no watermark in paid version
- fast export
- optional resize
- optional fps normalization

### Supported Formats
- MP4
- MOV

---

## 3. Extract All Frames

### Description
Extract every frame or periodic frames from a video.

### Use Cases
- AI dataset creation
- frame analysis
- animation workflows
- training datasets

### MVP Requirements
- configurable interval
- batch extraction
- ZIP packaging

---

## 4. Basic Resize Utility

### Description
Resize videos for different social platforms.

### Presets
- TikTok/Reels (9:16)
- YouTube (16:9)
- Square (1:1)

### MVP Requirements
- quick presets
- maintain aspect ratio
- minimal UI

---

## 5. Remove Audio

### Description
Remove audio track from videos.

### Use Cases
- AI remix workflows
- clean exports
- silent clip generation

---

## 6. Reverse Video

### Description
Reverse video clips quickly.

### Use Cases
- meme creation
- looping workflows
- transition generation

---

## 7. Loop Video Generator

### Description
Generate loop-ready clips.

### Use Cases
- AI looping animations
- background loops
- GIF-like workflows

---

# Free vs Paid Tier Strategy

## Free Tier

The free version must be genuinely useful.

### Included
- extract last frame
- stitch up to 5 clips
- limited exports/day
- basic quality export

### Future Free Utility Candidates
- basic resize
- remove audio

### Limitations
- daily export limit
- slower batch queue
- optional lightweight ads
- watermark on stitched videos

### Important
Avoid aggressive ads.
Do NOT destroy UX.

---

## Paid Tier — VideoFuse Pro

### Suggested Pricing
- $1.99/month
OR
- $14.99 lifetime purchase

### Included
- unlimited exports
- batch processing
- no watermark
- faster processing
- HD exports
- all utility tools
- future AI workflow tools
- priority new features

---

# Potential Future Premium Features

These should NOT be part of MVP.

## AI Workflow Features
- continuity frame extraction
- smart scene detection
- auto clip ordering
- AI caption generation
- auto transition generation
- prompt-to-sequence helpers

## Advanced Utility Features
- frame interpolation
- GIF generation
- video-to-image dataset export
- background removal
- auto crop
- audio extraction
- subtitle burn-in

## Cloud Features
- sync projects
- cloud processing
- shareable workflow presets

---

# UX Philosophy

The UX should feel:
- minimal
- instant
- focused
- modern
- not cluttered

Avoid:
- excessive animations
- complex editing paradigms
- onboarding friction
- mandatory login

Ideal workflow:
1. Open app
2. Select utility
3. Choose files
4. Export

Target: under 30 seconds for most operations.

---

# Technical Recommendations

## Frontend
Recommended:
- Flutter

Reason:
- cross-platform
- fast UI
- Android + iOS support
- strong media ecosystem

---

## Processing
Prefer on-device processing initially.

Benefits:
- low infrastructure cost
- privacy
- offline support
- scalability

Potential tools:
- FFmpeg
- ffmpeg-kit

---

# Suggested Architecture

## Mobile App
- Flutter frontend
- FFmpeg processing layer
- local storage management
- gallery/file picker integration

## Optional Future Backend
Only if needed later:
- user sync
- subscriptions
- cloud rendering
- analytics

---

# Monetization Philosophy

VideoFuse should avoid:
- ad-heavy monetization
- deceptive UX
- forced signups
- fake premium traps

Goal:
Create a trustworthy utility tool users keep installed long-term.

---

# App Store Positioning

## Keywords
- video stitcher
- frame extractor
- AI video tools
- clip merger
- batch video tools
- video utility
- creator tools
- AI workflow tools

---

# Suggested GitHub Structure

```text
/videofuse
  /mobile-app
  /core-processing
  /docs
  /assets
  /design
```

---

# Development Roadmap

## Phase 1 — MVP
- extract last frame
- stitch videos
- export/share

Goal:
Publish functional Play Store release quickly.

---

## Phase 2 — Creator Utilities
- reverse video
- loop generator
- extract all frames
- batch workflows

---

## Phase 3 — AI Workflow Tools
- continuity workflows
- smart extraction
- scene analysis
- AI helper features

---

# Detailed Android-First Development Plan

## Planning Decisions

Confirmed MVP scope:
- Extract last frame from video
- Stitch multiple videos into one export
- Android-first release
- Solo lean build

Recommendation:
Start with only these two core utilities for the first Play Store release.

Rationale:
- They directly serve the strongest AI creator workflow from the strategy: generating continuity frames and combining generated clips.
- They are easier to explain in store positioning than a broad utility bundle.
- They reduce implementation, QA, export-format, and permission risk for a solo developer.
- They create a clean foundation for later batch processing, resize, remove audio, reverse, loop, and extract-all-frames tools.

---

## Recommended Technical Direction

### App Framework
Use Flutter for the Android MVP.

Rationale:
- The existing strategy already recommends Flutter.
- It keeps the door open for iOS without forcing iOS release work into the MVP.
- Flutter is strong for fast utility-style screens, progress states, file selection flows, and future cross-platform expansion.

Alternative:
Native Android with Kotlin.

Why not recommended for MVP:
- It may provide tighter Android media integration, but it slows future iOS expansion and increases the chance of rebuilding UI patterns later.

### Video Processing
Use on-device FFmpeg-based processing behind a small internal processing service.

Rationale:
- It matches the privacy-first and offline-first positioning.
- It avoids backend cost and upload latency.
- It supports both required MVP workflows: frame extraction and concatenation.

Implementation note:
The processing layer should be isolated behind app-level methods such as `extractLastFrame()` and `stitchVideos()` so the app can later swap FFmpeg packages or add native implementations without rewriting the UI.

### Storage and Export
Use Android file picker/gallery access for input, app-local temporary storage during processing, and Android share/save flows for output.

Rationale:
- This keeps the app account-free and simple.
- Temporary working files prevent accidental source-file modification.
- Native share/save flows match user expectations for a utility app.

### Monetization for MVP
Do not implement subscriptions, ads, or watermarking in the first technical MVP.

Rationale:
- The immediate goal should be validating workflow usefulness and export reliability.
- Billing, ads, and watermark logic add testing overhead before the core value is proven.
- Monetization can be introduced after the first stable workflow release or during a public beta.

Suggested launch default:
Release the first MVP as a free, no-login utility with local-only processing.

---

## Milestone 0 — Product and Technical Setup

Goal:
Create the project foundation and remove delivery ambiguity before feature work begins.

Estimated duration:
2-3 days for a solo developer.

Deliverables:
- Flutter project scaffold under `/mobile-app`.
- Initial Android package name, app name, icon placeholder, and theme.
- Basic repository structure for app code, documentation, assets, and processing utilities.
- Development README with setup, run, build, and test commands.
- Decision record for MVP scope: Android-first, no login, no backend, no monetization in first build.

Key implementation tasks:
- Create Flutter app structure.
- Add baseline packages for file picking, permission handling, path management, sharing, and video processing.
- Define app routes/screens:
  - Home
  - Extract Last Frame
  - Stitch Videos
  - Processing Progress
  - Export Result
- Add lightweight app design tokens:
  - minimal color palette
  - compact spacing
  - utility-focused typography
  - accessible tap targets

Acceptance criteria:
- App launches on Android emulator/device.
- Home screen shows the two MVP utilities.
- Project can be built from a clean checkout.
- README allows another developer to run the app without guessing.

Suggestions and rationale:
- Suggestion: Keep navigation simple with two primary action tiles on the home screen.
  Rationale: The product promise is speed; users should not pass through onboarding or menus before selecting a utility.
- Suggestion: Create the processing service interface before wiring FFmpeg commands.
  Rationale: It keeps UI code testable and prevents FFmpeg details from leaking throughout the app.

---

## Milestone 1 — Media Selection and App Shell

Goal:
Build the shared user flow that both MVP utilities depend on.

Estimated duration:
3-4 days.

Deliverables:
- File picker integration for MP4 and MOV videos.
- Selected-media list UI.
- Basic file metadata display:
  - filename
  - duration when available
  - file size
  - thumbnail preview when feasible
- Permission handling for Android media access.
- Shared processing-progress screen with cancel affordance.
- Shared export-result screen with save/share actions.

Key implementation tasks:
- Implement reusable media picker component.
- Implement selected file model.
- Add validation for empty selection, unsupported files, inaccessible files, and very large files.
- Add error UI that explains what failed without technical jargon.
- Create app-local temp directory cleanup behavior.

Acceptance criteria:
- User can select one or more videos from Android storage.
- Unsupported files are rejected gracefully.
- User can remove selected files before processing.
- App does not crash when a file is missing, inaccessible, or cancelled from picker.

Suggestions and rationale:
- Suggestion: Support MP4 and MOV only in MVP.
  Rationale: These are listed in the strategy and cover the most common creator exports while keeping FFmpeg testing manageable.
- Suggestion: Use clear status states: selecting, ready, processing, success, failed, cancelled.
  Rationale: Media operations can take time; explicit states make the app feel reliable rather than frozen.

---

## Milestone 2 — Extract Last Frame

Goal:
Ship the first complete utility workflow end to end.

Estimated duration:
4-6 days.

Deliverables:
- Single-video last-frame extraction.
- Multi-video batch last-frame extraction.
- PNG output by default.
- Save to gallery/files.
- Share extracted image.
- Per-file success/failure result summary for batch extraction.

Key implementation tasks:
- Implement `extractLastFrame(inputVideo, outputImagePath)`.
- Generate output filenames using source name plus timestamp or suffix.
- Preserve image quality as much as possible.
- Handle videos with unusual duration metadata.
- Add progress UI for single and batch operations.
- Add output preview after extraction.

Acceptance criteria:
- Extracts the final visual frame from standard MP4 and MOV files.
- Handles multiple selected videos without requiring the user to repeat the flow.
- Saves and shares generated PNG images.
- Reports individual failures in batch mode without losing successful outputs.
- Completes typical short-video extraction in under 30 seconds on a mid-range Android device.

Suggestions and rationale:
- Suggestion: Use PNG as the default image format for MVP.
  Rationale: AI continuity and reference workflows benefit from lossless output; JPEG can be added later as a space-saving option.
- Suggestion: Keep ZIP export out of the first release.
  Rationale: Android share/save behavior for multiple images is enough for MVP validation, while ZIP adds file-management and QA overhead.

---

## Milestone 3 — Stitch Videos

Goal:
Ship the second complete MVP utility workflow end to end.

Estimated duration:
6-8 days.

Deliverables:
- Multi-video selection.
- Ordered clip list.
- Drag-and-drop reorder.
- Stitch/export into a single MP4.
- Save and share final stitched video.
- Export progress and completion state.

Key implementation tasks:
- Implement selected-clip ordering UI.
- Implement `stitchVideos(inputVideos, outputVideoPath)`.
- Normalize processing enough to avoid common export failures.
- Preserve clip order exactly as shown in UI.
- Add validation for minimum two clips.
- Add failure handling for mixed codecs, mismatched resolution, or unsupported metadata.

Acceptance criteria:
- User can select at least two clips and reorder them before export.
- App exports one stitched MP4 file.
- Output plays correctly in Android gallery/player.
- User can save or share the stitched video.
- App shows useful errors if clips cannot be stitched.

Suggestions and rationale:
- Suggestion: Export stitched videos as MP4 for MVP, even when inputs include MOV.
  Rationale: MP4 is the safest Android playback/share format and simplifies output expectations.
- Suggestion: Prefer a reliable re-encode path for MVP over a copy-only fast concatenation path.
  Rationale: AI-generated clips often vary in codec, resolution, fps, and metadata; re-encoding is slower but more dependable for a first public release.
- Suggestion: Do not include optional resize or fps controls in the MVP stitching UI.
  Rationale: They are useful later, but the first version should prove simple clip assembly before adding export knobs.

---

## Milestone 4 — Reliability, Polish, and Local QA

Goal:
Make the two MVP workflows stable enough for beta users.

Estimated duration:
5-7 days.

Deliverables:
- Error handling pass across both utilities.
- Temp-file cleanup.
- Processing cancellation behavior.
- Basic offline analytics-free usage logging only if local debugging needs it.
- UX polish for empty, loading, success, error, and cancelled states.
- Android device QA matrix results.

Key implementation tasks:
- Test short, long, portrait, landscape, high-resolution, and AI-generated clips.
- Test storage permission paths on current Android versions.
- Verify app behavior when processing is interrupted.
- Add guardrails for low storage.
- Confirm no source files are modified.
- Confirm app works offline.

Acceptance criteria:
- Both workflows can be completed repeatedly without restarting the app.
- Failed processing does not leave the user stuck.
- Temporary files are cleaned up safely.
- App handles permission denial gracefully.
- Exported files can be found, opened, and shared from Android.

Suggestions and rationale:
- Suggestion: Use a small real-device QA set rather than emulator-only testing.
  Rationale: Media picker, storage permissions, codec availability, and gallery behavior vary meaningfully across Android devices.
- Suggestion: Defer formal analytics until after MVP launch.
  Rationale: The strategy emphasizes privacy; early manual feedback and store reviews are enough to validate workflow value without adding tracking complexity.

---

## Milestone 5 — Play Store Beta Release

Goal:
Prepare and publish a controlled Android beta.

Estimated duration:
3-5 days, excluding Play Console review delays.

Deliverables:
- Release build configuration.
- App icon and basic store graphics.
- Play Store listing draft.
- Privacy policy explaining local on-device processing.
- Internal or closed testing release.
- Beta feedback checklist.

Key implementation tasks:
- Configure signing and release build.
- Write store copy around two clear promises:
  - extract last frame from videos
  - stitch clips quickly
- Create simple screenshots showing real workflows.
- Prepare privacy policy with no-account and local-processing positioning.
- Publish to internal testing first, then closed testing.

Acceptance criteria:
- Release build installs and runs on Android devices.
- Store listing accurately reflects MVP scope.
- Privacy policy is available and consistent with app behavior.
- Closed testers can complete both workflows without developer assistance.

Suggestions and rationale:
- Suggestion: Launch as closed beta before public production release.
  Rationale: Video processing bugs are often device-specific; beta feedback reduces the risk of early negative reviews.
- Suggestion: Avoid promising broad "AI video toolkit" functionality in the first listing.
  Rationale: The MVP only includes two tools; narrow positioning builds trust and avoids expectation mismatch.

---

## Milestone 6 — Public MVP Launch and Post-Launch Iteration

Goal:
Publish the first public Android release and use feedback to decide the next feature.

Estimated duration:
1-2 weeks after beta stabilization.

Deliverables:
- Public Play Store release.
- Issue/feedback tracker.
- Post-launch metrics review.
- Decision on next utility.

Key implementation tasks:
- Monitor crashes and user feedback.
- Track manual success signals:
  - completed exports
  - repeated use by testers
  - review themes
  - support requests
- Fix high-impact export failures first.
- Choose the next feature based on observed demand.

Acceptance criteria:
- Public app release is live.
- Critical crashes or broken export paths are addressed quickly.
- Next milestone is chosen from real user feedback rather than speculative expansion.

Suggestions and rationale:
- Suggestion: Choose "remove audio" as the likely first post-MVP utility if feedback does not strongly point elsewhere.
  Rationale: It is simpler than extract-all-frames, reverse, loop generation, or resize, and it fits the same lightweight workflow promise.
- Suggestion: Delay paid tier until users are repeatedly exporting.
  Rationale: Monetization works better after the app has proven retention and trust.

---

## MVP Timeline Summary

Suggested solo-development estimate:
4-6 weeks to closed beta, then 1-2 additional weeks to public launch depending on QA findings.

Milestone sequence:
1. Product and technical setup: 2-3 days
2. Media selection and app shell: 3-4 days
3. Extract last frame: 4-6 days
4. Stitch videos: 6-8 days
5. Reliability and polish: 5-7 days
6. Play Store beta release: 3-5 days
7. Public launch and iteration: 1-2 weeks

Recommendation:
Treat the first public release as a focused utility, not a full creator suite.

Rationale:
The fastest path to a trustworthy product is proving that VideoFuse can do two high-value tasks extremely well.

---

## Testing Plan

### Functional Tests
- Select one MP4 and extract last frame.
- Select one MOV and extract last frame.
- Select multiple videos and batch extract last frames.
- Select two videos and stitch them in original order.
- Reorder three or more videos and confirm export order matches UI order.
- Save and share outputs from both utilities.

### Edge Case Tests
- User cancels file picker.
- User denies media permissions.
- User selects unsupported files.
- Source file is removed or becomes inaccessible.
- Device has low available storage.
- Processing is cancelled mid-operation.
- App is backgrounded during processing.
- Clips have different resolutions, frame rates, orientations, or codecs.

### Device Tests
- Current Android version on a physical device.
- One older supported Android version if available.
- Mid-range Android device for performance expectations.
- Emulator only for quick regression checks, not final media QA.

### Acceptance Benchmarks
- Most short-video last-frame extractions complete within 30 seconds.
- Stitched exports are playable in Android gallery/player.
- No source media files are modified.
- App remains usable without account, backend, or internet.

---

# Success Metrics

Initial success should NOT be measured by downloads alone.

Track:
- retention
- exports/day
- subscription conversion
- user reviews
- workflow completion speed

---

# Strategic Direction

VideoFuse should evolve into:
> "The lightweight workflow toolkit for AI video creators."

Not:
- a social platform
- a heavy editor
- a CapCut clone

The focus should remain:
- utility
- speed
- reliability
- workflow efficiency
- creator productivity
