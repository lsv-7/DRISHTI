# Workflow Solution

## 1. Solution Architecture

```text
+--------------------------------------------------------------+
|                    USER APPLICATIONS                         |
|                                                              |
|  Flutter Citizen App        Flutter Responder App            |
|  (with vulnerability profile)      |                         |
+------------+-------------------------+-----------------------+
             |
             v
+--------------------------------------------------------------+
|                 CONNECTIVITY / SYNC LAYER                    |
|                                                              |
| Online | Intermittent | Offline | Local Queue | Sync Engine  |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
|                       FASTAPI BACKEND                        |
|                                                              |
| Auth | Emergencies | Resources | Shelters | Hospitals        |
| Roads | Assignments | Reports | Notifications | Simulation   |
| Synchronization | WebSockets | Audit                         |
| Vulnerability Profiles | Disaster Zone Policies             |
| Population Accounting | Missing Person Module                |
| Reconstruction Policy Advisor                                |
+-------------------------------+------------------------------+
                                |
               +----------------+----------------+
               |                                 |
               v                                 v
+---------------------------+       +--------------------------+
| PostgreSQL + PostGIS      |       | Redis                    |
| operational data          |       | queues/cache/events      |
| zone geometry             |       |                          |
| policy records            |       |                          |
| population census data    |       |                          |
+---------------------------+       +--------------------------+
               |
               v
+--------------------------------------------------------------+
|              INTELLIGENCE & DECISION ENGINE                  |
|                                                              |
| Vulnerability-Aware Priority Engine                         |
| Resource Matching (capability + vulnerability fit)          |
| Routing | Dynamic Replanning                                 |
| Confidence Layer | Simulation Engine                        |
| Disaster Zone Policy Engine                                 |
| Population Accounting & Missing-Person Inference Engine     |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
|                  LANGGRAPH ORCHESTRATION                     |
|                                                              |
| Supervisor                                                  |
|   ├── Situation Understanding Agent                         |
|   ├── Resource Management Agent                             |
|   ├── Routing & Planning Agent                              |
|   ├── What-If Simulation Agent                              |
|   ├── Policy & Compliance Agent                             |
|   └── Explanation Agent                                     |
+-------------------------------+------------------------------+
                                |
                                v
+--------------------------------------------------------------+
|                  REACT COMMAND CENTER                        |
|                                                              |
| Map | Emergency Queue | Resources | Roads | Shelters        |
| Assignments | Confidence | Alerts | What-If Simulator        |
| Disaster Zone Policies | Population Accounting Dashboard     |
| Missing Person Panel | Reconstruction Advisories            |
+--------------------------------------------------------------+
```

---

## 2. Domain Model

### User / Citizen Profile

```text
id
name
phone/email
role
created_at

--- Vulnerability Profile (citizen-only) ---
age_group             (CHILD | ADULT | ELDERLY)
gender                (for context-specific risk factors)
can_swim              (boolean)
has_disability        (boolean)
disability_type       (optional)
medical_conditions    (optional list)
mobility_level        (FULL | LIMITED | IMMOBILE)
vulnerability_score   (computed, updated on profile change)
```

Roles:

```text
CITIZEN
RESPONDER
COORDINATOR
ADMIN
MEDICAL
SHELTER_MANAGER
```

### Emergency

```text
id
reporter_id
type
severity
people_affected
medical_need
vulnerable_people         (count)
vulnerability_score       (from reporter profile + manual input)
vulnerability_factors     (JSON — contributing factors)
description
latitude
longitude
disaster_zone_id          (resolved from coordinates)
status
priority_score
priority_level
created_at
updated_at
sync_status
```

### Resource

```text
id
name
type
capabilities
capacity
current_location
availability_status
organization
updated_at
```

### Assignment

```text
id
emergency_id
resource_id
assigned_by
eta
route
status
created_at
updated_at
```

### Road

```text
id
name
geometry
status
confidence
last_verified_at
```

### Disaster Zone

```text
id
name
zone_type              (FLOOD | CYCLONE | EARTHQUAKE | COASTAL | URBAN)
geometry               (PostGIS polygon)
jurisdiction           (district/state)
active_disaster_types
```

### Disaster Zone Policy

```text
id
zone_id
policy_type            (EVACUATION | SHELTER | RECONSTRUCTION | PREVENTION | OPERATIONAL)
title
description
legal_reference        (optional — act/rule reference)
applicable_roles       (CITIZEN | RESPONDER | COORDINATOR | ALL)
reconstruction_norm    (boolean — marks this as a reconstruction/prevention rule)
created_by
updated_at
```

Example policy records:

```text
Zone: Flood Zone Alpha
Policy: Mandatory evacuation if water level > 1.5m
Roles: CITIZEN
Legal reference: Andhra Pradesh Disaster Management Act, Rule 14

Zone: Flood Zone Alpha
Policy: New buildings must include rainwater harvesting pit (minimum 3m x 3m)
Roles: COORDINATOR, ADMIN
Type: RECONSTRUCTION
reconstruction_norm: true

Zone: Coastal Zone Beta
Policy: Fishermen must not venture to sea during cyclone alerts
Roles: CITIZEN
```

### Population Accounting Record

```text
id
zone_id
reference_date
expected_population     (from census/administrative data)
accounted_population    (live — from shelter registrations + confirmed)
gap                     (computed)
gap_threshold           (configured per zone)
status                  (NORMAL | ATTENTION | CRITICAL)
last_computed_at
```

### Shelter Registration

```text
id
shelter_id
individual_name
individual_age
individual_gender
zone_of_origin_id       (where the individual came from)
registered_at
registered_by
status                  (REGISTERED | TRANSFERRED | DISCHARGED)
```

### Missing Person Record

```text
id
reported_by
name
age
gender
last_known_location
last_seen_at
zone_id
status                  (REPORTED | SEARCHING | FOUND | CLOSED)
source                  (MANUAL | INFERRED_ZONE_GAP)
inference_confidence    (for INFERRED records)
human_confirmed         (boolean — required before public listing)
created_at
updated_at
```

### Situation Observation

```text
id
entity_type
entity_id
source_type
status
details
timestamp
verification_status
```

### Simulation

```text
id
created_by
base_state_version
scenario_changes
result
status
created_at
```

---

## 3. Emergency Lifecycle

```text
CREATED
  ↓
SYNCED
  ↓
VALIDATED
  ↓
PRIORITIZED  (vulnerability score applied here)
  ↓
POLICY_SURFACED  (disaster zone policies delivered to coordinator)
  ↓
ASSIGNMENT_PENDING
  ↓
ASSIGNED
  ↓
IN_PROGRESS
  ↓
RESOLVED
```

---

## 4. Priority Algorithm (Vulnerability-Aware)

Explainable weighted heuristic.

```text
priority =
    severity_weight
  + affected_people_weight
  + medical_need_weight
  + vulnerability_weight        ← includes individual profile factors
  + waiting_time_weight
  + accessibility_weight
```

### Vulnerability component breakdown

```text
vulnerability_score =
    age_factor         (CHILD → high, ELDERLY → high, ADULT → baseline)
  + cannot_swim_factor (high if flood disaster type)
  + disability_factor
  + mobility_factor
  + medical_condition_factor
  + gender_specific_risk_factor (context-dependent)
```

Weights are configurable by administrators. All factors are normalized before combination.

Return both:

```text
score
+
reasons  (list of contributing factors with their weights)
```

Example output:

```json
{
  "priority_score": 96,
  "priority_level": "CRITICAL",
  "reasons": [
    "Critical severity",
    "Medical assistance required",
    "Reporter cannot swim (high risk in flood)",
    "Elderly occupant — mobility limited",
    "Waiting time: 12 minutes"
  ]
}
```

Do not present this as a clinically validated triage system.

---

## 5. Resource Matching Algorithm

### Step 1

Extract emergency requirements.

Example:

```text
water rescue
medical support
capacity >= 4
vulnerability_profile: elderly, cannot swim → prefer resources with medical + boat capability
```

### Step 2

Filter:

```text
available = true
```

### Step 3

Capability matching, weighted by vulnerability profile.

Resources with capabilities matching the vulnerability profile (e.g., medical + water rescue for an elderly non-swimmer in a flood) receive a higher match score.

### Step 4

Capacity validation.

### Step 5

Route feasibility.

### Step 6

ETA calculation.

### Step 7

Score candidates.

```text
resource_score =
    capability_match
  + vulnerability_fit_bonus
  + availability
  + capacity_fit
  + route_feasibility
  + ETA_factor
```

Return ranked candidates plus explanations.

---

## 6. Dynamic Replanning Algorithm

```text
Input:
current assignments
current resources
current roads
new event

1. Detect affected assignments.
2. Identify unavailable resources.
3. Remove blocked routes.
4. Identify alternative resources.
5. Recalculate candidate assignments, preserving vulnerability priority ordering.
6. Calculate new ETAs.
7. Validate constraints.
8. Generate revised plan.
9. Compare with existing plan.
10. Request human approval.
11. Apply approved changes.
12. Notify affected responders.
```

---

## 7. Disaster Zone Policy Engine

### Zone identification

When an emergency is registered, its GPS coordinates are resolved to a Disaster Zone using PostGIS spatial query:

```sql
SELECT dz.id, dz.name, dz.zone_type
FROM disaster_zones dz
WHERE ST_Contains(dz.geometry, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326));
```

### Policy delivery

Once the zone is identified:

```text
zone_id
→ fetch applicable policies filtered by role
→ return to client / coordinator
```

Policy delivery targets:

- Citizen app: policies tagged `CITIZEN` or `ALL`, in simple language.
- Responder app: policies tagged `RESPONDER` or `ALL`, operational rules.
- Command center: all policies, including `RECONSTRUCTION` norms.

### Reconstruction / prevention policies

Policies with `reconstruction_norm = true` are surfaced:

- In the command-center zone panel under a "Prevention & Reconstruction Norms" section.
- When authorities log new construction or reconstruction activity in a zone.
- As part of post-disaster recovery advisories.

Example:

```text
Zone: Flood Zone Alpha
Reconstruction Norm: New residential buildings must reserve minimum 10% ground area for water absorption or rainwater harvesting. Reference: APSDMA Guideline 2019.
```

---

## 8. Population Accounting & Missing-Person Inference Engine

### Data sources

- Pre-disaster population count per zone: stored by administrators from census/ward data.
- Shelter registrations: recorded as individuals arrive at shelters.
- Confirmed safe reports: coordinators can mark individuals as confirmed safe.

### Inference calculation

```text
For each zone:
  gap = expected_population - accounted_population
  gap_percentage = gap / expected_population

  if gap_percentage > zone.gap_threshold:
    status = CRITICAL
    emit alert: "Zone X has ~{gap} unaccounted individuals"
  elif gap_percentage > (zone.gap_threshold * 0.6):
    status = ATTENTION
```

### Alert output

```json
{
  "zone_id": "Z04",
  "zone_name": "Ward 7 — Flood Zone Alpha",
  "expected_population": 1200,
  "accounted_population": 847,
  "gap": 353,
  "gap_percentage": 29.4,
  "status": "CRITICAL",
  "confidence": "MEDIUM",
  "note": "Gap inference is probabilistic. Human coordinator review required before initiating missing-person search.",
  "computed_at": "..."
}
```

### Human confirmation gate

The system does NOT automatically list specific individuals as missing. Coordinator action is required:

```text
Zone gap alert received
       ↓
Coordinator reviews alert
       ↓
Coordinator may:
  → Initiate zone search operation
  → Create missing-person investigation record
  → Mark zone as under review
       ↓
As individuals are found/registered:
  → Gap narrows automatically
  → Alert status updates
```

### Privacy requirements

- Individual shelter registrations are not publicly exposed without consent.
- Zone-level gap data is available to coordinators and administrators only.
- Missing-person records require human confirmation before any public listing.

---

## 9. Confidence Layer

```json
{
  "entity_id": "R12",
  "status": "BLOCKED",
  "confidence": 0.82,
  "evidence_count": 5,
  "verified_count": 1,
  "last_updated": "..."
}
```

Heuristic:

```text
confidence =
    source_quality
  + corroboration
  + recency
  + geographic_consistency
  + verification
```

Normalize to a displayable scale. Always expose evidence and timestamp.

---

## 10. What-If Simulation

Create an immutable simulation snapshot:

```text
Live State Version N
       ↓
Simulation Snapshot
       ↓
Apply hypothetical modifications
  → road blockage
  → resource failure
  → emergency surge
  → shelter capacity reduction
  → flood severity increase
  → high-vulnerability cluster added
       ↓
Run decision engine (with vulnerability scoring)
       ↓
Run routing
       ↓
Calculate impact
       ↓
Compare live vs simulated plan
       ↓
Apply / Cancel
```

---

## 11. Agent Architecture

### Supervisor Agent

Responsibilities:

- understand event type
- determine which agents/tools are needed
- sequence operations
- maintain workflow state
- request explanation

### Situation Understanding Agent

Tools:

- emergency repository
- road repository
- report repository
- confidence service
- disaster zone resolver

Output:

```text
current situation
affected entities
applicable disaster zone
relevant policies
uncertainties
```

### Resource Management Agent

Tools:

- resource repository
- allocation engine (vulnerability-aware)
- availability service

Output:

```text
candidate resources
vulnerability-adjusted resource recommendations
reasons
```

### Routing & Planning Agent

Tools:

- route graph
- route service
- OR-Tools/NetworkX

Output:

```text
route
ETA
constraint violations
alternative routes
```

### Policy & Compliance Agent (new)

Tools:

- disaster zone policy repository
- zone geometry resolver
- reconstruction norm retriever

Output:

```text
applicable zone
active policies by role
reconstruction norms (if post-disaster context)
population accounting status for zone
```

### What-If Agent

Tools:

- simulation service
- allocation engine
- routing engine

Output:

```text
scenario impact
alternative plan
comparison
```

### Explanation Agent

Uses the configured LLM to turn structured outputs into concise operator-readable explanations.

The explanation agent must not invent facts not present in tool outputs.

---

## 12. Real-Time Flow

```text
Database update
     ↓
Domain event
     ↓
Redis/event mechanism where appropriate
     ↓
WebSocket
     ↓
React command center
     ↓
Map/queue/population accounting updates
```

---

## 13. Notification Flow

```text
Assignment approved
     ↓
Notification service
     ↓
Responder app:
  "Emergency E101 assigned to you.
   Priority: CRITICAL.
   Vulnerability: Elderly, cannot swim.
   ETA: 11 minutes."

Citizen app (on zone policy trigger):
  "Your area is under Flood Zone Alpha policy.
   Mandatory evacuation if water level exceeds 1.5m.
   Proceed to nearest shelter."

Coordinator (population gap alert):
  "Zone W7 has ~353 potentially unaccounted individuals.
   Please review and initiate appropriate action."
```

---

## 14. Offline Synchronization Design

### Client

```text
local entity
local UUID
payload (including vulnerability profile snapshot)
operation
created_at
retry_count
sync_status
```

### Sync request

```json
{
  "client_id": "...",
  "operations": [
    {
      "operation_id": "...",
      "entity_type": "EMERGENCY",
      "operation": "CREATE",
      "payload": {
        "vulnerability_profile_snapshot": {}
      }
    }
  ]
}
```

### Server

```text
receive
→ validate
→ check operation_id
→ ignore/replay safely if already processed
→ persist
→ return authoritative record
```

---

## 15. Software Radio Simulator

```text
Transport
 ├── InternetTransport
 ├── SimulatedRadioTransport
 └── OfflineQueueTransport
```

This is only a software simulation in the MVP.

---

## 16. Command Center Layout

```text
+--------------------------------------------------------------+
| Disaster Status | Connectivity | Active Alerts               |
+-------------------------+------------------------------------+
|                         | Emergency Queue                    |
|                         |                                    |
|        MAP              | E101 CRITICAL (elderly, no swim)   |
|  (zone overlays)        | E102 HIGH                          |
|  (population gaps)      | E103 MEDIUM                        |
|                         |                                    |
+-------------------------+------------------------------------+
| Resources | Roads | Shelters | Confidence | Simulator        |
+--------------------------------------------------------------+
| Zone Policies | Population Accounting | Reconstruction Norms  |
+--------------------------------------------------------------+
```

---

## 17. Suggested Repository Structure

```text
disaster-response/
│
├── mobile/
│   └── flutter_app/
│       ├── lib/
│       │   ├── core/
│       │   ├── features/
│       │   │   ├── emergency/
│       │   │   ├── vulnerability_profile/
│       │   │   ├── zone_policy/
│       │   │   └── missing_person/
│       │   ├── data/
│       │   ├── domain/
│       │   └── services/
│       └── test/
│
├── command-center/
│   └── react-app/
│       ├── src/
│       │   ├── components/
│       │   ├── pages/
│       │   ├── features/
│       │   │   ├── emergency/
│       │   │   ├── population_accounting/
│       │   │   ├── zone_policy/
│       │   │   └── reconstruction_advisor/
│       │   ├── services/
│       │   └── types/
│       └── tests/
│
├── backend/
│   └── fastapi/
│       ├── app/
│       │   ├── api/
│       │   ├── core/
│       │   ├── models/
│       │   ├── schemas/
│       │   ├── repositories/
│       │   ├── services/
│       │   │   ├── priority_engine/
│       │   │   ├── vulnerability_scorer/
│       │   │   ├── zone_policy_engine/
│       │   │   ├── population_accounting/
│       │   │   └── missing_person_inference/
│       │   ├── decision_engine/
│       │   ├── agents/
│       │   └── websocket/
│       └── tests/
│
├── infrastructure/
│   ├── docker/
│   └── migrations/
│
├── docs/
│
└── Tasks/
    ├── Tasks.md
    └── TasksCompleted.md
```

---

## 18. Implementation Order

```text
1. Repository/bootstrap
2. Backend foundation
3. Database models/migrations (including Zone, Policy, PopulationAccounting, VulnerabilityProfile)
4. Authentication/RBAC
5. Emergency APIs (with vulnerability profile)
6. Flutter emergency reporting + vulnerability onboarding
7. Offline local persistence
8. Synchronization
9. Resource APIs
10. Vulnerability-aware priority engine
11. Allocation engine (vulnerability-fit scoring)
12. Disaster zone resolver + policy delivery
13. Command-center map/dashboard (with zone overlays)
14. Assignment workflow
15. WebSockets
16. Road model/routing
17. Dynamic replanning
18. Population accounting + missing-person inference
19. Confidence layer
20. What-If simulator
21. LangGraph orchestration (including Policy & Compliance Agent)
22. LLM explanation
23. Reconstruction compliance advisor
24. Radio simulator
25. Hardening/tests/demo polish
```

---

## 19. Non-Functional Requirements

### Reliability

The system should degrade gracefully during connectivity failures.

### Explainability

Important decisions should have machine-readable reasons, including vulnerability factors contributing to priority.

### Privacy

Vulnerability profile data is sensitive personal information. It must be:
- Stored with access controls (citizen can view/edit own profile; coordinator/admin can view only for active emergencies).
- Not exposed in public APIs or to unauthenticated users.
- Used only for the purpose of improving emergency response.

Population accounting data is zone-level only; individual identities are not inferred automatically.

### Security

Use authentication and authorization throughout the system.

### Consistency

Synchronize offline data safely without duplicates.

### Maintainability

Keep domain logic independent from UI.

### Extensibility

Architecture should allow:
- additional disaster types
- additional vulnerability factors
- additional policy zones
- real radio hardware
- additional routing providers
- IoT/sensor feeds

without replacing the entire system.

---

## 20. Final Operational Workflow

```text
             DISASTER
                 |
                 v
        Citizen reports SOS
        (vulnerability profile attached)
                 |
        +--------+--------+
        |                 |
    CONNECTED          OFFLINE
        |                 |
        |             Local DB
        |                 |
        |             Pending
        |                 |
        +------SYNC-------+
                 |
                 v
      Disaster Zone Resolved
      Policies Surfaced to User
                 |
                 v
      Vulnerability-Aware Priority
                 |
                 v
      Vulnerability-Fit Resource Matching
                 |
                 v
          Route Planning
                 |
                 v
     Human-approved Assignment
                 |
                 v
             RESPONDER
                 |
          +------+------+
          |             |
      Road changes   Resource fails
          |             |
          +------+------+
                 |
                 v
        Dynamic Replanning
                 |
                 v
         Alternative Plan
                 |
                 v
          What-If Analysis
                 |
                 v
         Coordinated Action
                 |
                 v
    Population Accounting Running
                 |
                 v
       Zone Gap Detected?
          |         |
         YES        NO
          |         |
    Alert sent   Continue
    Human reviews
    Zone search initiated
                 |
                 v
          New Information
                 |
                 +----------> REPLAN
```
