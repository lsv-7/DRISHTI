from sqlalchemy.orm import Session
from app.repositories import crud
from app.schemas.domain import (
    UserCreate, DisasterZoneCreate, DisasterZonePolicyCreate,
    ResourceCreate, EmergencyCreate, VulnerabilityProfileBase
)
from app.models.domain import UserRole, PolicyType


def seed_database(db: Session):
    """
    Seeds comprehensive Vijayawada flood response demo data (Section 26).
    """
    print("🌱 Seeding Vijayawada flood response demo data...")

    # 1. Seed Users (Citizen, Responder, Coordinator, Admin)
    citizen_user = crud.get_user_by_email(db, "elderly.citizen@example.com")
    if not citizen_user:
        citizen_user = crud.create_user(
            db,
            UserCreate(
                email="elderly.citizen@example.com",
                full_name="Eleanor Vance (Vijayawada Citizen)",
                role="CITIZEN",
                phone="+91-98765-43210"
            )
        )
        crud.update_vulnerability_profile(
            db,
            citizen_user.id,
            {
                "age": 74,
                "age_group": "ELDERLY",
                "can_swim": False,
                "mobility_status": "WHEELCHAIR",
                "medical_conditions": ["ASTHMA", "HYPERTENSION"],
                "disability_notes": "Requires wheelchair accessibility for evacuation."
            }
        )

    coordinator_user = crud.get_user_by_email(db, "coordinator@vijayawada.gov")
    if not coordinator_user:
        crud.create_user(
            db,
            UserCreate(
                email="coordinator@vijayawada.gov",
                full_name="Commander Mark Vance (Vijayawada Coordinator)",
                role="COORDINATOR",
                phone="+91-98765-00000"
            )
        )

    # 2. Seed Vijayawada Disaster Zone
    existing_zones = crud.get_all_disaster_zones(db)
    zone_a = None
    if not existing_zones:
        zone_a = crud.create_disaster_zone(
            db,
            DisasterZoneCreate(
                name="DEMO: Krishna River Flood Basin Sector A (Vijayawada)",
                code="ZONE_VJ_FLOOD_01",
                disaster_type="FLOOD",
                expected_population=2500,
                is_active=True,
                geometry_geojson={
                    "type": "Polygon",
                    "coordinates": [[
                        [80.6200, 16.4800],
                        [80.6800, 16.4800],
                        [80.6800, 16.5200],
                        [80.6200, 16.5200],
                        [80.6200, 16.4800]
                    ]]
                }
            )
        )
    else:
        zone_a = existing_zones[0]

    # 3. Seed Zone Policies & Reconstruction Norms
    if zone_a and not crud.get_policies_for_zone(db, zone_a.id):
        crud.create_disaster_zone_policy(
            db,
            DisasterZonePolicyCreate(
                zone_id=zone_a.id,
                title="Prakasam Barrage Evacuation Corridor Directive",
                description="All citizens in Sector A must use Eluru Road Alternate Bypass (R20). Prakasam Barrage main road R12 is restricted.",
                category="EVACUATION",
                policy_type="LEGAL_REQUIREMENT",
                reconstruction_norm=False,
                role_target="CITIZEN",
                source="Andhra Pradesh Disaster Management Authority (APDMA) Sec 34"
            )
        )

        crud.create_disaster_zone_policy(
            db,
            DisasterZonePolicyCreate(
                zone_id=zone_a.id,
                title="Reconstruction Norm: Krishna Basin Stormwater Retention Mandate",
                description="Post-disaster building reconstruction requires minimum 20% permeable ground retention space and rainwater harvesting pits.",
                category="RECONSTRUCTION",
                policy_type="OFFICIAL_POLICY",
                reconstruction_norm=True,
                role_target="COORDINATOR",
                source="State Flood Mitigation & Urban Resilience Code 2025"
            )
        )

    # 4. Seed Vijayawada Resources (R01, R02)
    existing_resources = crud.get_all_resources(db)
    if not existing_resources:
        crud.create_resource(
            db,
            ResourceCreate(
                name="R01: NDRF Vijayawada Rescue Team",
                resource_type="RESCUE_TEAM",
                capacity=6,
                latitude=16.5050,
                longitude=80.6420,
                capabilities=["RESCUE", "MEDICAL", "WHEELCHAIR_ACCESSIBLE"],
                contact_info="NDRF Squad 4: +91-98765-11111"
            )
        )
        crud.create_resource(
            db,
            ResourceCreate(
                name="R02: Krishna River Water Rescue Boat Team",
                resource_type="BOAT_TEAM",
                capacity=10,
                latitude=16.5080,
                longitude=80.6460,
                capabilities=["WATER_RESCUE", "SHALLOW_NAV", "WHEELCHAIR_ACCESSIBLE"],
                contact_info="Krishna Boat Unit: +91-98765-22222"
            )
        )

    # 5. Seed E101 & E102 Vijayawada Demo Emergencies (Section 26)
    existing_emergencies = crud.get_all_emergencies(db)
    if not existing_emergencies and citizen_user:
        crud.create_emergency(
            db,
            EmergencyCreate(
                title="E101: Elderly Citizen Trapped in Vijayawada Flood Water",
                description="Water level reaching 4 feet inside house. Elderly resident cannot swim and uses a wheelchair.",
                category="MEDICAL_RESCUE",
                latitude=16.5062,
                longitude=80.6480,
                affected_count=4,
                vulnerability_snapshot=VulnerabilityProfileBase(
                    age=74,
                    age_group="ELDERLY",
                    can_swim=False,
                    mobility_status="WHEELCHAIR",
                    medical_conditions=["ASTHMA", "HYPERTENSION"],
                    disability_notes="Requires wheelchair assistance."
                )
            ),
            user_id=citizen_user.id
        )

        crud.create_emergency(
            db,
            EmergencyCreate(
                title="E102: Low-Lying Ward Residential Flood Rescue Request",
                description="8 residents stranded on rooftop near Prakasam Barrage. Rapid current.",
                category="RESCUE",
                latitude=16.5100,
                longitude=80.6500,
                affected_count=8,
                vulnerability_snapshot=VulnerabilityProfileBase(
                    age=35,
                    age_group="ADULT",
                    can_swim=True,
                    mobility_status="FULL"
                )
            ),
            user_id=citizen_user.id
        )

    print("✅ Vijayawada seed data successfully created.")
