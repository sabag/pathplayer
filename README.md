# pathplayer

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Building the APK

This project uses a vendored Flutter SDK located at `.flutter/`. Make sure you have an Android SDK installed and that the `ANDROID_HOME` / `ANDROID_SDK_ROOT` environment variable is set.

### Debug APK

After changing code, fetch dependencies and build a debug APK:

```bash
.flutter/flutter/bin/flutter pub get
.flutter/flutter/bin/flutter build apk --debug
```

The output will be at:

```
build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK

A release build also requires a configured signing key. Update `android/app/build.gradle.kts` (or `android/key.properties`) with your keystore details, then run:

```bash
.flutter/flutter/bin/flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Deploying the APK to a device with ADB

1. Enable USB debugging on the Android device and connect it.
2. Verify the device is detected:

   ```bash
   adb devices
   ```

3. Install the APK:

   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

   To overwrite an existing install, use:

   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

4. Launch the app manually from the app drawer, or run directly from the source during development:

   ```bash
   .flutter/flutter/bin/flutter run
   ```
