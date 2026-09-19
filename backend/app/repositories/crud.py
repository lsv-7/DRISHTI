import uuid
import threading
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from app.models.domain import (
    User, VulnerabilityProfile, Emergency, Resource, Assignment,
    Road, Shelter, ShelterRegistration, DisasterZone, DisasterZonePolicy,
    PopulationAccountingRecord, MissingPerson, SituationObservation, Simulation, Notification,
    UserRole, PriorityLevel, EmergencyStatus, ResourceStatus, AccountingStatus
)
from app.schemas.domain import (
    UserCreate, EmergencyCreate, ResourceCreate, DisasterZoneCreate,
    DisasterZonePolicyCreate, MissingPersonCreate, SimulationCreate,
    CitizenProfileUpdate
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


def get_citizen_profile(db: Session, user_id: str) -> Optional[User]:
    return get_user_by_id(db, user_id)


def update_citizen_profile(db: Session, user_id: str, profile_in: CitizenProfileUpdate) -> User:
    user = get_user_by_id(db, user_id)
    if not user:
        user = User(
            id=user_id,
            email=profile_in.email,
            full_name=profile_in.full_name,
            phone=profile_in.phone,
            gender=profile_in.gender,
            address=profile_in.address,
            city=profile_in.city,
            emergency_contact_name=profile_in.emergency_contact_name,
            emergency_contact_phone=profile_in.emergency_contact_phone,
            role=UserRole.CITIZEN
        )
        db.add(user)
    else:
        user.full_name = profile_in.full_name
        user.phone = profile_in.phone
        if profile_in.email is not None:
            user.email = profile_in.email
        if profile_in.gender is not None:
            user.gender = profile_in.gender
        if profile_in.address is not None:
            user.address = profile_in.address
        if profile_in.city is not None:
            user.city = profile_in.city
        if profile_in.emergency_contact_name is not None:
            user.emergency_contact_name = profile_in.emergency_contact_name
        if profile_in.emergency_contact_phone is not None:
            user.emergency_contact_phone = profile_in.emergency_contact_phone

    db.commit()
    db.refresh(user)
    return user


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


class IdempotencyConflictError(Exception):
    """Raised when an emergency creation is attempted with an existing idempotency key but differing payload attributes."""
    pass


def _is_payload_equivalent(existing: Emergency, e_in: EmergencyCreate) -> bool:
    """Verifies whether incoming payload is functionally identical to the existing record."""
    if existing.category != e_in.category:
        return False
    if existing.title.strip().lower() != e_in.title.strip().lower():
        return False
    if abs(existing.latitude - e_in.latitude) > 1e-4:
        return False
    if abs(existing.longitude - e_in.longitude) > 1e-4:
        return False
    if existing.affected_count != e_in.affected_count:
        return False
    existing_desc = (existing.description or "").strip()
    incoming_desc = (e_in.description or "").strip()
    if existing_desc != incoming_desc:
        return False
    # Check vulnerability snapshot if provided
    if e_in.vulnerability_snapshot is not None and existing.vulnerability_snapshot is not None:
        v_in = e_in.vulnerability_snapshot.model_dump()
        for field in ("age_group", "mobility_status", "can_swim", "medical_conditions"):
            if v_in.get(field) != existing.vulnerability_snapshot.get(field):
                return False
    elif (e_in.vulnerability_snapshot is not None) != (existing.vulnerability_snapshot is not None):
        return False

    return True


_emergency_creation_lock = threading.Lock()


# --- EMERGENCY REPOSITORY ---
def create_emergency(db: Session, e_in: EmergencyCreate, user_id: Optional[str] = None) -> Emergency:
    with _emergency_creation_lock:
        # 1. Check idempotency key if provided
        if e_in.idempotency_key:
            existing = db.query(Emergency).filter(Emergency.idempotency_key == e_in.idempotency_key).first()
            if existing:
                if not _is_payload_equivalent(existing, e_in):
                    raise IdempotencyConflictError(
                        f"Idempotency key conflict: key '{e_in.idempotency_key}' is already associated with an emergency with different attributes."
                    )
                existing._is_new = False
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
            vulnerability_snapshot=v_dict,
            affected_count=e_in.affected_count,
            idempotency_key=e_in.idempotency_key,
            reporter_name=e_in.reporter_name,
            contact_phone=e_in.contact_phone
        )

        try:
            db.add(emergency)
            db.commit()
            db.refresh(emergency)
            emergency._is_new = True
            return emergency
        except Exception:
            db.rollback()
            if e_in.idempotency_key:
                existing = db.query(Emergency).filter(Emergency.idempotency_key == e_in.idempotency_key).first()
                if existing:
                    if not _is_payload_equivalent(existing, e_in):
                        raise IdempotencyConflictError(
                            f"Idempotency key conflict: key '{e_in.idempotency_key}' is already associated with an emergency with different attributes."
                        )
                    existing._is_new = False
                    return existing
            raise


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
