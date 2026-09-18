from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import (
    DisasterZoneCreate, DisasterZoneResponse,
    DisasterZonePolicyCreate, DisasterZonePolicyResponse
)
from app.repositories import crud
from app.decision_engine.policy_engine import filter_policies_by_role, resolve_disaster_zone

router = APIRouter(prefix="/policies", tags=["Disaster Zone Policies & Reconstruction"])


@router.get("/zones", response_model=List[DisasterZoneResponse])
def get_disaster_zones(db: Session = Depends(get_db)):
    return crud.get_all_disaster_zones(db)


@router.post("/zones", response_model=DisasterZoneResponse)
def create_disaster_zone(zone_in: DisasterZoneCreate, db: Session = Depends(get_db)):
    return crud.create_disaster_zone(db, zone_in)


@router.post("", response_model=DisasterZonePolicyResponse)
def create_policy(policy_in: DisasterZonePolicyCreate, db: Session = Depends(get_db)):
    return crud.create_disaster_zone_policy(db, policy_in)


@router.get("/resolve")
def resolve_zone_and_policies(
    latitude: float = Query(...),
    longitude: float = Query(...),
    role: str = Query("ALL"),
    reconstruction_norms_only: bool = Query(False),
    db: Session = Depends(get_db)
):
    zones = crud.get_all_disaster_zones(db)
    zone_dicts = [
        {"id": z.id, "name": z.name, "geometry_geojson": z.geometry_geojson, "is_active": z.is_active}
        for z in zones
    ]
    resolved = resolve_disaster_zone(latitude, longitude, zone_dicts)
    if not resolved:
        return {"zone": None, "policies": [], "reconstruction_norms": []}

    db_policies = crud.get_policies_for_zone(db, resolved["id"])
    p_dicts = [
        {
            "id": p.id,
            "title": p.title,
            "description": p.description,
            "category": p.category,
            "policy_type": p.policy_type.value if hasattr(p.policy_type, 'value') else str(p.policy_type),
            "reconstruction_norm": p.reconstruction_norm,
            "role_target": p.role_target,
            "source": p.source,
            "effective_date": p.effective_date
        }
        for p in db_policies
    ]

    filtered = filter_policies_by_role(p_dicts, role, reconstruction_norms_only)
    reconstruction = filter_policies_by_role(p_dicts, role, reconstruction_norm_only=True)

    return {
        "resolved_zone": resolved,
        "applicable_policies": filtered,
        "reconstruction_norms": reconstruction
    }
