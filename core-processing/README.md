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

Milestone 2.3 implementation:
- AndroidX Media3 Transformer composes the selected clips in their supplied
  order and exports an MP4 using H.264 video and AAC audio.
- Resolution policy: matching selected inputs default to their shared source
  dimensions. Mixed inputs default to the largest selected source. Users can
  explicitly choose 1080p or 720p before export.
- The normalized Transformer composition applies Media3 `Presentation` at
  1920x1080 with `LAYOUT_SCALE_TO_FIT`, preserving source aspect ratios and
  adding letterbox bars for portrait or otherwise mismatched inputs.
- Video and audio transmuxing are disabled on this path so Transformer can
  normalize differing video dimensions/frame rates/codecs and audio sample
  rates/codecs at clip boundaries.
- Transformer performs the export asynchronously on Android's application
  thread and re-encodes as needed, allowing differing source codecs,
  resolutions, orientations, and frame rates to be normalized by the platform.
- Compatible clips may use a native compressed-sample fast path; clips that
  need normalization use the Transformer path above. The output is written to
  app cache as a temporary file and source URIs are never modified.
- Native merge progress is reported to Flutter as a 0–100 percentage. Fast-copy
  progress is based on processed source duration; Transformer progress comes
  from `Transformer.getProgress` polling.
- Cancellation immediately invalidates the active export and deletes its
  temporary output. Fast-copy cancellation takes effect before the next encoded
  sample is written; Transformer cancellation is delegated to
  `Transformer.cancel`.
- A foreground `dataSync` service displays an ongoing export notification while
  a merge runs, allowing normal app backgrounding where Android policy permits.

Rationale:
- AI-generated clips frequently differ in codec, resolution, frame rate, orientation, or metadata.
- Re-encoding is slower but more dependable for the first public release.
