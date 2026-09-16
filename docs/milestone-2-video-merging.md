# Milestone 2 — Video Merging

## Status

Complete. The complete Merge Videos flow, including progress, cancellation,
foreground backgrounding support, output-resolution choices, editable Downloads
filenames, and save/share actions, was verified on a physical Android device.

Playback, range marking, and non-destructive editing are defined in
`docs/milestone-3-video-editor.md`. They are intentionally outside this
milestone.

## Goal

Let a user select two or more videos, arrange their order, and export one
playable MP4. The source clips must never be modified.

## Product decisions

- User-facing name: **Merge Videos**. Do not use “Stitch Videos” in new UI,
  copy, or documentation. “Stitch” may remain temporarily in internal method
  names while the implementation is migrated.
- Merge Videos is a dedicated workflow, not a variant of frame extraction.
- A merge clip preview shows a small, representative filmstrip (target: three
  low-resolution frames at approximately 15%, 50%, and 85% through the clip).
  It must not build the 100-frame cache used by the frame-selection screen.
- The Merge Videos workflow never offers frame saving or custom frame picking.
- All added clips are selected by default. Tapping a clip's numbered position
  toggles whether that clip is included, without changing the displayed order.
- The ordered list is the source of truth: the exported timeline must exactly
  match the order of its selected clips.
- Merge preview metadata is provided by the native `inspectVideo` method and
  includes duration, dimensions, rotation, frame rate, video/audio MIME types,
  and audio presence.
- Initial supported input promise: compatible, readable MP4/MOV clips. The UI
  must validate actual media compatibility rather than broadly claiming every
  MP4/MOV file is supported.

## Target interaction

1. The app bar says “Merge videos,” with a short instruction below it:
   “Choose clips, then drag to set the final order.”
2. With no clips selected, show a compact empty state and an `Add videos`
   action. Do not show a large decorative header.
3. With clips selected, the reorderable clip list owns most of the screen.
   Keep `Add videos` compact above or within the list.
4. Each card shows stable order number, filename, duration, a three-frame
   preview strip, drag handle, and remove action. Technical metadata may be
   expandable, but is not the default view.
5. A persistent bottom CTA is disabled until two selected clips exist. Its label changes
   from `Select at least 2 videos` to `Merge N videos`.
6. A confirmation sheet summarizes the number of clips, total duration, and
   MP4 output before work starts.
7. During export, show real progress and a `Cancel` action. On success, allow
   the Downloads filename to be edited before Save to device, and offer Share,
   Create another, and a later path into the Milestone 3
   video-editor review experience.

## Shared context

- Flutter entry/UI: `mobile-app/lib/main.dart`.
- Flutter processing bridge: `mobile-app/lib/services/processing_service.dart`.
- Android implementation: `mobile-app/android/app/src/main/kotlin/com/videofuse/app/MainActivity.kt`.
- `MediaSelectionScreen` is currently shared by frame extraction and the old
  merge route. It extracts first/last frames, starts a 100-point preview cache,
  and exposes frame saving. It is correct for frame extraction but must not be
  reused for Merge Videos.
- The native `stitchVideos` method is a prototype passthrough muxer. It assumes
  tracks are compatible, advances every clip by a fixed one second, has no
  normalization, and has no meaningful progress or cancellation. Do not extend
  it as the production path.
- The native `ACTION_OPEN_DOCUMENT` picker returns persisted content URIs. Keep
  source media on-device and do not reintroduce byte-based Flutter file picking.
- Existing frame-selection cache behavior is complete and must not regress.
- Before device testing, rebuild the Android APK. Baseline checks currently pass:
  `flutter analyze` and `flutter test`.

## Submilestone 2.1 — Dedicated Merge Videos selection UI

### Scope

- Rename the user-facing route, home tile, titles, and labels to Merge Videos.
- Replace the merge route’s use of `MediaSelectionScreen` with a dedicated
  stateful screen. Leave the frame-selection screen behavior unchanged.
- Implement compact empty, selected, and minimum-selection states.
- Implement reorder, stable numbering, remove, and add-more interactions.
- Add a persistent disabled/enabled merge CTA, but do not invoke export yet.

### Do not do

- Do not implement media normalization or change the native merge algorithm.
- Do not show save-frame, custom-frame, first-frame/last-frame labels, or
  cache-progress indicators in Merge Videos.

### Acceptance criteria

- Four selected clips can be reviewed without the header/picker consuming a
  large portion of the display.
- Reordering immediately changes stable visible numbering.
- The CTA is disabled for zero/one clip and enabled for two or more clips.
- Frame extraction retains its existing first/last/custom-frame behavior.

### Handoff note

Stop after the UI is usable with placeholder merge action. Record any renamed
route or widget names in `docs/next-session-handoff.md`.

## Submilestone 2.2 — Lightweight merge previews and input preflight

### Scope

- Add a native/bridge API that returns only three small representative previews
  per selected clip; use bounded background work and per-card loading/error UI.
- Add media inspection needed for merge preflight: duration, video dimensions,
  rotation, frame rate, video codec, and audio-track presence/format.
- Validate each selected URI before merge. Report the affected filename and
  keep other clips selectable/removable.

### Do not do

- Do not build or expose the frame-selection 100-thumbnail cache.
- Do not make preview failures block ordering or a later merge attempt.

### Acceptance criteria

- Each merge card shows up to three content previews, or a compact retry/error
  state, without any frame-save interaction.
- Media inspection works for persisted `content://` URIs and file paths.
- A malformed/unreadable clip identifies itself before export begins.

### Handoff note

Document the chosen preview size, timestamps, and media metadata contract in
`core-processing/README.md` and `docs/decision-record.md`.

## Submilestone 2.3 — Reliable MP4 export pipeline

### Scope

- Choose and implement an Android export pipeline capable of normalizing
  supported inputs to one MP4: orientation, resolution, frame rate, codecs,
  and audio handling.
- Preserve list order exactly and calculate timestamps from actual source
  durations/samples, never a fixed offset.
- Write into app-owned temporary storage; only expose a completed playable file.
- Define output defaults (codec/container, dimensions, frame rate, audio policy,
  filename convention) and failure behavior.

### Do not do

- Do not silently fall back to the current sample-copy `stitchVideos` muxer for
  incompatible media.

### Acceptance criteria

- Two and three compatible clips merge to an MP4 that plays on a physical
  Android device in the exact UI order.
- Mixed supported MP4/MOV media with differing orientation/resolution/frame
  rate produces a playable normalized MP4.
- Audio behavior is deterministic and documented; source files remain unchanged.
- Failed exports remove only temporary output and leave every source usable.

### Handoff note

Record the exporter/library decision, output guarantees, and known unsupported
inputs in `docs/decision-record.md` and `core-processing/README.md`.

## Submilestone 2.4 — Progress, cancellation, and result actions

### Scope

- Connect the Merge CTA to a confirmation sheet and the export pipeline.
- Report progress from native work rather than using an indeterminate UI alone.
- Support cancellation, safely clean up temporary output, and return the UI to
  a retryable selected-clips state.
- Add save-to-device, share, and create-another actions. Video-editor playback
  and editing are Milestone 3 scope.
- Ensure long-running work survives normal app backgrounding where Android
  policy permits; use an appropriate foreground-capable worker/service if needed.

### Acceptance criteria

- A user can cancel a merge without losing selection or source clips.
- Completion offers save/share actions for the finalized output. Video-editor
  playback is Milestone 3 scope.
- Errors name the failed operation and, where known, the affected clip.
- The app does not claim success until the output has been finalized and is
  readable.

### Handoff note

Document the cancellation boundary (for example, between clips versus during
transcode) and Android background-processing approach.

## Submilestone 2.5 — Accessibility, device QA, and documentation

### Scope

- Add accessible reorder alternatives (Move up/Move down actions) alongside
  drag handles, with labels suitable for TalkBack.
- Verify layout and controls on small phones, large phones, and dark mode.
- Test success and failure flows on physical Android devices.
- Update README and handoff documentation to reflect the completed behavior.

### Device test matrix

- Two clips in displayed order; then reverse their order and verify output.
- Three clips with audio.
- Mixed orientation, resolution, frame rate, and supported MP4/MOV inputs.
- Missing/unreadable/unsupported input and a cancelled export.
- Save and share of a completed output.

### Completion criteria

- All preceding submilestones meet their acceptance criteria.
- `flutter analyze` and `flutter test` pass.
- The exported MP4 plays after saving on at least one physical Android device.
- `README.md`, `core-processing/README.md`, `docs/decision-record.md`, and
  `docs/next-session-handoff.md` accurately describe the final behavior.

## Verification record

- Physical Android device verification: successful (reported 2026-09-16).
- Flutter analysis and widget tests: passing.
- Android debug Kotlin compilation: passing.
- Native progress/cancellation/foreground-service implementation: verified on
  a physical Android device.
