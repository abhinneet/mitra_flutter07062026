# MITRA Flutter — AR Learning Platform
### Ministry of Education, Govt. of India

> **Full Flutter/Dart rewrite** of the original Expo/React Native project.  
> Targets VS Code + Flutter/Dart Extension. API-ready for your dashboard backend.

---

## 📁 Project Structure

```
mitra_flutter/
├── lib/
│   ├── main.dart                    # Entry point, Firebase init, theme
│   ├── router.dart                  # GoRouter — all app routes
│   ├── firebase_options.dart        # ⚠ Regenerate with: flutterfire configure
│   ├── constants/
│   │   └── colors.dart              # Brand colors, fonts, spacing, theme
│   ├── models/
│   │   └── user.dart                # MitraUser model (mirrors useAuthStore.ts)
│   ├── services/
│   │   └── api_service.dart         # Dio API client + all domain APIs
│   ├── stores/
│   │   ├── auth_store.dart          # Auth state (Riverpod = Zustand equivalent)
│   │   └── offline_store.dart       # Offline queue (mirrors useOfflineQueue.ts)
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── splash_screen.dart   # S-01: Animated splash + auth check
│   │   │   ├── onboarding_screen.dart # S-02: 3-slide swipeable intro
│   │   │   ├── login_screen.dart    # S-03: Phone + WhatsApp OTP login
│   │   │   └── setup_screen.dart    # S-04: 3-step profile wizard
│   │   ├── student/
│   │   │   ├── student_shell.dart   # Bottom tab navigator (5 tabs)
│   │   │   ├── home_screen.dart     # S-05: Dashboard with XP, streak, subjects
│   │   │   ├── learn_screen.dart    # Curriculum tree
│   │   │   ├── ar_tab_screen.dart   # AR topic list
│   │   │   ├── ranks_screen.dart    # Class leaderboard
│   │   │   └── student_profile_screen.dart
│   │   ├── teacher/
│   │   │   ├── teacher_shell.dart   # Bottom tab navigator (5 tabs, green theme)
│   │   │   ├── teacher_home_screen.dart
│   │   │   ├── students_screen.dart
│   │   │   ├── analytics_screen.dart
│   │   │   ├── assign_screen.dart
│   │   │   └── teacher_profile_screen.dart
│   │   ├── quiz/
│   │   │   ├── quiz_screen.dart     # Full quiz flow
│   │   │   └── quiz_result_screen.dart
│   │   └── ar/
│   │       └── ar_viewer_screen.dart # AR camera + overlay UI
│   └── widgets/
│       └── gradient_button.dart     # Shared saffron gradient button
├── android/
│   ├── app/
│   │   ├── build.gradle             # Firebase BoM, compileSdk 34
│   │   ├── google-services.json     # ⚠ Replace with real file from Firebase
│   │   └── src/main/
│   │       └── AndroidManifest.xml  # Camera, internet, FCM permissions
│   └── build.gradle                 # Project-level Gradle
├── .vscode/
│   ├── launch.json                  # Debug/profile/release run configs
│   ├── settings.json                # Dart format + linting rules
│   └── extensions.json              # Recommended extensions
├── pubspec.yaml                     # All dependencies
├── .env                             # ⚠ Fill with your real API URL + Firebase keys
└── .gitignore
```

---

## ⚡ Quick Start (VS Code)

### 1. Prerequisites
```bash
# Install Flutter SDK (if not installed)
# https://docs.flutter.dev/get-started/install

flutter --version   # Should be ≥ 3.19.0
dart --version      # Should be ≥ 3.3.0
```

Install VS Code extensions:
- **Dart** (`Dart-Code.dart-code`)
- **Flutter** (`Dart-Code.flutter`)

### 2. Clone & install
```bash
cd mitra_flutter
flutter pub get
```

### 3. Fill in your environment variables
```bash
# Edit .env — replace placeholder values:
nano .env
```
```env
API_BASE_URL=https://your-mitra-api.a.run.app   # Your Cloud Run URL
FIREBASE_PROJECT_ID=watchaugs-mitra
FIREBASE_MESSAGING_SENDER_ID=123456789
```

### 4. Set up Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Connect to your Firebase project (regenerates firebase_options.dart)
flutterfire configure --project=watchaugs-mitra
```
Then replace `android/app/google-services.json` with the real file from:  
Firebase Console → Project Settings → Android App → Download `google-services.json`

### 5. Run
```bash
# Option A: VS Code — press F5 and select "MITRA (debug)"
# Option B: Terminal
flutter run
```

---

## 🔌 API Handshake

Your dashboard backend connects via these endpoints in `lib/services/api_service.dart`.  
Set `API_BASE_URL` in `.env` to your Cloud Run / backend URL.

| Domain | Class | Key Endpoints |
|--------|-------|---------------|
| Auth | `AuthAPI` | `POST /api/auth/login`, `/verify-otp`, `/refresh`, `GET /api/auth/me` |
| Users | `UsersAPI` | `GET /api/users/me`, `PUT /api/users/:id` |
| Curriculum | `CurriculumAPI` | `GET /api/curriculum/tree`, `/ar-topics`, `/hierarchy/:state` |
| AR Assets | `ArAPI` | `GET /api/ar/assets`, `/api/ar/assets/:id`, `/api/ar/links/:nodeId` |
| Quiz | `QuizAPI` | `GET /api/quiz`, `/api/quiz/:id/questions`, `POST /api/quiz/attempts` |
| Analytics | `DashboardAPI` | `GET /api/dashboard/summary`, `/api/analytics/overview` |
| Telemetry | `TelemetryAPI` | `POST /api/analytics/telemetry` |
| Notifications | `NotificationsAPI` | `GET /api/notifications` |

**Token management:** Dio automatically attaches `Bearer <token>` from `flutter_secure_storage`  
and silently refreshes on `401` — same logic as the original Expo `api.ts`.

---

## 🌐 i18n Languages Supported

Hindi · English · Tamil · Telugu · Kannada · Bengali · Marathi · Gujarati  
*(Matches original `i18n/index.ts`)*

---

## 📦 Key Package Equivalents

| Expo Package | Flutter Package |
|---|---|
| `expo-router` | `go_router` |
| `zustand` | `flutter_riverpod` |
| `axios` | `dio` |
| `expo-secure-store` | `flutter_secure_storage` |
| `expo-sqlite` | `sqflite` |
| `expo-notifications` | `firebase_messaging` + `flutter_local_notifications` |
| `expo-camera` | `camera` |
| `expo-linear-gradient` | Flutter's built-in `LinearGradient` |
| `@react-native-community/netinfo` | `connectivity_plus` |
| `@tanstack/react-query` | `flutter_riverpod` (FutureProvider) |
| `i18next` | `flutter_localizations` + `intl` |

---

## 🚀 Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

> Before release: replace `signingConfig signingConfigs.debug` in  
> `android/app/build.gradle` with your production keystore.

---

## ⚠️ Checklist Before First Run

- [ ] `flutter pub get` completed without errors
- [ ] `.env` filled with real `API_BASE_URL`
- [ ] `android/app/google-services.json` replaced with real Firebase file
- [ ] `flutterfire configure` run → `lib/firebase_options.dart` regenerated
- [ ] Android device/emulator connected (`flutter devices`)
- [ ] Press **F5** in VS Code with "MITRA (debug)" selected
