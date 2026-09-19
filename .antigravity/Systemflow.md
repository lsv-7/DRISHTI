Absolutely. Below is a **complete Markdown document** you can save as:

`SystemDataFlow.md`

This is written specifically for **demonstrating/explaining the system flow**, including **where data originates, how it enters the platform, how it is validated, stored, updated, consumed by the decision engine, and eventually reaches citizens/responders**.

I’ve also distinguished **master data, live operational data, field observations, external disaster alerts, and demo/simulated data**, because that distinction will matter when judges ask where your data actually comes from.

````md
# Intelligent Disaster Response & Relief Coordination
# Complete System Data Flow

---

## 1. Purpose

The platform is an intelligent disaster-response coordination system that connects:

- Citizens
- Responders
- Hospitals
- Fire stations
- Police
- Shelters
- Ambulances
- Rescue teams
- Government / disaster-management authorities
- Command-center coordinators

The system continuously collects, validates, stores, updates and distributes
information about:

- Emergencies
- People and vulnerability
- Disaster zones
- Roads
- Hospitals
- Fire stations
- Shelters
- Rescue resources
- Ambulances
- Resource availability
- Shelter occupancy
- Hospital capacity
- Road conditions
- Population movement
- Missing-person investigations
- Disaster policies
- Evacuation routes

The core principle is:

> Stable information is maintained as master data, while rapidly changing
> information is maintained as live operational state.

---

# 2. High-Level System

```text
                         EXTERNAL / MASTER SOURCES
                                  |
             +--------------------+--------------------+
             |                    |                    |
             v                    v                    v
        Government /          Facility Data       Geographic Data
        Authority Data                              / GIS / OSM
             |                    |                    |
             +--------------------+--------------------+
                                  |
                                  v
                         DATA INGESTION LAYER
                                  |
                                  v
                      VALIDATION / NORMALIZATION
                                  |
                                  v
                         MASTER DATA STORE
                                  |
                                  |
             +--------------------+---------------------+
             |                                          |
             v                                          v
      STATIC INFORMATION                         OPERATIONAL STATE
             |                                          |
             |                              +-----------+-----------+
             |                              |           |           |
             v                              v           v           v
       Hospitals                         Capacity    Resources    Roads
       Fire Stations                    Occupancy    Status       Status
       Shelters                         Availability Location     Flood
       Police Stations
       Roads
       Wards
       Disaster Zones
             |                                          |
             +----------------------+-------------------+
                                    |
                                    v
                          DISASTER PLATFORM
                                    |
                    +---------------+---------------+
                    |               |               |
                    v               v               v
              Decision Engine   Agentic AI     Event Engine
                    |               |               |
                    +---------------+---------------+
                                    |
                                    v
                            COMMAND CENTER
                                    |
             +----------------------+----------------------+
             |                      |                      |
             v                      v                      v
         Citizens              Responders             Authorities
````

---

# 3. Five Major Data Categories

The system separates data into five major categories.

```text
1. MASTER DATA
2. LIVE OPERATIONAL DATA
3. FIELD OBSERVATION DATA
4. EXTERNAL DISASTER / ALERT DATA
5. DEMO / SIMULATION DATA
```

This separation is important because each type of information has a different
source, update frequency and reliability.

---

# 4. Master Data

Master data describes relatively stable entities.

Examples:

```text
Hospital
Fire Station
Police Station
Shelter
Road
Ward
Disaster Zone
Resource Organization
Emergency Facility
```

Example:

```text
Hospital H01

Name: Hospital A
Latitude: 16.xxxx
Longitude: 80.xxxx
Type: Hospital
Capabilities:
    Emergency
    ICU
    Trauma
```

This information does not normally change every few minutes.

---

# 5. Sources of Master Data

Master data can be obtained from multiple sources.

## 5.1 Government / Municipal Sources

Examples:

* Municipal GIS
* State government GIS
* Disaster-management authorities
* Government facility registries
* Official administrative datasets
* Official facility directories

The Vijayawada municipal portal provides a GIS map and municipal information,
which can serve as one example of an official municipal geographic source.

Source:

[https://vijayawada.cdma.ap.gov.in/ulbprofile/vijayawada/gis-map](https://vijayawada.cdma.ap.gov.in/ulbprofile/vijayawada/gis-map)

---

## 5.2 Geographic Data

Geographic information can come from:

* OpenStreetMap
* Government GIS
* Municipal GIS
* Open geospatial datasets
* Verified geographic datasets

Examples:

```text
City boundary
Ward boundary
Road network
Buildings
Water bodies
Geographic coordinates
```

The geographic data provides the spatial foundation of the system.

---

## 5.3 Facility Data

Facilities can be onboarded into the platform.

Examples:

```text
Hospital
Fire Station
Police Station
Shelter
Ambulance Center
Relief Center
```

The platform stores the facility's:

```text
Identity
Location
Capabilities
Contact information
Capacity
Accessibility
Operating status
```

---

# 6. Master Data Ingestion

The initial flow is:

```text
External Source
      |
      v
Data Collection
      |
      v
Format Conversion
      |
      v
Validation
      |
      v
Normalization
      |
      v
Duplicate Detection
      |
      v
Human Verification (if required)
      |
      v
Master Database
```

For example:

```text
Government GIS
       |
       v
Hospital Location Dataset
       |
       v
Normalize coordinates
       |
       v
Validate hospital identity
       |
       v
Store Hospital H01
```

---

# 7. Master Database

The master database stores stable information.

Example:

```text
HOSPITAL
----------------------------
hospital_id
name
location
type
capabilities
contact
accessibility
source
source_reference
verified_at
created_at
updated_at
```

Example:

```json
{
  "hospital_id": "H01",
  "name": "Hospital A",
  "latitude": 16.50,
  "longitude": 80.64,
  "type": "HOSPITAL",
  "capabilities": [
    "EMERGENCY",
    "ICU",
    "TRAUMA"
  ],
  "source": "VERIFIED_FACILITY_REGISTRY"
}
```

---

# 8. Master Data Is Not Live Data

This distinction is extremely important.

For example:

```text
Hospital location
```

is master data.

But:

```text
Available ICU beds
```

is live operational data.

Similarly:

```text
Shelter location
```

is master data.

But:

```text
Shelter currently has 120 available spaces
```

is operational data.

---

# 9. Live Operational Data

Live operational data represents the current state of resources.

Examples:

```text
Hospital beds
ICU availability
Ambulance availability
Fire-team availability
Rescue-team availability
Shelter occupancy
Road status
Resource location
Resource assignment
Water level
Disaster severity
```

This data changes frequently.

---

# 10. Hospital Data Flow

Consider a hospital.

## Initial state

```text
Hospital H01

Location:
16.xxxx, 80.xxxx

Capabilities:
Emergency
ICU
Trauma
```

This is master data.

---

## Operational state

```text
Hospital H01

Emergency Beds = 12
ICU Beds = 3
Ambulances = 2
Medical Teams = 2
Status = OPERATIONAL
```

This is live data.

---

# 11. Hospital Update

Suppose the hospital receives emergency patients.

Initial:

```text
ICU Beds Available = 3
```

After patients arrive:

```text
ICU Beds Available = 1
```

The hospital's authorized operator sends an update:

```text
Hospital H01
    |
    v
Operational Update
    |
    v
API
    |
    v
Validation
    |
    v
Operational Database
    |
    v
Event
    |
    v
WebSocket / Event Bus
    |
    v
Command Center
```

The command center now sees:

```text
ICU Availability
3 -> 1
```

---

# 12. Fire Station Data Flow

Master data:

```text
Fire Station F01

Location
Capabilities
Equipment
Contact
Service Area
```

Operational state:

```text
Fire Engines = 4
Available = 3
Busy = 1
```

When a fire engine is dispatched:

```text
AVAILABLE
    |
    v
ASSIGNED
    |
    v
EN_ROUTE
    |
    v
AT_INCIDENT
    |
    v
BUSY
```

When it becomes free:

```text
BUSY
  |
  v
AVAILABLE
```

Every state change is stored.

---

# 13. Shelter Data Flow

Master data:

```text
Shelter S01

Location
Capacity
Accessibility
Facilities
Amenities
```

Operational state:

```text
Capacity = 500
Occupied = 380
Available = 120
```

Suppose 80 people arrive.

```text
Occupied:
380 -> 460

Available:
120 -> 40
```

The updated state becomes:

```text
Shelter S01
Capacity = 500
Occupied = 460
Available = 40
```

The resource engine can now avoid sending another group of 100 people
to this shelter.

---

# 14. Resource Registry

All operational resources are represented in a common resource registry.

Examples:

```text
RESCUE_TEAM
BOAT_TEAM
AMBULANCE
MEDICAL_TEAM
FIRE_TEAM
POLICE_TEAM
VOLUNTEER_TEAM
EVACUATION_VEHICLE
TRUCK
HELICOPTER
DRONE
RELIEF_TEAM
EQUIPMENT
```

Each resource has:

```text
Resource ID
Type
Capabilities
Capacity
Location
Availability
Current Assignment
Organization
Last Updated
```

---

# 15. Resource Lifecycle

```text
AVAILABLE
    |
    v
RESERVED
    |
    v
ASSIGNED
    |
    v
ACKNOWLEDGED
    |
    v
EN_ROUTE
    |
    v
ARRIVED
    |
    v
IN_PROGRESS
    |
    v
COMPLETED
    |
    v
AVAILABLE
```

If something goes wrong:

```text
ASSIGNED
    |
    v
RESOURCE_FAILURE
    |
    v
UNAVAILABLE
```

This can trigger dynamic replanning.

---

# 16. Citizen Data Flow

The citizen is another source of live information.

Citizen:

```text
Flutter App
    |
    v
Emergency / Observation
    |
    v
Connectivity Layer
    |
    +----------------------+
    |                      |
    v                      v
 ONLINE                  OFFLINE
    |                      |
    v                      v
API                    Local DB
    |                      |
    |                 Pending Queue
    |                      |
    |                 Connectivity Restored
    |                      |
    +----------+-----------+
               |
               v
             SYNC
               |
               v
          Backend API
```

---

# 17. Citizen SOS

Example:

```text
Citizen
   |
   | SOS
   v
Flutter App
   |
   v
Emergency Payload
   |
   v
FastAPI
   |
   v
Validation
   |
   v
Emergency Database
   |
   v
Decision Engine
```

The emergency contains:

```text
Emergency ID
Reporter
Location
Severity
People affected
Medical need
Vulnerability information
Description
Timestamp
Media
```

---

# 18. Offline Emergency

If the citizen has no internet:

```text
Citizen
   |
   v
SOS
   |
   v
Local SQLite / Drift
   |
   v
PENDING_SYNC
```

The application displays:

```text
Emergency saved locally.
Waiting for connectivity.
```

When connectivity returns:

```text
PENDING_SYNC
     |
     v
SYNC REQUEST
     |
     v
SERVER
     |
     v
VALIDATION
     |
     v
DATABASE
     |
     v
SYNCED
```

---

# 19. Idempotent Synchronization

Every offline operation receives:

```text
operation_id
```

Example:

```text
OP-EMG-001
```

If the same operation is accidentally sent twice:

```text
OP-EMG-001
OP-EMG-001
```

the backend recognizes the duplicate.

Result:

```text
One emergency
NOT
Two emergencies
```

This prevents duplicate emergency creation.

---

# 20. Responder Data Flow

Responders are another important source of live information.

```text
Responder App
      |
      v
Observation / Status Update
      |
      v
Backend API
      |
      v
Validation
      |
      v
Operational Database
      |
      v
Event
      |
      +----------------+
      |                |
      v                v
Decision Engine    Command Center
```

Examples:

```text
Road blocked
Flood level increased
Resource unavailable
Person rescued
Person missing
Shelter full
Hospital overloaded
```

---

# 21. Road Status Data Flow

Initial road:

```text
R12
Status = OPEN
```

Citizen reports:

```text
R12
Status = BLOCKED
Source = CITIZEN
```

The system does not automatically assume that the report is verified.

It stores:

```text
Source = CITIZEN
Verification = UNVERIFIED
Confidence = MEDIUM
```

Then a responder confirms:

```text
R12
Status = BLOCKED
Source = RESPONDER
Verification = VERIFIED
```

Now the operational state becomes:

```text
R12
Status = BLOCKED
Verification = VERIFIED
```

---

# 22. Confidence-Aware Situation Layer

Each observation contains:

```text
Source
Timestamp
Location
Status
Evidence
Verification
Confidence
```

Possible sources:

```text
CITIZEN
RESPONDER
AUTHORITY
SENSOR
EXTERNAL_FEED
SYSTEM
```

Verification:

```text
UNVERIFIED
PARTIALLY_VERIFIED
VERIFIED
REJECTED
CONFLICTING
```

Confidence:

```text
VERY_LOW
LOW
MEDIUM
HIGH
VERY_HIGH
```

The confidence value is a system heuristic unless it has been statistically
validated.

It should not be presented as a scientifically validated probability.

---

# 23. External Disaster Alerts

The system can also consume authorized external disaster information.

For example, India's NDMA SACHET platform provides geo-targeted disaster
alerts and receives warning information from authorized government sources.
It also exposes a CAP/RSS-based dissemination mechanism.

Source:

[https://sachet.ndma.gov.in/](https://sachet.ndma.gov.in/)

SACHET documents describe a CAP-based integrated alert system using
geo-intelligence and multiple dissemination channels.

The platform includes sources such as:

* NDMA
* IMD
* CWC
* INCOIS
* FSI
* DGRE

These are examples of external authoritative information sources, not
necessarily direct APIs that the hackathon prototype must integrate.

---

# 24. External Alert Flow

```text
Government / Authorized Source
             |
             v
       Disaster Alert
             |
             v
       Alert Ingestion
             |
             v
      Validate / Normalize
             |
             v
       Disaster Event
             |
             v
       Geographic Zone
             |
             v
       Affected Area
             |
      +------+------+
      |             |
      v             v
 Citizens       Command Center
```

Example:

```text
FLOOD ALERT
Severity: HIGH
Affected Area: Zone 03
```

The system maps the alert to the corresponding geographic zone.

---

# 25. Disaster Zone Creation

A disaster zone contains:

```text
Zone ID
Disaster Type
Geometry
Severity
Water Level
Status
Evacuation Required
Restriction Status
Created At
Updated At
Source
```

Example:

```json
{
  "zone_id": "ZONE-03",
  "disaster_type": "FLOOD",
  "severity": 5,
  "evacuation_required": true,
  "restricted": true
}
```

For the hackathon demo, simulated disaster zones must be clearly identified
as DEMO/SIMULATED unless they originate from an actual verified feed.

---

# 26. Disaster Event Processing

Once a disaster event enters the system:

```text
Disaster Event
      |
      v
Identify Geographic Area
      |
      v
Identify Affected Zones
      |
      v
Find Affected Population
      |
      v
Find Affected Emergencies
      |
      v
Find Affected Resources
      |
      v
Find Affected Roads
      |
      v
Find Nearby Shelters
      |
      v
Find Nearby Hospitals
      |
      v
Decision Engine
```

---

# 27. Person-Centric Emergency Processing

When an emergency is created:

```text
Emergency
    |
    v
Person / Group Information
    |
    v
Environmental Context
    |
    v
Medical Context
    |
    v
Accessibility Context
    |
    v
Priority Engine
```

Factors can include:

```text
Emergency Severity
People Affected
Medical Need
Waiting Time
Accessibility
Evacuation Difficulty
Age Group
Mobility
Disability
Medical Conditions
Swimming Ability
Medication Dependency
```

Factors should only affect priority when relevant to the actual disaster context.

For example:

```text
Cannot Swim + Deep Flood
        |
        v
Higher rescue difficulty
```

But:

```text
Cannot Swim + Non-Water Medical Emergency
        |
        v
No automatic swimming-related increase
```

Gender should not be used as an arbitrary risk multiplier.

---

# 28. Priority Data Flow

```text
Emergency
    |
    v
Emergency Details
    |
    +---- Severity
    +---- People Affected
    +---- Medical Need
    +---- Waiting Time
    +---- Accessibility
    +---- Disaster Context
    +---- Relevant Vulnerability
    |
    v
Deterministic Priority Engine
    |
    v
Priority Score
    |
    v
Priority Level
    |
    v
Explanation
```

Example:

```text
Priority = CRITICAL

Reasons:
- Critical medical need
- Multiple people affected
- Elderly person
- Limited mobility
- Severe flooding
- Difficult evacuation conditions
```

The score is a configurable heuristic and is not a clinically validated
triage score.

---

# 29. Resource Matching

Once an emergency receives priority:

```text
Emergency
    |
    v
Required Capabilities
    |
    v
Resource Registry
    |
    +---- Capability
    +---- Availability
    +---- Capacity
    +---- Location
    +---- Route Feasibility
    +---- Current Assignment
    |
    v
Resource Matching Engine
    |
    v
Candidate Resources
    |
    v
Best Feasible Assignment
```

Example:

```text
Emergency:
Water Rescue
4 People
Medical Need: HIGH

Candidate:

R01 Rescue Team
R02 Boat Team
R03 Ambulance
```

The engine evaluates capability and feasibility.

---

# 30. Routing

After resource matching:

```text
Resource
    |
    v
Current Location
    |
    v
Emergency Location
    |
    v
Road Graph
    |
    v
Blocked / Restricted Roads
    |
    v
Routing Engine
    |
    v
Route
    |
    v
ETA
```

The routing engine should operate on the local road graph for the hackathon
demo rather than requiring a live external routing API.

---

# 31. Assignment

After matching and routing:

```text
Emergency
     |
     v
Resource Recommendation
     |
     v
Route
     |
     v
ETA
     |
     v
Coordinator Approval
     |
     v
Assignment Created
```

Assignment:

```text
Emergency E101
       |
       v
Resource R02
       |
       v
Route R101
       |
       v
ETA 8 minutes
```

---

# 32. Notification Flow

Once the assignment is approved:

```text
Assignment
    |
    +------------------+
    |                  |
    v                  v
Responder          Command Center
    |
    v
Notification
```

Example:

```text
R02 BOAT TEAM

Emergency: E101
Priority: CRITICAL
Location: ...
ETA: 8 minutes
Route: Route R101
```

---

# 33. Dynamic Replanning

This is where the system becomes dynamic.

Suppose:

```text
Road R12
OPEN
```

becomes:

```text
Road R12
BLOCKED
```

The flow becomes:

```text
Road Update
     |
     v
Operational Database
     |
     v
ROAD_STATUS_CHANGED Event
     |
     v
Find Affected Assignments
     |
     v
Routing Engine
     |
     v
Alternative Route
     |
     v
New ETA
     |
     v
Replanning Proposal
     |
     v
Coordinator
     |
     v
APPROVE
     |
     v
Assignment Updated
     |
     v
Responder Notified
```

---

# 34. Why Replanning Is Necessary

Suppose:

```text
Resource R02
     |
     v
Emergency E101
     |
     v
Route R12
```

Then:

```text
R12 = BLOCKED
```

The original plan is no longer feasible.

The system therefore calculates:

```text
Original Route
        VS
Alternative Route
```

Example:

```text
Original ETA = 8 min
New ETA = 12 min
```

The coordinator sees the proposed change before it becomes operational.

---

# 35. Human Approval

Consequential operations should require human approval.

Example:

```text
AI / Decision Engine
        |
        v
Proposed Replan
        |
        v
Coordinator
        |
   +----+----+
   |         |
 APPROVE   REJECT
   |         |
   v         v
Apply      Keep Current Plan
```

The AI should propose and explain.

It should not silently perform critical operational actions.

---

# 36. Population Reconciliation

During a disaster, the system can calculate:

```text
Expected Population
        VS
Accounted Population
```

Sources of accounted population can include:

```text
Shelter registrations
Confirmed safe reports
Hospital admissions
Evacuation records
Responder sightings
Citizen check-ins
```

---

# 37. Population Flow

```text
Population Sources
       |
       +---- Shelter
       +---- Hospital
       +---- Evacuation
       +---- Citizen
       +---- Responder
       |
       v
Population Reconciliation Engine
       |
       v
Expected Population
       |
       VS
Accounted Population
       |
       v
Population Gap
       |
       v
Investigation Required?
```

Example:

```text
Expected = 1000
Accounted = 930

Gap = 70
```

This does NOT mean:

```text
70 people are confirmed missing
```

It means:

```text
The zone has a population-accounting discrepancy
requiring investigation.
```

---

# 38. Missing-Person Investigation

The lifecycle is:

```text
NORMAL
   |
   v
EXPECTED_IN_ZONE
   |
   v
NO_RECENT_PRESENCE
   |
   v
UNACCOUNTED
   |
   v
POTENTIAL_MISSING
   |
   v
UNDER_VERIFICATION
   |
   +--------+---------+---------+
   |        |         |         |
   v        v         v         v
ACCOUNTED EVACUATED FOUND    CONFIRMED
                     SAFE     MISSING
```

Individual missing-person confirmation requires human verification.

---

# 39. Shelter Registration and Missing-Person Reconciliation

Example:

```text
Person P1001

Expected in Zone 03
       |
       v
Not found in shelter records
       |
       v
Not found in hospital records
       |
       v
No recent responder sighting
       |
       v
Family report received
       |
       v
Investigation
       |
       v
Human verification
```

Possible outcomes:

```text
ACCOUNTED
EVACUATED
FOUND_AT_SHELTER
FOUND_AT_HOSPITAL
FOUND_BY_RESPONDER
FOUND_SAFE
FALSE_ALERT
CONFIRMED_MISSING
```

---

# 40. What-If Simulation

The system supports scenario simulation.

Example:

```text
Current State

Road R12 = OPEN
R02 = AVAILABLE
S01 = 120 spaces
```

Coordinator selects:

```text
BLOCK ROAD R12
```

The system does NOT modify the real state.

Instead:

```text
LIVE STATE
    |
    v
CREATE SNAPSHOT
    |
    v
SIMULATION STATE
    |
    v
Apply Scenario
    |
    v
Run Decision Engine
    |
    v
Compare Results
```

---

# 41. Simulation Result

Example:

```text
LIVE:

Route R101
ETA = 8 minutes

SIMULATION:

R12 blocked

Alternative Route
ETA = 12 minutes

Difference
+4 minutes
```

The coordinator can choose:

```text
APPLY
```

or:

```text
CANCEL
```

Only after approval does the simulated change become live.

---

# 42. Policy Data Flow

Each disaster zone can have associated policies/guidance.

Examples:

```text
Evacuation
Shelter
Operational
Prevention
Reconstruction
```

Flow:

```text
Disaster Zone
      |
      v
Identify Applicable Policies
      |
      v
Filter by Role
      |
      +---------+---------+
      |         |         |
      v         v         v
   Citizen   Responder Coordinator
      |         |         |
      v         v         v
 Citizen     Operational  Full
 Guidance    Guidance    Guidance
```

---

# 43. Policy Source

Policy information should be separated into:

```text
OFFICIAL_REQUIREMENT
OFFICIAL_RECOMMENDATION
EDUCATIONAL_GUIDANCE
DEMO_POLICY
```

The system must not present a fabricated rule as a legal requirement.

Where official disaster guidance is available, it should be linked to its
source.

For example, NDMA SACHET publishes disaster-specific Dos and Don'ts covering
hazards including floods, urban floods, cyclones, earthquakes and others.

---

# 44. Resilience / Reconstruction Data

After or before a disaster, the system can surface resilience guidance.

Examples:

```text
Rainwater harvesting
Stormwater management
Flood-resilient construction
Emergency access
Evacuation routes
Accessibility
Drainage maintenance
Water conservation
Hazard-aware construction
```

Flow:

```text
Zone
 |
 v
Hazard Type
 |
 v
Relevant Resilience Guidance
 |
 v
Construction / Planning Context
 |
 v
Recommendation
```

Legal requirements must only be shown when supported by an authoritative
source.

---

# 45. Agentic AI Data Flow

The agentic layer sits above the deterministic services.

```text
EVENT
  |
  v
LangGraph Supervisor
  |
  +------------------+
  |                  |
  v                  v
Situation Agent   Policy Agent
  |                  |
  v                  v
Resource Agent    Explanation Agent
  |
  v
Routing Agent
  |
  v
Simulation Agent
```

Agents should use structured tools.

---

# 46. AI Responsibilities

AI can:

```text
Understand the situation
Summarize reports
Identify relevant information
Retrieve policies
Orchestrate workflows
Explain recommendations
Generate incident summaries
Prepare reports
```

Deterministic services should handle:

```text
Priority calculation
Resource constraints
Capacity checks
Routing
Distance
ETA
Population arithmetic
Simulation state
Validation
Safety constraints
```

---

# 47. AI Must Not Directly Mutate Critical State

Correct architecture:

```text
LLM
 |
 v
Agent
 |
 v
Structured Tool
 |
 v
Deterministic Service
 |
 v
Validation
 |
 v
Human Approval
 |
 v
Database Mutation
```

Not:

```text
LLM
 |
 v
Direct Database Write
```

---

# 48. Central Data Store

The main operational database contains:

```text
Users
Vulnerability Profiles
Emergencies
Resources
Hospitals
Shelters
Fire Stations
Roads
Disaster Zones
Policies
Assignments
Observations
Population Records
Missing-Person Records
Simulations
Notifications
Audit Logs
```

PostgreSQL/PostGIS is used for:

```text
Structured data
Spatial data
Relationships
Geographic queries
```

---

# 49. Redis / Event Layer

Redis can support:

```text
Caching
Queues
Transient state
Real-time events
WebSocket event propagation
Background processing
```

Example:

```text
Database Update
      |
      v
Event
      |
      v
Redis
      |
      +----------+----------+
      |          |          |
      v          v          v
 WebSocket   Worker     Notification
      |
      v
Command Center
```

---

# 50. WebSocket Flow

The command center should not continuously reload the entire database.

Instead:

```text
Operational Change
       |
       v
Event
       |
       v
Redis / Event Layer
       |
       v
WebSocket
       |
       v
Command Center
```

Example:

```text
ROAD_STATUS_CHANGED
```

Command center receives:

```json
{
  "event": "ROAD_STATUS_CHANGED",
  "road_id": "R12",
  "status": "BLOCKED"
}
```

The map updates the road immediately.

---

# 51. Audit Trail

Every important operational change should be traceable.

Example:

```text
Who:
Responder R21

What:
Road R12 changed to BLOCKED

When:
10:35:22

Source:
RESPONDER

Evidence:
Photo

Previous:
OPEN

New:
BLOCKED
```

Audit records should include:

```text
actor
role
action
entity
old_state
new_state
timestamp
source
reason
```

This is important for accountability.

---

# 52. Complete Data Lifecycle

Every major piece of information follows this lifecycle:

```text
SOURCE
  |
  v
COLLECT
  |
  v
INGEST
  |
  v
VALIDATE
  |
  v
NORMALIZE
  |
  v
STORE
  |
  v
PUBLISH EVENT
  |
  v
DECISION ENGINE
  |
  v
AI ORCHESTRATION
  |
  v
COMMAND CENTER
  |
  v
HUMAN DECISION
  |
  v
OPERATIONAL ACTION
  |
  v
FIELD UPDATE
  |
  v
DATABASE
  |
  +---------> LOOP
```

This creates a continuous disaster-response feedback loop.

---

# 53. Complete End-to-End Example

Consider a flood in Vijayawada.

## STEP 1 — Disaster Alert

External / authority source:

```text
FLOOD ALERT
Zone = Z03
Severity = HIGH
```

Data enters:

```text
Alert Ingestion
     |
     v
Validation
     |
     v
Disaster Event
     |
     v
PostGIS
```

---

## STEP 2 — Geographic Impact

System determines:

```text
Affected Zone
Affected Roads
Affected Shelters
Affected Hospitals
Affected Emergencies
Affected Resources
```

---

## STEP 3 — Citizen SOS

Citizen reports:

```text
Family trapped
4 people
Elderly person
Limited mobility
Medical requirement
Flood water
```

Flow:

```text
Flutter
 |
 v
SOS
 |
 v
FastAPI
 |
 v
Emergency DB
```

---

## STEP 4 — Priority

Decision engine calculates:

```text
Severity
+
Medical Need
+
People Affected
+
Environmental Risk
+
Relevant Vulnerability
+
Accessibility
+
Waiting Time
```

Result:

```text
Priority = CRITICAL
```

---

## STEP 5 — Resource Matching

System searches:

```text
Boat Teams
Rescue Teams
Medical Teams
Ambulances
```

It evaluates:

```text
Capability
Availability
Capacity
Distance
Route
Current Assignment
```

Result:

```text
R02 Boat Team
```

---

## STEP 6 — Route

Routing engine calculates:

```text
R02
  |
  v
Road Network
  |
  v
Emergency
```

Result:

```text
ETA = 8 minutes
```

---

## STEP 7 — Human Approval

Coordinator sees:

```text
Emergency E101
Priority CRITICAL

Recommended:
R02 Boat Team

ETA:
8 minutes

Route:
R101
```

Coordinator:

```text
APPROVE
```

---

## STEP 8 — Assignment

```text
R02
ASSIGNED
```

Responder receives:

```text
Emergency E101
Location
Priority
Route
ETA
```

---

## STEP 9 — Road Blockage

Responder reports:

```text
R12 = BLOCKED
```

System receives:

```text
ROAD_STATUS_CHANGED
```

---

## STEP 10 — Replanning

System:

```text
Find affected assignments
        |
        v
Calculate alternative routes
        |
        v
Calculate new ETA
        |
        v
Create replan proposal
```

Result:

```text
Old ETA = 8 min
New ETA = 12 min
```

---

## STEP 11 — Human Approval

Coordinator:

```text
APPROVE REPLAN
```

---

## STEP 12 — Population Reconciliation

System calculates:

```text
Expected = 1000
Accounted = 930
Gap = 70
```

System creates:

```text
Population Investigation
```

It does NOT automatically declare 70 missing people.

---

## STEP 13 — Missing-Person Investigation

Evidence is collected from:

```text
Shelters
Hospitals
Evacuation Records
Citizen Check-ins
Responder Reports
Family Reports
```

Potential candidates are generated.

Human coordinator verifies them.

---

## STEP 14 — Shelter Update

Shelter S01:

```text
Capacity = 500
Occupied = 460
Available = 40
```

System updates the resource registry.

Future evacuation planning uses:

```text
Available = 40
```

instead of the original capacity.

---

## STEP 15 — Hospital Update

Hospital H01:

```text
ICU Available
3 -> 1
```

System updates operational state.

Future medical resource matching avoids relying on stale capacity.

---

## STEP 16 — What-If Simulation

Coordinator asks:

```text
What if R12 becomes blocked?
```

System creates a snapshot.

```text
LIVE STATE
    |
    v
SNAPSHOT
    |
    v
SIMULATION
```

Alternative routes are calculated.

The live system remains unchanged.

---

## STEP 17 — Apply

Coordinator chooses:

```text
APPLY
```

The simulation state is promoted into live operational state.

---

# 54. Complete System Architecture

```text
                           EXTERNAL SOURCES
                                  |
         +------------------------+------------------------+
         |                        |                        |
         v                        v                        v
 Government/GIS             Facility Data          Disaster Alerts
         |                        |                        |
         +------------------------+------------------------+
                                  |
                                  v
                         DATA INGESTION LAYER
                                  |
                     +------------+------------+
                     |                         |
                     v                         v
               VALIDATION                 NORMALIZATION
                     |                         |
                     +------------+------------+
                                  |
                                  v
                          MASTER DATA STORE
                                  |
                                  v
                     +-------------------------+
                     |                         |
                     v                         v
                STATIC DATA              LIVE STATE
                     |                         |
                     |              +----------+----------+
                     |              |          |          |
                     |              v          v          v
                     |          Resources   Capacity    Roads
                     |          Status      Occupancy   Status
                     |                         |
                     +-------------+-----------+
                                   |
                                   v
                          OPERATIONAL DATABASE
                          PostgreSQL + PostGIS
                                   |
                   +---------------+---------------+
                   |               |               |
                   v               v               v
              Event Layer      Decision Engine   Audit
                   |               |
                   |       +-------+-------+
                   |       |       |       |
                   |       v       v       v
                   |    Priority Resource Routing
                   |               |
                   |               v
                   |         Replanning
                   |               |
                   +-------+-------+
                           |
                           v
                     LangGraph Agents
                           |
              +------------+-------------+
              |            |             |
              v            v             v
          Situation     Policy       Explanation
           Agent        Agent          Agent
              |
              v
        Structured Tools
              |
              v
       Deterministic Services
              |
              v
       Human Approval Layer
              |
              v
        Operational Action
              |
      +-------+--------+
      |                |
      v                v
 Responders        Citizens
      |                |
      +-------+--------+
              |
              v
        FIELD OBSERVATIONS
              |
              v
        EVENT / UPDATE API
              |
              v
       OPERATIONAL DATABASE
              |
              +---------------------> LOOP
```

---

# 55. The Core Feedback Loop

The most important concept in the entire system is the feedback loop.

```text
          PLAN
           |
           v
       ASSIGN RESOURCE
           |
           v
       FIELD ACTION
           |
           v
       FIELD OBSERVATION
           |
           v
       SYSTEM UPDATE
           |
           v
       RE-EVALUATION
           |
           v
       REPLANNING
           |
           v
       HUMAN APPROVAL
           |
           v
       NEW PLAN
           |
           +--------------------+
                                |
                                v
                         FIELD ACTION
```

The disaster environment continuously changes.

Therefore the platform is not:

```text
Report -> Store -> Finish
```

It is:

```text
Observe
   ->
Understand
   ->
Decide
   ->
Act
   ->
Observe Again
   ->
Update
   ->
Replan
   ->
Act Again
```

---

# 56. Data Ownership Model

Different actors update different types of information.

| Data                        | Primary Source                       |
| --------------------------- | ------------------------------------ |
| Hospital location           | Facility / authoritative registry    |
| Hospital capabilities       | Facility                             |
| Hospital bed availability   | Hospital operator                    |
| ICU availability            | Hospital operator                    |
| Fire station location       | Authoritative facility data          |
| Fire team availability      | Fire/responder authority             |
| Shelter location            | Authority / shelter registry         |
| Shelter capacity            | Shelter authority                    |
| Shelter occupancy           | Shelter manager / registration       |
| Road geometry               | GIS / geographic dataset             |
| Road blockage               | Responders / authorities / citizens  |
| Emergency report            | Citizen / responder                  |
| Resource location           | Responder/resource device            |
| Resource availability       | Resource operator                    |
| Disaster alert              | Authorized authority / external feed |
| Population reconciliation   | System + operational sources         |
| Missing-person confirmation | Authorized human coordinator         |
| Policy                      | Authority / verified source          |
| Route                       | Decision engine                      |
| Priority                    | Deterministic decision engine        |

---

# 57. Source Reliability Model

Not every source has the same level of verification.

The system therefore records:

```text
SOURCE
VERIFICATION
CONFIDENCE
TIMESTAMP
EVIDENCE
```

Example:

```text
Citizen report
    |
    v
UNVERIFIED

Responder confirms
    |
    v
VERIFIED
```

The system should preserve the provenance of important information rather
than simply overwriting everything with the newest value.

---

# 58. Data Freshness

Every operational record should have:

```text
created_at
updated_at
last_verified_at
source
```

Example:

```text
Shelter S01

Available Spaces: 40

Updated:
10:35 AM

Source:
Shelter Manager

Verified:
10:35 AM
```

The command center can therefore identify stale information.

---

# 59. Stale Data Handling

If:

```text
Hospital capacity
```

has not been updated for a long period, the system can display:

```text
Last updated:
2 hours ago

Status:
STALE
```

It should not silently assume the information is still accurate.

---

# 60. Offline + Online Combined Flow

The platform supports three connectivity states.

```text
ONLINE
   |
   v
Direct API synchronization


LOW CONNECTIVITY
   |
   v
Local queue
+
Retry
+
Partial synchronization


OFFLINE
   |
   v
Local storage
+
Cached critical information
+
Pending operations
```

When connectivity returns:

```text
Local Operations
      |
      v
Sync Queue
      |
      v
Backend
      |
      v
Deduplication
      |
      v
Validation
      |
      v
Database
      |
      v
Events
      |
      v
Command Center
```

---

# 61. Data Storage Layers

The system effectively has several storage layers.

```text
                    STORAGE
                       |
       +---------------+---------------+
       |               |               |
       v               v               v
   PostgreSQL        Redis        Mobile Local DB
   + PostGIS
       |               |               |
       |               |               |
       v               v               v
Permanent          Temporary /      Offline
Operational        Event / Cache    Operations
State
```

### PostgreSQL + PostGIS

Stores:

```text
Users
Emergencies
Resources
Hospitals
Shelters
Roads
Zones
Assignments
Policies
Observations
Population records
Missing-person records
Audit records
```

### Redis

Used for:

```text
Caching
Queues
Events
WebSocket propagation
Temporary state
Background jobs
```

### Mobile Local DB

Used for:

```text
Offline emergency reports
Pending sync operations
Cached critical data
```

---

# 62. Data Update Pattern

The general update pattern is:

```text
SOURCE
  |
  v
API / INGESTION
  |
  v
VALIDATION
  |
  v
DATABASE TRANSACTION
  |
  v
EVENT CREATED
  |
  v
REDIS / EVENT BUS
  |
  +------------+-------------+
  |            |             |
  v            v             v
Decision     WebSocket    Notification
Engine
  |
  v
Recalculation
```

---

# 63. Example: One Road Update Through the Entire System

Initial:

```text
R12 = OPEN
```

Citizen reports blockage:

```text
Citizen
  |
  v
Flutter
  |
  v
Observation API
  |
  v
Validation
  |
  v
PostgreSQL
  |
  v
Observation stored
  |
  v
Confidence Layer
  |
  v
UNVERIFIED BLOCKED
```

Responder confirms:

```text
Responder
  |
  v
Observation API
  |
  v
Validation
  |
  v
PostgreSQL
  |
  v
VERIFIED BLOCKED
  |
  v
ROAD_STATUS_CHANGED
  |
  +------------+-------------+
  |            |             |
  v            v             v
Routing     Replanning    Command Center
  |            |             |
  v            v             v
New Route   Proposal       Map Update
```

This demonstrates how one field observation propagates through the entire
platform.

---

# 64. What the Command Center Actually Sees

The command center is not the source of all information.

It is the place where information from different sources is consolidated.

```text
                  COMMAND CENTER
                        |
      +-----------------+------------------+
      |                 |                  |
      v                 v                  v
 Situational        Resource           Geographic
 Awareness          Management         Awareness
      |                 |                  |
      v                 v                  v
 Emergencies        Hospitals          Roads
 Population         Shelters            Zones
 Missing Persons    Responders          Routes
 Alerts             Fire Teams          Evacuation
```

The coordinator sees a unified operational picture.

---

# 65. The Main Principle

The system should always distinguish:

```text
WHAT WE KNOW
```

from:

```text
WHAT WAS REPORTED
```

and:

```text
WHAT THE SYSTEM RECOMMENDS
```

and:

```text
WHAT A HUMAN HAS APPROVED
```

Therefore:

```text
Observed
   |
   v
Verified
   |
   v
Understood
   |
   v
Recommended
   |
   v
Approved
   |
   v
Executed
```

These are different states.

---

# 66. Final End-to-End Flow

```text
                         DATA SOURCES
                              |
      +-----------------------+-----------------------+
      |                       |                       |
      v                       v                       v
 Government              Facilities             Geographic
 Authorities             Hospitals              GIS / OSM
 Disaster Sources        Fire Stations
                         Shelters
                              |
                              v
                       DATA INGESTION
                              |
                              v
                     VALIDATE + NORMALIZE
                              |
                              v
                      MASTER DATA STORE
                              |
                              v
                    OPERATIONAL DATABASE
                              ^
                              |
                  +-----------+-----------+
                  |                       |
                  |                       |
             LIVE UPDATES            FIELD REPORTS
                  |                       |
          +-------+-------+       +-------+-------+
          |       |       |       |       |       |
          v       v       v       v       v       v
       Hospital Shelter Resource Citizen Responder Authority
                              |
                              v
                        EVENT LAYER
                              |
                 +------------+------------+
                 |                         |
                 v                         v
          DECISION ENGINE             COMMAND CENTER
                 |                         |
        +--------+--------+                |
        |        |        |                |
        v        v        v                |
     Priority Resource Routing              |
              Matching                     |
                 |                         |
                 v                         |
             Replanning <------------------+
                 |
                 v
          LangGraph Agents
                 |
                 v
        Human Approval Layer
                 |
                 v
          Operational Action
                 |
                 v
       Citizens / Responders
                 |
                 v
          FIELD OBSERVATION
                 |
                 +----------------------+
                                        |
                                        v
                                DATABASE UPDATE
                                        |
                                        v
                                  SYSTEM REACTS
```

---

# 67. One-Sentence Explanation for Judges

> **Our platform maintains relatively stable disaster-resource information as master data, continuously updates changing operational state through authorized facilities, responders, authorities, citizens and external feeds, stores these updates with provenance and timestamps, and feeds the resulting operational picture into deterministic decision engines and agentic workflows for prioritization, resource allocation, routing and replanning, with humans approving consequential actions.**

---

# 68. What Makes This Different From a Normal Emergency App

A normal application might do:

```text
Citizen
   |
   v
Report Emergency
   |
   v
Database
```

Our platform does:

```text
Citizen / Authority / Responder
            |
            v
       Data Collection
            |
            v
      Validation + Evidence
            |
            v
       Unified Data Store
            |
            v
      Situational Awareness
            |
            v
   Person-Centric Prioritization
            |
            v
       Resource Matching
            |
            v
          Routing
            |
            v
       Human Approval
            |
            v
         Assignment
            |
            v
       Field Response
            |
            v
       New Observation
            |
            v
       Dynamic Replanning
            |
            v
       Continuous Loop
```

The core idea is therefore:

> **The platform is not merely collecting emergency reports. It continuously maintains and updates a shared operational picture of the disaster and uses that changing picture to coordinate the response.**

```

### The key thing to emphasize in your demo

The **database is not just a storage box**. The important flow is:

**Source → Ingest → Validate → Store → Event → Understand → Decide → Human Approval → Action → New Field Data → Update → Replan.**

For your Vijayawada demonstration, you can make this particularly visual: start with the **master registry** containing hospitals, fire stations, shelters, roads and resources; then inject a flood, citizen SOS, hospital capacity change and blocked-road report. The judges can literally watch the same data propagate through the system and change the recommended response.

The official Vijayawada municipal portal does expose a GIS map, while NDMA's SACHET platform demonstrates the kind of authoritative, geo-targeted disaster-alert source your architecture can consume. :contentReference[oaicite:0]{index=0}
```
