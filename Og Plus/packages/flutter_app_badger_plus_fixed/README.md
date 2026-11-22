# Flutter App Badger Plus plugin (UNMAINTAINED)

## 技术支持邮箱(1539841933@qq.com)。

[![Pub](https://img.shields.io/pub/v/flutter_app_badger_plus.svg)](https://pub.dev/packages/flutter_app_badger_plus)

This plugin for [Flutter](https://flutter.io) adds the ability to change the badge of the app in the launcher.
It supports iOS, macOS, and some Android devices (the official API does not support the feature, even on Oreo).

<p align="center">
  <img src="https://raw.githubusercontent.com/g123k/flutter_app_badger_plus/master/assets/ios.png" alt="Android badge" style="margin:auto" width="600" 
height="228">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/g123k/flutter_app_badger_plus/master/assets/android.png" alt="Android badge" style="margin:auto" width="600" 
height="322">
</p>


## Getting Started

### iOS

On iOS, the notification permission is required to update the badge.
It is automatically asked when the badge is added or removed.

Please also add the following to your <your project>/ios/Runner/Info.plist:
```xml
<key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>
```

## macOS

On macOS, the notification permission is required to update the badge.
It is automatically asked when the badge is added or removed.

Please also add the following to your <your project>/macos/Runner/Info.plist:
```xml
<key>NSUserNotificationAlertStyle</key>
<string>banner</string>
```

### Android

On Android, no official API exists to show a badge in the launcher. But some devices (Samsung, HTC...) support the feature.
Thanks to the [Shortcut Badger library](https://github.com/leolin310148/ShortcutBadger/), ~ 16 launchers are supported.


### Dart

First, you just have to import the package in your dart files with:
```dart
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
```

Then you can add a badge:
```dart
FlutterAppBadgerPlus.updateBadgeCount(1);
```

Remove a badge:
```dart
FlutterAppBadgerPlus.removeBadge();
```

Or just check if the device supports this feature with:
```dart
FlutterAppBadgerPlus.isAppBadgeSupported();
```
