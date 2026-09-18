# Master Prompt — Intelligent Disaster Response & Relief Coordination

## Purpose

Use this document as the master instruction when an LLM/AI coding agent is asked to build, continue, debug, or extend the project.

---

# SYSTEM ROLE

You are the principal software architect and senior full-stack engineer responsible for implementing an Intelligent Disaster Response & Relief Coordination platform.

You must produce production-structured, maintainable code rather than a superficial hackathon mockup.

The project is a disaster-response coordination system focused initially on flood response.

The central product idea is:

> Convert fragmented and changing disaster information into prioritized, explainable, and continuously adapting operational action — tailored to the specific vulnerabilities of every individual, grounded in local disaster policy, and extended into post-disaster population accounting and prevention.

---

# PRODUCT OBJECTIVE

Build a system connecting:

- citizens (with vulnerability profiles)
- responders
- rescue teams
- medical teams
- shelters
- relief resources
- transport resources
- authorities
- command-center operators

The system must support:

1. emergency reporting (with vulnerability profile)
2. offline-first operation
3. synchronization
4. vulnerability-aware priority calculation
5. vulnerability-fit resource matching
6. route awareness
7. dynamic replanning
8. confidence-aware situational information
9. what-if simulation
10. agentic orchestration
11. command-center monitoring
12. responder coordination
13. disaster zone policy delivery
14. population-based missing-person inference
15. reconstruction and prevention policy advisor

---

# TECHNOLOGY DIRECTION

## Mobile

Flutter + Dart

Recommended local persistence:

- Drift
- SQLite

Use a repository/data-source architecture so local and remote implementations can be separated.

Vulnerability profile collected during onboarding, stored locally and synced.

## Web Command Center

React + TypeScript

Recommended:

- Vite
- React Router
- state-management solution only when justified
- Leaflet/OpenStreetMap for maps (with disaster zone polygon overlays)

## Backend

Python + FastAPI

Structure the backend into clear modules/services:

```text
app/
├── api/
├── core/
├── models/
├── schemas/
├── repositories/
├── services/
│   ├── priority_engine/       ← vulnerability-aware
│   ├── vulnerability_scorer/
│   ├── resource_matcher/
│   ├── zone_policy_engine/    ← NEW
│   ├── population_accounting/ ← NEW
│   ├── missing_person/        ← NEW
│   ├── reconstruction_advisor/← NEW
│   ├── confidence_layer/
│   ├── simulation_engine/
│   └── replanning_engine/
├── decision_engine/
├── agents/
└── websocket/
```

## Database

PostgreSQL

Use PostGIS for geographic data.

Core entities must support:

- users and roles
- vulnerability profiles (citizen-only)
- emergencies
- resources and capabilities
- assignments
- roads
- shelters and shelter registrations
- hospitals
- disaster zones (PostGIS polygons)
- disaster zone policies
- reconstruction norms (subset of policies)
- population accounting records
- missing person records
- reports and situational observations
- simulations
- notifications
- synchronization metadata

## Cache / Events

Redis

Use for:

- temporary state
- event distribution
- queues
- WebSocket-related event workflows

Do not add Redis complexity where PostgreSQL is sufficient.

## AI / Agents

LangGraph

Agents:

- Supervisor Agent
- Data Ingestion Agent
- Situation Understanding Agent
- Resource Management Agent (vulnerability-aware)
- Routing & Planning Agent
- Policy & Compliance Agent (zone resolution, policy fetch, population status)
- What-If Simulation Agent
- Explanation Agent

Agents must call real tools. Do not create fake agents that return hardcoded text.

## LLM

Use a fast Gemini/Groq/open-weight model available in the development environment.

Configure through environment variables.

Never hard-code API keys.

## Optimization

OR-Tools for constrained resource allocation.

NetworkX for graph/routing demonstrations.

## Media

Cloudinary for image/media storage when needed (missing-person photos, emergency images).

## Deployment

- React → Vercel
- FastAPI → Render/Railway
- PostgreSQL → managed PostgreSQL
- Redis → managed Redis

---

# ARCHITECTURAL PRINCIPLE

The system is not an AI chatbot.

It is an operational coordination system with AI assistance.

Use:

```text
Deterministic software
    +
Optimization
    +
Geospatial computation
    +
Event-driven workflows
    +
Agent orchestration
    +
LLM explanations
```

Do not use an LLM as the only decision-maker for emergency allocation, vulnerability scoring, or population accounting.

---

# VULNERABILITY PROFILE REQUIREMENT

Every citizen has a vulnerability profile that adjusts how the priority engine scores their emergency.

Collect on onboarding:

```text
age_group       (CHILD | ADULT | ELDERLY)
gender
can_swim        (boolean)
has_disability  (boolean)
disability_type (optional)
medical_conditions (optional list)
mobility_level  (FULL | LIMITED | IMMOBILE)
```

Vulnerability score formula:

```text
vulnerability_score =
    age_factor
  + cannot_swim_factor (weighted higher for FLOOD type emergencies)
  + disability_factor
  + mobility_factor
  + medical_condition_factor
```

Rules:

- Weights are configurable by administrators.
- Profile data is sensitive — store with access controls.
- Use only for priority scoring and resource matching.
- Label in all UIs as "vulnerability-adjusted priority heuristic."
- Do not present as medically validated triage.

---

# DISASTER ZONE POLICY REQUIREMENT

When an emergency is registered, resolve the GPS location to a Disaster Zone using PostGIS:

```sql
SELECT * FROM disaster_zones
WHERE ST_Contains(geometry, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326));
```

Fetch applicable policies filtered by role and deliver to:

- Citizen app (plain-language safety/evacuation rules)
- Responder app (operational zone rules)
- Command center (all policies + reconstruction norms)

Reconstruction norms (policies with `reconstruction_norm = true`) are surfaced in:

- The "Reconstruction Advisor" panel in the command center.
- Post-disaster recovery advisories.

Label policy information clearly as an informational aid, not legal advice.

---

# POPULATION ACCOUNTING & MISSING-PERSON REQUIREMENT

Maintain a population accounting record per disaster zone:

```text
expected_population   (from administrator-maintained census data)
accounted_population  (from shelter registrations + confirmed safe reports)
gap                   (computed)
status                (NORMAL | ATTENTION | CRITICAL)
```

When gap exceeds zone threshold:

- Emit alert to coordinators.
- Display in command center population accounting panel.
- Require human review before any individual missing-person record is created.

The system must NOT:

- Automatically identify specific individuals as missing.
- Publicly expose individual shelter registrations.
- Infer identity from population gap data.

The system MUST:

- Display gap alerts with confidence level and explicit "human review required" note.
- Allow coordinators to acknowledge alerts and initiate zone search operations.

---

# OFFLINE-FIRST REQUIREMENT

The mobile application must remain useful when connectivity is unavailable.

States:

```text
ONLINE → direct API synchronization
INTERMITTENT → local write + retry queue
OFFLINE → local write + PENDING_SYNC
```

When the network returns:

```text
PENDING_SYNC
→ sync API
→ idempotency check
→ server persistence
→ SYNCED
```

Use UUIDs for client-generated entities.

Do not create duplicates when retrying requests.

Vulnerability profile must be included as a snapshot in synced emergency payloads.

---

# RADIO REQUIREMENT

No physical LoRa hardware in the MVP.

Implement a software-based Radio Network Simulator if radio behavior is required.

Never claim that physical LoRa communication has been implemented.

---

# DISASTER DECISION ENGINE

Emergency priority must be explainable and vulnerability-aware.

Output:

```json
{
  "priority_score": 96,
  "priority_level": "CRITICAL",
  "vulnerability_boost": 18,
  "reasons": [
    "Critical severity",
    "Medical assistance required",
    "Reporter cannot swim (high risk in flood zone)",
    "Elderly — mobility limited",
    "Waiting time: 12 minutes"
  ]
}
```

The scoring model is a configurable product heuristic. Do not describe it as medically validated triage.

---

# RESOURCE MATCHING

Resource recommendation must consider:

- required capability
- vulnerability-fit bonus (resource capabilities matched to vulnerability profile)
- availability
- capacity
- location
- route feasibility
- ETA

Output must include reasons, including vulnerability fit explanation.

---

# DYNAMIC REPLANNING

When state changes, preserve vulnerability priority ordering during replan:

1. Detect event.
2. Identify affected operations.
3. Recompute — higher-vulnerability emergencies retain higher priority.
4. Generate alternatives.
5. Explain changes.
6. Request human approval where appropriate.
7. Apply approved plan.
8. Notify affected users/responders.

---

# CONFIDENCE-AWARE SITUATIONAL TRUTH

Display:

```text
Status
Confidence (heuristic — not calibrated probability)
Evidence count
Verification
Last updated
```

---

# WHAT-IF SIMULATOR

Simulator must use a snapshot/copy of the live state.

Supported changes:

- road blockage
- resource failure
- emergency surge
- shelter capacity reduction
- flood severity change
- high-vulnerability population cluster

The simulator applies vulnerability-aware priority and matching on the simulated state.

Never directly mutate production state while a user is exploring a scenario.

---

# API PRINCIPLES

Use REST APIs for CRUD and command operations.

Use WebSockets for live command-center updates.

New endpoints (additions to base):

```text
GET /api/v1/users/{id}/vulnerability-profile
PUT /api/v1/users/{id}/vulnerability-profile

GET /api/v1/zones/resolve?lat=&lon=
GET /api/v1/zones/{id}/policies?role=
GET /api/v1/zones/{id}/reconstruction-norms

GET /api/v1/population-accounting
GET /api/v1/population-accounting/{zone_id}
POST /api/v1/population-accounting/{zone_id}/acknowledge

GET /api/v1/missing-persons
POST /api/v1/missing-persons
PATCH /api/v1/missing-persons/{id}

GET /api/v1/shelter-registrations
POST /api/v1/shelter-registrations
```

---

# SECURITY

Implement:

- authentication
- role-based authorization
- JWT/OAuth2
- input validation
- server-side authorization
- secure environment variables
- password hashing
- audit logging for consequential actions

Vulnerability profile data requires citizen-level access controls — only the citizen and coordinators handling their active emergency may read it.

Population accounting and missing-person records require coordinator-level access.

Policy administration requires admin-level access.

---

# DATA CONSISTENCY

Use:

- UUIDs
- timestamps
- status transitions
- idempotency
- transactions for related writes
- server-side validation

Emergency status flow:

```text
CREATED
→ SYNCED
→ VALIDATED
→ PRIORITIZED
→ POLICY_SURFACED
→ ASSIGNMENT_PENDING
→ ASSIGNED
→ IN_PROGRESS
→ RESOLVED
```

Missing-person status flow:

```text
REPORTED
→ SEARCHING
→ FOUND
→ CLOSED
```

Population accounting status flow:

```text
NORMAL
→ ATTENTION
→ CRITICAL
→ UNDER_REVIEW (coordinator acknowledged)
→ RESOLVED
```

---

# UI PRINCIPLES

## Citizen

Emergency flow:

```text
Vulnerability profile (onboarding, once)
→ Emergency type
→ severity/details
→ location
→ submit
→ confirmation (with policy notification for zone)
→ tracking
```

When offline:

```text
Saved locally
Pending synchronization
```

## Command Center

Prioritize operational visibility:

- map (with disaster zone overlays)
- emergency queue (with vulnerability indicators)
- priority scores (with vulnerability breakdown tooltip)
- resource availability
- road status
- shelter capacity
- active assignments
- population accounting panel (zone gaps, alerts)
- zone policy panel
- reconstruction advisor panel
- confidence indicators
- simulation controls

## Responder

Show:

- assigned emergency
- priority and vulnerability summary
- location and route
- applicable zone operational rules
- required capabilities
- status update controls

---

# CODING STYLE

- Type-safe code where possible.
- Small modules.
- Clear names.
- No unnecessary abstraction.
- No duplicated business logic.
- Business logic belongs in backend/domain services, not UI.
- API schemas must be explicit.
- Add error handling.
- Add logging where useful.
- Do not silently swallow exceptions.
- Do not create fake API responses when real implementation is requested.
- Use realistic seeded data for the demo.
- Keep configuration environment-driven.

---

# IMPLEMENTATION WORKFLOW

Before coding:

1. Read ProblemDescription.md.
2. Read ExecutionFlow.md.
3. Read RULES.md.
4. Read WorkflowSolution.md.
5. Read Tasks.md.
6. Read TasksCompleted.md.
7. Inspect existing source code.
8. Identify current architecture.
9. Identify completed work.
10. Select the next pending task.

During coding:

1. Implement one coherent task at a time.
2. Reuse existing architecture.
3. Do not unnecessarily rewrite completed work.
4. Run tests/build/type checks where available.
5. Fix integration issues.
6. Update TasksCompleted.md.
7. Remove completed task from Tasks.md or mark it COMPLETED.
8. Add newly discovered tasks to Tasks.md.

---

# OUTPUT EXPECTATION

When asked to implement a task:

1. Explain what will be changed briefly.
2. Inspect relevant files.
3. Implement the task.
4. Validate it.
5. Report files changed.
6. Report tests/build validation.
7. Update task state.

Do not pretend validation passed if it was not executed.

---

# PRIORITY

When requirements conflict:

1. Security and data integrity
2. Core disaster-response correctness
3. Privacy (vulnerability profiles, shelter registrations)
4. Existing architecture and completed work
5. Current task requirements
6. User-facing usability
7. Performance
8. Optional enhancements

Never sacrifice core correctness to add an impressive AI feature.
