# Milestone 2 — Video Merging

Implementation handoff: see [`next-session-handoff.md`](next-session-handoff.md) for
the current code paths, constraints, and recommended first tasks.

## Status

Next development focus.

## Goal

Merge multiple selected videos into one playable MP4 while preserving the order
shown in the UI.

## Planned work

- Multi-video picker with clear ordered previews.
- Drag-and-drop reorder with stable numbering.
- Validate a minimum of two clips before processing.
- Normalize incompatible resolution, orientation, frame rate, and codecs.
- Process off the UI thread with progress, cancellation, and failure states.
- Export one MP4 to app storage, then offer save/share actions.
- Verify output playback on physical Android devices.

## Acceptance criteria

- At least two clips can be selected and reordered.
- The output follows the displayed clip order.
- Mixed but supported MP4/MOV inputs produce a playable MP4.
- Source files remain unchanged.
- Failures identify the affected operation and leave the source clips usable.
