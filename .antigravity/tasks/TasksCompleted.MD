# Tasks Completed

> This file is the persistent implementation history for the project.

## How to Use

An AI coding agent switching into this repository/account must read this file before continuing development.

Only mark a task completed after the implementation exists and relevant validation has been performed.

---

# Completed Tasks

No implementation tasks have been verified as completed in this context yet.

---

# Implementation History Template

For every completed task, use:

```text
## TXXX — Task Name

Status: COMPLETED
Date: YYYY-MM-DD

### What was implemented
- ...

### Files changed
- ...

### Validation
- Test:
- Build:
- Type check:
- Manual verification:

### Dependencies / follow-up
- ...

### Known limitations
- ...
```

---

# Architectural Decisions

## ADR-001 — Flood-response-first MVP

The initial implementation focuses on flood/disaster response because the core coordination workflow can be demonstrated clearly with emergencies, roads, resources, shelters and changing conditions.

## ADR-002 — Offline-first mobile architecture

Citizen/responder mobile workflows use local persistence and a pending synchronization queue so that emergency information is not lost merely because connectivity is temporarily unavailable.

Vulnerability profile data is stored locally and included as a snapshot in synced emergency payloads.

## ADR-003 — Software radio simulation

Physical LoRa/radio hardware is not available for the MVP.

The project may therefore contain a software-based Radio Network Simulator. It must be clearly identified as simulation.

## ADR-004 — Deterministic safety-critical decision engine

LLMs are not the sole authority for emergency resource allocation, vulnerability scoring, or population accounting.

Deterministic scoring, optimization and routing engines produce operational recommendations. Agentic AI orchestrates tools and provides explanations.

## ADR-005 — What-If isolation

What-If simulations operate on a snapshot/copy of live state.

Running a simulation must not mutate live operational state.

## ADR-006 — Confidence is heuristic

The situational truth layer exposes a confidence indicator based on evidence factors. Unless a calibrated statistical model is implemented and validated, the value must be described as heuristic confidence rather than probability.

## ADR-007 — Human approval

Consequential changes to operational assignments should support human approval before execution.

## ADR-008 — Vulnerability-aware priority (NEW)

Emergency priority scoring incorporates a vulnerability component based on individual citizen profiles (age, swim ability, disability, mobility, medical conditions).

Vulnerability weights are configurable by administrators.

The vulnerability score is a product heuristic, not a medically validated triage score, and must be labeled as such in all displays.

Vulnerability profile data is sensitive personal data governed by role-based access controls:
- Citizen can view and edit their own profile.
- Coordinators can view vulnerability data only for active emergencies they are handling.
- The data is used only for priority scoring and resource matching.

Resource matching incorporates a vulnerability_fit_bonus that prefers resources whose capabilities address the specific vulnerability profile of the affected person.

## ADR-009 — Disaster zone policy engine (NEW)

Disaster zone boundaries are stored as PostGIS polygon geometries.

When an emergency is registered, the system resolves the GPS coordinates to a disaster zone using ST_Contains.

Zone-specific policies are stored in the DisasterZonePolicy table with role-based delivery targeting (CITIZEN, RESPONDER, COORDINATOR, ALL).

Reconstruction norms are a subset of zone policies (reconstruction_norm = true). They are surfaced in the command-center Reconstruction Advisor panel and in post-disaster recovery advisories.

Policy information is clearly labeled as an informational aid, not legal advice.

Policy records are created and maintained by administrators. Policy delivery does not constitute legal enforcement.

## ADR-010 — Population accounting and missing-person inference (NEW)

Population accounting operates at the zone level using pre-disaster population counts stored by administrators from census/administrative data.

Accounted population is computed from shelter registrations and coordinator-confirmed safe reports.

Zone-level population gaps are flagged when the gap percentage exceeds a configurable threshold:
- ATTENTION: gap_pct > 60% of threshold
- CRITICAL: gap_pct > threshold

Zone gap alerts are dispatched to coordinators via WebSocket and the notification system.

The system does NOT automatically create individual missing-person records from gap inference. This is a hard rule enforced by:
1. Missing-person records require a human coordinator to create them.
2. The human_confirmed flag must be set to true before any public listing.
3. Gap alerts always display a "human review required" notice.

Individual missing-person records may be created manually or marked as INFERRED_ZONE_GAP source, but human_confirmed remains false until a coordinator explicitly confirms.

Privacy: zone-level gap data is available to coordinators and administrators only. Individual shelter registrations are not publicly exposed.

## ADR-011 — Reconstruction & prevention policy advisor (NEW)

Reconstruction norms (policies with reconstruction_norm = true) are a formal part of the DisasterZonePolicy model, not a separate system.

They are surfaced via:
1. The command-center Reconstruction Advisor panel (showing all active reconstruction norms for affected zones).
2. Post-disaster recovery advisories generated by coordinators.
3. The Policy & Compliance Agent when queried for zone information.

The system does not enforce compliance. It makes requirements visible and traceable. Coordinators can log reconstruction advisory records against specific locations, but these are informational logs only.

## ADR-012 — Policy & Compliance Agent in LangGraph (NEW)

A dedicated Policy & Compliance Agent is added to the LangGraph orchestration layer.

Responsibilities:
- Resolve emergency location to disaster zone.
- Fetch applicable policies by role.
- Fetch reconstruction norms for the zone.
- Retrieve zone population accounting status.
- Return structured output for operator consumption and Explanation Agent.

This agent calls real backend tools. It does not invent policy content.

---

# Current Product Definition

The target end-to-end workflow is:

```text
Disaster
→ Citizen SOS (with vulnerability profile)
→ Offline/online handling
→ Synchronization
→ Disaster Zone Resolution
→ Zone Policies delivered to citizen and coordinator
→ Vulnerability-aware priority calculation
→ Vulnerability-fit resource matching
→ Route planning
→ Assignment
→ Road/resource state changes
→ Dynamic replanning (vulnerability order preserved)
→ Confidence-aware situation
→ What-If simulation (with vulnerability cluster scenario)
→ Human approval
→ Population accounting running in background
→ Zone gap alert dispatched to coordinator
→ Coordinator acknowledges, initiates zone search
→ Reconstruction norms surfaced in command center
→ Coordinated response
```

---

# Current Technology Direction

```text
Flutter (with vulnerability profile and zone policy delivery)
React + TypeScript (with zone overlays, population accounting panel, reconstruction advisor)
FastAPI
PostgreSQL + PostGIS (zones, policies, population accounting, vulnerability profiles)
Redis
Drift/SQLite
Leaflet + OpenStreetMap (with zone polygon overlays)
LangGraph (Supervisor + Situation + Resource + Routing + Policy&Compliance + Simulation + Explanation agents)
Gemini/Groq/open-weight LLM
OR-Tools
NetworkX
Cloudinary (optional)
WebSockets
JWT/OAuth2
```

---

# Current Known Limitations

1. Physical LoRa/radio hardware is not part of the MVP.
2. Disaster priority weights (including vulnerability weights) are product heuristics, not medically validated triage.
3. Confidence scores are heuristic unless statistically calibrated.
4. Routing may initially use a simplified graph/demo implementation.
5. External weather/sensor feeds are optional.
6. Missing-person matching must remain human-verified.
7. LLM availability must not block deterministic emergency coordination.
8. Paid SMS should not be a core dependency.
9. Population gap inference is probabilistic — specific individuals cannot be automatically identified as missing.
10. Pre-disaster population counts depend on administrator-maintained census data; the system cannot self-populate these.
11. Disaster zone boundaries must be manually created by administrators; the system does not auto-generate zone geometries.
12. Policy information is informational only — the system does not enforce compliance with reconstruction norms or disaster management laws.

---

# Continuation Protocol

When switching accounts or AI coding agents:

```text
1. Read ProblemDescription.md
2. Read ExecutionFlow.md
3. Read Prompt.md
4. Read RULES.md
5. Read WorkflowSolution.md
6. Read Tasks.md
7. Read TasksCompleted.md
8. Inspect repository
9. Find first uncompleted, unblocked task
10. Implement it
11. Validate it
12. Update TasksCompleted.md
13. Update Tasks.md
14. Continue
```

The files in this directory are the persistent project context. Code in the repository remains the source of truth for what has actually been implemented.
