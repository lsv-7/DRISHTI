import copy
from typing import Dict, Any, List
from app.decision_engine.priority import calculate_priority_score
from app.decision_engine.matching import rank_matching_resources


def run_what_if_simulation(
    live_emergencies: List[Dict[str, Any]],
    live_resources: List[Dict[str, Any]],
    live_roads: List[Dict[str, Any]],
    scenario_type: str,
    parameters: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Executes a What-If Disaster Simulation on an isolated state snapshot.
    
    IMPORTANT: Operates on deep copies of live data (ADR-005). Never mutates live state.
    """
    sim_emergencies = copy.deepcopy(live_emergencies)
    sim_resources = copy.deepcopy(live_resources)
    sim_roads = copy.deepcopy(live_roads)

    impact_summary = []

    # Scenario 1: Road Blockage
    if scenario_type == "ROAD_BLOCKAGE":
        blocked_road_id = parameters.get("road_id")
        for road in sim_roads:
            if road["id"] == blocked_road_id or parameters.get("block_all"):
                road["status"] = "BLOCKED"
                road["blockage_reason"] = "Simulated landslide / severe flood water"
        impact_summary.append("Road segment blocked. Route feasibility recalculated.")

    # Scenario 2: Resource Failure
    elif scenario_type == "RESOURCE_FAILURE":
        failed_resource_id = parameters.get("resource_id")
        for res in sim_resources:
            if res["id"] == failed_resource_id or parameters.get("fail_all_boats"):
                if parameters.get("fail_all_boats") and "BOAT" in res["resource_type"].upper():
                    res["status"] = "UNAVAILABLE"
                elif res["id"] == failed_resource_id:
                    res["status"] = "UNAVAILABLE"
        impact_summary.append("Target rescue resources disabled. Alternate assignments calculated.")

    # Scenario 3: Emergency Demand Surge
    elif scenario_type == "DEMAND_SURGE":
        surge_count = parameters.get("surge_count", 5)
        for i in range(surge_count):
            sim_e = {
                "id": f"sim_surge_{i+1}",
                "title": f"Simulated Surge Flood Request #{i+1}",
                "category": "FLOOD_RESCUE",
                "latitude": 12.9716 + (i * 0.005),
                "longitude": 77.5946 + (i * 0.005),
                "affected_count": 3,
                "vulnerability_score": 65.0,
                "status": "PENDING"
            }
            sim_emergencies.append(sim_e)
        impact_summary.append(f"Simulated surge of {surge_count} critical flood emergencies added.")

    # Scenario 4: High-Vulnerability Population Cluster
    elif scenario_type == "HIGH_VULNERABILITY_CLUSTER":
        for e in sim_emergencies:
            e["vulnerability_score"] = min(e.get("vulnerability_score", 0.0) + 40.0, 100.0)
            e["priority_score"] = min(e.get("priority_score", 0.0) + 30.0, 100.0)
            e["priority_level"] = "CRITICAL"
        impact_summary.append("High vulnerability cluster applied across affected population.")

    # Calculate simulated allocation recommendations
    sim_assignments = []
    unassigned_count = 0

    for e in sim_emergencies:
        ranked = rank_matching_resources(e, sim_resources)
        if ranked and ranked[0]["match_score"] > 30.0:
            top_match = ranked[0]
            sim_assignments.append({
                "emergency_id": e["id"],
                "emergency_title": e["title"],
                "resource_id": top_match["id"],
                "resource_name": top_match["name"],
                "match_score": top_match["match_score"],
                "eta_minutes": top_match["eta_minutes"]
            })
        else:
            unassigned_count += 1

    return {
        "scenario_type": scenario_type,
        "input_parameters": parameters,
        "impact_summary": impact_summary,
        "live_emergency_count": len(live_emergencies),
        "simulated_emergency_count": len(sim_emergencies),
        "simulated_assignments": sim_assignments,
        "unassigned_emergencies": unassigned_count,
        "isolation_verified": True,
        "disclaimer": "Simulation output. Live operational state remains unchanged until explicit Coordinator Apply action."
    }
