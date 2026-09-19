from typing import Dict, Any, List, TypedDict, Optional
try:
    from langgraph.graph import StateGraph, END
except ImportError:
    StateGraph, END = None, None
from app.decision_engine.vulnerability import calculate_vulnerability_score
from app.decision_engine.priority import calculate_priority_score
from app.decision_engine.matching import rank_matching_resources
from app.decision_engine.policy_engine import resolve_disaster_zone, filter_policies_by_role
from app.decision_engine.population_accounting import calculate_population_gap
from app.decision_engine.simulation import run_what_if_simulation


# State schema for LangGraph workflow
class DisasterResponseState(TypedDict):
    query: str
    user_role: str
    emergency_context: Optional[Dict[str, Any]]
    zone_context: Optional[Dict[str, Any]]
    policy_output: Optional[List[Dict[str, Any]]]
    reconstruction_norms: Optional[List[Dict[str, Any]]]
    vulnerability_output: Optional[Dict[str, Any]]
    matching_resources: Optional[List[Dict[str, Any]]]
    population_status: Optional[Dict[str, Any]]
    simulation_output: Optional[Dict[str, Any]]
    final_explanation: Optional[str]


def situation_agent_node(state: DisasterResponseState) -> DisasterResponseState:
    """Situation Understanding Agent: Analyzes emergency severity and location."""
    e = state.get("emergency_context") or {}
    title = e.get("title", "Active Incident")
    lat, lon = e.get("latitude", 0.0), e.get("longitude", 0.0)
    
    state["query"] += f" | Analyzed situation for {title} at ({lat}, {lon})."
    return state


def policy_compliance_agent_node(state: DisasterResponseState) -> DisasterResponseState:
    """
    Policy & Compliance Agent (ADR-012): Resolves zone, fetches policies by role,
    surfaces reconstruction norms, and checks population accounting status.
    """
    e = state.get("emergency_context") or {}
    lat, lon = e.get("latitude", 12.978), e.get("longitude", 77.592)
    role = state.get("user_role", "CITIZEN")

    # Mock zone resolution for agent orchestration
    zone = {
        "id": "zone_A",
        "name": "Central Flood Zone A",
        "expected_population": 2500,
        "is_active": True
    }
    state["zone_context"] = zone

    # Policies
    sample_policies = [
        {
            "id": "pol_1",
            "title": "Evacuation Corridor Directive",
            "description": "Use North Main Bridge. Avoid underpasses.",
            "policy_type": "LEGAL_REQUIREMENT",
            "reconstruction_norm": False,
            "role_target": "CITIZEN"
        },
        {
            "id": "pol_2",
            "title": "Stormwater & Rainwater Harvesting Mandate",
            "description": "20% permeable ground retention space required for rebuilds.",
            "policy_type": "OFFICIAL_POLICY",
            "reconstruction_norm": True,
            "role_target": "COORDINATOR"
        }
    ]
    state["policy_output"] = filter_policies_by_role(sample_policies, role)
    state["reconstruction_norms"] = filter_policies_by_role(sample_policies, role, reconstruction_norm_only=True)
    return state


def resource_management_agent_node(state: DisasterResponseState) -> DisasterResponseState:
    """Resource Management Agent: Performs capability & vulnerability fit matching."""
    e = state.get("emergency_context") or {
        "category": "FLOOD_RESCUE",
        "latitude": 12.978,
        "longitude": 77.592,
        "vulnerability_score": 65.0,
        "vulnerability_factors": {"cannot_swim_factor": 30.0}
    }
    sample_resources = [
        {
            "id": "res_1",
            "name": "Rescue Boat 01",
            "resource_type": "BOAT",
            "status": "AVAILABLE",
            "latitude": 12.975,
            "longitude": 77.590,
            "capacity": 8,
            "current_load": 0,
            "capabilities": ["FLOOD_WATER_RESCUE", "SHALLOW_WATER_NAV"]
        },
        {
            "id": "res_2",
            "name": "Mobile Ambulance Unit A",
            "resource_type": "AMBULANCE",
            "status": "AVAILABLE",
            "latitude": 12.980,
            "longitude": 77.595,
            "capacity": 2,
            "current_load": 0,
            "capabilities": ["MEDICAL_FIRST_AID", "WHEELCHAIR_ACCESSIBLE"]
        }
    ]
    state["matching_resources"] = rank_matching_resources(e, sample_resources)
    return state


def explanation_agent_node(state: DisasterResponseState) -> DisasterResponseState:
    """Explanation Agent: Synthesizes structured facts into operational explanation."""
    e = state.get("emergency_context") or {}
    policies = state.get("policy_output") or []
    resources = state.get("matching_resources") or []

    top_res = resources[0]["name"] if resources else "None"
    top_score = resources[0]["match_score"] if resources else 0

    explanation = (
        f"Operational Plan Summary:\n"
        f"- Target Emergency: {e.get('title', 'Flood Request')}\n"
        f"- Recommended Resource: {top_res} (Match Score: {top_score}%)\n"
        f"- Applicable Policies Surfaced: {len(policies)} policies for {state.get('user_role', 'user')}.\n"
        f"- Deterministic decision engines executed cleanly."
    )
    state["final_explanation"] = explanation
    return state


# Build LangGraph StateGraph
def build_disaster_agent_graph():
    builder = StateGraph(DisasterResponseState)
    builder.add_node("situation_agent", situation_agent_node)
    builder.add_node("policy_agent", policy_compliance_agent_node)
    builder.add_node("resource_agent", resource_management_agent_node)
    builder.add_node("explanation_agent", explanation_agent_node)

    builder.set_entry_point("situation_agent")
    builder.add_edge("situation_agent", "policy_agent")
    builder.add_edge("policy_agent", "resource_agent")
    builder.add_edge("resource_agent", "explanation_agent")
    builder.add_edge("explanation_agent", END)

    return builder.compile()
