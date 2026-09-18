# Intelligent Disaster Response & Relief Coordination

## 1. Project Identity

**Project:** Intelligent Disaster Response & Relief Coordination  
**Primary scenario for MVP:** Urban flood/disaster response  
**Application type:** Multi-platform disaster-response coordination system  
**Primary users:** Citizens, responders/rescue teams, hospitals/medical teams, shelters, relief coordinators, authorities/command-center operators.

The application is designed around a single guiding principle:

> A disaster-response system must not stop at collecting emergency reports. It must continuously convert changing disaster information into coordinated, explainable, and privacy-conscious action — adapted to the specific vulnerabilities of every individual it serves.

---

## 2. Problem

During a disaster such as a flood, the difficulty is not only identifying that people need help. The response environment changes continuously:

- Citizens may have unstable or unavailable internet connectivity.
- Many emergency requests may arrive simultaneously.
- Not every emergency has the same severity or urgency.
- Not every person faces the same risk — age, gender, disability, and behavioral traits (e.g., ability to swim) determine how dangerous the same disaster is for each individual.
- Rescue, medical, transport, shelter and relief resources are limited.
- The closest resource is not necessarily the correct resource.
- Roads and routes can become blocked after an assignment has already been made.
- Resource availability can change while operations are in progress.
- Citizen reports can conflict or become stale.
- Authorities may lack knowledge of local disaster management laws and policies specific to the affected zone.
- After a disaster, population accounting becomes unreliable — people at shelters may not be registered, and people who are missing may not be reported immediately.
- Long-term recovery and future disaster prevention require adherence to reconstruction norms (e.g., water harvesting mandates for new buildings) that are often ignored or unknown.
- Authorities need to understand the current situation before making decisions.
- Authorities may want to test a response plan under hypothetical worsening conditions without disturbing the live operation.
- Different organizations and responders need a shared operational view.

The core problem is therefore **coordination under uncertainty and changing conditions — tailored to individual vulnerability, grounded in local policy, and extended into prevention.**

---

## 3. Problem → Solution Mapping

| Disaster problem | System response |
|---|---|
| Internet unavailable/intermittent | Offline-first mobile reporting with local persistence and later synchronization |
| Too many emergency requests | Explainable priority engine |
| Different people face different risk levels | Vulnerability-aware priority scoring using age, gender, behavioral traits (e.g., swim ability), disability, and medical conditions |
| Limited heterogeneous resources | Capability-aware resource matching |
| Changing road conditions | Dynamic route recalculation and replanning |
| Resource becomes unavailable | Reallocation/replanning |
| Conflicting reports | Confidence-aware situational truth layer |
| Authorities need scenario planning | What-If disaster simulator |
| Authorities lack local disaster law knowledge | Disaster zone policy engine delivering jurisdiction-specific rules and mandates |
| People missing after disaster | Automated missing-person inference from population count vs. shelter registration, plus manual reporting and matching |
| Future disaster prevention ignored | Reconstruction compliance advisor surfacing policy norms (e.g., water harvesting mandates for new buildings) |
| Constantly changing information | Event-driven/agent-assisted coordination workflow |
| Citizens need status | Emergency tracking and notifications |
| Responders need actionable work | Assigned incidents, route/location, priority and status |
| Command center lacks unified visibility | React-based command-center dashboard |
| Need intelligent assistance | LangGraph-based agent orchestration with deterministic decision engines |

---

## 4. Core Product Goal

Build an operational coordination layer connecting:

**Citizens → Emergencies → Decision Engine → Resources → Responders → Authorities**

while continuously adapting to:

**new emergencies + connectivity changes + road changes + resource changes + situational uncertainty + individual vulnerability profiles + local disaster policy.**

---

## 5. Key Additions to Base Architecture

### 5.1 Vulnerability-Aware Priority

Emergency priority is not uniform. The same flood affects a 70-year-old non-swimmer differently than a 25-year-old trained swimmer. The priority engine must accept and apply individual vulnerability factors including:

- Age group (child, elderly, adult)
- Gender (for context-specific risks)
- Behavioral traits (can swim / cannot swim, physical fitness level, mobility impairment)
- Medical conditions relevant to the disaster type
- Disability status

These factors adjust the priority score so that the most vulnerable receive faster, more appropriate responses. This is a configurable product heuristic and must not be described as a medically validated triage protocol.

**User profile collection:** During onboarding, the citizen app collects basic vulnerability traits. Users may update these. Vulnerability data is handled with privacy protections (minimal disclosure, purpose-limited use, no unnecessary exposure).

### 5.2 Disaster Zone Policy Engine

Different geographic disaster zones operate under different government-mandated rules and policies. For example:

- Flood-prone areas may have mandatory evacuation corridors.
- Cyclone zones may have designated shelter categories.
- Earthquake-prone zones may have specific search-and-rescue protocols.
- Coastal areas may have fishermen evacuation norms.
- Urban zones may have specific crowd-management policies during emergencies.

When a citizen's location is determined, the system identifies the applicable disaster zone and surfaces relevant policies and legal mandates to:

- Authorities and coordinators (full policy view)
- Responders (operational rules relevant to their assignment)
- Citizens (relevant safety mandates they must follow)

Policy data is stored as structured records linked to geographic zones. Updates to policies are made by administrators. The system does not interpret or adjudicate legal compliance — it surfaces known policy information as a decision aid.

### 5.3 Automated Missing-Person Inference

After a disaster, families are separated and official missing-person reports may lag the actual situation by hours. The system addresses this in two ways:

**Manual reporting (existing):** Authorities or families register missing-person reports. Shelters log individuals who arrive. The system matches reports to shelter records.

**Population-based automated inference (new):** Using pre-disaster population counts by geographic area (ward/zone level), the system compares expected population against registered individuals at shelters and relief centres. When the discrepancy exceeds a configurable threshold for a given zone, the system:

- Flags the zone as having potentially unaccounted individuals.
- Generates an automated alert for coordinators.
- Estimates the number of potentially missing persons.
- Does NOT automatically mark specific individuals as missing without human confirmation.

This inference is probabilistic and displayed with a confidence indicator. Human review is mandatory before any individual is officially listed as missing. Privacy is preserved — zone-level population gaps are surfaced, not personal identification.

### 5.4 Reconstruction & Prevention Policy Advisor

Disasters reveal structural vulnerabilities in built environments. Post-disaster reconstruction frequently ignores mandated prevention norms. The system includes a policy compliance advisory layer that:

- Surfaces government-mandated construction and land-use norms relevant to the affected zone (e.g., mandatory rainwater harvesting space in new buildings, floodplain setback requirements, building material standards in cyclone zones).
- Provides this information to coordinators and authorities during and after disaster response.
- Allows authorities to log reconstruction compliance advisories against specific affected locations.
- Does not enforce compliance — it makes the requirements visible and traceable.

This feature is scoped as an informational aid, not a legal enforcement tool.

---

## 6. MVP Scope

The MVP should focus on a realistic flood-response demonstration rather than attempting to implement every possible disaster-management feature.

### Must demonstrate

1. Citizen emergency creation with vulnerability profile.
2. Offline-first emergency creation.
3. Local queue when connectivity is unavailable.
4. Synchronization after connectivity returns.
5. Vulnerability-aware emergency prioritization.
6. Resource allocation.
7. Route/road awareness.
8. Dynamic replanning after a road/resource change.
9. Confidence-aware incident/road information.
10. What-If simulation.
11. Command-center visualization.
12. Responder assignment/status.
13. Agentic orchestration where agents call real system tools.
14. Human approval before consequential response-plan changes.
15. Disaster zone policy delivery to relevant users.
16. Population-gap missing-person inference (zone level, with human confirmation).

### Optional/secondary

- Missing-person image matching.
- Weather/sensor integration.
- Cloudinary media storage.
- Advanced notifications.
- Additional disaster types.
- Real external radio/LoRa hardware.
- Reconstruction compliance logging.

---

## 7. Important Transparency Constraints

### Radio

The MVP does **not** have physical LoRa/radio hardware.

Therefore, any radio capability must be described as:

**Software-based Radio Network Simulator / Simulated Radio Transport**

### Vulnerability scoring

Vulnerability scores are product heuristics based on configured weights. They are not medically validated triage scores and must not be presented as such.

### Missing-person inference

Population-gap inference is probabilistic. Zone-level discrepancy alerts require human confirmation before any individual is listed as missing.

### Policy data

Policy information is sourced from administrator-maintained records. The system surfaces policy; it does not provide legal advice.

---

## 8. Key Innovation Areas

### 8.1 Resilient communication

The mobile application should remain useful when connectivity is intermittent.

Connectivity states:

- ONLINE
- LOW/INTERMITTENT
- OFFLINE

The app stores important actions locally and synchronizes them when connectivity is restored.

### 8.2 Intelligent priority (vulnerability-aware)

Priority should consider configurable factors such as:

- severity
- number of people affected
- medical need
- vulnerable groups
- individual vulnerability traits (age, swim ability, disability, gender-specific risks)
- waiting time
- accessibility/location

The resulting score is a product decision heuristic, not a medically validated triage score.

### 8.3 Intelligent resource matching

Resources can include:

- rescue teams
- boat teams
- ambulances
- medical teams
- shelters
- relief supplies
- transport
- boats
- generators
- communication equipment
- volunteers
- animal rescue
- specialized equipment

Matching should consider:

- capability
- availability
- capacity
- location/distance
- route feasibility
- ETA
- emergency requirements
- individual vulnerability of those affected (e.g., prioritizing resources with medical capability for high-vulnerability profiles)

### 8.4 Dynamic replanning

When the live state changes:

1. Detect relevant change.
2. Identify affected assignments.
3. Recalculate routes.
4. Check alternative resources.
5. Generate revised recommendations.
6. Obtain human approval where required.
7. Apply the new plan.
8. Notify affected responders/users.
9. Continue monitoring.

### 8.5 Confidence-aware situational truth

The system should combine reports and display an operational confidence indicator.

Example:

```text
Road R12
Status: PARTIALLY BLOCKED
Confidence: 82%
4 corroborating reports
1 responder verification
Last updated: 8 minutes ago
```

The confidence value is a transparent heuristic based on factors such as source, corroboration, agreement, recency, proximity and verification.

### 8.6 What-If simulation

The simulator must operate on a copy of the live state.

Possible scenarios:

- block a road
- disable a resource
- increase emergency demand
- reduce shelter capacity
- increase flood severity
- disable internet connectivity
- add a high-vulnerability population cluster

The simulation produces an alternative plan without changing live state. Operators can then choose whether to apply the plan.

### 8.7 Disaster zone policy delivery

When a user's location maps to a recognized disaster zone, the system surfaces applicable policies. This occurs:

- Automatically when an emergency is registered from a known zone.
- On demand when a coordinator queries zone information.
- As part of the command-center zone information panel.

### 8.8 Population accounting and missing-person inference

Post-disaster population accounting is performed at the zone level:

- Pre-disaster population counts are stored per zone (sourced from official census or administrative data, maintained by administrators).
- As individuals register at shelters and relief centres, the zone's accounted population increases.
- When the gap between expected and accounted population exceeds a threshold, the zone is flagged.
- Coordinators receive an alert with the estimated unaccounted count.
- Coordinators initiate search-and-rescue or outreach for the flagged zone.

---

## 9. Success Criterion

The most important demonstration is the complete operational loop:

**Emergency occurs → report received (with vulnerability profile) → priority calculated (vulnerability-adjusted) → relevant disaster policies surfaced → resource allocated → disaster state changes → system replans → authority evaluates alternative → coordinated response continues → population accounting flags potential missing persons → coordinator acts.**
