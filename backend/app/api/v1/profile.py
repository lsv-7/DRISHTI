from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import CitizenProfileUpdate, CitizenProfileResponse
from app.repositories import crud

router = APIRouter(prefix="/profile", tags=["Citizen Profiles"])


@router.get("/{user_id}", response_model=CitizenProfileResponse)
def get_citizen_profile(user_id: str, db: Session = Depends(get_db)):
    user = crud.get_citizen_profile(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Citizen profile not found."
        )
    return user


@router.put("/{user_id}", response_model=CitizenProfileResponse)
def update_citizen_profile(
    user_id: str,
    profile_in: CitizenProfileUpdate,
    db: Session = Depends(get_db)
):
    user = crud.update_citizen_profile(db, user_id, profile_in)
    return user
