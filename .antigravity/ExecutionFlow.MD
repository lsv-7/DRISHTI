# Execution Flow

## 1. End-to-End System Flow

```text
Citizen / Responder Mobile App
(with Vulnerability Profile)
        |
        v
Connectivity Router
        |
   +----+----------------------+
   |                           |
ONLINE / INTERMITTENT        OFFLINE
   |                           |
   v                           v
FastAPI Backend          Drift / SQLite
   |                           |
   |                     Pending Queue
   |                           |
   +------------+--------------+
                |
                v
        Synchronization Layer
                |
                v
        PostgreSQL + PostGIS
                |
        +-------+---------+----------+---------+
        |                 |          |          |
       Redis        WebSocket   Zone/Policy  Population
        |            Events      Engine      Accounting
        |                 |
        +-------+---------+
                |
                v
      Disaster Intelligence Layer
                |
        +-------+------------------------------+---------------+
        |       |        |        |             |               |
  Vulnerability Resource  Route  Confidence Simulation    Policy &
  Priority     Engine    Engine   Layer      Engine       Compliance
  Engine                                                  Engine
        |       |        |        |             |               |
        +-------+--------+--------+-------------+---------------+
                         |
                         v
                Agent Orchestration
                    LangGraph
                         |
                         v
                React Command Center
                         |
                         v
       Human Approval / Operational Action
                         |
                         v
        Responders / Shelters / Hospitals /
                Citizens / Authorities
                         |
                         v
                 New Events
                         |
                         +----> Replanning Loop
```

---

## 2. Citizen Emergency Flow

### Step 1 — Vulnerability profile check

Before submitting an emergency, the citizen should have completed a vulnerability profile (age, gender, swim ability, disability, mobility). If not collected, the app prompts a quick capture during emergency creation as a one-time step.

Vulnerability data is stored locally and synced. It accompanies every emergency submission.

### Step 2 — Emergency occurs

A citizen opens the Flutter application and selects an emergency type.

Example:

```text
Emergency Type: Medical Rescue
Severity: Critical
People Affected: 4
Location: GPS coordinates
Description: Family trapped inside flooded house

Vulnerability Profile:
  - Reporter age: 68 (ELDERLY)
  - Can swim: NO
  - Mobility: LIMITED
  - Medical condition: Hypertension
```

### Step 3 — Connectivity check

The Connectivity Router determines whether the application is:

- online
- intermittent
- offline

### Step 4 — Local persistence

If the network is unavailable:

```text
Flutter
  ↓
Drift/SQLite (with vulnerability profile snapshot)
  ↓
Emergency status = PENDING_SYNC
```

The citizen should still receive a local confirmation.

### Step 5 — Synchronization

When connectivity returns:

```text
PENDING_SYNC
    ↓
Sync API
    ↓
Idempotency validation
    ↓
PostgreSQL/PostGIS
    ↓
Emergency status = SYNCED
```

---

## 3. Disaster Zone Resolution Flow

After an emergency is received and synced:

```text
Emergency (lat, lon)
    ↓
PostGIS spatial query
    ↓
Disaster Zone identified (or UNKNOWN)
    ↓
Fetch applicable policies by role
    ↓
Push policies to:
  → Citizen app (citizen-facing rules)
  → Coordinator command center (all policies, including reconstruction norms)
  → Responder app (operational rules for the zone)
```

If no zone is matched, the system proceeds without zone-specific policy but logs the gap for administrator review.

---

## 4. Emergency Prioritization (Vulnerability-Aware)

After an emergency is received:

```text
Emergency
    ↓
Validate payload
    ↓
Extract severity
people affected
medical need
waiting time
accessibility
    ↓
Extract vulnerability factors from profile:
  age group
  can swim (critical for flood type)
  disability
  mobility
  medical conditions
    ↓
Vulnerability-Aware Priority Engine
    ↓
Priority score + explanation (including vulnerability breakdown)
```

Example:

```text
E101
Severity = 5
People affected = 4
Medical need = HIGH
Waiting time = 6 min
Vulnerability factors:
  - Reporter: elderly, cannot swim, hypertension
  - Vulnerability boost: +18 pts

Priority = 96
Reason:
Critical medical rescue. Elderly non-swimmer with hypertension
in flood zone. Limited mobility. High vulnerability classification.
```

Weights remain configurable by administrators.

---

## 5. Resource Allocation

```text
Prioritized Emergency (with vulnerability profile)
        ↓
Find compatible resources
        ↓
Filter unavailable resources
        ↓
Check capabilities (required + vulnerability-fit)
        ↓
Check capacity
        ↓
Check route feasibility
        ↓
Estimate ETA
        ↓
Calculate resource score (capability + vulnerability_fit_bonus + ETA)
        ↓
Recommend resource (ranked with reasons)
        ↓
Human approval / automatic policy action
        ↓
Assignment created
```

Example:

```text
E101 requires:
- water rescue
- medical capability
- capacity >= 4
- vulnerability fit: elderly, cannot swim → prefer medical boat team

Candidates:
R01: medical + rescue, ETA 14 min, no boat
R02: water rescue, ETA 8 min, no medical
R03: water rescue + medical, ETA 11 min, boat equipped

Recommendation:
R03
Reason:
Meets all required capabilities. Best vulnerability fit for elderly non-swimmer.
Medical capability available. Feasible ETA.
```

---

## 6. Live Road Change

```text
Road R12 → BLOCKED
       ↓
Event generated
       ↓
Find affected assignments
       ↓
Recalculate routes
       ↓
Check alternate resources (maintaining vulnerability priority order)
       ↓
Generate revised plan
       ↓
Human approval
       ↓
Update assignment
       ↓
Notify responder
```

---

## 7. Dynamic Replanning

```text
OBSERVE
  ↓
Detect changed state
  ↓
UNDERSTAND
  ↓
Determine affected emergencies/resources/routes
  ↓
PLAN
  ↓
Generate alternatives (vulnerability ordering preserved)
  ↓
VALIDATE
  ↓
Check constraints
  ↓
APPROVE
  ↓
Human operator confirms
  ↓
EXECUTE
  ↓
Update assignments
  ↓
MONITOR
  ↓
Observe next event
```

---

## 8. Population Accounting & Missing-Person Inference Flow

This flow runs continuously in the background and on-demand.

```text
Shelter Registration Events
Confirmed Safe Reports
        ↓
Population Accounting Engine
        ↓
For each active disaster zone:
  accounted = shelter_registrations + confirmed_safe
  gap = expected_population - accounted
  gap_pct = gap / expected_population
        ↓
If gap_pct > threshold:
  Status = CRITICAL
  Alert dispatched to coordinators
Elif gap_pct > 0.6 * threshold:
  Status = ATTENTION
        ↓
Coordinator receives alert:
  "Zone W7: ~353 potentially unaccounted individuals.
   Confidence: MEDIUM. Human review required."
        ↓
Coordinator action:
  → Initiate zone outreach/search
  → Create missing-person investigation
  → Mark zone as UNDER_REVIEW
        ↓
As individuals are found:
  Shelter registration increases
  Gap narrows
  Alert status updates automatically
```

Note: The system does NOT automatically create individual missing-person records. It flags zones with population gaps. Human coordinators initiate the individual-level search.

---

## 9. Confidence Layer Flow

```text
Citizen Report
Responder Report
Authority Report
Sensor/External Feed (optional)
        ↓
Normalize
        ↓
Group related observations
        ↓
Check source reliability rules
        ↓
Check corroboration
        ↓
Check recency
        ↓
Check geographic proximity
        ↓
Check verification
        ↓
Calculate heuristic confidence
        ↓
Current Situation Record
```

Example:

```text
Road R12

Citizen reports: 4
Responder verification: 1
Conflicting reports: 1
Recent update: 8 minutes ago

Status: PARTIALLY BLOCKED
Confidence: 82%
```

---

## 10. What-If Simulation Flow

The simulator must never mutate the live state directly.

```text
LIVE STATE
   |
   v
Create Simulation Snapshot
   |
   v
Operator modifies scenario
   |
   +--> Block Road
   +--> Disable Resource
   +--> Increase Emergencies
   +--> Reduce Shelter Capacity
   +--> Increase Flood Severity
   +--> Add High-Vulnerability Population Cluster
   |
   v
Run Decision Engine (vulnerability-aware)
   |
   v
Run Routing / Allocation
   |
   v
Compare:
LIVE PLAN vs SIMULATED PLAN
   |
   v
Show impact (including vulnerability-priority shifts)
   |
   +--> CANCEL
   |
   +--> APPLY
          |
          v
      Update Live State
          |
          v
      Trigger notifications
```

---

## 11. Disaster Zone Policy Delivery Flow

```text
Emergency registered (lat, lon)
       ↓
PostGIS zone lookup
       ↓
Zone identified
       ↓
Policy Engine: fetch policies for zone
  filtered by role:
    CITIZEN → basic safety & evacuation rules
    RESPONDER → operational rules
    COORDINATOR → all policies
    COORDINATOR → reconstruction norms (reconstruction_norm = true)
       ↓
Policies delivered via:
  → Push notification to citizen app
  → Command center zone panel
  → Responder app sidebar
       ↓
Reconstruction norms displayed in:
  → Command center "Reconstruction Advisor" panel
  → Post-disaster recovery report
```

---

## 12. Agentic AI Execution Flow

LangGraph orchestration layer.

```text
EVENT
  ↓
Supervisor Agent
  ↓
Situation Understanding Agent
  ↓
Policy & Compliance Agent  ← zone identified, policies fetched
  ↓
Resource Management Agent  ← vulnerability-aware matching
  ↓
Routing & Planning Agent
  ↓
What-If Simulation Agent (when needed)
  ↓
Explanation Agent
  ↓
Human Approval
  ↓
Action
  ↓
Feedback / New Event
  ↓
Replanning
```

### Critical architectural rule

LLMs do not independently perform safety-critical resource allocation.

```text
LLM = orchestration + reasoning assistance + explanation
Deterministic engine = scoring + constraints + allocation + routing
Human = approval for consequential operational changes
```

---

## 13. Suggested Live Demo Execution

The strongest demo sequence:

1. Start with a flood dashboard — zone overlays visible.
2. Show available rescue/medical resources.
3. Citizen creates a critical SOS with vulnerability profile (elderly, cannot swim).
4. Show vulnerability-boosted priority score with explanation.
5. Show disaster zone policies delivered to citizen and coordinator.
6. Show vulnerability-fit resource recommendation (medical boat team preferred).
7. Assign responder.
8. Disable internet — show report stored locally.
9. Restore internet — show automatic synchronization.
10. Block the route used by the responder.
11. Trigger dynamic replanning (vulnerability order preserved).
12. Make another resource unavailable. Show revised recommendation.
13. Open Population Accounting panel — show zone gap alert for affected ward.
14. Coordinator acknowledges gap, initiates zone search.
15. Open What-If Simulator — add high-vulnerability cluster, block another road.
16. Run simulation. Compare live vs simulated plan.
17. Apply alternative plan.
18. Show responder/citizen updates.
19. Show Reconstruction Norms panel for the disaster zone.

Do not attempt to demo every feature. Tell the story of the changing disaster and how the platform adapts — starting from the vulnerable person needing help and ending with coordinated, policy-grounded response.
