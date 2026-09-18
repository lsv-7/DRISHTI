import pytest
from app.decision_engine.vulnerability import calculate_vulnerability_score
from app.decision_engine.priority import calculate_priority_score
from app.decision_engine.matching import rank_matching_resources
from app.decision_engine.policy_engine import filter_policies_by_role, resolve_disaster_zone
from app.decision_engine.population_accounting import calculate_population_gap
from app.decision_engine.simulation import run_what_if_simulation


def test_vulnerability_score_calculation():
    # Test elderly non-swimmer in wheelchair with asthma during FLOOD
    profile = {
        "age": 75,
        "age_group": "ELDERLY",
        "can_swim": False,
        "mobility_status": "WHEELCHAIR",
        "medical_conditions": ["ASTHMA"]
    }
    score, factors, reasons = calculate_vulnerability_score(profile, disaster_type="FLOOD")
    # 25 (Elderly) + 30 (Cannot swim in flood) + 25 (Wheelchair) + 10 (Asthma) = 90.0
    assert score == 90.0
    assert factors["cannot_swim_factor"] == 30.0
    assert factors["mobility_factor"] == 25.0
    assert "Unable to swim in flood water conditions" in reasons


def test_priority_score_calculation():
    score, level, reasons, v_score, v_factors = calculate_priority_score(
        category="FLOOD_RESCUE",
        affected_count=3,
        vulnerability_snapshot={
            "age_group": "ELDERLY",
            "can_swim": False,
            "mobility_status": "WHEELCHAIR"
        }
    )
    assert score >= 70.0
    assert level in ["HIGH", "CRITICAL"]
    assert "Active flood rescue emergency" in reasons


def test_resource_matching_vulnerability_bonus():
    emergency = {
        "category": "FLOOD_RESCUE",
        "latitude": 12.978,
        "longitude": 77.592,
        "vulnerability_score": 80.0,
        "vulnerability_factors": {"cannot_swim_factor": 30.0, "mobility_factor": 25.0}
    }
    resources = [
        {
            "id": "r1",
            "name": "Standard Van",
            "resource_type": "TRUCK",
            "status": "AVAILABLE",
            "latitude": 12.978,
            "longitude": 77.592,
            "capacity": 5,
            "current_load": 0,
            "capabilities": []
        },
        {
            "id": "r2",
            "name": "Rescue Boat 01",
            "resource_type": "BOAT",
            "status": "AVAILABLE",
            "latitude": 12.978,
            "longitude": 77.592,
            "capacity": 5,
            "current_load": 0,
            "capabilities": ["FLOOD_WATER_RESCUE", "WHEELCHAIR_ACCESSIBLE"]
        }
    ]
    ranked = rank_matching_resources(emergency, resources)
    assert ranked[0]["id"] == "r2"
    assert ranked[0]["match_score"] > ranked[1]["match_score"]


def test_population_accounting_gap_inference():
    # 1000 expected, 200 accounted -> 800 gap (80%) -> CRITICAL
    gap, gap_pct, status, notice = calculate_population_gap(1000, 200)
    assert gap == 800
    assert gap_pct == 80.0
    assert status == "CRITICAL"
    assert notice["human_review_required"] is True


def test_what_if_simulation_isolation():
    live_emergencies = [{"id": "e1", "title": "Live SOS", "category": "FLOOD", "latitude": 12.9, "longitude": 77.5}]
    live_resources = [{"id": "r1", "name": "Boat 1", "resource_type": "BOAT", "status": "AVAILABLE", "latitude": 12.9, "longitude": 77.5, "capacity": 5}]
    live_roads = []

    res = run_what_if_simulation(
        live_emergencies=live_emergencies,
        live_resources=live_resources,
        live_roads=live_roads,
        scenario_type="RESOURCE_FAILURE",
        parameters={"fail_all_boats": True}
    )

    # Live data must not be mutated
    assert live_resources[0]["status"] == "AVAILABLE"
    assert res["isolation_verified"] is True
