from typing import Dict, Any, Tuple


def calculate_population_gap(
    expected_population: int,
    accounted_population: int,
    critical_threshold_pct: float = 30.0
) -> Tuple[int, float, str, Dict[str, Any]]:
    """
    Computes zone-level population accounting status.
    
    IMPORTANT: As per ADR-010, population gaps are signals requiring human reconciliation.
    Individual missing-person records are NOT automatically created without human coordinator confirmation.
    
    Returns: (gap_count, gap_percentage, status, notice_payload)
    """
    expected = max(expected_population, 1)
    accounted = max(accounted_population, 0)
    gap = max(expected - accounted, 0)
    gap_pct = round((gap / expected) * 100.0, 1)

    attention_threshold = critical_threshold_pct * 0.6

    if gap_pct >= critical_threshold_pct:
        status = "CRITICAL"
    elif gap_pct >= attention_threshold:
        status = "ATTENTION"
    else:
        status = "NORMAL"

    notice = {
        "zone_gap_count": gap,
        "gap_percentage": gap_pct,
        "status": status,
        "human_review_required": True,
        "disclaimer": "Zone population discrepancy alert. Human coordinator verification is required before initiating missing-person entries."
    }

    return gap, gap_pct, status, notice
