# Core Processing

This directory tracks processing behavior and command-level decisions for VideoFuse.

The MVP should expose processing through app-level methods rather than scattering command details throughout UI code:
- `extractFrame(inputVideo, timestamp, outputImagePath)`
- `stitchVideos(inputVideos, outputVideoPath)`

## Adapter Decision

Do not bind UI code directly to a specific FFmpeg Flutter package.

Milestone 0 tested `ffmpeg_kit_flutter_new`, but it forced older Android plugin dependencies that failed the debug build with the current Flutter/Android toolchain. The current frame-selection flow uses the Android native/Media3 path; merging remains the next processing milestone.

## Processing Defaults

- Run locally on device.
- Do not upload source media.
- Write outputs to app-controlled temporary storage before save/share.
- Never modify source media files.
- Clean temporary files after success, failure, or cancellation when safe.

## Frame Extraction

Recommended output:
- PNG

Rationale:
- Lossless output is better for AI continuity/reference workflows.

Validation expectations:
- Support MP4 and MOV inputs for MVP.
- Handle first, last, and custom timestamp selection.
- Preserve the detected source frame rate for timestamp display.
- Report extraction failures without discarding successful outputs.

## Stitch Videos

Recommended output:
- MP4

Rationale:
- MP4 is the safest Android playback and sharing target.

Recommended MVP processing strategy:
- Prefer a reliable re-encode path over copy-only concatenation.

Rationale:
- AI-generated clips frequently differ in codec, resolution, frame rate, orientation, or metadata.
- Re-encoding is slower but more dependable for the first public release.
