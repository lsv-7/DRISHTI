# Tasks — Pending Work

> This file contains pending implementation work. AI coding agents should read `TasksCompleted.md` first and then select the next valid pending task.

## Status Legend

- `[ ]` Pending
- `[~]` In progress
- `[x]` Completed — move to TasksCompleted.md
- `[!]` Blocked

---

# Phase 0 — Repository & Environment

- [ ] T001 Inspect repository structure and identify existing applications/services.
- [ ] T002 Identify existing technologies and avoid unnecessary rewrites.
- [ ] T003 Create/update environment configuration templates.
- [ ] T004 Create local development setup for PostgreSQL/PostGIS and Redis.
- [ ] T005 Establish baseline build/test commands for mobile, web and backend.

# Phase 1 — Backend Foundation

- [ ] T006 Create FastAPI application structure.
- [ ] T007 Configure settings using environment variables.
- [ ] T008 Configure PostgreSQL connection.
- [ ] T009 Configure Redis connection.
- [ ] T010 Add health-check endpoints.
- [ ] T011 Establish API versioning.
- [ ] T012 Establish consistent API error responses.

# Phase 2 — Database & Domain

- [ ] T013 Create User model.
- [ ] T014 Create Emergency model (with vulnerability_score and vulnerability_factors fields).
- [ ] T015 Create Resource model.
- [ ] T016 Create Assignment model.
- [ ] T017 Create Road model with geographic support.
- [ ] T018 Create Shelter model.
- [ ] T019 Create Hospital/medical-resource model.
- [ ] T020 Create SituationObservation model.
- [ ] T021 Create Simulation model.
- [ ] T022 Create Notification model.
- [ ] T023 Create VulnerabilityProfile model (linked to User).
- [ ] T024 Create DisasterZone model (PostGIS polygon geometry).
- [ ] T025 Create DisasterZonePolicy model (with reconstruction_norm flag).
- [ ] T026 Create PopulationAccountingRecord model.
- [ ] T027 Create ShelterRegistration model (with zone_of_origin).
- [ ] T028 Create MissingPerson model (with source: MANUAL | INFERRED_ZONE_GAP and human_confirmed gate).
- [ ] T029 Add database migrations.
- [ ] T030 Add indexes and geographic indexes where required.
- [ ] T031 Add seed/demo flood-response data including:
         - zones with polygon boundaries
         - zone policies (including reconstruction norms)
         - population counts per zone
         - at least one citizen with vulnerability profile

# Phase 3 — Authentication & Authorization

- [ ] T032 Implement authentication.
- [ ] T033 Implement role-based authorization.
- [ ] T034 Protect command-center endpoints.
- [ ] T035 Protect responder operations.
- [ ] T036 Protect vulnerability profile endpoints (citizen-owned, coordinator read for active emergencies).
- [ ] T037 Protect population accounting endpoints (coordinator and admin only).
- [ ] T038 Add audit logging for consequential actions.

# Phase 4 — Vulnerability Profile

- [ ] T039 Implement vulnerability profile CRUD API.
- [ ] T040 Implement vulnerability scoring service.
         - age_factor
         - cannot_swim_factor (weighted higher for FLOOD)
         - disability_factor
         - mobility_factor
         - medical_condition_factor
- [ ] T041 Implement configurable weight management (admin-editable).
- [ ] T042 Build Flutter vulnerability onboarding flow (one-time, updateable).
- [ ] T043 Attach vulnerability profile snapshot to emergency submission payload.
- [ ] T044 Add unit tests for vulnerability score calculation.

# Phase 5 — Emergency Reporting

- [ ] T045 Implement emergency creation API (accepting vulnerability profile snapshot).
- [ ] T046 Implement emergency retrieval/filtering.
- [ ] T047 Implement emergency status transitions.
- [ ] T048 Build Flutter emergency reporting flow.
- [ ] T049 Add location capture.
- [ ] T050 Add emergency tracking.
- [ ] T051 Add validation and error states.

# Phase 6 — Offline-First

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

- [ ] T061 Implement normalized priority inputs.
- [ ] T062 Implement configurable priority weights.
- [ ] T063 Integrate vulnerability score into priority calculation.
- [ ] T064 Return score, vulnerability breakdown, and explanation.
- [ ] T065 Add unit tests for priority calculation with vulnerability factors.
- [ ] T066 Expose priority through backend API.
- [ ] T067 Show priority with vulnerability indicator in command center.

# Phase 8 — Resource Management

- [ ] T068 Implement resource CRUD.
- [ ] T069 Implement capabilities.
- [ ] T070 Implement availability state.
- [ ] T071 Implement resource location.
- [ ] T072 Implement vulnerability-aware resource matching engine.
         - Add vulnerability_fit_bonus to resource score
         - Prefer resources whose capabilities address the vulnerability profile
- [ ] T073 Implement candidate ranking with reasons (including vulnerability fit).
- [ ] T074 Add capacity constraints.
- [ ] T075 Add allocation API.
- [ ] T076 Build command-center resource panel.
- [ ] T077 Build responder assignment view.

# Phase 9 — Maps, Routing & Zone Overlays

- [ ] T078 Add Leaflet/OpenStreetMap command-center map.
- [ ] T079 Display emergency locations (with vulnerability severity indicator).
- [ ] T080 Display resource locations.
- [ ] T081 Display shelters/hospitals.
- [ ] T082 Display disaster zone polygon overlays on map.
- [ ] T083 Create road graph/model.
- [ ] T084 Implement basic route calculation.
- [ ] T085 Implement route feasibility checks.
- [ ] T086 Display routes and ETAs.

# Phase 10 — Disaster Zone Policy Engine

- [ ] T087 Implement zone resolution API (PostGIS ST_Contains query by lat/lon).
- [ ] T088 Implement policy CRUD (admin-only).
- [ ] T089 Implement policy delivery API filtered by role.
- [ ] T090 Implement reconstruction norm retrieval API.
- [ ] T091 Deliver zone policies to citizen app after emergency creation.
- [ ] T092 Display zone policies in command-center zone panel.
- [ ] T093 Display reconstruction norms in command-center Reconstruction Advisor panel.
- [ ] T094 Add zone policy delivery to responder assignment notifications.
- [ ] T095 Add unit tests for zone resolution and policy delivery.

# Phase 11 — Dynamic Replanning

- [ ] T096 Implement road status changes.
- [ ] T097 Detect affected assignments.
- [ ] T098 Detect resource unavailability.
- [ ] T099 Implement alternative resource search (preserving vulnerability priority order).
- [ ] T100 Implement route recalculation.
- [ ] T101 Implement revised allocation generation.
- [ ] T102 Add human approval flow.
- [ ] T103 Notify affected responders.
- [ ] T104 Add dynamic replanning tests.

# Phase 12 — Confidence-Aware Truth Layer

- [ ] T105 Create observation/report ingestion model.
- [ ] T106 Normalize observations.
- [ ] T107 Implement corroboration logic.
- [ ] T108 Implement recency logic.
- [ ] T109 Implement verification logic.
- [ ] T110 Implement heuristic confidence calculation.
- [ ] T111 Show confidence/evidence/timestamp in command center.
- [ ] T112 Add conflicting-report visualization.

# Phase 13 — Population Accounting & Missing-Person Inference

- [ ] T113 Implement shelter registration API.
- [ ] T114 Implement confirmed-safe report API.
- [ ] T115 Implement population accounting computation engine.
         - gap = expected - accounted
         - gap_pct = gap / expected
         - status logic: NORMAL / ATTENTION / CRITICAL
- [ ] T116 Implement zone gap alert dispatch (WebSocket + notification).
- [ ] T117 Build command-center population accounting panel.
         - Zone list with expected / accounted / gap
         - Status indicators
         - "Human review required" notice on ATTENTION/CRITICAL
- [ ] T118 Implement coordinator zone acknowledgment flow.
- [ ] T119 Implement missing-person record creation (manual, coordinator-only).
- [ ] T120 Implement missing-person status transitions.
- [ ] T121 Implement human-confirmation gate (human_confirmed must be true before public listing).
- [ ] T122 Add unit tests for population gap calculation.
- [ ] T123 Add tests for missing-person human-confirmation gate.
- [ ] T124 Add tests for shelter registration aggregation.

# Phase 14 — What-If Simulator

- [ ] T125 Create immutable simulation snapshot.
- [ ] T126 Add scenario modification model.
- [ ] T127 Support road blockage scenario.
- [ ] T128 Support resource failure scenario.
- [ ] T129 Support emergency surge scenario.
- [ ] T130 Support shelter-capacity reduction.
- [ ] T131 Support high-vulnerability population cluster scenario (new).
- [ ] T132 Run vulnerability-aware priority/allocation/routing on simulation state.
- [ ] T133 Generate live-vs-simulation comparison (include vulnerability impact).
- [ ] T134 Implement Apply/Cancel behavior.
- [ ] T135 Verify simulation never mutates live state accidentally.

# Phase 15 — Real-Time Updates

- [ ] T136 Add WebSocket endpoint.
- [ ] T137 Publish important domain events (including population gap alerts).
- [ ] T138 Update command-center dashboard in real time.
- [ ] T139 Update responder state in real time.
- [ ] T140 Add connection/reconnection handling.

# Phase 16 — Agentic AI

- [ ] T141 Establish LangGraph state model.
- [ ] T142 Implement Supervisor Agent.
- [ ] T143 Implement Situation Understanding Agent.
- [ ] T144 Implement Resource Management Agent (vulnerability-aware tools).
- [ ] T145 Implement Routing & Planning Agent.
- [ ] T146 Implement Policy & Compliance Agent (zone resolution + policy fetch + population status).
- [ ] T147 Implement What-If Simulation Agent.
- [ ] T148 Implement Explanation Agent.
- [ ] T149 Connect agents to real backend tools/services.
- [ ] T150 Add structured agent outputs.
- [ ] T151 Add execution tracing/logging.
- [ ] T152 Add guardrails preventing unsupported AI decisions.

# Phase 17 — LLM Explanation

- [ ] T153 Configure LLM provider through environment variables.
- [ ] T154 Implement explanation service.
- [ ] T155 Generate operator-readable explanations from structured facts (including vulnerability and zone policy context).
- [ ] T156 Prevent unsupported/hallucinated operational facts.
- [ ] T157 Add failure fallback when LLM is unavailable.

# Phase 18 — Software Radio Simulator

- [ ] T158 Define communication transport abstraction.
- [ ] T159 Implement Internet transport.
- [ ] T160 Implement simulated radio transport.
- [ ] T161 Implement simulated nodes/gateway.
- [ ] T162 Implement store-and-forward packet behavior.
- [ ] T163 Implement delay/failure/retry simulation.
- [ ] T164 Visualize simulated packet path.
- [ ] T165 Clearly label feature as simulated radio, not real LoRa hardware.

# Phase 19 — Notifications

- [ ] T166 Implement in-app notification model.
- [ ] T167 Implement assignment notification (with vulnerability summary and zone rules).
- [ ] T168 Implement emergency status notification.
- [ ] T169 Implement replanning notification.
- [ ] T170 Implement zone policy notification to citizen after emergency creation.
- [ ] T171 Implement population gap alert notification to coordinator.
- [ ] T172 Add notification history.

# Phase 20 — Missing Person / Optional AI Features

- [ ] T173 Add missing-person record (extends Phase 13 manual reporting).
- [ ] T174 Add media upload (photos for missing-person reports).
- [ ] T175 Implement optional image similarity workflow.
- [ ] T176 Require human verification for potential image matches.

# Phase 21 — Testing & Hardening

- [ ] T177 Add backend unit tests (priority, vulnerability, resource matching, zone policy, population accounting).
- [ ] T178 Add API integration tests.
- [ ] T179 Add database tests.
- [ ] T180 Add synchronization tests.
- [ ] T181 Add allocation tests (including vulnerability fit).
- [ ] T182 Add replanning tests.
- [ ] T183 Add simulation-isolation tests.
- [ ] T184 Add authorization tests (vulnerability profile access, population accounting access).
- [ ] T185 Add zone policy delivery tests.
- [ ] T186 Add missing-person human-confirmation gate tests.
- [ ] T187 Add frontend tests where practical.
- [ ] T188 Add Flutter tests for offline workflow.
- [ ] T189 Run complete build/test validation.

# Phase 22 — Demo Readiness

- [ ] T190 Prepare realistic flood scenario seed data.
- [ ] T191 Seed at least one citizen with vulnerability profile (elderly, cannot swim).
- [ ] T192 Seed disaster zones with polygon boundaries.
- [ ] T193 Seed zone policies (citizen rules + reconstruction norms).
- [ ] T194 Seed population counts per zone.
- [ ] T195 Prepare demo emergency (vulnerable citizen profile visible).
- [ ] T196 Prepare demo road blockage and dynamic replanning.
- [ ] T197 Prepare demo resource failure.
- [ ] T198 Prepare demo zone policy delivery to citizen and coordinator.
- [ ] T199 Prepare demo population gap alert and coordinator acknowledgment.
- [ ] T200 Prepare demo what-if scenario (high-vulnerability cluster).
- [ ] T201 Prepare demo reconstruction norms surfacing.
- [ ] T202 Verify offline → online synchronization demo.
- [ ] T203 Verify dynamic replanning demo (vulnerability order preserved).
- [ ] T204 Verify confidence-layer demo.
- [ ] T205 Verify agentic workflow demo.
- [ ] T206 Verify simulated-radio demo if included.
- [ ] T207 Prepare final end-to-end demo reset mechanism.

# Phase 23 — Documentation

- [ ] T208 Keep ProblemDescription.md synchronized with actual MVP.
- [ ] T209 Keep ExecutionFlow.md synchronized with actual implementation.
- [ ] T210 Keep WorkflowSolution.md synchronized with architecture.
- [ ] T211 Record major architectural decisions.
- [ ] T212 Record known limitations.
- [ ] T213 Keep TasksCompleted.md updated.

---

## Agent Instructions

When beginning work:

1. Read all context files.
2. Read repository code.
3. Read `TasksCompleted.md`.
4. Find the earliest unblocked task.
5. Implement only the required scope.
6. Validate.
7. Update task tracking.

Do not mark a task complete without implementation/validation evidence.
