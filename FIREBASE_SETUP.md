# Firebase Setup Guide for Talent2Trophy

This guide will help you set up Firebase for the Talent2Trophy app.

## Prerequisites

1. A Google account
2. Flutter project set up
3. Android Studio or VS Code

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `talent2trophy`
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Click "Save"

## Step 3: Set up Cloud Firestore

1. In Firebase Console, go to "Firestore Database" in the left sidebar
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your target users)
5. Click "Done"

### Firestore Security Rules

Update your Firestore security rules to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow public read access to verified users
    match /users/{userId} {
      allow read: if request.auth != null;
    }
    
    // Add more rules as needed for other collections
  }
}
```

## Step 4: Storage (Optional - Not Used in Phase 1)

> **Note**: Firebase Storage is not used in Phase 1 to avoid costs. Video storage will be implemented in Phase 2 using local storage and alternative solutions.

If you plan to use Firebase Storage in future phases:
1. In Firebase Console, go to "Storage" in the left sidebar
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select a location (same as Firestore)
5. Click "Done"

### Storage Security Rules (for future use)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload and read their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow public read access to verified content
    match /public/{allPaths=**} {
      allow read: if true;
    }
  }
}
```

## Step 5: Add Android App

1. In Firebase Console, click the gear icon next to "Project Overview"
2. Select "Project settings"
3. In the "Your apps" section, click the Android icon
4. Enter Android package name: `com.example.talent2trophy`
5. Enter app nickname: `Talent2Trophy`
6. Click "Register app"
7. Download the `google-services.json` file
8. Place it in `android/app/` directory

## Step 6: Add iOS App (if needed)

1. In the same project settings, click the iOS icon
2. Enter iOS bundle ID: `com.example.talent2trophy`
3. Enter app nickname: `Talent2Trophy`
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place it in `ios/Runner/` directory

## Step 7: Update Android Configuration

### android/app/build.gradle

Add the following to the bottom of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

### android/build.gradle

Add the following to the dependencies:

```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

## Step 8: Update iOS Configuration (if needed)

### ios/Runner/Info.plist

Add the following keys:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from your `GoogleService-Info.plist`.

## Step 9: Test the Setup

1. Run the app: `flutter run`
2. Try to register a new user
3. Check if the user appears in Firebase Console > Authentication
4. Check if user data appears in Firestore Database

## Troubleshooting

### Common Issues

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Make sure you've added the configuration files correctly
   - Check that the package name/bundle ID matches

2. **"Permission denied" errors**
   - Check your Firestore and Storage security rules
   - Make sure you're signed in with a valid account

3. **"Network error"**
   - Check your internet connection
   - Verify Firebase project is in the correct region

### Debug Mode

For development, you can use test mode in Firestore and Storage, but remember to update the security rules before production.

## Production Considerations

1. **Security Rules**: Update Firestore and Storage rules for production
2. **Authentication**: Consider adding additional sign-in methods
3. **Monitoring**: Set up Firebase Analytics and Crashlytics
4. **Backup**: Set up automated backups for your Firestore database

## Support

If you encounter issues:
1. Check the [Firebase Documentation](https://firebase.google.com/docs)
2. Check the [FlutterFire Documentation](https://firebase.flutter.dev/)
3. Create an issue in the project repository

---

**Note**: This setup is for development. For production, you'll need to configure proper security rules and enable additional Firebase services as needed.

