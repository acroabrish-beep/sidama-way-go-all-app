# sidama_way_go

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running the Project with Gemini AI

To enable the AI Assistant, you MUST pass the Gemini API Key using `--dart-define` at runtime.

### Windows
```bash
flutter run -d windows --dart-define=GEMINI_API_KEY=your_actual_key
```

### Web
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_actual_key
```

### Android Release
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=your_actual_key
```

