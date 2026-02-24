# Shared Scripts (Planned)

Cross-platform automation scripts will move here over time.

- `build-android-rust.sh`: builds Android Rust bridge JNI libs into `apps/android/core/bridge/src/main/jniLibs`.
- `deploy-android-ondevice.sh`: builds Rust JNI libs, assembles `onDeviceDebug`, installs on a target device (`--serial`/`ANDROID_SERIAL`), and launches the app.
- `android-deploy-phone.sh`: builds Android debug flavor (`onDevice` or `remoteOnly`), installs on a connected phone, and launches the app.
