from typing import List, Dict, Any, Optional


def point_in_polygon(lat: float, lon: float, polygon_coords: List[List[float]]) -> bool:
    """
    Standard Ray-Casting algorithm for point-in-polygon check.
    polygon_coords format: [[lon, lat], [lon, lat], ...]
    """
    n = len(polygon_coords)
    inside = False
    p1x, p1y = polygon_coords[0]
    for i in range(n + 1):
        p2x, p2y = polygon_coords[i % n]
        if lon > min(p1x, p2x):
            if lon <= max(p1x, p2x):
                if lat <= max(p1y, p2y):
                    if p1y != p2y:
                        xinters = (lon - p1x) * (p2y - p1y) / (p2x - p1x) + p1y
                    if p1y == p2y or lat <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y
    return inside


def resolve_disaster_zone(lat: float, lon: float, zones: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    """
    Resolves GPS latitude and longitude to an active Disaster Zone polygon.
    """
    for zone in zones:
        if not zone.get("is_active", True):
            continue
        geojson = zone.get("geometry_geojson", {})
        if geojson.get("type") == "Polygon":
            coords = geojson.get("coordinates", [[]])[0]
            if coords and point_in_polygon(lat, lon, coords):
                return zone
    # If no exact polygon hit, return closest active zone or default
    return zones[0] if zones else None


def filter_policies_by_role(
    policies: List[Dict[str, Any]],
    role: str = "ALL",
    reconstruction_norm_only: bool = False
) -> List[Dict[str, Any]]:
    """
    Filters zone policies by user target role and optionally reconstruction norms.
    """
    filtered = []
    role_upper = role.upper()

    for p in policies:
        if reconstruction_norm_only and not p.get("reconstruction_norm", False):
            continue
        p_target = str(p.get("role_target", "ALL")).upper()
        if p_target == "ALL" or p_target == role_upper or role_upper == "ADMIN":
            filtered.append(p)
    return filtered
