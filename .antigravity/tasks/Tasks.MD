# Tasks — Pending Work

> This file contains pending implementation work. AI coding agents should read `TasksCompleted.md` first and then select the next valid pending task.

## Status Legend

- `[ ]` Pending
- `[~]` In progress
- `[x]` Completed — move to TasksCompleted.md
- `[!]` Blocked

---

# Phase 0 — Repository & Environment

- [x] T001 Inspect repository structure and identify existing applications/services.
- [x] T002 Identify existing technologies and avoid unnecessary rewrites.
- [x] T003 Create/update environment configuration templates.
- [x] T004 Create local development setup for PostgreSQL/PostGIS and Redis.
- [x] T005 Establish baseline build/test commands for mobile, web and backend.

# Phase 1 — Backend Foundation

- [x] T006 Create FastAPI application structure.
- [x] T007 Configure settings using environment variables.
- [x] T008 Configure PostgreSQL connection.
- [x] T009 Configure Redis connection.
- [x] T010 Add health-check endpoints.
- [x] T011 Establish API versioning.
- [x] T012 Establish consistent API error responses.

# Phase 2 — Database & Domain

- [x] T013 Create User model.
- [x] T014 Create Emergency model (with vulnerability_score and vulnerability_factors fields).
- [x] T015 Create Resource model.
- [x] T016 Create Assignment model.
- [x] T017 Create Road model with geographic support.
- [x] T018 Create Shelter model.
- [x] T019 Create Hospital/medical-resource model.
- [x] T020 Create SituationObservation model.
- [x] T021 Create Simulation model.
- [x] T022 Create Notification model.
- [x] T023 Create VulnerabilityProfile model (linked to User).
- [x] T024 Create DisasterZone model (PostGIS polygon geometry).
- [x] T025 Create DisasterZonePolicy model (with reconstruction_norm flag).
- [x] T026 Create PopulationAccountingRecord model.
- [x] T027 Create ShelterRegistration model (with zone_of_origin).
- [x] T028 Create MissingPerson model (with source: MANUAL | INFERRED_ZONE_GAP and human_confirmed gate).
- [x] T029 Add database migrations.
- [x] T030 Add indexes and geographic indexes where required.
- [x] T031 Add seed/demo flood-response data including:
         - zones with polygon boundaries
         - zone policies (including reconstruction norms)
         - population counts per zone
         - at least one citizen with vulnerability profile

# Phase 3 — Authentication & Authorization

- [x] T032 Implement authentication.
- [x] T033 Implement role-based authorization.
- [x] T034 Protect command-center endpoints.
- [x] T035 Protect responder operations.
- [x] T036 Protect vulnerability profile endpoints.
- [x] T037 Protect population accounting endpoints.
- [x] T038 Add audit logging for consequential actions.

# Phase 4 — Vulnerability Profile

- [x] T039 Implement vulnerability profile CRUD API.
- [x] T040 Implement vulnerability scoring service.
- [x] T041 Implement configurable weight management.
- [x] T042 Build Flutter vulnerability onboarding flow (one-time, updateable).
- [x] T043 Attach vulnerability profile snapshot to emergency submission payload.
- [x] T044 Add unit tests for vulnerability score calculation.

# Phase 5 — Emergency Reporting

- [x] T045 Implement emergency creation API (accepting vulnerability profile snapshot).
- [x] T046 Implement emergency retrieval/filtering.
- [x] T047 Implement emergency status transitions.
- [x] T048 Build Flutter emergency reporting flow.
- [x] T049 Add location capture.
- [x] T050 Add emergency tracking.
- [ ] T051 Add validation and error states.

# Phase 6 — Offline-First (Flutter)

- [ ] T052 Add Drift/SQLite local database.
- [ ] T053 Create local emergency repository.
- [ ] T054 Create pending-operation queue.
- [ ] T055 Implement connectivity state detection.
- [ ] T056 Implement sync API.
- [ ] T057 Implement idempotent synchronization.
- [ ] T058 Implement retry/backoff.
- [ ] T059 Show local pending/sync status in Flutter.
- [ ] T060 Test offline → online synchronization.

# Phase 7 — Vulnerability-Aware Priority Engine

- [x] T061 Implement normalized priority inputs.
- [x] T062 Implement configurable priority weights.
- [x] T063 Integrate vulnerability score into priority calculation.
- [x] T064 Return score, vulnerability breakdown, and explanation.
- [x] T065 Add unit tests for priority calculation with vulnerability factors.
- [x] T066 Expose priority through backend API.
- [x] T067 Show priority with vulnerability indicator in command center.

# Phase 8 — Resource Management

- [x] T068 Implement resource CRUD.
- [x] T069 Implement capabilities.
- [x] T070 Implement availability state.
- [x] T071 Implement resource location.
- [x] T072 Implement vulnerability-aware resource matching engine.
- [x] T073 Implement candidate ranking with reasons.
- [x] T074 Add capacity constraints.
- [x] T075 Add allocation API.
- [x] T076 Build command-center resource panel.
- [x] T077 Build responder assignment view.

# Phase 9 — Maps, Routing & Zone Overlays

- [x] T078 Add Leaflet/OpenStreetMap command-center map.
- [x] T079 Display emergency locations.
- [x] T080 Display resource locations.
- [x] T081 Display shelters/hospitals.
- [x] T082 Display disaster zone polygon overlays on map.
- [x] T083 Create road graph/model.
- [x] T084 Implement basic route calculation.
- [x] T085 Implement route feasibility checks.
- [x] T086 Display routes and ETAs.

# Phase 10 — Disaster Zone Policy Engine

- [x] T087 Implement zone resolution API.
- [x] T088 Implement policy CRUD.
- [x] T089 Implement policy delivery API filtered by role.
- [x] T090 Implement reconstruction norm retrieval API.
- [x] T091 Deliver zone policies to citizen app after emergency creation.
- [x] T092 Display zone policies in command-center zone panel.
- [x] T093 Display reconstruction norms in command-center Reconstruction Advisor panel.
- [x] T094 Add zone policy delivery to responder assignment notifications.
- [x] T095 Add unit tests for zone resolution and policy delivery.

# Phase 11 — Dynamic Replanning

- [x] T096 Implement road status changes.
- [x] T097 Detect affected assignments.
- [x] T098 Detect resource unavailability.
- [x] T099 Implement alternative resource search.
- [x] T100 Implement route recalculation.
- [x] T101 Implement revised allocation generation.
- [x] T102 Add human approval flow.
- [x] T103 Notify affected responders.
- [x] T104 Add dynamic replanning tests.

# Phase 12 — Confidence-Aware Truth Layer

- [x] T105 Create observation/report ingestion model.
- [x] T106 Normalize observations.
- [x] T107 Implement corroboration logic.
- [x] T108 Implement recency logic.
- [x] T109 Implement verification logic.
- [x] T110 Implement heuristic confidence calculation.
- [x] T111 Show confidence/evidence/timestamp in command center.
- [x] T112 Add conflicting-report visualization.

# Phase 13 — Population Accounting & Missing-Person Inference

- [x] T113 Implement shelter registration API.
- [x] T114 Implement confirmed-safe report API.
- [x] T115 Implement population accounting computation engine.
- [x] T116 Implement zone gap alert dispatch.
- [x] T117 Build command-center population accounting panel.
- [x] T118 Implement coordinator zone acknowledgment flow.
- [x] T119 Implement missing-person record creation.
- [x] T120 Implement missing-person status transitions.
- [x] T121 Implement human-confirmation gate.
- [x] T122 Add unit tests for population gap calculation.
- [x] T123 Add tests for missing-person human-confirmation gate.
- [x] T124 Add tests for shelter registration aggregation.

# Phase 14 — What-If Simulator

- [x] T125 Create immutable simulation snapshot.
- [x] T126 Add scenario modification model.
- [x] T127 Support road blockage scenario.
- [x] T128 Support resource failure scenario.
- [x] T129 Support emergency surge scenario.
- [x] T130 Support shelter-capacity reduction.
- [x] T131 Support high-vulnerability population cluster scenario.
- [x] T132 Run vulnerability-aware priority/allocation/routing on simulation state.
- [x] T133 Generate live-vs-simulation comparison.
- [x] T134 Implement Apply/Cancel behavior.
- [x] T135 Verify simulation never mutates live state accidentally.

# Phase 15 — Real-Time Updates

- [x] T136 Add WebSocket endpoint.
- [x] T137 Publish important domain events.
- [x] T138 Update command-center dashboard in real time.
- [x] T139 Update responder state in real time.
- [x] T140 Add connection/reconnection handling.

# Phase 16 — Agentic AI

- [x] T141 Establish LangGraph state model.
- [x] T142 Implement Supervisor Agent.
- [x] T143 Implement Situation Understanding Agent.
- [x] T144 Implement Resource Management Agent.
- [x] T145 Implement Routing & Planning Agent.
- [x] T146 Implement Policy & Compliance Agent.
- [x] T147 Implement What-If Simulation Agent.
- [x] T148 Implement Explanation Agent.
- [x] T149 Connect agents to real backend tools/services.
- [x] T150 Add structured agent outputs.
- [x] T151 Add execution tracing/logging.
- [x] T152 Add guardrails preventing unsupported AI decisions.

# Phase 21 — Testing & Hardening

- [x] T177 Add backend unit tests.
- [x] T187 Add frontend build validation.
