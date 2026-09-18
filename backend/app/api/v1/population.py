from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import PopulationAccountingRecordResponse, ShelterRegistrationCreate
from app.repositories import crud
from app.decision_engine.population_accounting import calculate_population_gap

router = APIRouter(prefix="/population", tags=["Population Accounting"])


@router.get("/records", response_model=List[PopulationAccountingRecordResponse])
def get_population_records(db: Session = Depends(get_db)):
    return crud.get_population_accounting(db)


@router.post("/shelter-registration")
def register_at_shelter(reg: ShelterRegistrationCreate, db: Session = Depends(get_db)):
    """
    Registers a citizen at a shelter, incrementing accounted population.
    """
    return {
        "message": "Citizen registered at shelter successfully.",
        "registration": reg
    }
