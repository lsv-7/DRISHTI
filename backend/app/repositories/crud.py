import uuid
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from app.models.domain import (
    User, VulnerabilityProfile, Emergency, Resource, Assignment,
    Road, Shelter, ShelterRegistration, DisasterZone, DisasterZonePolicy,
    PopulationAccountingRecord, MissingPerson, SituationObservation, Simulation, Notification,
    UserRole, PriorityLevel, EmergencyStatus, ResourceStatus, AccountingStatus
)
from app.schemas.domain import (
    UserCreate, EmergencyCreate, ResourceCreate, DisasterZoneCreate,
    DisasterZonePolicyCreate, MissingPersonCreate, SimulationCreate
)
from app.decision_engine.priority import calculate_priority_score
from app.decision_engine.vulnerability import calculate_vulnerability_score
from app.decision_engine.policy_engine import resolve_disaster_zone
from app.decision_engine.population_accounting import calculate_population_gap


# --- USER & VULNERABILITY REPOSITORY ---
def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, user_in: UserCreate, user_id: Optional[str] = None) -> User:
    uid = user_id or f"usr_{uuid.uuid4().hex[:12]}"
    user = User(
        id=uid,
        email=user_in.email,
        full_name=user_in.full_name,
        role=UserRole(user_in.role) if user_in.role in UserRole.__members__ else UserRole.CITIZEN,
        phone=user_in.phone,
        hashed_password=user_in.password # In production, hash password
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def get_or_create_vulnerability_profile(db: Session, user_id: str) -> VulnerabilityProfile:
    profile = db.query(VulnerabilityProfile).filter(VulnerabilityProfile.user_id == user_id).first()
    if not profile:
        profile = VulnerabilityProfile(
            id=f"vuln_{uuid.uuid4().hex[:12]}",
            user_id=user_id,
            age_group="ADULT",
            can_swim=True,
            mobility_status="FULL",
            medical_conditions=[],
            vulnerability_score=0.0
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


def update_vulnerability_profile(db: Session, user_id: str, data: Dict[str, Any]) -> VulnerabilityProfile:
    profile = get_or_create_vulnerability_profile(db, user_id)
    for key, val in data.items():
        if hasattr(profile, key) and val is not None:
            setattr(profile, key, val)

    p_dict = {
        "age": profile.age,
        "age_group": profile.age_group,
        "can_swim": profile.can_swim,
        "mobility_status": profile.mobility_status,
        "medical_conditions": profile.medical_conditions,
        "disability_notes": profile.disability_notes,
    }
    v_score, _, _ = calculate_vulnerability_score(p_dict)
    profile.vulnerability_score = v_score
    db.commit()
    db.refresh(profile)
    return profile


# --- DISASTER ZONE & POLICY REPOSITORY ---
def create_disaster_zone(db: Session, zone_in: DisasterZoneCreate) -> DisasterZone:
    zone = DisasterZone(
        id=f"zone_{uuid.uuid4().hex[:12]}",
        name=zone_in.name,
        code=zone_in.code,
        disaster_type=zone_in.disaster_type,
        geometry_geojson=zone_in.geometry_geojson,
        expected_population=zone_in.expected_population,
        is_active=zone_in.is_active
    )
    db.add(zone)
    db.commit()
    db.refresh(zone)

    # Auto-initialize population accounting record
    gap, gap_pct, status, _ = calculate_population_gap(zone_in.expected_population, 0)
    acc = PopulationAccountingRecord(
        id=f"pop_{uuid.uuid4().hex[:12]}",
        zone_id=zone.id,
        expected_population=zone_in.expected_population,
        accounted_population=0,
        gap_count=gap,
        gap_percentage=gap_pct,
        status=AccountingStatus(status)
    )
    db.add(acc)
    db.commit()
    return zone


def get_all_disaster_zones(db: Session) -> List[DisasterZone]:
    return db.query(DisasterZone).filter(DisasterZone.is_active == True).all()


def create_disaster_zone_policy(db: Session, policy_in: DisasterZonePolicyCreate) -> DisasterZonePolicy:
    policy = DisasterZonePolicy(
        id=f"pol_{uuid.uuid4().hex[:12]}",
        zone_id=policy_in.zone_id,
        title=policy_in.title,
        description=policy_in.description,
        category=policy_in.category,
        policy_type=policy_in.policy_type,
        reconstruction_norm=policy_in.reconstruction_norm,
        role_target=policy_in.role_target,
        source=policy_in.source,
        effective_date=policy_in.effective_date
    )
    db.add(policy)
    db.commit()
    db.refresh(policy)
    return policy


def get_policies_for_zone(db: Session, zone_id: str) -> List[DisasterZonePolicy]:
    return db.query(DisasterZonePolicy).filter(DisasterZonePolicy.zone_id == zone_id).all()


# --- EMERGENCY REPOSITORY ---
def create_emergency(db: Session, e_in: EmergencyCreate, user_id: Optional[str] = None) -> Emergency:
    # Check idempotency key if provided
    if e_in.idempotency_key:
        existing = db.query(Emergency).filter(Emergency.idempotency_key == e_in.idempotency_key).first()
        if existing:
            return existing

    # Resolve disaster zone
    zones = [
        {"id": z.id, "name": z.name, "geometry_geojson": z.geometry_geojson, "is_active": z.is_active}
        for z in db.query(DisasterZone).filter(DisasterZone.is_active == True).all()
    ]
    resolved_zone = resolve_disaster_zone(e_in.latitude, e_in.longitude, zones)
    zone_id = resolved_zone["id"] if resolved_zone else None

    # Calculate Priority & Vulnerability
    v_dict = e_in.vulnerability_snapshot.model_dump() if e_in.vulnerability_snapshot else None
    priority_score, priority_level, priority_reasons, v_score, v_factors = calculate_priority_score(
        category=e_in.category,
        affected_count=e_in.affected_count,
        vulnerability_snapshot=v_dict
    )

    emergency = Emergency(
        id=f"emg_{uuid.uuid4().hex[:12]}",
        user_id=user_id,
        zone_id=zone_id,
        title=e_in.title,
        description=e_in.description,
        category=e_in.category,
        latitude=e_in.latitude,
        longitude=e_in.longitude,
        status=EmergencyStatus.PENDING,
        priority_score=priority_score,
        priority_level=PriorityLevel(priority_level),
        priority_reasons=priority_reasons,
        vulnerability_score=v_score,
        vulnerability_factors=v_factors,
        affected_count=e_in.affected_count,
        idempotency_key=e_in.idempotency_key
    )
    db.add(emergency)
    db.commit()
    db.refresh(emergency)
    return emergency


def get_all_emergencies(db: Session) -> List[Emergency]:
    return db.query(Emergency).order_by(Emergency.priority_score.desc()).all()


def get_emergency_by_id(db: Session, emergency_id: str) -> Optional[Emergency]:
    return db.query(Emergency).filter(Emergency.id == emergency_id).first()


# --- RESOURCE REPOSITORY ---
def create_resource(db: Session, r_in: ResourceCreate) -> Resource:
    resource = Resource(
        id=f"res_{uuid.uuid4().hex[:12]}",
        name=r_in.name,
        resource_type=r_in.resource_type,
        capacity=r_in.capacity,
        latitude=r_in.latitude,
        longitude=r_in.longitude,
        capabilities=r_in.capabilities,
        contact_info=r_in.contact_info
    )
    db.add(resource)
    db.commit()
    db.refresh(resource)
    return resource


def get_all_resources(db: Session) -> List[Resource]:
    return db.query(Resource).all()


def allocate_resource_to_emergency(db: Session, resource_id: str, emergency_id: str) -> Dict[str, Any]:
    emergency = db.query(Emergency).filter(Emergency.id == emergency_id).first()
    resource = db.query(Resource).filter(Resource.id == resource_id).first()
    if not emergency or not resource:
        return {"status": "ERROR", "message": "Emergency or Resource not found"}

    emergency.status = EmergencyStatus.ASSIGNED
    if resource.current_load < resource.capacity:
        resource.current_load += 1
    resource.status = ResourceStatus.DISPATCHED

    assignment = Assignment(
        id=f"asg_{uuid.uuid4().hex[:12]}",
        emergency_id=emergency_id,
        resource_id=resource_id,
        status="ACTIVE",
        eta_minutes=12.5
    )
    db.add(assignment)
    db.commit()
    db.refresh(assignment)
    db.refresh(emergency)
    db.refresh(resource)

    return {
        "status": "SUCCESS",
        "message": f"Resource '{resource.name}' successfully allocated to incident '{emergency.title}'",
        "assignment_id": assignment.id,
        "emergency_id": emergency.id,
        "resource_id": resource.id,
        "emergency_status": emergency.status.value,
        "resource_status": resource.status.value,
        "current_load": resource.current_load
    }


def get_all_assignments(db: Session) -> List[Assignment]:
    return db.query(Assignment).all()


# --- POPULATION & MISSING PERSON REPOSITORY ---
def get_population_accounting(db: Session) -> List[PopulationAccountingRecord]:
    return db.query(PopulationAccountingRecord).all()


def create_missing_person(db: Session, m_in: MissingPersonCreate) -> MissingPerson:
    mp = MissingPerson(
        id=f"mp_{uuid.uuid4().hex[:12]}",
        full_name=m_in.full_name,
        age=m_in.age,
        gender=m_in.gender,
        last_known_location_lat=m_in.last_known_location_lat,
        last_known_location_lon=m_in.last_known_location_lon,
        zone_id=m_in.zone_id,
        reporter_contact=m_in.reporter_contact,
        photo_url=m_in.photo_url,
        human_confirmed=False
    )
    db.add(mp)
    db.commit()
    db.refresh(mp)
    return mp


def get_missing_persons(db: Session, include_unconfirmed: bool = False) -> List[MissingPerson]:
    if include_unconfirmed:
        return db.query(MissingPerson).all()
    return db.query(MissingPerson).filter(MissingPerson.human_confirmed == True).all()
