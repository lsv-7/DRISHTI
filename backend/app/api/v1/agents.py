from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Dict, Any
from app.agents.workflow import build_disaster_agent_graph

router = APIRouter(prefix="/agents", tags=["Agentic AI"])


class AgentQuery(BaseModel):
    query: str
    user_role: Optional[str] = "COORDINATOR"
    emergency_context: Optional[Dict[str, Any]] = None


@router.post("/orchestrate")
def orchestrate_agent_workflow(q: AgentQuery):
    """
    Executes LangGraph orchestration graph across Supervisor, Situation, Policy, Resource, and Explanation agents.
    """
    graph = build_disaster_agent_graph()
    initial_state = {
        "query": q.query,
        "user_role": q.user_role or "COORDINATOR",
        "emergency_context": q.emergency_context,
        "zone_context": None,
        "policy_output": None,
        "reconstruction_norms": None,
        "vulnerability_output": None,
        "matching_resources": None,
        "population_status": None,
        "simulation_output": None,
        "final_explanation": None
    }
    result = graph.invoke(initial_state)
    return result
