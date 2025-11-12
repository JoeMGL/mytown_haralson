# Visit Haralson — Flutter + Firebase Starter

A unified Flutter codebase for:
- Visitor mobile app (iOS/Android/PWA)
- Web Admin (Flutter Web)

## Quick Start
1. Ensure Flutter SDK is installed (3.24+ recommended).
2. `flutter create .` is **not** required — this is a ready project skeleton.
3. Run `flutter pub get`.
4. Add your Firebase config by generating `lib/firebase_options.dart` via:
   ```bash
   flutterfire configure
   ```
5. Update `android`, `ios`, and `web` Firebase config files as needed.
6. Run dev:
   ```bash
   flutter run -d chrome       # web admin / PWA
   flutter run -d windows      # desktop (optional)
   flutter run -d ios          # iOS
   flutter run -d android      # Android
   ```

## Project Structure
```
lib/
  main.dart
  app_router.dart
  core/
    theme/app_theme.dart
    widgets/city_chips.dart
  features/
    home/home_page.dart
    explore/explore_page.dart
    events/events_page.dart
    admin/
      admin_shell.dart
      dashboard_page.dart
      attractions_page.dart
      add_attraction_page.dart
      announcements_page.dart
      add_announcement_page.dart
firebase/
  firestore.rules
  firestore.indexes.json
```

## Notes
- State management: Riverpod
- Routing: GoRouter
- Maps: Google Maps Flutter (add API key)
