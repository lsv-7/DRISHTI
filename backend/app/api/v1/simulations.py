from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.domain import SimulationCreate, SimulationResponse
from app.repositories import crud
from app.decision_engine.simulation import run_what_if_simulation

router = APIRouter(prefix="/simulations", tags=["What-If Simulator"])


@router.post("/run")
def run_simulation(sim_in: SimulationCreate, db: Session = Depends(get_db)):
    """
    Runs a What-If Disaster Simulation on an isolated state snapshot.
    Operates on deep copies of live data (ADR-005). Does NOT mutate live state.
    """
    emergencies = [
        {
            "id": e.id,
            "title": e.title,
            "category": e.category,
            "latitude": e.latitude,
            "longitude": e.longitude,
            "affected_count": e.affected_count,
            "vulnerability_score": e.vulnerability_score,
            "priority_score": e.priority_score,
            "priority_level": e.priority_level.value if hasattr(e.priority_level, 'value') else str(e.priority_level),
            "status": e.status.value if hasattr(e.status, 'value') else str(e.status)
        }
        for e in crud.get_all_emergencies(db)
    ]

    resources = [
        {
            "id": r.id,
            "name": r.name,
            "resource_type": r.resource_type,
            "status": r.status.value if hasattr(r.status, 'value') else str(r.status),
            "latitude": r.latitude,
            "longitude": r.longitude,
            "capacity": r.capacity,
            "current_load": r.current_load,
            "capabilities": r.capabilities or []
        }
        for r in crud.get_all_resources(db)
    ]

    roads = []

    res_output = run_what_if_simulation(
        live_emergencies=emergencies,
        live_resources=resources,
        live_roads=roads,
        scenario_type=sim_in.scenario_type,
        parameters=sim_in.input_parameters
    )

    # Save simulation log
    sim_db = crud.Simulation(
        id=f"sim_{crud.uuid.uuid4().hex[:12]}",
        title=sim_in.title,
        scenario_type=sim_in.scenario_type,
        input_parameters=sim_in.input_parameters,
        simulation_output=res_output,
        applied=False
    )
    db.add(sim_db)
    db.commit()
    db.refresh(sim_db)

    return res_output
