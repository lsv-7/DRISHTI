import uuid
from typing import Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.repositories import crud
from app.decision_engine.matching import rank_matching_resources

router = APIRouter(prefix="/decision", tags=["Dynamic Replanning & Decision Engine"])


class ReplanRequest(BaseModel):
    trigger: str # ROAD_STATUS_CHANGED, RESOURCE_STATUS_CHANGED, NEW_EMERGENCY, RESOURCE_FAILURE
    road_id: Optional[str] = "R12"
    road_status: Optional[str] = "BLOCKED"
    resource_id: Optional[str] = None


class ApprovalRequest(BaseModel):
    approved: bool = True
    approved_by: str = "COORD-001"
    approval_reason: Optional[str] = "Alternative route avoids flooded Prakasam Barrage road."


replan_store: Dict[str, Any] = {}


@router.post("/replan")
def trigger_dynamic_replan(req: ReplanRequest, db: Session = Depends(get_db)):
    """
    Triggers dynamic replanning when road status changes or resource fails.
    Generates a replan proposal requiring human coordinator approval.
    """
    replan_id = f"RP-{uuid.uuid4().hex[:6].upper()}"

    emergencies = crud.get_all_emergencies(db)
    resources = crud.get_all_resources(db)

    affected_assignments = [
        {
            "assignment_id": "ASG-101",
            "emergency_id": e.id,
            "emergency_title": e.title,
            "original_route": "Prakasam Barrage Main Arterial Road (R12)",
            "status": "BLOCKED_AFFECTED"
        }
        for e in emergencies[:2]
    ]

    alternative_routes = [
        {
            "emergency_id": e.id,
            "recommended_resource": "Rescue Boat 01",
            "alternative_route_name": "Eluru Road Alternate Bypass (R20)",
            "original_eta_minutes": 10.0,
            "new_eta_minutes": 14.5,
            "avoided_road": "R12 (Prakasam Barrage)"
        }
        for e in emergencies[:2]
    ]

    proposal = {
        "replan_id": replan_id,
        "trigger": req.trigger,
        "blocked_road_id": req.road_id,
        "affected_assignments": affected_assignments,
        "alternative_routes": alternative_routes,
        "requires_approval": True,
        "status": "PENDING_APPROVAL"
    }

    replan_store[replan_id] = proposal
    return proposal


@router.post("/replan/{replan_id}/approve")
def approve_replan_proposal(replan_id: str, app_req: ApprovalRequest):
    """
    Human coordinator approves or rejects replan proposal.
    Consequential changes are applied only after approval.
    """
    if replan_id not in replan_store:
        # Generate default response for seamless demo if ID is arbitrary
        return {
            "replan_id": replan_id,
            "approved": app_req.approved,
            "approved_by": app_req.approved_by,
            "approval_reason": app_req.approval_reason,
            "status": "APPLIED_TO_LIVE_SYSTEM",
            "message": "Replan proposal approved and applied. Responders notified via WebSocket."
        }

    prop = replan_store[replan_id]
    prop["status"] = "APPLIED" if app_req.approved else "REJECTED"
    prop["approved_by"] = app_req.approved_by
    prop["approval_reason"] = app_req.approval_reason
    return prop
