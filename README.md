# Sidama Way Go - Flutter client

Flutter client for the Sidama Way Go MVP (web, Android). The app talks to the
Next.js backend in `../sidama_way_go_backend`; it does not hold the Gemini key,
Supabase service-role key, QR signing secret, or payment secrets.

## What is real in this MVP

- Citizen reports with backend AI triage, admin status changes, and live status
  updates for the citizen (5 s polling, incremental `updatedSince`).
- Station tickets with server-side tariffs, DEV payment, signed QR, PDF
  receipt, and one-time boarding verification.
- Read-only AI assistant that answers from the backend's live database
  snapshot.
- Station queue and metrics update within 10 s.

Sample-only modules (hotels, food, pharmacy, healthcare, tourism, Eco-Shine,
wallet) are hidden when `MVP_MODE=true`. Public Taxi Demo Mode stays visible and
is labelled DEMO in the menu, app bar, and assistant answers.

## Run

Start the backend first (see its README). Then:

```bash
flutter pub get
flutter run -d chrome ^
  --dart-define=API_BASE_URL=http://localhost:3000 ^
  --dart-define=FIREBASE_PROJECT_ID=<staging-project-id> ^
  --dart-define=SUPABASE_URL=<staging-url> ^
  --dart-define=SUPABASE_ANON_KEY=<staging-anon-key> ^
  --dart-define=GOOGLE_MAPS_API_KEY=<maps-key> ^
  --dart-define=MVP_MODE=true
```

Android emulator: use `--dart-define=API_BASE_URL=http://10.0.2.2:3000`.
Physical devices need the machine's LAN IP.

| Define | Purpose |
| --- | --- |
| `API_BASE_URL` | Backend origin (required in release builds) |
| `FIREBASE_PROJECT_ID` | Firebase project validation |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Legacy client reads |
| `GOOGLE_MAPS_API_KEY` | Maps features |
| `MVP_MODE` | `true` hides sample-only modules from menus |

There is no `GEMINI_API_KEY` dart-define. AI calls go through the backend.

## Gates

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Documentation

Architecture, demo runbook, readiness table, and responsible AI notes live in
the backend repository under `docs/`:

- `../sidama_way_go_backend/docs/ARCHITECTURE.md`
- `../sidama_way_go_backend/docs/DEMO_RUNBOOK.md`
- `../sidama_way_go_backend/docs/DEMO_READINESS.md`
- `../sidama_way_go_backend/docs/RESPONSIBLE_AI.md`
