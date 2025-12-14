# Zentry Implementation Documentation

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Firebase Implementation](#firebase-implementation)
3. [Cloudinary Image Storage](#cloudinary-image-storage)
4. [Google Authentication](#google-authentication)
5. [APIs and Packages](#apis-and-packages)

---

## System Architecture

Zentry follows a **feature-based architecture** with clear separation of concerns. The project structure is organized as follows:

### Folder Structure

```
lib/
├── core/                           # Core/shared functionality
│   ├── models/                     # Data models (User, Project, Ticket, etc.)
│   ├── services/                   # Core services
│   │   ├── firebase/              # Firebase-related services
│   │   │   ├── firestore_service.dart
│   │   │   └── notification_manager.dart
│   │   ├── cloudinary_service.dart
│   │   └── user_service.dart
│   ├── views/                      # Core UI screens
│   │   └── home_page.dart         # Main dashboard
│   ├── widgets/                    # Reusable widgets
│   ├── theme/                      # App theming
│   └── utils/                      # Utility functions
│
├── features/                       # Feature modules
│   ├── auth/                       # Authentication
│   │   ├── views/                 # Login, Register screens
│   │   └── services/              # Auth service
│   │
│   ├── projects/                   # Project management
│   │   ├── views/                 # Project screens
│   │   │   ├── project_detail_page.dart
│   │   │   ├── add_ticket_page.dart
│   │   │   └── edit_ticket_page.dart
│   │   ├── widgets/               # Project-specific widgets
│   │   ├── models/                # Project models
│   │   └── services/              # Project services
│   │       ├── project_manager.dart
│   │       └── project_notification_service.dart
│   │
│   ├── journal/                    # Journal entries
│   │   ├── views/                 # Journal screens
│   │   ├── widgets/               # Rich text editor
│   │   │   └── rich_text_editor.dart
│   │   └── services/              # Journal services
│   │
│   ├── wishlist/                   # Wishlist feature
│   │   ├── views/                 # Wishlist screens
│   │   ├── controllers/           # Wishlist controllers
│   │   └── models/                # Wishlist models
│   │
│   └── profile/                    # User profile
│       ├── views/                 # Profile, notifications, settings
│       └── services/              # Profile services
│
└── main.dart                       # App entry point
```

### Architecture Principles

1. **Feature-First Organization**: Each feature (projects, journal, wishlist) has its own folder with views, models, and services
2. **Core Services**: Shared services like Firebase, Cloudinary, and user management are in `core/services/`
3. **Separation of Concerns**: Business logic is separated from UI components
4. **Reusability**: Common widgets and utilities are centralized in `core/`

---

## Firebase Implementation

Zentry uses **Firebase** for backend services including authentication, real-time database (Firestore), and cloud messaging.

### Core Firebase Services

#### 1. FirestoreService (`lib/core/services/firebase/firestore_service.dart`)

**Purpose**: Central service for all Firestore CRUD operations

**Key Methods**:

```dart
// Create operations
Future<void> createUser(User user)
Future<void> createProject(Project project)
Future<void> createTicket(Ticket ticket)
Future<void> createJournalEntry(JournalEntry entry)
Future<void> createWishlistItem(WishlistItem item)

// Read operations
Future<User?> getUserData(String userId)
Future<Project?> getProjectById(String projectId)
Future<List<Ticket>> getTicketsForProject(String projectId)
Stream<List<Project>> getUserProjectsStream(String userId, String userEmail)
Stream<List<Ticket>> listenToUserTickets(String userId, String userEmail)

// Update operations
Future<void> updateUser(String userId, Map<String, dynamic> data)
Future<void> updateProject(String projectId, Map<String, dynamic> data)
Future<void> updateTicket(String projectId, String ticketId, Map<String, dynamic> data)

// Delete operations
Future<void> deleteProject(String projectId)
Future<void> deleteTicket(String projectId, String ticketId)
```

**Files Using FirestoreService**:
- `lib/core/views/home_page.dart` - Dashboard data loading
- `lib/features/projects/services/project_manager.dart` - Project/ticket CRUD
- `lib/features/projects/views/project_detail_page.dart` - Ticket management
- `lib/features/journal/views/(add|edit)_journal_screen.dart` - Journal CRUD
- `lib/features/wishlist/controllers/wishlist_controller.dart` - Wishlist CRUD
- `lib/features/profile/views/profile_screen.dart` - User profile management

#### 2. NotificationManager (`lib/core/services/firebase/notification_manager.dart`)

**Purpose**: Manages in-app notifications and Firebase Cloud Messaging

**Key Methods**:

```dart
// Listen to user notifications
Stream<List<AppNotification>> listenToUserNotifications(String userId)

// Create notifications
Future<void> notifyTaskAssigned(...)
Future<void> notifyTaskDeadlineApproaching(...)
Future<void> notifyTaskOverdue(...)
Future<void> notifyProjectInvite(...)

// Mark as read/delete
Future<void> markAsRead(String notificationId)
Future<void> deleteNotification(String notificationId)
```

**Firestore Structure for Notifications**:
```
notifications/
  users/
    {userId}/
      notifications/
        {notificationId}/
          - type: string
          - title: string
          - message: string
          - data: map
          - timestamp: timestamp
          - read: boolean
```

**Files Using NotificationManager**:
- `lib/features/profile/views/notifications_screen.dart` - Display notifications
- `lib/features/projects/services/project_notification_service.dart` - Send project notifications
- `lib/features/projects/views/project_detail_page.dart` - Ticket status notifications
- `lib/core/views/home_page.dart` - Real-time notification updates

#### 3. ProjectManager (`lib/features/projects/services/project_manager.dart`)

**Purpose**: Handles project and ticket-specific operations

**Key Methods**:

```dart
// Project operations
Future<void> createProject(Project project)
Future<void> updateProject(String projectId, Map<String, dynamic> updates)
Future<void> deleteProject(String projectId)
Stream<List<Project>> listenToProjects()

// Ticket operations
Future<void> addTicket(Ticket ticket)
Future<void> updateTicket(String ticketId, Map<String, dynamic> updates)
Future<void> deleteTicket(String ticketId)
Stream<List<Ticket>> listenToUserTickets(String userId, String userEmail)
```

**Firestore Structure for Projects**:
```
projects/
  {projectId}/
    - title: string
    - description: string
    - userId: string (owner)
    - memberEmails: array
    - acceptedMemberEmails: array
    - color: string
    - createdAt: timestamp
    
    tickets/
      {ticketId}/
        - ticketNumber: string
        - title: string
        - description: string
        - richDescription: string (JSON)
        - priority: string
        - status: string
        - assignedTo: array
        - deadline: timestamp
        - imageUrls: array
        - projectId: string
```

#### 4. ProjectNotificationService (`lib/features/projects/services/project_notification_service.dart`)

**Purpose**: Sends notifications for project-related events

**Key Methods**:

```dart
Future<void> notifyProjectInvite(String recipientEmail, String projectTitle, ...)
Future<void> notifyAssigneeStatusChanged(String assigneeEmail, String ticketTitle, ...)
Future<void> notifyPMTicketReady(String pmUserId, String ticketTitle, ...)
```

**Notification Path**:
```
notifications/users/{userId}/notifications/{notificationId}
```

---

## Cloudinary Image Storage

Zentry uses **Cloudinary** for image storage instead of Firebase Storage for better performance and CDN delivery.

### CloudinaryService (`lib/core/services/cloudinary_service.dart`)

**Configuration**:
```dart
static const String _cloudName = 'dg1cz2twr';

static const Map<CloudinaryUploadType, String> _uploadPresets = {
  CloudinaryUploadType.accountPhoto: 'zentry_accounts_photos',
  CloudinaryUploadType.journalImage: 'zentry_journal_images',
  CloudinaryUploadType.projectImage: 'zentry_project_images',
  CloudinaryUploadType.wishlistImage: 'zentry_wishlist_images',
  CloudinaryUploadType.bugReport: 'zentry_bug_reports',
  CloudinaryUploadType.accountAppeal: 'zentry_account_appeal',
};
```

**Key Methods**:

```dart
// Upload image (mobile)
Future<String> uploadImage(File file, {required CloudinaryUploadType uploadType})

// Upload image (web-compatible)
Future<String> uploadXFile(XFile xfile, {required CloudinaryUploadType uploadType})
```

**Web Support**:
- Uses `XFile` from `image_picker` for cross-platform compatibility
- On web: Reads bytes and uses `CloudinaryFile.fromByteData()`
- On mobile: Uses `CloudinaryFile.fromFile()` with file path

**Files Using CloudinaryService**:

1. **Profile Picture Upload**:
   - `lib/features/profile/views/profile_screen.dart`
   - Upload type: `CloudinaryUploadType.accountPhoto`

2. **Journal Image Upload**:
   - `lib/features/journal/views/add_journal_screen.dart`
   - `lib/features/journal/views/edit_journal_screen.dart`
   - Upload type: `CloudinaryUploadType.journalImage`

3. **Project Ticket Images**:
   - `lib/features/projects/views/add_ticket_page.dart`
   - `lib/features/projects/views/edit_ticket_page.dart`
   - Upload type: `CloudinaryUploadType.projectImage`

4. **Wishlist Item Images**:
   - `lib/features/wishlist/views/add_wishlist_screen.dart`
   - Upload type: `CloudinaryUploadType.wishlistImage`

5. **Bug Reports**:
   - `lib/features/profile/views/bug_report_screen.dart`
   - Upload type: `CloudinaryUploadType.bugReport`

6. **Account Appeals**:
   - `lib/features/profile/views/account_appeal_screen.dart`
   - Upload type: `CloudinaryUploadType.accountAppeal`

**Image Upload Flow**:

```dart
// 1. User picks image
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);

// 2. Upload to Cloudinary
final imageUrl = await CloudinaryService().uploadXFile(
  image!,
  uploadType: CloudinaryUploadType.projectImage,
);

// 3. Store URL in Firestore
await FirestoreService().updateTicket(ticketId, {
  'imageUrls': FieldValue.arrayUnion([imageUrl]),
});
```

---

## Google Authentication

Zentry uses **Firebase Authentication** with **Google Sign-In** for user authentication.

### Setup Process

#### 1. Firebase Configuration

**Android** (`android/app/google-services.json`):
- Downloaded from Firebase Console
- Contains client IDs and API keys

**iOS** (`ios/Runner/GoogleService-Info.plist`):
- Downloaded from Firebase Console
- Contains bundle ID and API keys

**Web** (`web/index.html`):
```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "...",
    authDomain: "...",
    projectId: "...",
    // ...
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

#### 2. Authentication Implementation

**Main Entry Point** (`lib/main.dart`):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Cloudinary
  CloudinaryService().initialize();
  
  runApp(const MyApp());
}
```

**Auth Flow** (`lib/features/auth/views/login_page.dart`):

```dart
// Google Sign-In
Future<void> signInWithGoogle() async {
  try {
    // 1. Trigger Google Sign-In flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    // 2. Obtain auth details
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    
    // 3. Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // 4. Sign in to Firebase
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    // 5. Create/update user in Firestore
    await FirestoreService().createUser(User(
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
      fullName: userCredential.user!.displayName ?? '',
      // ...
    ));
  } catch (e) {
    // Handle error
  }
}
```

**Auth State Management** (`lib/core/views/home_page.dart`):

```dart
@override
void initState() {
  super.initState();
  _setupAuthListener();
}

void _setupAuthListener() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      // User is signed in
      _currentUserId = user.uid;
      _currentUserEmail = user.email;
      _loadUserData();
    } else {
      // User is signed out
      Navigator.pushReplacementNamed(context, '/login');
    }
  });
}
```

**Protected Routes**:
- All screens except Login/Register check authentication in `initState()`
- Redirect to login if `FirebaseAuth.instance.currentUser == null`

---

## APIs and Packages

### Firebase Services

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `firebase_core` | ^4.2.1 | Firebase initialization | `main.dart`, all Firebase services |
| `firebase_auth` | ^6.1.2 | User authentication | `auth/`, `home_page.dart`, all authenticated screens |
| `cloud_firestore` | ^6.1.0 | NoSQL database | `FirestoreService`, `ProjectManager`, all CRUD operations |
| `firebase_messaging` | ^16.0.4 | Push notifications | `NotificationManager` |
| `firebase_storage` | ^13.0.4 | File storage (deprecated in favor of Cloudinary) | None currently active |

### Google Services

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `google_sign_in` | ^6.2.1 | Google OAuth | `lib/features/auth/views/login_page.dart` |
| `google_fonts` | ^6.1.0 | Custom fonts | Theme configuration |

### Image Services

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `cloudinary_public` | ^0.23.1 | Image upload/CDN | `CloudinaryService`, all image upload screens |
| `image_picker` | ^1.0.7 | Pick images from gallery/camera | Add/Edit screens for tickets, journals, wishlist, profile |

### UI & Rich Text

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `flutter_quill` | ^11.5.0 | Rich text editor | `RichTextEditor`, ticket/journal description fields |
| `flutter_svg` | ^2.0.9 | SVG rendering | UI assets |
| `table_calendar` | ^3.0.9 | Calendar widget | `HomePage` dashboard |
| `fl_chart` | ^0.69.0 | Charts and graphs | Analytics screens |

### Notifications

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `flutter_local_notifications` | ^17.2.2 | Local notifications | `NotificationManager` |
| `timezone` | ^0.9.4 | Timezone handling | Notification scheduling |

### Utilities

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `intl` | ^0.20.2 | Date/number formatting | All date displays, deadline formatting |
| `uuid` | ^4.2.2 | Generate unique IDs | Creating tickets, projects, notifications |
| `shared_preferences` | ^2.2.2 | Local storage | User preferences, cache |
| `rxdart` | ^0.28.0 | Reactive streams | Real-time data streams |
| `timeago` | ^3.7.0 | Relative time formatting | "2 hours ago" in notifications |
| `encrypt` | ^5.0.3 | Data encryption | Sensitive data handling |
| `crypto` | ^3.0.3 | Cryptographic operations | Password hashing, token generation |

### Form Fields

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `intl_phone_field` | ^3.2.0 | Phone number input | Profile screen |
| `country_picker` | ^2.0.26 | Country selection | Registration/profile |

### State Management

| Package | Version | Purpose | Files Using It |
|---------|---------|---------|----------------|
| `provider` | ^6.1.1 | State management | App-wide state (user, theme, etc.) |

---

## API Usage Summary

### Firebase APIs

1. **Authentication API**:
   - **Endpoint**: Firebase Auth REST API
   - **Methods**: `signInWithCredential()`, `signOut()`, `authStateChanges()`
   - **Used in**: `lib/features/auth/`, `lib/core/views/home_page.dart`

2. **Firestore API**:
   - **Endpoint**: Cloud Firestore REST/gRPC API
   - **Methods**: CRUD operations via `FirestoreService`
   - **Collections**:
     - `users/` - User profiles
     - `projects/{projectId}/tickets/` - Project tickets
     - `journals/` - Journal entries
     - `wishlists/` - Wishlist items
     - `notifications/users/{userId}/notifications/` - User notifications

3. **Cloud Messaging API**:
   - **Endpoint**: FCM API
   - **Purpose**: Push notifications
   - **Used in**: `NotificationManager`

### Cloudinary API

- **Endpoint**: `https://api.cloudinary.com/v1_1/{cloud_name}/image/upload`
- **Authentication**: Unsigned presets (no API key required for uploads)
- **Upload Presets**:
  - `zentry_accounts_photos`
  - `zentry_journal_images`
  - `zentry_project_images`
  - `zentry_wishlist_images`
  - `zentry_bug_reports`
  - `zentry_account_appeal`
- **Response**: JSON with `secure_url` for the uploaded image
- **Used in**: All screens with image upload functionality

### Google Sign-In API

- **Endpoint**: Google OAuth 2.0
- **Scopes**: Email, profile
- **Flow**: OAuth 2.0 with redirect
- **Used in**: `lib/features/auth/views/login_page.dart`

---

## Key Implementation Patterns

### 1. Real-Time Data Streaming

```dart
// Listen to projects in real-time
Stream<List<Project>> getUserProjectsStream(String userId, String userEmail) {
  return _firestore
      .collection('projects')
      .where('memberEmails', arrayContains: userEmail)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
}
```

### 2. Role-Based Access Control

```dart
// Check if user can edit ticket
bool canEditTicket(Ticket ticket, String userId) {
  final project = getProjectById(ticket.projectId);
  return project.userId == userId; // Only project owner
}

// Check if user can update ticket status
bool canUpdateStatus(Ticket ticket, String userEmail) {
  return ticket.assignedTo.contains(userEmail); // Only assignees
}
```

### 3. Cross-Platform Image Upload

```dart
Future<String> uploadImage(XFile file) async {
  if (kIsWeb) {
    // Web: Use bytes
    final bytes = await file.readAsBytes();
    return _uploadBytes(bytes, file.name);
  } else {
    // Mobile: Use file path
    return _uploadFile(File(file.path));
  }
}
```

### 4. Rich Text Storage

```dart
// Save rich text to Firestore
final richDescription = _descriptionController.getJsonContent(); // Returns Delta JSON
await updateTicket(ticketId, {
  'richDescription': richDescription,
  'description': _descriptionController.getPlainText(), // Fallback
});

// Display rich text
final doc = Document.fromJson(jsonDecode(ticket.richDescription));
return QuillEditor.basic(
  controller: QuillController(document: doc, readOnly: true),
);
```

---

## Security Rules Summary

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Projects: members can read, owner can write
    match /projects/{projectId} {
      allow read: if request.auth.email in resource.data.memberEmails;
      allow write: if request.auth.uid == resource.data.userId;
      
      // Tickets within projects
      match /tickets/{ticketId} {
        allow read: if request.auth.email in get(/databases/$(database)/documents/projects/$(projectId)).data.memberEmails;
        allow write: if request.auth.uid == get(/databases/$(database)/documents/projects/$(projectId)).data.userId;
      }
    }
    
    // Notifications: users can only access their own
    match /notifications/users/{userId}/notifications/{notificationId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## Future Enhancements

1. **Offline Support**: Implement Firestore offline persistence for better UX
2. **Image Optimization**: Compress images before upload using `flutter_image_compress`
3. **Analytics**: Add Firebase Analytics for user behavior tracking
4. **Crashlytics**: Implement Firebase Crashlytics for error monitoring
5. **Cloud Functions**: Move notification logic to Firebase Cloud Functions for better scalability

---

**Last Updated**: December 15, 2025  
**Version**: 1.0.0+1
