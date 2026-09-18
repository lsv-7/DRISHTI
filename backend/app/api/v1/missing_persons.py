from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import MissingPersonCreate, MissingPersonResponse
from app.repositories import crud

router = APIRouter(prefix="/missing-persons", tags=["Missing Persons"])


@router.post("", response_model=MissingPersonResponse)
def report_missing_person(mp_in: MissingPersonCreate, db: Session = Depends(get_db)):
    """
    Registers a missing person case.
    Initial human_confirmed gate is set to False (ADR-010).
    """
    mp = crud.create_missing_person(db, mp_in)
    return mp


@router.get("", response_model=List[MissingPersonResponse])
def get_missing_persons(
    include_unconfirmed: bool = Query(False),
    db: Session = Depends(get_db)
):
    """
    Retrieves missing person cases.
    Public view returns only human-confirmed missing persons (ADR-010).
    Coordinator view (include_unconfirmed=True) returns all unconfirmed/inferred cases.
    """
    return crud.get_missing_persons(db, include_unconfirmed)


@router.post("/{missing_person_id}/confirm", response_model=MissingPersonResponse)
def confirm_missing_person(missing_person_id: str, db: Session = Depends(get_db)):
    """
    Human verification gate: Authorized coordinator confirms missing person case.
    """
    mp = db.query(crud.MissingPerson).filter(crud.MissingPerson.id == missing_person_id).first()
    if not mp:
        raise HTTPException(status_code=404, detail="Missing person record not found.")
    mp.human_confirmed = True
    mp.status = crud.MissingPersonStatus.CONFIRMED_MISSING
    db.commit()
    db.refresh(mp)
    return mp
