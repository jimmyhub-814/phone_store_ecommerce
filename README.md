 # 📱 DM Store — Phone Store App

A full-featured Vietnamese e-commerce mobile application for purchasing smartphones, built with Flutter & Firebase.

<img width="720" height="1600" alt="Image" src="https://github.com/user-attachments/assets/9e73b2e6-b65a-4172-a917-956e4aa1b319" />

<img width="720" height="1600" alt="Image" src="https://github.com/user-attachments/assets/8f887bb0-95d9-4601-9d8b-f473c177e5a8" />

<img width="720" height="1600" alt="Image" src="https://github.com/user-attachments/assets/4afd1a99-a598-439d-be1e-2fce89c19706" />
---

## ✨ Features

### 🛍️ User App (DM Store)
- **Authentication** — Email/Password, Google Sign-In, Phone OTP (Firebase Auth)
- **Product Browsing** — Search, filter, view history, product detail pages
- **Smart Recommendations** — Collaborative filtering based on order history, cart, view & search behavior (weighted scoring)
- **Shopping Cart** — Real-time sync with Firestore, atomic batch deletes on purchase
- **Order Management** — Place, track, and cancel orders with live status updates
- **AI Chat Assistant** — Gemini-powered chatbot with streaming text responses and stop functionality
- **Push Notifications** — FCM integration across foreground, background, and killed states with deep linking to order detail
- **Privacy Policy & Terms of Service** — Vietnamese localized legal content


---

## 🏗️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Backend | Firebase (Firestore, Auth, Cloud Functions, FCM, App Check) |
| State Management | BLoC / Cubit, Provider, GetX |
| AI | Google Gemini API |
| Recommendations | Custom collaborative filtering engine |
| Charts | Syncfusion Flutter Charts |
| Image Handling | Parallel uploads via `Future.wait`, pure-Dart compression |

---
 

 

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/dm-store.git
cd dm-store

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add your Android/iOS app and download `google-services.json` / `GoogleService-Info.plist`
3. Place the config files in the appropriate directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
4. Enable **Authentication** (Email, Google, Phone)
5. Enable **Firestore**, **FCM**, and **App Check**
6. Add SHA-1 and SHA-256 fingerprints for Google Sign-In and Phone Auth

### Environment Configuration

Create `lib/app_constants/api_helper.dart` and fill in:

```dart
// Gemini API key
static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

---

## 🔔 Push Notifications

FCM is configured to handle all three app states:

| State | Behavior |
|---|---|
| Foreground | In-app notification banner |
| Background | System tray → tap opens order detail |
| Killed | Launch → await auth → navigate to order detail |

Deep linking from killed state uses `authStateChanges().first` to wait for auth before navigating, preventing Navigator-not-mounted errors.

---

## 🤖 AI Chat (Gemini)

- Streaming character-by-character text rendering
- Stop response mid-stream
- Session-based chat history (cleared on page exit)
- `ScrollController` managed in UI layer, decoupled from Cubit state

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.x
  provider: ^6.x
  get: ^4.x
  firebase_core: ^2.x
  cloud_firestore: ^4.x
  firebase_auth: ^4.x
  firebase_messaging: ^14.x
  loading_animation_widget: ^1.x
  syncfusion_flutter_charts: ^x.x
  uuid: ^4.x
  equatable: ^2.x
```

---

## 📸 Screenshots

> _Coming soon_

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Built with ❤️ in Vietnam
</div>
