# Public Taxi Demo Final QA & Bug Fixes Tasks

- [x] **1. Align Fare Formula with Production**
    - [x] Update `TaxiDemoService.calculateFare` constants and logic
    - [x] Update `TaxiDemoProvider` to pass estimated minutes to fare calculation
    - [x] Verify Hawassa University → Piazza fare logic (15 + 8/km + 0.5/min)
- [x] **2. Enhance TaxiDemoProvider**
    - [x] Comprehensive `reset()` (clear AI reason, etc.)
    - [x] Ensure all timers are properly cancelled on dispose/reset
- [x] **3. Improve TaxiDemoScreen UI/UX**
    - [x] Implement Map Auto-Centering for taxi movement
    - [x] Ensure map is responsive and markers are correct
- [x] **4. AI Assistant Integration**
    - [x] Inject taxi demo state into `AiAssistantScreen`
    - [x] Add quick-response logic for taxi-related queries
- [x] **5. Final Verification**
    - [x] Run `analyze_file` on modified files (No errors)
    - [x] Perform full end-to-end manual walkthrough
    - [x] Test with backend offline
    - [x] Verify Chrome Web performance
