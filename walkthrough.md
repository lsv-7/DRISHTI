# Walkthrough — DRISHTI AI Phase 6: Citizen Basic Details & Profile Persistence

## Problem Addressed
Previously, the DRISHTI Flutter client only collected vulnerability indicators (such as mobility, medical conditions, swimming ability) while completely missing essential basic citizen identity and contact details (`fullName`, `phoneNumber`, `email`, `city`, `address`, `emergencyContactName`, `emergencyContactPhone`). Responders and command center operators could not identify the reporter, communicate with survivors or their next of kin, or trace incident origins.

This corrective enhancement adds first-class citizen identification and contact persistence, updates onboarding and profile management, integrates reporter identity with emergency reporting, maintains strict isolation of the immutable vulnerability snapshot, and establishes offline persistence with online background synchronization.

---

## 1. What was Implemented

### Strongly-Typed Citizen Profile Model & Validation
- **Model** ([`flutter-frontend/lib/models/citizen_profile.dart`](file:///c:/Users/wwwlo/Downloads/DRISHTI/flutter-frontend/lib/models/citizen_profile.dart)):
  - Defines `CitizenProfile` containing `fullName`, `phoneNumber`, `email`, `age`, `gender`, `address`, `city`, `emergencyContactName`, `emergencyContactPhone`, and `status` (`CitizenProfileStatus.complete` / `incomplete`).
  - Added deterministic static validation methods:
    - `validateFullName(value)`: Non-empty, 2–100 characters.
    - `validatePhoneNumber(value)`: Non-empty, 8–15 digits (handles international prefixes and formatting).
    - `validateEmail(value)`: Optional, enforces valid email syntax supporting multi-domain extensions when provided.
    - `validateEmergencyPhone(value)`: Optional, 8–15 digits when provided.
  - Implemented `validate()`, `toJson()`, `toPersistenceJson()`, `fromJson()`, `copyWith()`, `defaultProfile()`, and `empty()`.

### Strict Identity vs. Vulnerability Snapshot Separation (ADR-008)
- **Architectural Invariant**:
  - Personal identity information (`reporter_name`, `contact_phone`) is placed exclusively at the **root level** of `EmergencyCreate`, `EmergencyResponse`, and local emergency dictionaries.
  - The `vulnerability_snapshot` dictionary remains strictly isolated to operational dispatch heuristics (`age`, `age_group`, `can_swim`, `mobility_status`, `medical_conditions`, `disability_notes`).
  - **Snapshot Immutability**: Modifying the citizen profile after an emergency has been reported does NOT alter the historical emergency's frozen vulnerability snapshot or root-level reporter identity.

### Two-Step Onboarding Flow
- **OnboardingScreen** ([`flutter-frontend/lib/screens/onboarding_screen.dart`](file:///c:/Users/wwwlo/Downloads/DRISHTI/flutter-frontend/lib/screens/onboarding_screen.dart)):
  - **Step 1 (Citizen Identification)**: Collects full name, phone number, optional email, city, address, and emergency contact details with form validation.
  - **Step 2 (Vulnerability Profile)**: Collects operational dispatch heuristics (age, mobility status, swimming ability, medical conditions, disability notes) alongside the mandatory educational heuristic disclaimer.
  - **Skip Options**: Citizens can skip the vulnerability setup to immediately proceed with a completed basic citizen profile and standard default vulnerability profile.

### Dedicated Citizen Profile Management
- **ProfileScreen** ([`flutter-frontend/lib/screens/profile_screen.dart`](file:///c:/Users/wwwlo/Downloads/DRISHTI/flutter-frontend/lib/screens/profile_screen.dart)):
  - 4 clean, structured sections:
    1. *Basic Information* (Full Name, Phone Number, Email)
    2. *Location & Personal Details* (City, Gender, Address)
    3. *Emergency Contact* (Contact Name, Contact Phone)
    4. *Vulnerability Profile (Disaster Dispatch)* (Isolated heuristics with educational disclaimer)
  - Changes are saved immediately to local storage (`SharedPreferences`) and synchronized to the backend via `PUT /api/v1/profile/{user_id}` when online.

### Personalized Home Screen & Brand Palette
- **HomeScreen** ([`flutter-frontend/lib/screens/home_screen.dart`](file:///c:/Users/wwwlo/Downloads/DRISHTI/flutter-frontend/lib/screens/home_screen.dart)):
  - Personalized top-bar greeting: `"Hi, <FirstName>"`.
  - Profile Summary Card displays citizen full name, phone number, and city above the vulnerability badges.
  - Strictly adheres to the DRISHTI design system palette: Primary Blue `#2563EB`, Deep Navy `#1E3A8A`, Dark Navy Text `#0F172A`, Warning Orange `#F97316`, Success Green `#22C55E`, Light Blue `#DBEAFE`, and Background `#F8FAFC`.

### Backend Schema & API
- **Data Models** ([`backend/app/models/domain.py`](file:///c:/Users/wwwlo/Downloads/DRISHTI/backend/app/models/domain.py)):
  - `User`: Added `phone`, `gender`, `address`, `city`, `emergency_contact_name`, `emergency_contact_phone`; set `email` nullable to support phone-only registrations.
  - `Emergency`: Added `reporter_name`, `contact_phone`.
- **Schemas** ([`backend/app/schemas/domain.py`](file:///c:/Users/wwwlo/Downloads/DRISHTI/backend/app/schemas/domain.py)):
  - Added `CitizenProfileUpdate` and `CitizenProfileResponse` with Pydantic field validators.
  - Added `reporter_name` and `contact_phone` to `EmergencyCreate` and `EmergencyResponse`.
- **Endpoints** ([`backend/app/api/v1/profile.py`](file:///c:/Users/wwwlo/Downloads/DRISHTI/backend/app/api/v1/profile.py)):
  - `GET /api/v1/profile/{user_id}`: Retrieves citizen profile; returns 404 if not found.
  - `PUT /api/v1/profile/{user_id}`: Creates or updates citizen basic details.

---

## 2. Automated Test Verification

### Flutter Test Suite: 16 Suites, 178 Tests (100% Passing)
Executed `flutter test` across all suites:
- `test/citizen_profile_test.dart` (16/16 PASSED):
  1. *Model: CitizenProfile serialization and deserialization*
  2. *Model: Persistence JSON includes status and roundtrips accurately*
  3. *Validation: Full name constraints (2 to 100 chars, non-empty)*
  4. *Validation: Phone number constraints (8 to 15 digits)*
  5. *Validation: Email constraints (optional, valid format if present)*
  6. *Validation: Emergency contact phone constraints (optional)*
  7. *Distinction: Basic Profile vs Vulnerability Profile completion states*
  8. *OfflineService: Persistence across simulated app restarts*
  9. *Emergency Submission: Reporter details at top level, strictly isolated from vulnerability snapshot*
  10. *Background Sync: PUT /api/v1/profile/{user_id} when online*
  11. *UI: OnboardingScreen Step 1 validates required citizen details*
  12. *UI: OnboardingScreen transitions from Step 1 to Step 2 upon valid input*
  13. *UI: OnboardingScreen skip vulnerability retains complete citizen profile*
  14. *UI: ProfileScreen renders distinct Citizen and Vulnerability sections*
  15. *UI: HomeScreen renders personalized greeting and citizen info card*
  16. *UI: ProfileScreen saves updated details and calls OfflineService*
- Plus 162 existing tests across all other 15 suites -> **Total: 178/178 PASSED**.

### Static Analysis: 0 Issues
Executed `flutter analyze` inside `flutter-frontend/`:
```
Analyzing flutter-frontend...
No issues found! (ran in 3.5s)
```
**0 errors, 0 warnings, 0 lints.**

### Backend Tests: 24 Tests (100% Passing)
Executed `py -3.14 -m pytest app/tests/ -v`:
- All 24 test cases passed in 2.99s across auth, decision engine, idempotency, and citizen profile.

### Frontend Web Build
Executed `npm run build` inside `frontend/`:
- **Vite production build succeeded cleanly in 497ms** with 0 errors.

---

## 3. Mobile-to-Admin End-to-End Synchronization Resolution

### Root Cause Analysis
1. **Outdated Mobile Device Build**: The physical test device was running an older APK compiled prior to cleartext HTTP permissions and forced background sync trigger implementations.
2. **Dashboard Static Data Precedence**: The web dashboard's `mergeWithDefaults` function evaluated timestamps on demo mock data dynamically (`Date.now() - 30m`), placing static mock cards above live mobile emergency submissions.
3. **Missing Citizen Attribution in Dashboard**: Incident streams lacked display of citizen reporter names, phone numbers, and origin badges, making real mobile reports look identical to static cards.

### Key Changes
- **Flutter Client**:
  - Rebuilt debug APK with Android Network Security Config (`android:usesCleartextTraffic="true"`).
  - Streamed and installed directly to connected physical device (`adb -s ad742c93 install -r`).
  - Active reverse port forwarding (`adb reverse tcp:3000 tcp:3000`) verified via device shell curl.
- **Web Frontend (`frontend/src/services/api.js`, `AdminDashboard.jsx`, `EmergenciesAdmin.jsx`)**:
  - Live backend records now take authoritative precedence in `mergeWithDefaults()`, sorted descending by creation timestamp.
  - Added citizen attribution: `📱 Mobile App` badge, `reporter_name`, `contact_phone`, and incident description in both priority incident cards and emergencies data table.
  - Exported `apiLogin` in `api.js` ensuring full production build compatibility with `AuthContext.jsx`.
- **FastAPI Backend (`backend/app/main.py`)**:
  - Generalized CORS regex `https?://.*` to permit requests from local IPs, mobile devices, and admin dashboards without origin blocking.

