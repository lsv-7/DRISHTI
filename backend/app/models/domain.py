import enum
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Enum as SQLEnum, JSON, Text
)
from sqlalchemy.orm import relationship
from app.core.database import Base


class UserRole(str, enum.Enum):
    CITIZEN = "CITIZEN"
    RESPONDER = "RESPONDER"
    COORDINATOR = "COORDINATOR"
    ADMIN = "ADMIN"
    MEDICAL = "MEDICAL"
    SHELTER_MANAGER = "SHELTER_MANAGER"


class EmergencyStatus(str, enum.Enum):
    PENDING = "PENDING"
    ASSIGNED = "ASSIGNED"
    IN_PROGRESS = "IN_PROGRESS"
    RESOLVED = "RESOLVED"
    CANCELLED = "CANCELLED"


class PriorityLevel(str, enum.Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class ResourceStatus(str, enum.Enum):
    AVAILABLE = "AVAILABLE"
    DISPATCHED = "DISPATCHED"
    MAINTENANCE = "MAINTENANCE"
    UNAVAILABLE = "UNAVAILABLE"


class PolicyType(str, enum.Enum):
    LEGAL_REQUIREMENT = "LEGAL_REQUIREMENT"
    OFFICIAL_POLICY = "OFFICIAL_POLICY"
    OFFICIAL_RECOMMENDATION = "OFFICIAL_RECOMMENDATION"
    EDUCATIONAL_GUIDANCE = "EDUCATIONAL_GUIDANCE"


class AccountingStatus(str, enum.Enum):
    NORMAL = "NORMAL"
    ATTENTION = "ATTENTION"
    CRITICAL = "CRITICAL"


class MissingPersonSource(str, enum.Enum):
    MANUAL = "MANUAL"
    INFERRED_ZONE_GAP = "INFERRED_ZONE_GAP"


class MissingPersonStatus(str, enum.Enum):
    UNACCOUNTED = "UNACCOUNTED"
    POTENTIAL_MISSING = "POTENTIAL_MISSING"
    UNDER_VERIFICATION = "UNDER_VERIFICATION"
    CONFIRMED_MISSING = "CONFIRMED_MISSING"
    FOUND = "FOUND"
    FOUND_AT_SHELTER = "FOUND_AT_SHELTER"
    FOUND_AT_HOSPITAL = "FOUND_AT_HOSPITAL"
    EVACUATED = "EVACUATED"
    FALSE_ALERT = "FALSE_ALERT"


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(SQLEnum(UserRole), default=UserRole.CITIZEN, nullable=False)
    phone = Column(String, nullable=True)
    hashed_password = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    vulnerability_profile = relationship("VulnerabilityProfile", back_populates="user", uselist=False)
    emergencies = relationship("Emergency", back_populates="user")


class VulnerabilityProfile(Base):
    __tablename__ = "vulnerability_profiles"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), unique=True, nullable=False)
    age = Column(Integer, nullable=True, default=30)
    age_group = Column(String, nullable=False, default="ADULT") # CHILD, ADULT, ELDERLY
    can_swim = Column(Boolean, default=True)
    mobility_status = Column(String, default="FULL") # FULL, LIMITED, WHEELCHAIR, BEDRIDDEN
    medical_conditions = Column(JSON, default=list) # e.g. ["ASTHMA", "DIABETES"]
    disability_notes = Column(Text, nullable=True)
    vulnerability_score = Column(Float, default=0.0)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="vulnerability_profile")


class DisasterZone(Base):
    __tablename__ = "disaster_zones"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    code = Column(String, unique=True, nullable=False)
    disaster_type = Column(String, default="FLOOD")
    geometry_geojson = Column(JSON, nullable=False) # Polygon geometry
    expected_population = Column(Integer, default=1000)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    policies = relationship("DisasterZonePolicy", back_populates="zone")
    accounting_records = relationship("PopulationAccountingRecord", back_populates="zone")


class DisasterZonePolicy(Base):
    __tablename__ = "disaster_zone_policies"

    id = Column(String, primary_key=True, index=True)
    zone_id = Column(String, ForeignKey("disaster_zones.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String, default="EVACUATION") # EVACUATION, SHELTER, RECONSTRUCTION, SAFETY
    policy_type = Column(SQLEnum(PolicyType), default=PolicyType.OFFICIAL_POLICY)
    reconstruction_norm = Column(Boolean, default=False)
    role_target = Column(String, default="ALL") # CITIZEN, RESPONDER, COORDINATOR, ALL
    source = Column(String, nullable=True)
    effective_date = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    zone = relationship("DisasterZone", back_populates="policies")


class Emergency(Base):
    __tablename__ = "emergencies"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    zone_id = Column(String, ForeignKey("disaster_zones.id"), nullable=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, default="FLOOD_RESCUE")
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    status = Column(SQLEnum(EmergencyStatus), default=EmergencyStatus.PENDING)
    priority_score = Column(Float, default=50.0)
    priority_level = Column(SQLEnum(PriorityLevel), default=PriorityLevel.MEDIUM)
    priority_reasons = Column(JSON, default=list)
    vulnerability_score = Column(Float, default=0.0)
    vulnerability_factors = Column(JSON, default=dict)
    affected_count = Column(Integer, default=1)
    idempotency_key = Column(String, unique=True, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="emergencies")
    assignments = relationship("Assignment", back_populates="emergency")


class Resource(Base):
    __tablename__ = "resources"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    resource_type = Column(String, nullable=False) # BOAT, AMBULANCE, MEDICAL_TEAM, SHELTER_SUPPLY
    capacity = Column(Integer, default=5)
    current_load = Column(Integer, default=0)
    status = Column(SQLEnum(ResourceStatus), default=ResourceStatus.AVAILABLE)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    capabilities = Column(JSON, default=list) # ["FLOOD_WATER_RESCUE", "MEDICAL_FIRST_AID", "WHEELCHAIR_ACCESSIBLE"]
    contact_info = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    assignments = relationship("Assignment", back_populates="resource")


class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(String, primary_key=True, index=True)
    emergency_id = Column(String, ForeignKey("emergencies.id"), nullable=False)
    resource_id = Column(String, ForeignKey("resources.id"), nullable=False)
    status = Column(String, default="ACTIVE") # ACTIVE, COMPLETED, REPLANNED, CANCELLED
    assigned_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)
    route_geometry = Column(JSON, nullable=True) # LineString GeoJSON
    eta_minutes = Column(Float, default=15.0)

    emergency = relationship("Emergency", back_populates="assignments")
    resource = relationship("Resource", back_populates="assignments")


class Road(Base):
    __tablename__ = "roads"

    id = Column(String, primary_key=True, index=True)
    road_name = Column(String, nullable=False)
    status = Column(String, default="OPEN") # OPEN, PARTIALLY_BLOCKED, BLOCKED, FLOODED
    blockage_reason = Column(String, nullable=True)
    geometry_geojson = Column(JSON, nullable=False) # LineString GeoJSON
    confidence_score = Column(Float, default=1.0)
    corroboration_count = Column(Integer, default=1)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Shelter(Base):
    __tablename__ = "shelters"

    id = Column(String, primary_key=True, index=True)
    zone_id = Column(String, ForeignKey("disaster_zones.id"), nullable=True)
    name = Column(String, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    capacity = Column(Integer, default=200)
    current_occupancy = Column(Integer, default=0)
    status = Column(String, default="OPEN")
    contact_person = Column(String, nullable=True)


class ShelterRegistration(Base):
    __tablename__ = "shelter_registrations"

    id = Column(String, primary_key=True, index=True)
    shelter_id = Column(String, ForeignKey("shelters.id"), nullable=False)
    zone_of_origin_id = Column(String, ForeignKey("disaster_zones.id"), nullable=True)
    person_name = Column(String, nullable=False)
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    contact = Column(String, nullable=True)
    registered_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class PopulationAccountingRecord(Base):
    __tablename__ = "population_accounting_records"

    id = Column(String, primary_key=True, index=True)
    zone_id = Column(String, ForeignKey("disaster_zones.id"), nullable=False)
    expected_population = Column(Integer, default=1000)
    accounted_population = Column(Integer, default=0)
    gap_count = Column(Integer, default=1000)
    gap_percentage = Column(Float, default=100.0)
    status = Column(SQLEnum(AccountingStatus), default=AccountingStatus.NORMAL)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    zone = relationship("DisasterZone", back_populates="accounting_records")


class MissingPerson(Base):
    __tablename__ = "missing_persons"

    id = Column(String, primary_key=True, index=True)
    zone_id = Column(String, ForeignKey("disaster_zones.id"), nullable=True)
    full_name = Column(String, nullable=False)
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    last_known_location_lat = Column(Float, nullable=True)
    last_known_location_lon = Column(Float, nullable=True)
    source = Column(SQLEnum(MissingPersonSource), default=MissingPersonSource.MANUAL)
    human_confirmed = Column(Boolean, default=False)
    status = Column(SQLEnum(MissingPersonStatus), default=MissingPersonStatus.UNACCOUNTED)
    reporter_contact = Column(String, nullable=True)
    photo_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SituationObservation(Base):
    __tablename__ = "situation_observations"

    id = Column(String, primary_key=True, index=True)
    source_type = Column(String, default="CITIZEN_REPORT") # CITIZEN_REPORT, RESPONDER, AUTHORITY, SENSOR
    description = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    confidence_score = Column(Float, default=0.7)
    corroboration_count = Column(Integer, default=1)
    verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Simulation(Base):
    __tablename__ = "simulations"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, nullable=False)
    scenario_type = Column(String, nullable=False) # ROAD_BLOCKAGE, RESOURCE_FAILURE, DEMAND_SURGE, HIGH_VULNERABILITY_CLUSTER
    input_parameters = Column(JSON, default=dict)
    simulation_output = Column(JSON, default=dict)
    applied = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    role_target = Column(String, default="ALL")
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    category = Column(String, default="INFO")
    read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
