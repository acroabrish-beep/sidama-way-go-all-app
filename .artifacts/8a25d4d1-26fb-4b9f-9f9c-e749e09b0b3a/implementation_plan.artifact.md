# FINAL QA — SIDAMA WAY GO PUBLIC TAXI DEMO

This plan outlines the final QA pass and necessary bug fixes to ensure the Public Taxi Demo is "Ready for Live Demonstration".

## User Review Required

> [!IMPORTANT]
> The fare formula will be aligned with the production `ride_service.dart`.
> Map tracking will be implemented to ensure the taxi remains visible during movement.
> The AI Assistant will be updated to reflect the current taxi demo state.

## Proposed Changes

### [Component] Taxi Demo Service

#### [MODIFY] [taxi_demo_service.dart](file:///C:/src/sidama_way_go/lib/services/taxi_demo_service.dart)
- Update `calculateFare` to match production: `15 + (km * 8) + (min * 0.5)`.
- Update signature to `calculateFare(double distanceKm, int estimatedMinutes)`.

### [Component] Taxi Demo Provider

#### [MODIFY] [taxi_demo_provider.dart](file:///C:/src/sidama_way_go/lib/providers/taxi_demo_provider.dart)
- Update calls to `calculateFare` with the new signature.
- Improve `reset()` to clear all demo-related fields (`aiSelectionReason`, etc.).
- Add logic to center map if taxi moves out of view (or notify listeners for the UI to handle it).

### [Component] Taxi Demo Screen

#### [MODIFY] [taxi_demo_screen.dart](file:///C:/src/sidama_way_go/lib/screens/taxi_demo_screen.dart)
- Implement map auto-centering logic when the taxi moves.
- Verify responsive layout (no overflows).

### [Component] AI Assistant

#### [MODIFY] [ai_assistant_screen.dart](file:///C:/src/sidama_way_go/lib/screens/ai_assistant_screen.dart)
- Inject `TaxiDemoProvider` state into the AI conversation context.
- Handle taxi-specific queries ("Where is my taxi?", "How much is the fare?") with demo-aware responses.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no regressions.
- Run `test/taxi_demo_logic_test.dart`.

### Manual Verification
- Perform full end-to-end flow: **Pickup → Destination → Map → Fare → AI Matching → Taxi Approaching → Taxi Arrived → Start Ride → Live Movement → Destination → Ride Completed → Reset**.
- Test with backend offline.
- Test on Chrome (web).
- Verify fare calculation with specific example: Hawassa University to Piazza (~4.8 km, ~14 min).
