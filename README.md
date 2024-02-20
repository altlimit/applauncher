# applauncher

```bash
# to test release
flutter run --release

# to build apk
flutter build apk --release

# to build bundle
flutter build appbundle

# or to auto build both
python build.py 2.5.0 103

# to run local server
cd server
dev_appserver.py app.yaml --enable_host_checking=0 --host=0.0.0.0

# on windows - disable enable usb debugging
adb tcpip 5555
# on wsl
adb connect 192.168.1.20:5555

# to restart
adb kill-server


# release new version
git tag -a "v2.5.1-mobile" -m "bugfixes"
git push origin --tags

```

Updating launcher icon
---
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```


