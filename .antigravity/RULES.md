# Project Rules

These rules are mandatory for every AI coding agent working on this project.

## 1. Context Rules

Before changing code, read:

1. ProblemDescription.md
2. ExecutionFlow.md
3. WorkflowSolution.md
4. Tasks.md
5. TasksCompleted.md

If repository code contradicts documentation, inspect the code and task history before changing architecture.

Do not assume that an unfinished feature is implemented merely because it appears in the documentation.

---

## 2. Task Rules

### One task at a time

Work on the smallest coherent pending task.

Do not implement unrelated enhancements unless they are required for the current task.

### Completed work is protected

Do not rewrite completed modules without a concrete reason.

Before replacing existing code, identify:

- why it must change
- what depends on it
- what regression risk exists

### Task bookkeeping

After successful implementation:

- update `TasksCompleted.md`
- update `Tasks.md`
- record important architectural decisions
- record known limitations if applicable

---

## 3. Truthfulness Rules

Never claim:

- a feature is implemented when it is mocked
- a test passed when it was not run
- LoRa hardware exists when it does not
- an AI model is reliable for safety-critical decisions without validation
- a confidence score is a calibrated probability when it is only a heuristic
- a vulnerability score is a medically validated triage score when it is a configurable product heuristic
- population gap inference has identified a specific missing person when only a zone-level discrepancy has been detected
- policy information constitutes legal advice — it is an informational aid only

For the MVP radio feature, use:

> Software-based Radio Network Simulator

not:

> Real LoRa communication

For vulnerability scoring, use:

> Configurable vulnerability heuristic / vulnerability-adjusted priority

not:

> Medically validated triage

For population accounting, use:

> Zone-level population gap indicator (probabilistic)

not:

> Automated missing-person identification

---

## 4. AI Rules

The LLM must not independently make safety-critical emergency allocation decisions.

Use:

```text
LLM
→ orchestrate
→ interpret
→ summarize
→ explain

Deterministic engine
→ calculate
→ optimize
→ validate constraints
→ recommend

Human operator
→ approve consequential action
→ confirm missing-person records before public listing
→ review zone gap alerts before initiating searches
```

Agents must have real tools or service calls.

Do not create fake "agents" that only return hardcoded text.

---

## 5. Data Rules

All client-created entities that can be retried must have stable UUIDs.

All synchronization operations must be idempotent.

Do not duplicate emergency reports during reconnect/retry.

Use server timestamps for authoritative state where required.

Validate all user-controlled data on the backend.

---

## 6. Offline Rules

Offline mode must not pretend that server synchronization happened.

Use explicit states:

```text
LOCAL_PENDING
SYNCING
SYNCED
SYNC_FAILED
```

The UI must communicate the actual synchronization state.

When connectivity returns, retry safely.

---

## 7. Simulation Rules

The What-If simulator must never modify live operational state merely by running a simulation.

Use:

```text
live state
→ snapshot
→ modifications
→ simulation
→ comparison
→ apply/cancel
```

Only an explicit Apply action may modify live state.

---

## 8. Security Rules

Never hard-code:

- API keys
- database passwords
- JWT secrets
- OAuth secrets

Use environment variables/configuration.

Do not put private backend credentials into Flutter or React builds.

Validate authorization server-side.

Do not trust role information sent by the frontend.

---

## 9. API Rules

Use versioned API paths where appropriate:

```text
/api/v1/...
```

Use consistent response/error formats.

Return appropriate HTTP status codes.

Validate request schemas.

Do not expose internal stack traces to users.

---

## 10. Database Rules

Use migrations.

Do not manually modify production schemas without migration support.

Use indexes for common filtering/geospatial queries.

Use transactions when multiple related records must remain consistent.

Avoid storing derived values when they can become inconsistent unless there is a clear performance reason.

---

## 11. Geographic Rules

Coordinates must be stored consistently.

Use PostGIS for spatial queries when geographic computation is required.

Validate latitude and longitude.

Do not calculate operational distances using arbitrary string comparisons.

Zone boundaries must be stored as PostGIS polygon geometries and queried with ST_Contains or ST_Intersects.

---

## 12. Vulnerability Profile Rules

Vulnerability profiles contain sensitive personal data (age, disability, medical conditions).

- Store with appropriate access controls.
- Only expose to the citizen who owns the profile and to coordinators handling their active emergency.
- Do not log or expose vulnerability details in generic API responses.
- Use the vulnerability profile only for priority scoring and resource matching — not for other purposes.
- Vulnerability weights must remain configurable by administrators.
- The vulnerability score must be labeled clearly as a heuristic in all UI displays.

---

## 13. Policy Rules

Disaster zone policies are informational only.

- The system must not represent policy data as legal advice.
- Policies must be clearly sourced (reference to act/guideline where available).
- Only administrators may create or update policy records.
- Reconstruction norms must be clearly labeled as prevention guidelines, not enforcement.
- Policy delivery must be role-filtered (citizens only receive citizen-relevant policies, not internal coordination rules).

---

## 14. Population Accounting Rules

- Zone-level population gap data is available only to coordinators and administrators.
- The system must not automatically create individual missing-person records from gap inference.
- All zone gap alerts must require human coordinator review and action.
- Gap calculations must display confidence level and a note that inference is probabilistic.
- Pre-disaster population figures must be sourced from administrator-maintained census/administrative data, not estimated by the system.
- Shelter registration data must not be exposed publicly without appropriate consent/access controls.

---

## 15. Frontend Rules

Do not put complex disaster business logic into React/Flutter UI components.

Use:

```text
UI
→ state/controller
→ API/repository
→ backend/domain logic
```

Keep components focused.

Provide loading/error/empty/offline states.

---

## 16. UX Rules

Emergency reporting should require minimal interaction.

Critical operational information should be visible without navigating through many screens.

Use clear status labels.

Do not hide important uncertainty.

If data is stale, display the last-update time.

Vulnerability factor labels in the UI must be respectful and non-stigmatizing.

Zone gap alerts must always display the "human review required" notice alongside the discrepancy count.

Policy information in the citizen app must be in plain, accessible language.

---

## 17. Error Handling

Errors must be:

- logged appropriately
- translated into useful user-facing messages
- recoverable where possible

Do not use:

```python
except Exception:
    pass
```

unless there is a documented reason and the exception is genuinely non-critical.

---

## 18. Dependency Rules

Do not add dependencies merely because they are popular.

Before adding a package:

1. verify it solves a real requirement
2. check whether an existing dependency already solves it
3. use a maintained version
4. update dependency documentation where appropriate

---

## 19. Mock Data Rules

Mock/seed data is allowed for demonstrations.

However:

- clearly separate seed/demo data from production logic
- do not hard-code fake live operational responses into business logic
- use realistic entities and relationships
- make it easy to replace seeded data with real API data

Seed data must include:

- at least one zone with defined policies
- at least one zone with pre-disaster population count
- at least one citizen with a vulnerability profile
- at least one reconstruction norm policy

---

## 20. Logging Rules

Logs should help diagnose:

- synchronization
- assignment
- routing
- simulation
- agent execution
- API failures
- zone resolution
- population accounting computation

Do not log sensitive personal information (vulnerability profile details, individual shelter records) unnecessarily.

---

## 21. Testing Rules

At minimum, test:

- priority calculation (including vulnerability scoring)
- resource matching (including vulnerability-fit bonus)
- synchronization/idempotency
- simulation isolation
- status transitions
- authorization
- zone policy lookup (PostGIS)
- population gap calculation
- missing-person human-confirmation gate
- important API endpoints

Run the relevant test/build/type-check commands after implementation when available.

---

## 22. Documentation Rules

When architecture changes materially, update documentation.

Do not allow:

```text
documentation says A
code implements B
```

without documenting the reason.

---

## 23. Demo Rules

The primary demo should tell a story:

```text
Disaster
→ Vulnerable citizen reports emergency
→ Vulnerability-boosted priority calculated
→ Zone policies surfaced
→ Vulnerability-fit resource allocated
→ Road/resource failure
→ Dynamic replanning (vulnerability order preserved)
→ Population gap alert generated
→ Coordinator reviews and acts
→ What-If scenario
→ Reconstruction norms surfaced
→ Coordinated response
```

Do not spend most of the demo on login screens, CRUD tables or configuration pages.

---

## 24. Scope Control

For the MVP, prefer a small working vertical slice over many incomplete modules.

If time is limited:

```text
Core workflow > optional AI feature
Vulnerability-aware priority > generic AI chatbot
Working simulation > elaborate animations
Correct synchronization > cosmetic features
Explainable allocation > vague "AI decisions"
Zone policy delivery > full policy management UI
Population gap alert > individual missing-person image matching
```

---

## 25. Final Rule

Every implementation decision should answer:

> Does this make disaster response more resilient, coordinated, explainable, adaptive — and more equitable for vulnerable people?

If not, question whether it belongs in the MVP.
