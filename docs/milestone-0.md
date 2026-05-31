# Milestone 0 — Product and Technical Setup

## Goal

Create the project foundation and remove delivery ambiguity before feature work begins.

## Status

Completed.

Completed:
- Repository folders created.
- Root README added.
- Decision record added.
- Processing command notes started.
- Design direction started.
- Flutter Android app scaffold generated in `/mobile-app`.
- Android app label set to `VideoFuse`.
- Android application ID set to `com.videofuse.app`.
- MVP app shell added with Home, Extract Last Frame, Stitch Videos, Processing Progress, and Export Result screens.
- Baseline Flutter dependencies added.
- Android debug APK build verified.
- Android emulator profile `videofuse_android` created.
- App launch verified on `emulator-5554`.

Known issue:
- `flutter doctor` is green for Android but reports missing Xcode/CocoaPods. This is acceptable for the Android-first MVP.
- `ffmpeg_kit_flutter_new` was tested and removed because it forced older Android plugin dependencies that failed the debug build. Keep processing isolated so Milestone 1 can choose a compatible FFmpeg adapter.
- `file_selector_android` and `share_plus` currently emit a future Flutter warning about plugin Kotlin migration. It does not block the Android MVP build, but it should be watched during dependency upgrades.

## Flutter Scaffold Command

Completed with:

```sh
cd mobile-app
flutter create --platforms=android --project-name videofuse .
```

Recommended verification:

```sh
flutter doctor
flutter run
```

## Milestone 0 Acceptance Criteria

- App launches on Android emulator/device.
- Home screen shows the two MVP utilities.
- Project can be built from a clean checkout.
- README allows another developer to run the app without guessing.

Current acceptance status:
- Documentation criteria are satisfied.
- Project scaffold criteria are satisfied.
- App build/test verification is satisfied.
- Android emulator launch verification is satisfied.
- Physical Android device launch remains useful but is not required to close Milestone 0.

## Suggested Next Steps

1. Start Milestone 1 media selection implementation with `file_selector`.
2. Choose the Milestone 1 FFmpeg adapter after validating Android build compatibility.
3. Add the first processing-service interface before wiring media commands into UI.
4. Test on a physical Android device once media permissions and storage flows are implemented.
