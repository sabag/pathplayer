# PathPlayer

A folder-based Android music player built with Flutter. It connects to a local Jellyfin server and browses your library using the actual filesystem directory structure, rather than relying on metadata tags.

## Getting Started

On first launch the app shows a login screen. Enter your Jellyfin server URL, username, and password. Once connected, the credentials are saved securely on the device using the platform keychain/keystore, so you won't have to enter them again until you log out.

To log out later, open the menu in the top-right corner of the browse screen and choose **Logout**.

If your Jellyfin server uses plain HTTP on your local network, `android:usesCleartextTraffic="true"` is already enabled in `AndroidManifest.xml`.

---

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

---

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
