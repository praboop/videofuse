# Milestone 3 — Video Editor

## Status

Not started. Video Editor is an independent workflow. It accepts either a
completed merge or one existing video chosen by the user, and remains
non-destructive until the user exports an edited copy.

## Goal

Let a user open an existing video or completed merge, precisely identify
ranges, and non-destructively delete, copy, and paste those ranges. Source
videos and merge outputs remain unchanged until the user explicitly exports an
edited video.

## Product decisions

- Video Editor is a separate home-screen pipeline with an `Edit video` entry
  point. It uses the native persisted-document picker to select exactly one
  existing video.
- A completed merge offers `Edit video`, which opens the same editor route
  directly with its temporary completed output; it does not create a second
  editor implementation.
- Edits apply to the editor timeline, not to the underlying source file or
  individual source clips.
- Every editing session starts with one full-duration timeline segment for its
  input video, regardless of whether that input came from the picker or merge.
- Direct editing never overwrites the chosen existing video. Save/export always
  creates a new MP4.
- Deleting a selected range uses ripple delete: the range is removed and later
  content closes the gap.
- Copied ranges include both video and their corresponding audio.
- Pasting inserts the copied range at the playhead and moves later content
  forward.
- Edits are non-destructive decisions until export. Undo/redo operates on those
  decisions rather than modifying media files.
- The seek control is a timeline scrubber with a visible playhead, selection
  boundaries, and thumbnail/frame detail as appropriate; it is not a generic
  scroll bar.
- Frame stepping is available while paused. Playback speeds are 0.25x, 0.5x,
  1x, 1.5x, and 2x; extremely slow continuous playback is not a substitute for
  reliable previous/next-frame controls.

## Interaction model

1. The home screen offers `Edit video`; the user picks one existing video and
   enters the editor. A completed merge can also enter that same editor route
   through an `Edit video` result action before Save/Share.
2. The player exposes play/pause, elapsed/total time, a draggable timeline,
   frame stepping, seek jumps, and playback-rate control.
3. Double-tapping the video toggles immersive fullscreen. A second double-tap
   exits fullscreen. This gesture must not also seek, to keep the behavior
   predictable.
4. The playhead represents the insertion point for paste and the current
   position for marking.
5. `Mark In` records the current timeline position. `Mark Out` completes a
   selection. The selected range is visibly highlighted on the timeline.
6. The selection can be deleted, copied, cleared, or adjusted. Copy makes a
   reusable range clipboard; paste inserts it at the current playhead.

## Data model

- Store timeline positions in microseconds and show a frame-formatted label
  when the input video's frame rate is known.
- Represent the editable video as ordered timeline segments that reference
  ranges of the immutable editor input. A pasted selection creates another
  segment reference; it does not duplicate media bytes.
- Persist edit decisions separately from the temporary/output media path so
  undo, redo, and export can reconstruct the composition.
- The final export uses Media3 `EditedMediaItem` clipping/composition from the
  ordered segments and includes audio for every copied or retained segment.

## Submilestone 3.1 — Video playback and review

### Scope

- Add the `Edit video` home action and one-video native picker entry point.
- Add a shared editor route that accepts either a selected source URI or a
  completed merge output.
- Add an input-video preview before save/share.
- Add timeline seeking, playback rates, previous/next-frame controls, and
  normal seek jumps.
- Add double-tap fullscreen toggle and accessible button alternatives for all
  gestures.

### Acceptance criteria

- A user can open either an existing video or a completed merge, seek to a
  visible position, change playback
  speed, and step one decoded frame backward or forward while paused.
- Fullscreen can be entered and exited with double-tap and with an explicit
  accessible control.
- Save/Share still acts only on a finalized edited-video output.

## Submilestone 3.2 — Mark ranges and timeline selections

### Scope

- Add the playhead, Mark In, Mark Out, selection visualization, and clear
  selection action.
- Show precise time/frame labels and allow timeline scrubbing to adjust marks.

### Acceptance criteria

- A user can make, inspect, clear, and adjust a selected range.
- Marks remain stable while playback is paused, resumed, or scrubbed.

## Submilestone 3.3 — Ripple delete, copy/paste, and undo

### Scope

- Add ripple delete, audio-inclusive copy/paste, and undo/redo.
- Add a compact region list for jumping to, renaming, or removing saved
  selections.

### Acceptance criteria

- Deleting a range closes the gap in the preview timeline.
- Pasting a copied range at the playhead preserves its audio and shifts later
  content.
- Undo/redo restores exact segment order and timing without modifying source
  files.

## Submilestone 3.4 — Export edited videos

### Scope

- Render the edit-decision timeline to a new MP4 with Media3.
- Preserve the established normalization policy and only expose a playable,
  finalized file.
- Add physical-device coverage for edits, audio continuity, save, and share.

### Acceptance criteria

- A saved edited video plays with deleted ranges removed and pasted ranges in
  the expected order, including audio.
- The original source clips and pre-edit merge remain usable and unchanged.

## Technical caveat

Frame stepping and displayed frame numbers describe decoded output frames.
Exact source-frame cuts can vary by codec, GOP structure, and device decoder;
the export must be verified against the decoded Media3 composition rather than
promising universal source-frame-perfect cuts.
