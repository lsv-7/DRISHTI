# Vijayawada Geographic Dataset & Offline Layer

This directory contains the local geographic dataset for the **Intelligent Disaster Response & Relief Coordination System** centered on Vijayawada, Andhra Pradesh (`16.5062`, `80.6480`).

---

## Directory Contents & Data Sources

1. **`boundary/Vijayawada_Boundary.geojson`**:
   - Official municipal boundary polygon for Vijayawada (NTR District, Andhra Pradesh).
   - Source: Open Administrative Boundaries / India Geodata repository.

2. **`wards/Vijayawada_Wards.geojson`**:
   - Administrative wards for Vijayawada.
   - Label: `Vijayawada Administrative Wards — Demo Dataset` (for hackathon operational demo).

3. **`roads/roads.geojson`**:
   - OSM Road Network extract covering Vijayawada arterial routes (Prakasam Barrage Corridor R12, MG Road R14, Eluru Bypass R20).
   - Source: OpenStreetMap (OSM) extract via BBBike.

4. **`shelters/shelters.geojson`**:
   - Emergency relief shelters with capacity metrics (`S01`, `S02`).
   - Labeled: `DEMO: Vijayawada Municipal Indoor Relief Shelter`.

5. **`hospitals/hospitals.geojson`**:
   - Hospitals with emergency bed & ICU availability (`H01` Vijayawada GGH, `H02` Ramesh Hospital).
   - Labeled: `DEMO Operational Data`.

6. **`disaster-zones/disaster-zones.geojson`**:
   - Simulated Krishna River Flood Basin sectors (`ZONE_VJ_FLOOD_01`).
   - Labeled: `DEMO: Krishna River Flood Basin Sector A`.

7. **`evacuation/evacuation-routes.geojson`**:
   - Primary evacuation corridors from flooded Krishna basin wards to indoor relief shelters.

---

## Licensing & Offline Notice

- OpenStreetMap data © OpenStreetMap contributors under ODbL.
- All operational capacity values and flood boundary extents are clearly marked as **DEMO DATA** for hackathon simulation purposes.
- This dataset is loaded locally by Leaflet and FastAPI services to ensure 100% offline capability during network disruptions.
