# Born Again Memories (BAM)

A Flutter app for capturing and cherishing your child's precious milestones — photos, videos, audio, and links — all in one beautiful place.

## Features

- **Milestone tracking** — log moments with photos, videos, audio recordings, and external links
- **Multiple profiles** — manage milestones for multiple children
- **Google Sign-In** — secure authentication via Firebase
- **Rich media attachments** — pick files, images, or add URLs with live link previews
- **Chime sounds & haptics** — satisfying feedback when adding a milestone
- **Theming** — choose your accent color, toggle sound and haptic feedback
- **Cross-platform** — runs on iOS, Android, macOS, web, Linux, and Windows

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ≥ 3.11)
- A Firebase project with Google Sign-In enabled

### Firebase Setup

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication → Google** sign-in
3. Register your iOS and Android apps, download their config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Generate `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. In `ios/Runner/Info.plist`, replace `REVERSED_CLIENT_ID` with the value from `GoogleService-Info.plist`

### Run

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                  # App entry point, Firebase init, auth routing
├── firebase_options.dart      # Generated Firebase config (not committed)
├── models/                    # Data models (Milestone, KidProfile, Attachment, …)
├── providers/                 # Riverpod state (auth, profiles, settings, form)
├── screens/                   # Full-page screens (login, home, settings)
├── widgets/                   # Reusable UI components
└── utils/                     # Helpers (date formatting, attachments, chime audio)
```

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter + Dart |
| State management | Riverpod |
| Authentication | Firebase Auth + Google Sign-In |
| Media | image_picker, file_picker, audioplayers |
| Link previews | any_link_preview, url_launcher |

## Contributing

Pull requests are welcome. For major changes please open an issue first.

## License

MIT
