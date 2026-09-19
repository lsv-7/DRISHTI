from typing import List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import ResourceCreate, ResourceResponse
from app.repositories import crud
from app.decision_engine.matching import rank_matching_resources

router = APIRouter(prefix="/resources", tags=["Resources"])


@router.post("", response_model=ResourceResponse)
@router.post("/", response_model=ResourceResponse, include_in_schema=False)
def create_resource(r_in: ResourceCreate, db: Session = Depends(get_db)):
    resource = crud.create_resource(db, r_in)
    return resource


@router.get("", response_model=List[ResourceResponse])
@router.get("/", response_model=List[ResourceResponse], include_in_schema=False)
def get_resources(db: Session = Depends(get_db)):
    return crud.get_all_resources(db)


@router.get("/match/{emergency_id}")
def get_matching_resources_for_emergency(emergency_id: str, db: Session = Depends(get_db)):
    emergency = crud.get_emergency_by_id(db, emergency_id)
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found.")

    resources = crud.get_all_resources(db)
    res_dicts = [
        {
            "id": r.id,
            "name": r.name,
            "resource_type": r.resource_type,
            "status": r.status.value,
            "latitude": r.latitude,
            "longitude": r.longitude,
            "capacity": r.capacity,
            "current_load": r.current_load,
            "capabilities": r.capabilities or []
        }
        for r in resources
    ]

    e_dict = {
        "latitude": emergency.latitude,
        "longitude": emergency.longitude,
        "category": emergency.category,
        "vulnerability_score": emergency.vulnerability_score,
        "vulnerability_factors": emergency.vulnerability_factors or {}
    }

    ranked = rank_matching_resources(e_dict, res_dicts)
    return {
        "emergency_id": emergency_id,
        "matched_resources": ranked
    }


class AllocationPayload(BaseModel):
    resource_id: str
    emergency_id: str


@router.post("/allocate")
def allocate_resource(payload: AllocationPayload, db: Session = Depends(get_db)):
    res = crud.allocate_resource_to_emergency(db, payload.resource_id, payload.emergency_id)
    if res.get("status") == "ERROR":
        raise HTTPException(status_code=400, detail=res["message"])
    return res


@router.get("/assignments")
def get_assignments(db: Session = Depends(get_db)):
    assignments = crud.get_all_assignments(db)
    result = []
    for a in assignments:
        emergency = crud.get_emergency_by_id(db, a.emergency_id)
        resource = db.query(crud.Resource).filter(crud.Resource.id == a.resource_id).first()
        result.append({
            "id": a.id,
            "emergency_id": a.emergency_id,
            "emergency_title": emergency.title if emergency else "Emergency Incident",
            "emergency_priority": emergency.priority_level.value if emergency and hasattr(emergency.priority_level, "value") else "CRITICAL",
            "resource_id": a.resource_id,
            "resource_name": resource.name if resource else "Relief Unit",
            "resource_type": resource.resource_type if resource else "FLEET",
            "status": a.status,
            "assigned_at": a.assigned_at.isoformat() if a.assigned_at else None,
            "eta_minutes": a.eta_minutes
        })
    return result
