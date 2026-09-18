from typing import List, Optional, Dict, Any
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime


# --- Auth & User Schemas ---
class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    role: str = "CITIZEN"
    phone: Optional[str] = None


class UserCreate(UserBase):
    password: Optional[str] = None


class UserResponse(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# --- Vulnerability Profile ---
class VulnerabilityProfileBase(BaseModel):
    age: Optional[int] = 30
    age_group: str = "ADULT" # CHILD, ADULT, ELDERLY
    can_swim: bool = True
    mobility_status: str = "FULL" # FULL, LIMITED, WHEELCHAIR, BEDRIDDEN
    medical_conditions: List[str] = Field(default_factory=list)
    disability_notes: Optional[str] = None


class VulnerabilityProfileUpdate(VulnerabilityProfileBase):
    pass


class VulnerabilityProfileResponse(VulnerabilityProfileBase):
    id: str
    user_id: str
    vulnerability_score: float
    updated_at: datetime

    class Config:
        from_attributes = True


# --- Disaster Zone & Policy ---
class DisasterZonePolicyBase(BaseModel):
    title: str
    description: str
    category: str = "EVACUATION"
    policy_type: str = "OFFICIAL_POLICY"
    reconstruction_norm: bool = False
    role_target: str = "ALL"
    source: Optional[str] = None
    effective_date: Optional[str] = None


class DisasterZonePolicyCreate(DisasterZonePolicyBase):
    zone_id: str


class DisasterZonePolicyResponse(DisasterZonePolicyBase):
    id: str
    zone_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class DisasterZoneBase(BaseModel):
    name: str
    code: str
    disaster_type: str = "FLOOD"
    geometry_geojson: Dict[str, Any]
    expected_population: int = 1000
    is_active: bool = True


class DisasterZoneCreate(DisasterZoneBase):
    pass


class DisasterZoneResponse(DisasterZoneBase):
    id: str
    created_at: datetime
    policies: List[DisasterZonePolicyResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True


# --- Emergency Schemas ---
class EmergencyCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str = "FLOOD_RESCUE"
    latitude: float
    longitude: float
    affected_count: int = 1
    vulnerability_snapshot: Optional[VulnerabilityProfileBase] = None
    idempotency_key: Optional[str] = None


class EmergencyStatusUpdate(BaseModel):
    status: str


class EmergencyResponse(BaseModel):
    id: str
    user_id: Optional[str] = None
    zone_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    category: str
    latitude: float
    longitude: float
    status: str
    priority_score: float
    priority_level: str
    priority_reasons: List[str] = Field(default_factory=list)
    vulnerability_score: float
    vulnerability_factors: Dict[str, Any] = Field(default_factory=dict)
    affected_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# --- Resource & Assignment ---
class ResourceBase(BaseModel):
    name: str
    resource_type: str # BOAT, AMBULANCE, MEDICAL_TEAM, SHELTER_SUPPLY
    capacity: int = 5
    latitude: float
    longitude: float
    capabilities: List[str] = Field(default_factory=list)
    contact_info: Optional[str] = None


class ResourceCreate(ResourceBase):
    pass


class ResourceResponse(ResourceBase):
    id: str
    current_load: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class AssignmentCreate(BaseModel):
    emergency_id: str
    resource_id: str


class AssignmentResponse(BaseModel):
    id: str
    emergency_id: str
    resource_id: str
    status: str
    assigned_at: datetime
    completed_at: Optional[datetime] = None
    route_geometry: Optional[Dict[str, Any]] = None
    eta_minutes: float

    class Config:
        from_attributes = True


# --- Road & Situation ---
class RoadBase(BaseModel):
    road_name: str
    status: str = "OPEN" # OPEN, PARTIALLY_BLOCKED, BLOCKED, FLOODED
    blockage_reason: Optional[str] = None
    geometry_geojson: Dict[str, Any]
    confidence_score: float = 1.0


class RoadResponse(RoadBase):
    id: str
    corroboration_count: int
    updated_at: datetime

    class Config:
        from_attributes = True


# --- Population Accounting & Missing Person ---
class ShelterRegistrationCreate(BaseModel):
    shelter_id: str
    zone_of_origin_id: Optional[str] = None
    person_name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    contact: Optional[str] = None


class PopulationAccountingRecordResponse(BaseModel):
    id: str
    zone_id: str
    expected_population: int
    accounted_population: int
    gap_count: int
    gap_percentage: float
    status: str
    updated_at: datetime

    class Config:
        from_attributes = True


class MissingPersonCreate(BaseModel):
    full_name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    last_known_location_lat: Optional[float] = None
    last_known_location_lon: Optional[float] = None
    zone_id: Optional[str] = None
    reporter_contact: Optional[str] = None
    photo_url: Optional[str] = None


class MissingPersonResponse(BaseModel):
    id: str
    zone_id: Optional[str] = None
    full_name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    last_known_location_lat: Optional[float] = None
    last_known_location_lon: Optional[float] = None
    source: str
    human_confirmed: bool
    status: str
    reporter_contact: Optional[str] = None
    photo_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# --- Simulation ---
class SimulationCreate(BaseModel):
    title: str
    scenario_type: str # ROAD_BLOCKAGE, RESOURCE_FAILURE, DEMAND_SURGE, HIGH_VULNERABILITY_CLUSTER
    input_parameters: Dict[str, Any] = Field(default_factory=dict)


class SimulationResponse(BaseModel):
    id: str
    title: str
    scenario_type: str
    input_parameters: Dict[str, Any]
    simulation_output: Dict[str, Any]
    applied: bool
    created_at: datetime

    class Config:
        from_attributes = True
