from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import EmergencyCreate, EmergencyResponse, EmergencyStatusUpdate
from app.repositories import crud
from app.models.domain import EmergencyStatus

router = APIRouter(prefix="/emergencies", tags=["Emergencies"])


@router.post("", response_model=EmergencyResponse, status_code=status.HTTP_201_CREATED)
def create_emergency(e_in: EmergencyCreate, response: Response, db: Session = Depends(get_db)):
    """
    Creates an emergency report with vulnerability snapshot & idempotency support.
    Automatically calculates vulnerability-adjusted priority score and resolves disaster zone.
    Returns 201 Created for new reports, 200 OK for idempotent duplicate replays,
    and 409 Conflict if payload conflicts with an existing key.
    """
    try:
        emergency = crud.create_emergency(db, e_in)
        if getattr(emergency, "_is_new", True) is False:
            response.status_code = status.HTTP_200_OK
        return emergency
    except crud.IdempotencyConflictError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.get("", response_model=List[EmergencyResponse])
def get_emergencies(db: Session = Depends(get_db)):
    return crud.get_all_emergencies(db)


@router.get("/{emergency_id}", response_model=EmergencyResponse)
def get_emergency(emergency_id: str, db: Session = Depends(get_db)):
    emergency = crud.get_emergency_by_id(db, emergency_id)
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found.")
    return emergency


@router.patch("/{emergency_id}/status", response_model=EmergencyResponse)
def update_emergency_status(emergency_id: str, status_in: EmergencyStatusUpdate, db: Session = Depends(get_db)):
    emergency = crud.get_emergency_by_id(db, emergency_id)
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found.")
    if status_in.status in EmergencyStatus.__members__:
        emergency.status = EmergencyStatus(status_in.status)
        db.commit()
        db.refresh(emergency)
    return emergency
