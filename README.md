# Qiscus Chat SDK Flutter - Complete Implementation

This is a comprehensive implementation of the Qiscus Chat SDK for Flutter with a complete chat UI. The app includes all major features and follows best practices for Flutter development.

## Overview

This sample demonstrates how to build a full-featured chat application using the Qiscus Chat SDK. It includes user authentication, real-time messaging, file uploads, typing indicators, presence tracking, and more.

**Built with:**
- ✅ Flutter 3.x
- ✅ Qiscus Chat SDK 2.0.11
- ✅ Provider for state management
- ✅ Material 3 design
- ✅ Firebase integration

## Quick Start

### Prerequisites

1. **Flutter Environment**
   ```bash
   flutter doctor
   ```

2. **Firebase Setup** (for Android/iOS)
   - Follow [Firebase Flutter Setup Guide](https://firebase.google.com/docs/flutter/setup?platform=android)
   - Add `GoogleService-Info.plist` (iOS)
   - Add `google-services.json` (Android)

3. **Qiscus App ID**
   - Get your App ID from [Qiscus Dashboard](https://dashboard.qiscus.com/)

### Installation & Running

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Project Structure

```
lib/
├── main.dart                          # App entry point with providers
├── services/
│   └── qiscus_service.dart           # Singleton service for SDK operations
├── providers/
│   ├── auth_provider.dart            # Authentication state management
│   └── chat_provider.dart            # Chat state management
└── screens/
    ├── splash_screen.dart            # Initial loading screen
    ├── login_screen.dart             # User authentication
    ├── home_screen.dart              # Main navigation
    ├── chat_list_screen.dart         # List of chat rooms
    ├── chat_room_screen.dart         # Chat interface
    ├── create_chat_screen.dart       # Create new chats
    └── profile_screen.dart           # User profile management
```

## Features Implemented

### 1. **Authentication**
- ✅ Login with user credentials (userId + userKey)
- ✅ Login with JWT token
- ✅ Persistent login (auto-login on app restart)
- ✅ Logout functionality
- ✅ Profile management (name, avatar)
- ✅ Demo credentials for quick testing

### 2. **Chat Operations**
- ✅ Create 1-on-1 chats
- ✅ Create group chats
- ✅ Create/join channels
- ✅ View chat room list with real-time updates
- ✅ Unread message badges
- ✅ Last message preview
- ✅ Room type indicators

### 3. **Messaging**
- ✅ Send text messages
- ✅ Send file attachments (images, documents)
- ✅ Update messages
- ✅ Delete messages
- ✅ Clear all messages in room
- ✅ Message pagination (load previous messages)
- ✅ Message status tracking (sent, delivered, read)

### 4. **Real-time Features**
- ✅ Real-time message delivery
- ✅ Typing indicators
- ✅ User presence (online/offline)
- ✅ Read receipts
- ✅ Unread count tracking
- ✅ Push notifications support

### 5. **Advanced Features**
- ✅ File upload with progress tracking
- ✅ Participant management (add/remove from groups)
- ✅ Block/unblock users
- ✅ Pull-to-refresh for chat list
- ✅ Infinite scroll for message history
- ✅ Error handling and retry logic

## Configuration

### 1. Set Your Qiscus App ID

Edit `lib/services/qiscus_service.dart`:

```dart
Future<void> initialize() async {
  try {
    const appId = 'YOUR_ACTUAL_APP_ID'; // Replace with your App ID
    await sdk.setup(appId);
    // ...
  }
}
```

Get your App ID from [Qiscus Dashboard](https://dashboard.qiscus.com/)

### 2. Firebase Configuration

**Android:**
- Place `google-services.json` in `android/app/`

**iOS:**
- Place `GoogleService-Info.plist` in `ios/Runner/`

## Usage Guide

### Login
1. Launch the app
2. Enter User ID and User Key
3. Optionally add display name and avatar URL
4. Or click "Use Demo Credentials" for quick testing

### Create Chats
1. Tap the floating action button (+) on the Chats screen
2. Choose chat type:
   - **1-on-1**: Enter target user ID
   - **Group**: Enter group name and comma-separated user IDs
   - **Channel**: Enter unique channel ID

### Send Messages
1. Open a chat room
2. Type message in the input field
3. Tap send button or press Enter

### Send Files
1. Tap the attachment icon
2. Choose Image or File
3. Select file from device
4. File uploads with progress indicator

### Update Profile
1. Go to Profile tab
2. Update display name or avatar URL
3. Tap "Update Profile"

## Architecture

### Design Patterns

**Singleton Pattern**
- `QiscusService` provides single instance for SDK access throughout the app

**Provider Pattern**
- `AuthProvider` manages authentication state
- `ChatProvider` manages chat operations and real-time updates
- Reactive UI updates via Provider listeners

**Separation of Concerns**
- **Services**: SDK operations and API calls
- **Providers**: State management and business logic
- **Screens**: UI presentation and user interaction

### State Management

```dart
// Access providers
final authProvider = context.read<AuthProvider>();
final chatProvider = context.read<ChatProvider>();

// Watch for changes
context.watch<AuthProvider>().isLoggedIn
context.watch<ChatProvider>().messages
```

## Key Implementation Details

### File Upload Flow
1. Show placeholder message immediately
2. Upload file in background with progress
3. Replace placeholder with actual message when complete
4. Show progress percentage during upload

### Message Status Indicators
- ⏱️ **Sending** (clock icon)
- ✓ **Sent** (single check)
- ✓✓ **Delivered** (double check, gray)
- ✓✓ **Read** (double check, blue)

### Login Persistence
- Credentials saved to SharedPreferences
- Auto-login on app restart if session exists
- Automatic session recovery if SDK session expires
- Graceful fallback to login screen if credentials invalid

### Error Handling
- Comprehensive try-catch blocks for all operations
- User-friendly error messages via SnackBars
- Loading states prevent duplicate actions
- Retry options for failed operations
- Detailed debug logging with `debugPrint`

## Dependencies

```yaml
# Core
flutter: sdk: flutter

# Qiscus Chat SDK
qiscus_chat_sdk: ^2.0.11

# State Management
provider: ^6.0.5

# UI Components
cached_network_image: ^3.2.3
image_picker: ^1.0.4
file_picker: ^9.0.0

# Firebase
firebase_core: ^2.32.0
firebase_messaging: ^14.7.10

# Utilities
intl: ^0.18.1
path_provider: ^2.1.1
permission_handler: ^11.4.0
shared_preferences: ^2.2.2
```

## Troubleshooting

### Build Issues

**Android Gradle Error**
- Ensure Kotlin version is 1.9.22+
- AGP should be 8.1.4+
- Gradle wrapper should be 8.4+

**iOS Firebase Error**
- Set `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = YES` in Xcode

### Runtime Issues

**SDK not initialized**
- Verify `YOUR_ACTUAL_APP_ID` is set correctly
- Check internet connection

**Login fails**
- Confirm App ID is correct
- Verify user credentials are valid
- Check Firebase configuration

**Messages not appearing**
- Ensure SDK is initialized
- Verify real-time listeners are active
- Check room subscription status

**File upload fails**
- Verify file permissions
- Check file size limits
- Ensure stable internet connection

## Debugging

### Enable Debug Logging

All SDK operations log to console with `debugPrint`:

```
🚀 Initializing Qiscus SDK
🔐 Attempting login for user: demo-user
✅ User logged in: demo-user
📨 Message received: Hello
✓ Message delivered: 12345
```

## Testing

### Test User Credentials
Use the "Use Demo Credentials" button to generate test accounts:
- User ID: `demo-user-{timestamp}`
- User Key: `demo-password`
- Display Name: `Demo User`

### Test Different Chat Types
1. **1-on-1 Chat**: Create chat with another user ID
2. **Group Chat**: Add multiple user IDs
3. **Channel**: Use a unique channel ID (e.g., "general")

## Next Steps

### Optional Enhancements
1. Add message search functionality
2. Implement emoji picker
3. Add voice/video calls
4. Implement message reactions
5. Add message forwarding
6. Implement chat room settings
7. Add user blocking UI
8. Implement message encryption

## Resources

- [Qiscus Chat SDK Documentation](https://documentation.qiscus.com/v2.1/chat-sdk-flutter/)
- [Flutter Provider Documentation](https://pub.dev/packages/provider)
- [Qiscus Dashboard](https://dashboard.qiscus.com/)
- [Flutter Documentation](https://flutter.dev/docs)

## Screenshots

Android:

<img src="https://d1edrlpyc25xu0.cloudfront.net/sdksample/image/upload/IQQGENk7W0/Screen+Shot+2020-04-14+at+18.26.46.png" alt="Login" width="240"/>

<img src="https://d1edrlpyc25xu0.cloudfront.net/sdksample/image/upload/yULkESkVGl/Screen+Shot+2020-04-14+at+16.08.51.png" alt="Chat Room" width="240"/>

iOS:

<img src="https://d1edrlpyc25xu0.cloudfront.net/sdksample/image/upload/E0kPczjE7I/Screen+Shot+2020-04-14+at+21.08.53.png" alt="Login" width="240"/>

<img src="https://d1edrlpyc25xu0.cloudfront.net/sdksample/image/upload/j1YKm13i0_/Screen+Shot+2020-04-14+at+21.04.33.png" alt="Chat Room" width="240"/>

## Contribution

Qiscus Chat SDK Sample UI is fully open-source. All contributions and suggestions are welcome!

## Security Disclosure

If you believe you have identified a security vulnerability with Qiscus Chat SDK, you should report it as soon as possible via email to contact.us@qiscus.com. Please do not post it to a public issue.

## License

This implementation follows the same license as the Qiscus Chat SDK Flutter package.

## Support

For issues related to:
- **This implementation**: Check the code comments and this README
- **Qiscus SDK**: Visit [Qiscus Support](https://support.qiscus.com/)
- **Flutter**: Visit [Flutter Documentation](https://flutter.dev/docs)
