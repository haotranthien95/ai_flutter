# Firebase Setup Instructions

**Status**: ⏸️ Deferred (Optional for MVP)  
**Required For**: Push notifications (P3), Real-time features  
**Can Skip For**: P1 MVP (Guest Discovery, Authentication, Cart/Checkout)

---

## Prerequisites

1. **Firebase Console Access**: https://console.firebase.google.com
2. **Flutter Firebase CLI**: Install with `dart pub global activate flutterfire_cli`
3. **Firebase Project**: Create a new project in Firebase Console

---

## Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Project name: `ai-flutter-marketplace` (or your preferred name)
4. Enable Google Analytics (optional)
5. Complete project creation

### 2. Add iOS App

1. In Firebase Console, click iOS icon
2. **iOS bundle ID**: Get from `ios/Runner.xcodeproj/project.pbxproj`
   - Search for `PRODUCT_BUNDLE_IDENTIFIER`
   - Example: `com.example.aiFlutter`
3. Download `GoogleService-Info.plist`
4. Place file in: `ios/Runner/GoogleService-Info.plist`
5. Open Xcode and add file to project:
   ```bash
   open ios/Runner.xcworkspace
   # File > Add Files to "Runner" > Select GoogleService-Info.plist
   # Ensure "Copy items if needed" is checked
   ```

### 3. Add Android App

1. In Firebase Console, click Android icon
2. **Android package name**: Get from `android/app/build.gradle`
   - Search for `applicationId`
   - Example: `com.example.ai_flutter`
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

### 4. Configure Firebase Messaging (Push Notifications)

#### iOS Configuration

1. Enable Push Notifications in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Click "+ Capability" → Search "Push Notifications" → Add
   - Add "Background Modes" capability
   - Check "Remote notifications"

2. Upload APNs Key to Firebase:
   - Go to Apple Developer Portal → Certificates, Identifiers & Profiles
   - Create APNs Key (if not exists)
   - Download `.p8` file
   - Upload to Firebase Console → Project Settings → Cloud Messaging → iOS

3. Update `ios/Runner/AppDelegate.swift`:
   ```swift
   import UIKit
   import Flutter
   import FirebaseCore
   import FirebaseMessaging

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       FirebaseApp.configure()
       
       if #available(iOS 10.0, *) {
         UNUserNotificationCenter.current().delegate = self
       }
       
       application.registerForRemoteNotifications()
       
       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

#### Android Configuration

1. Update `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.4.0'
       }
   }
   ```

2. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   
   android {
       defaultConfig {
           minSdkVersion 21  // Firebase requires minimum 21
       }
   }
   ```

3. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <manifest>
       <application>
           <!-- FCM -->
           <meta-data
               android:name="com.google.firebase.messaging.default_notification_channel_id"
               android:value="high_importance_channel" />
       </application>
   </manifest>
   ```

### 5. Verify Installation

Run the Flutter app to verify Firebase is configured:

```bash
flutter run
```

Check logs for "Firebase initialized" or similar confirmation messages.

---

## Environment-Specific Configuration

### Development
- Use separate Firebase project: `ai-flutter-dev`
- Update `lib/app/config.dart`:
  ```dart
  static const String firebaseProjectId = 'ai-flutter-dev';
  ```

### Staging
- Use: `ai-flutter-staging`

### Production
- Use: `ai-flutter-marketplace`

---

## Testing Push Notifications

### From Firebase Console
1. Go to Cloud Messaging → Send test message
2. Enter FCM token (get from app logs)
3. Send notification

### From Code
```dart
// Request permission
FirebaseMessaging messaging = FirebaseMessaging.instance;
NotificationSettings settings = await messaging.requestPermission();

// Get FCM token
String? token = await messaging.getToken();
print('FCM Token: $token');

// Listen to foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got a message whilst in the foreground!');
  print('Message data: ${message.data}');
  
  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
});
```

---

## Troubleshooting

### iOS: Push notifications not working
- Verify APNs key uploaded to Firebase
- Check Xcode capabilities enabled
- Ensure device/simulator supports push (real device required)
- Check provisioning profile has push enabled

### Android: Build fails
- Verify `google-services.json` in `android/app/`
- Check `com.google.gms:google-services` plugin applied
- Ensure `minSdkVersion >= 21`

### Token not received
- Check internet connection
- Verify Firebase project ID in config files
- Check app permissions granted
- Review device logs: `flutter logs`

---

## Security Notes

- **Never commit** `GoogleService-Info.plist` or `google-services.json` to public repos
- Add to `.gitignore`:
  ```
  ios/Runner/GoogleService-Info.plist
  android/app/google-services.json
  ```
- Use environment-specific config files for different environments
- Rotate FCM tokens periodically
- Implement server-side token validation

---

## Cost Considerations

- **Cloud Messaging**: Free for unlimited messages
- **Firestore/Realtime Database**: Pay-as-you-go (not used in MVP)
- **Analytics**: Free
- **Authentication**: Free for phone/email auth

---

## References

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com)
- [FCM Setup Guide](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [APNs Configuration](https://firebase.google.com/docs/cloud-messaging/ios/certs)

---

**Note**: For MVP (P1), push notifications can be deferred. Focus on core e-commerce functionality first, then add Firebase when implementing notification features in P2/P3.
