# ChottuLink for Flutter
[![Pub Version](https://img.shields.io/pub/v/chottu_link?color=blue&label=pub.dev)](https://pub.dev/packages/chottu_link)  [![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-red)](#)
<!-- SEO Keywords: Flutter Deep Linking, Firebase Dynamic Links Alternative Flutter, Universal Links Flutter, Deferred Deep Linking Flutter, Short Links Flutter, Deep Link Analytics Flutter, Best Deep Linking for Flutter, Install referral links Flutter, Deep linking SDK Flutter, Flutter deep linking library -->

**ChottuLink** is the **best deep linking solution for Flutter**, offering a **drop-in replacement for Firebase Dynamic Links** with zero complexity.  
It comes with a **lightweight Flutter SDK** and supports:

- **Universal Deep Links** – Open your app from any platform with a single link
- **Deferred Deep Links** – Redirect users to the right content even after app install
- **Branded Short Links** – Create shareable, professional links with your own branding
- **Advanced Analytics** – Track user behavior, clicks, and conversions with ease

ChottuLink ensures **fast integration, high performance,** and **seamless user experiences**, making it the **#1 choice for Flutter developers**.


## Why Choose ChottuLink ?
- 🚀 **Drop-in Replacement for Firebase Dynamic Links** – Easy migration, no complexity.
- 📱 **One Link for Both App Stores** – Works for **Apple App Store** & **Google Play Store**.
- 🎯 **Universal & Deferred Deep Links** – Seamless routing even after app install.
- 🔗 **Branded Short Links** – Strengthen your brand identity with custom domains.
- 📊 **Advanced Analytics** – Track clicks, installs, and conversions effortlessly.
- 🛠 **Lightweight Flutter SDK** – Minimal size, simple integration, fast performance.

## Key Benefits
- ✅ Flutter-only SDK – Lightweight & fast.
- ✅ Simple migration from Firebase Dynamic Links.
- ✅ One link for all stores, all platforms.
- ✅ Built-in analytics for real-time tracking.

## 🛠 Prerequisites

Before integrating ChottuLink into your iOS app, ensure you have the following:

### Development Environment

* Flutter SDK installed (Flutter `v3.3.0` or later recommended)
* Dart SDK installed (Dart `v3.1.0` or later recommended)
* A working Flutter project targeting iOS `15.0+` and Android `5.0+ (API 21+)`
* Xcode `16.2` or later installed (for iOS)
* Android Studio or other IDE with Android SDK installed
* Physical devices or simulators/emulators to run your app
* Git for version control


## 🔧 Configure ChottuLink Dashboard

#### 1. For iOS - [Click here](https://docs.chottulink.com/get-started/ios-setup#-configure-chottulink-dashboard)
#### 2. For Android - [Click here](https://docs.chottulink.com/get-started/android-setup#-configure-chottulink-dashboard)

## 📦 Installation

### 1. Add the [ChottuLink](https://pub.dev/packages/chottu_link/install) SDK to your Flutter project:
```yaml
dependencies:
  flutter:
    sdk: flutter
  chottu_link: ^latest_version
```
#### Click [here](https://pub.dev/packages/chottu_link/versions) to get the latest version.

### 2. Then run:

```bash
flutter pub get
```

## 📱Platform Specific Configurations
#### 1. For iOS - [Click here](https://docs.chottulink.com/get-started/flutter-setup#1-for-ios)
#### 2. For Android - [Click here](https://docs.chottulink.com/get-started/flutter-setup#2-for-android)

### Remember to change:
**`yourapp.chottu.link` to the domain you've set up on ChottuLink Dashboard for your app's links.**


## 🚀 Initialize the ChottuLink SDK

Note: You can get the mobile SDK API KEY from [ChottuLink Dashboard API Keys section](https://app.chottulink.com/api-keys)

Initialize the SDK in `main.dart`:

```dart
import 'package:chottu_link/chottu_link.dart';

void main() async {
  /// ⚠️ Make sure to call this before call ChottuLink.init(apiKey: "your_api_key_here").
  WidgetsFlutterBinding.ensureInitialized();

   /// ✅ Initialize the ChottuLink SDK
   /// Make sure to call this before using any ChottuLink features.
   await ChottuLink.init(apiKey: "your_api_key_here");
  
   runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ChottuLink Demo',
      home: HomeScreen(),
    );
  }
}
```

# 🦋 Generate Dynamic Links in Flutter
This guide covers how to create a Dynamic Link directly from your Flutter app using Dart.

### 🔗 Build a Dynamic Link

```dart
/// ✅ Import ChottuLink SDK packages
import 'package:chottu_link/chottu_link.dart';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_behaviour.dart';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_parameters.dart';

/// Create dynamic link parameters
final parameters = CLDynamicLinkParameters(
  link: Uri.parse("https://example.com"), // Target deep link
  domain: "yourapp.chottu.link", // Your ChottuLink domain

  // Set behavior for Android & iOS
  androidBehaviour: CLDynamicLinkBehaviour.app,
  iosBehaviour: CLDynamicLinkBehaviour.app,

  // UTM Tracking (for analytics)
  utmCampaign: "exampleCampaign",
  utmMedium: "exampleMedium",
  utmSource: "exampleSource",
  utmContent: "exampleContent",
  utmTerm: "exampleTerm",

  // Optional metadata
  linkName: "linkname",
  selectedPath: "customPath",
  socialTitle: "Social Title",
  socialDescription: "Description to show when shared",
  socialImageUrl: "https://yourdomain.com/image.png", // Must be a valid image URL
);
```

### 🧬 Create the Link

```dart
ChottuLink.createDynamicLink(
  parameters: parameters,
  onSuccess: (link) {
    debugPrint("✅ Shared Link: $link"); // 🔗 Successfully created link
  },
  onError: (error) {
    debugPrint("❌ Error creating link: ${error.description}");
  },
);
```

- Default behavior is set to `.app` for both platforms
- `selectedPath` is optional - if not provided, a random path will be generated
- `SocialParameters` is optional - enhances link previews when shared
- `UTMParameters` is optional - helps track campaign performance


# 🦋 Handle Dynamic Links in Flutter
Enable your Flutter app to receive and handle ChottuLinks seamlessly. This allows users to open specific screens when
they tap a dynamic link, whether the app is running, in the background, or launched from a cold start. Integrate link
handling to ensure a smooth and context-aware user experience across platforms.

### 🔧 Implementation Guide

```dart
/// ✅ Import ChottuLink SDK packages
import 'package:flutter/material.dart';
import 'package:chottu_link/chottu_link.dart';

/// 🔗 Listen for incoming dynamic links
ChottuLink.onLinkReceived.listen((String link) {

  debugPrint(" ✅ Link Received: $link");      

  /// Tip: ➡️ Navigate to a specific page or take action based on the link

});
```

## (Optional) Get AppLink Data from the Deeplink URL directly

### URL Processing

Process the shortened Deeplink using the `getAppLinkDataFromUrl` method.  
This retrieves the associated app link data and returns a `ResolvedLink` object containing the resolved destination URL and the original short link.

### 📝 Method Signature

**New Feature**  
This method was introduced in **SDK version** `v1.0.9+`

```dart
static Future<void> getAppLinkDataFromUrl({
   required String shortUrl,
   void Function(ResolvedLink resolvedLink)? onSuccess,
   void Function(ChottuLinkError error)? onError,
});
```

### Parameter

| Parameter  | Type                               | Required | Description                                      |
|------------|------------------------------------|----------|--------------------------------------------------|
| shortUrl   | String                             | ✅ Yes   | The shortened URL string to be resolved          |
| onSuccess  | Function(ResolvedLink resolvedLink) | No       | Called on successful link resolve                |
| onError    | Function(ChottuLinkError error)     | No       | Called if link resolve fails                      |

### 📤 Return Value
```dart
class ResolvedLink {
    String? link;
    String? shortLink;
    ResolvedLink({this.link, this.shortLink});
}
```

### 💻 Basic Implementation
```dart
ChottuLink.getAppLinkDataFromUrl(
   shortUrl: "https://yourApp.chottu.link/xxxxxx",
   onSuccess: (resolvedLink) {
      print("✅ Link: ${resolvedLink.link}");
      print("✅ Short Link: ${resolvedLink.shortLink}");
   },
   onError: (error) {
      print("❌ Error: ${error.message}");
   },
);
```