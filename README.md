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

A release build must be signed with your own release key. You can create a self-signed keystore locally — no online certificate purchase is required for manual distribution.

**Important:** Keep your keystore file and passwords backed up securely. If you lose them, you will not be able to publish updates to existing installs.

#### 1. Create the release keystore

Run this once and place the keystore inside the Android module (it is already gitignored, so it will not be committed):

```bash
keytool -genkey -v \
  -keystore android/pathplayer-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pathplayer
```

`keytool` will prompt you for keystore and key passwords, plus a few identity fields. The values you enter are only stored in the keystore and are not validated by Android for sideloading.

#### 2. Configure signing

Create `android/key.properties` (this file is already gitignored) and point it at the keystore:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=pathplayer
storeFile=../pathplayer-release-key.jks
```

Replace `YOUR_KEYSTORE_PASSWORD` / `YOUR_KEY_PASSWORD` with the passwords you chose in step 1.

#### 3. Build the release APK

```bash
.flutter/flutter/bin/flutter pub get
.flutter/flutter/bin/flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

If you later want to publish on the Google Play Store, you will need to build an **Android App Bundle (AAB)** instead of an APK and use Play App Signing. See the [Flutter deployment documentation](https://docs.flutter.dev/deployment/android) for details.

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

---

## Integration smoke test

`tool/test_jellyfin.dart` is a small command-line script that exercises the Jellyfin API. It reads credentials from environment variables so no secrets are committed:

```bash
export JELLYFIN_URL='http://YOUR_SERVER_IP:8096'
export JELLYFIN_USER='YOUR_USERNAME'
export JELLYFIN_PASSWORD='YOUR_PASSWORD'
.flutter/flutter/bin/dart run tool/test_jellyfin.dart
```
