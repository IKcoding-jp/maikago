# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**まいカゴ (Maikago)** is a Japanese shopping list management app built with Flutter. It allows housewives to manage shopping lists with quantity, unit price, discount calculations, and automatic total calculation. The app features Google Sign-In authentication, Firebase Firestore for cloud data sync, and supports both online and offline modes.

## Architecture

### Core Components
- **State Management**: Provider pattern with separate `AuthProvider` and `DataProvider`
- **Backend**: Firebase Authentication + Cloud Firestore for user data persistence
- **Models**: `Item` (shopping list items), `Shop` (multiple shopping lists)
- **Services**: `AuthService`, `DataService`, `DonationManager`, `InAppPurchaseService`
- **UI**: Material Design with custom pastel color themes and font customization

### Key Files Structure
```
lib/
├── providers/           # State management (Provider pattern)
├── services/           # Business logic and external integrations
├── models/             # Data models (Item, Shop, SortMode)
├── screens/            # UI screens and settings logic
├── widgets/            # Reusable UI components
└── constants/colors.dart # App color definitions
```

### Firebase Integration
- Uses Cloud Firestore with user-scoped security rules
- Authentication via Google Sign-In
- Supports anonymous local sessions when user skips login
- Real-time data synchronization across devices

## Common Development Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Build for release (Android)
build-release.bat    # Custom batch script that sets env vars and builds APK/AAB

# Manual release builds
flutter build apk --release
flutter build appbundle --release

# Code analysis
flutter analyze

# Tests
flutter test
```

### Build Configuration
- Release builds use `build-release.bat` which calls `android/app/set-env.bat` for keystore configuration
- Icons generated via `flutter_launcher_icons` package
- Multi-platform support: Android, iOS, Web, Windows, macOS, Linux

## Code Conventions

### File Length Limits
- Cursor rule enforces max 500 lines per Dart file (see `.cursor/rules/500.mdc`)
- Split large files using extensions or separate modules

### State Management Pattern
- Use Provider for app-wide state
- DataProvider manages shopping data and sync status
- AuthProvider handles authentication state
- Settings managed through dedicated logic/persistence files

### Theming System
- Global theme management via `main.dart` with ValueNotifiers
- Custom theme generation in `SettingsLogic.generateTheme()`
- Support for multiple color themes and font families
- Font families: nunito, roboto, noto_sans_jp

### Firebase Security Rules
User data is scoped per authenticated user:
```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  match /items/{itemId} { /* same rule */ }
  match /shops/{shopId} { /* same rule */ }
}
```

## Key Features to Understand

1. **Dual Mode Operation**: Supports both authenticated (cloud sync) and anonymous (local storage) modes
2. **Shopping List Management**: Items belong to shops, with quantity/price/discount calculations
3. **Real-time Sync**: Uses Firestore listeners for live updates across devices
4. **Monetization**: Includes Google Ads integration and in-app purchases for donations
5. **Localization**: Japanese-first app with appropriate UI/UX considerations

## Testing and Quality

- Uses `flutter_lints` with standard Flutter lint rules
- Analysis options configured in `analysis_options.yaml`
- Widget tests in `test/` directory
- Release checklist available in `RELEASE_CHECKLIST.md`

## Development Environment

- Flutter SDK ^3.8.1
- Firebase project configuration required (`google-services.json`)
- Google Cloud Console setup for OAuth
- Android signing key setup for releases (`key.properties`, `release-key.jks`)