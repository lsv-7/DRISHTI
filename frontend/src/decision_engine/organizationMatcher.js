/**
 * Parameterized Decision Engine for Organization & Resource Matching
 */
export function rankMatchingOrganizations(emergency, resources = []) {
  if (!emergency || !resources.length) return [];

  const eTitle = (emergency.title || "").toUpperCase();
  const eCategory = (emergency.category || "").toUpperCase();

  return resources.map(res => {
    let score = 50; // base score
    const reasons = [];

    // 1. Status Check
    if (res.status !== "AVAILABLE") {
      score -= 40;
      reasons.push(`Status ${res.status}`);
    } else {
      score += 20;
      reasons.push("Resource currently AVAILABLE");
    }

    // 2. Capacity & Availability Check
    const availCount = res.available !== undefined ? res.available : ((res.capacity || 5) - (res.current_load || 0));
    if (availCount <= 0 && res.status !== "AVAILABLE") {
      score -= 35;
      reasons.push("Zero available capacity");
    } else {
      score += Math.min(25, Math.max(5, availCount));
      reasons.push(`${availCount} available capacity units`);
    }

    // 3. Domain Specific Hazard & Capability Alignment
    const rType = (res.resource_type || "").toUpperCase();
    const caps = (res.capabilities || []).map(c => String(c).toUpperCase());

    // 🚒 Flood / Water Incident -> Water Rescue Boats & Equipment
    if (eTitle.includes("FLOOD") || eCategory.includes("FLOOD") || eTitle.includes("WATER") || eCategory.includes("WATER")) {
      if (rType.includes("BOAT") || rType.includes("WATER_RESCUE") || caps.some(c => c.includes("WATER") || c.includes("BOAT") || c.includes("FLOOD"))) {
        score += 35;
        reasons.push("Water Rescue capability matched to Flood hazard");
      }
    }

    // 🏥 Medical / Trauma / Evacuation -> Emergency & ICU Beds, Ambulances, Medical Supplies
    if (eTitle.includes("MEDICAL") || eCategory.includes("MEDICAL") || eTitle.includes("TRAUMA") || (emergency.vulnerability_score && emergency.vulnerability_score > 70)) {
      if (["EMERGENCY_BEDS", "ICU_BEDS", "AMBULANCE", "MEDICAL_TEAM", "MEDICAL_SUPPLIES"].includes(rType) || caps.some(c => c.includes("TRAUMA") || c.includes("LIFE_SUPPORT") || c.includes("SURGICAL"))) {
        score += 35;
        reasons.push("Critical Medical / ICU capability matched to Medical Trauma emergency");
      }
    }

    // 🏠 Evacuation / Displacement -> Shelter Capacity, Food, Water Rations
    if (eTitle.includes("EVACUAT") || eCategory.includes("EVACUAT") || eTitle.includes("SHELTER") || eCategory.includes("SHELTER")) {
      if (["SHELTER_CAPACITY", "AVAILABLE_SPACES", "FOOD_SUPPLY", "WATER_SUPPLY", "MEDICAL_ACCESSIBILITY_SUPPORT"].includes(rType)) {
        score += 35;
        reasons.push("Shelter housing & relief rations matched to Evacuation request");
      }
    }

    // 🛣️ Debris / Blocked Road -> Road Clearing Teams, Excavators, Diversions
    if (eTitle.includes("BLOCK") || eCategory.includes("ROAD") || eTitle.includes("DEBRIS") || eCategory.includes("INFRASTRUCTURE")) {
      if (["ROAD_SEGMENT", "BRIDGE", "EVACUATION_ROUTE", "ROAD_CLEARING_TEAM", "TRAFFIC_DIVERSION_POINT", "EXCAVATOR"].includes(rType) || caps.some(c => c.includes("DEBRIS") || c.includes("CLEARANCE") || c.includes("DIVERSION"))) {
        score += 35;
        reasons.push("Road clearance & traffic diversion capability matched to Road Blockage");
      }
    }

    // 👮 Security / Crowd Control -> Police Personnel & Patrol
    if (eTitle.includes("SECURITY") || eTitle.includes("CROWD") || eCategory.includes("SECURITY")) {
      if (["POLICE_PERSONNEL", "PATROL_VEHICLE", "TRAFFIC_CONTROL_UNIT", "COMMUNICATION_UNIT"].includes(rType)) {
        score += 35;
        reasons.push("Police Security & Patrol unit matched to Security incident");
      }
    }

    // 4. Proximity / Distance Calculation
    const dLat = (res.latitude || 16.506) - (emergency.latitude || 16.506);
    const dLon = (res.longitude || 80.648) - (emergency.longitude || 80.648);
    const distKm = Math.sqrt(dLat * dLat + dLon * dLon) * 111;
    const estEta = Math.round((distKm / 35) * 60 + 4);

    if (distKm < 3) {
      score += 15;
      reasons.push(`Close proximity (~${distKm.toFixed(1)} km, ETA ${estEta} min)`);
    } else if (distKm > 10) {
      score -= 15;
      reasons.push(`Distant location (~${distKm.toFixed(1)} km)`);
    }

    return {
      resource_id: res.id,
      name: res.name,
      resource_type: res.resource_type,
      source: res.source || res.organization_type || "System Command",
      available: availCount,
      capacity: res.capacity,
      match_score: Math.max(0, Math.min(100, Math.round(score))),
      eta_minutes: estEta,
      match_reasons: reasons
    };
  }).sort((a, b) => b.match_score - a.match_score);
}

