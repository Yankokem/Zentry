# Zentry

A comprehensive personal productivity Flutter application designed to help users manage their tasks, maintain a digital journal, and organize their wishlist. Built with modern Flutter architecture using Provider for state management and Firebase for backend services.

## Features

- **Task Management**: Create, edit, and track personal tasks with due dates and priorities
- **Digital Journal**: Write and organize daily journal entries with rich text support
- **Wishlist**: Keep track of items you want to purchase or achieve
- **Authentication**: Secure user authentication with Firebase Auth
- **Dark/Light Theme**: Support for both light and dark themes
- **Cross-Platform**: Works on iOS, Android, Web, Windows, Mac, and Linux

## Project Structure

### Root Level

- `android/` - Android platform-specific code and configuration
- `ios/` - iOS platform-specific code and configuration
- `web/` - Web platform configuration and assets
- `windows/` - Windows platform-specific code
- `macos/` - macOS platform-specific code
- `linux/` - Linux platform-specific code
- `assets/` - Static assets like images, icons, and fonts
- `lib/` - Main Flutter application code
- `test/` - Unit and widget tests
- `pubspec.yaml` - Flutter project configuration and dependencies
- `analysis_options.yaml` - Dart analysis configuration

### lib/ Directory Structure

#### `config/`

Contains application configuration files:

- `routes.dart` - App navigation routes and route generation logic
- `theme.dart` - Light and dark theme definitions using Google Fonts
- `constants.dart` - App-wide constants and configuration values

#### `models/`

Data models representing the core entities:

- `user_model.dart` - User data structure
- `task_model.dart` - Task data with properties like title, description, due date, priority
- `journal_entry_model.dart` - Journal entry structure with date and content
- `wish_model.dart` - Wishlist item model

#### `providers/`

State management using Provider pattern:

- `auth_provider.dart` - Authentication state management
- `task_provider.dart` - Task CRUD operations and state
- `journal_provider.dart` - Journal entries management
- `wishlist_provider.dart` - Wishlist items management
- `theme_provider.dart` - Theme switching logic

#### `screens/`

UI screens organized by feature:

- `launch_screen.dart` - App launch/splash screen
- `auth/` - Authentication screens (login, signup, forgot password)
- `home/` - Main home screen with navigation
- `tasks/` - Task management screens
- `journal/` - Journal writing and viewing screens
- `wishlist/` - Wishlist management screens
- `profile/` - User profile screen

#### `services/`

Business logic and external service integrations:

- `firebase/` - Firebase services

  - `auth_service.dart` - Firebase Authentication wrapper
  - `firestore_service.dart` - Firestore database operations
  - `firebase_config.dart` - Firebase project configuration

- `local/` - Local storage services
  - `storage_service.dart` - Local data persistence

#### `utils/`

Utility functions and helpers:

- `date_formatter.dart` - Date formatting utilities
- `helpers.dart` - General helper functions
- `validators.dart` - Input validation logic

#### `widgets/`

Reusable UI components:

- `common/` - Shared widgets like floating navigation bar
- `home/` - Home screen specific widgets
- `tasks/` - Task-related widgets
- `journal/` - Journal-specific widgets

### assets/ Directory

- `images/` - App images and graphics
- `icons/` - Custom icons and icon fonts
- `fonts/` - Custom font files (if any)

## Important Files

### Core Application Files

- `lib/main.dart` - Application entry point, provider setup, and MaterialApp configuration
- `lib/config/routes.dart` - Centralized route management and navigation logic
- `lib/config/theme.dart` - Theme definitions for consistent UI styling

### Data Management

- `lib/models/` - All data models defining the app's data structures
- `lib/providers/` - State management providers for each feature
- `lib/services/firebase/firestore_service.dart` - Main database service for CRUD operations

### UI Components

- `lib/screens/home/home_screen.dart` - Main dashboard screen
- `lib/widgets/common/floating_nav_bar.dart` - Bottom navigation component

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase project setup (for authentication and database)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Yankokem/Zentry
   cd Zentry
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project at https://console.firebase.google.com/
   - Add your Flutter app to the Firebase project
   - Download and place the configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`
   - Enable Authentication and Firestore in Firebase Console

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS

```bash
flutter build ios --release
```

#### Web

```bash
flutter build web --release
```

## Dependencies

### Core Dependencies

- `flutter` - Flutter SDK
- `provider: ^6.1.1` - State management
- `google_fonts: ^6.1.0` - Custom fonts
- `flutter_svg: ^2.0.9` - SVG support

### Utilities

- `intl: ^0.18.1` - Internationalization
- `uuid: ^4.2.2` - Unique ID generation

### Development Dependencies

- `flutter_test` - Testing framework
- `flutter_lints: ^3.0.0` - Code linting

## Architecture

This app follows a clean architecture pattern with:

- **Presentation Layer**: Screens and widgets for UI
- **Business Logic Layer**: Providers for state management
- **Data Layer**: Services for API calls and local storage
- **Domain Layer**: Models for data structures

State management is handled by Provider, providing a simple and effective way to manage app state across the widget tree.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
"# Zentry"
