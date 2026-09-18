import math
from typing import List, Dict, Any


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates distance in kilometers between two GPS coordinates."""
    R = 6371.0 # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def rank_matching_resources(
    emergency: Dict[str, Any],
    resources: List[Dict[str, Any]],
    blocked_roads: List[Dict[str, Any]] = None
) -> List[Dict[str, Any]]:
    """
    Ranks available resources for an emergency based on:
    - Proximity / Distance (40%)
    - Capability fit (30%)
    - Capacity availability (15%)
    - Vulnerability fit bonus (15%) (ADR-008: prefers resources with capabilities matching the vulnerable profile)
    """
    e_lat = emergency.get("latitude", 0.0)
    e_lon = emergency.get("longitude", 0.0)
    e_category = str(emergency.get("category", "")).upper()
    v_score = emergency.get("vulnerability_score", 0.0)
    v_factors = emergency.get("vulnerability_factors", {})

    ranked = []
    for r in resources:
        if r.get("status") != "AVAILABLE":
            continue

        r_lat = r.get("latitude", 0.0)
        r_lon = r.get("longitude", 0.0)
        dist_km = haversine_distance(e_lat, e_lon, r_lat, r_lon)
        eta_min = round((dist_km / 30.0) * 60, 1) # Assumes avg speed 30 km/h in flood

        capabilities = [c.upper() for c in r.get("capabilities", [])]
        reasons = []

        # Distance score (100 = 0km, 0 = 50km+)
        dist_score = max(100.0 - (dist_km * 2.0), 0.0)
        reasons.append(f"Distance: {round(dist_km, 2)} km (ETA ~{eta_min} mins)")

        # Capability fit score
        cap_score = 50.0
        if "RESCUE" in e_category and ("BOAT" in r.get("resource_type", "").upper() or "FLOOD_WATER_RESCUE" in capabilities):
            cap_score += 50.0
            reasons.append("Equipped for flood water rescue")
        elif "MEDICAL" in e_category and ("MEDICAL" in capabilities or "AMBULANCE" in r.get("resource_type", "").upper()):
            cap_score += 50.0
            reasons.append("Medical team / ambulance capability match")

        # Vulnerability fit bonus (ADR-008)
        v_fit_bonus = 0.0
        if v_score > 40.0:
            if v_factors.get("cannot_swim_factor", 0) > 0 and "BOAT" in r.get("resource_type", "").upper():
                v_fit_bonus += 20.0
                reasons.append("Vulnerability Bonus: Specialized boat resource for non-swimmer")
            if v_factors.get("mobility_factor", 0) > 0 and ("WHEELCHAIR_ACCESSIBLE" in capabilities or "AMBULANCE" in r.get("resource_type", "").upper()):
                v_fit_bonus += 20.0
                reasons.append("Vulnerability Bonus: Mobility/wheelchair accessible resource")
            if v_factors.get("medical_condition_factor", 0) > 0 and "MEDICAL_FIRST_AID" in capabilities:
                v_fit_bonus += 20.0
                reasons.append("Vulnerability Bonus: Medical response team for high-risk medical profile")

        # Capacity score
        cap = r.get("capacity", 5)
        load = r.get("current_load", 0)
        rem_cap = max(cap - load, 0)
        cap_availability_score = (rem_cap / max(cap, 1)) * 100.0

        # Overall composite match score
        total_score = (dist_score * 0.35) + (cap_score * 0.35) + (cap_availability_score * 0.15) + (v_fit_bonus * 0.15)
        total_score = min(max(round(total_score, 1), 0.0), 100.0)

        r_copy = dict(r)
        r_copy["match_score"] = total_score
        r_copy["distance_km"] = round(dist_km, 2)
        r_copy["eta_minutes"] = eta_min
        r_copy["match_reasons"] = reasons
        ranked.append(r_copy)

    ranked.sort(key=lambda x: x["match_score"], reverse=True)
    return ranked
