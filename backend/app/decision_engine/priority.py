from typing import Dict, Any, List, Tuple
from app.decision_engine.vulnerability import calculate_vulnerability_score


def calculate_priority_score(
    category: str,
    affected_count: int,
    vulnerability_snapshot: Dict[str, Any] = None,
    disaster_type: str = "FLOOD"
) -> Tuple[float, str, List[str], float, Dict[str, Any]]:
    """
    Calculates overall Emergency Priority (0 to 100) combining base severity,
    affected population count, and individual vulnerability factors.
    
    Returns: (priority_score, priority_level, priority_reasons, vulnerability_score, vulnerability_factors)
    """
    reasons = []
    
    # Base category severity
    category_upper = category.upper()
    if "MEDICAL" in category_upper or "TRAPPED" in category_upper:
        base_score = 40.0
        reasons.append("High-severity medical/trapped emergency category")
    elif "RESCUE" in category_upper or "FLOOD" in category_upper:
        base_score = 30.0
        reasons.append("Active flood rescue emergency")
    elif "SHELTER" in category_upper or "FOOD" in category_upper:
        base_score = 15.0
        reasons.append("Relief/shelter request category")
    else:
        base_score = 20.0
        reasons.append("Standard disaster request category")

    # Affected population multiplier
    count_score = min(affected_count * 5.0, 25.0)
    if affected_count > 1:
        reasons.append(f"Multiple people affected ({affected_count} individuals)")

    # Vulnerability score addition
    v_score = 0.0
    v_factors = {}
    v_reasons = []
    if vulnerability_snapshot:
        v_score, v_factors, v_reasons = calculate_vulnerability_score(vulnerability_snapshot, disaster_type)
        reasons.extend(v_reasons)

    # Combined priority weighted score
    # 40% Category Base + 20% Population + 40% Vulnerability
    total_priority = base_score + count_score + (v_score * 0.4)
    final_priority = min(max(round(total_priority, 1), 0.0), 100.0)

    # Determine Priority Level
    if final_priority >= 80.0:
        level = "CRITICAL"
    elif final_priority >= 60.0:
        level = "HIGH"
    elif final_priority >= 35.0:
        level = "MEDIUM"
    else:
        level = "LOW"

    return final_priority, level, reasons, v_score, v_factors
