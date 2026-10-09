# Zunax IT Support - Flutter Mobile App (iOS & Android)

A modern, cross-platform Flutter application for iOS and Android built for the **Zunax IT Support Ticketing System**. It connects directly to the custom Odoo REST API endpoints (`/api/v1/...`).

---

## 📱 Features

- 🔐 **Secure REST Authentication**: Odoo login and session management via `/api/v1/auth/login`.
- ⚡ **Offline Demo Mode**: Toggle demo mode to preview app UI offline without a running Odoo server.
- 📊 **Real-time Ticket Dashboard**: Summary stats for Total, New, In Progress, and Resolved tickets.
- 🎯 **Stage Filters & Search**: Quick filter pills (Draft, New, In Progress, Resolved, Cancelled) and dynamic title/number search.
- ➕ **Raise New IT Tickets**: Auto-fetching IT Departments & predefined Subjects with priority selection.
- 🔄 **Ticket Workflow Stepper**: Visual stepper tracking ticket progress from Draft → New → In Progress → Resolved.
- 💬 **Live Chatter Timeline**: Discussion thread viewing and commenting powered by Odoo's `mail.message`.

---

## 🚀 How to Run on iOS & Android

### Prerequisites
1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0.0 or higher).
2. Install Android Studio (for Android Emulator / APK build) or Xcode (for iOS Simulator / iPhone build).

### Steps
1. Open terminal in this folder:
   ```bash
   cd zunax_it_flutter
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on an Android emulator or connected device:
   ```bash
   flutter run
   ```
4. Build Android APK:
   ```bash
   flutter build apk --release
   ```
5. Build iOS App (macOS required):
   ```bash
   flutter build ios
   ```
