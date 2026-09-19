/**
 * Client-side Decision Matrix for Organization & Resource Matching
 */
export function rankMatchingOrganizations(emergency, resources = []) {
  if (!emergency || !resources.length) return [];

  return resources.map(res => {
    let score = 50; // base score
    const reasons = [];

    // 1. Status Check
    if (res.status !== "AVAILABLE") {
      score -= 40;
      reasons.push(`Resource status is ${res.status}`);
    } else {
      score += 20;
      reasons.push("Resource currently AVAILABLE");
    }

    // 2. Capacity Check
    const remainingCap = (res.capacity || 5) - (res.current_load || 0);
    if (remainingCap <= 0) {
      score -= 30;
      reasons.push("Zero available capacity");
    } else {
      score += Math.min(20, remainingCap * 5);
      reasons.push(`${remainingCap} capacity slots available`);
    }

    // 3. Vulnerability Alignment
    const vScore = emergency.vulnerability_score || 0;
    const capabilities = res.capabilities || [];
    if (vScore > 70) {
      if (capabilities.includes("TRAUMA_ICU") || capabilities.includes("ADVANCED_LIFE_SUPPORT")) {
        score += 25;
        reasons.push("High vulnerability matched to Advanced Life Support capability");
      }
      if (capabilities.includes("WHEELCHAIR_ACCESSIBLE") && emergency.vulnerability_factors?.mobility === "WHEELCHAIR") {
        score += 20;
        reasons.push("Wheelchair accessible capability matched");
      }
    }

    // 4. Distance / Proximity (Euclidean approximation)
    const dLat = (res.latitude || 16.506) - (emergency.latitude || 16.506);
    const dLon = (res.longitude || 80.648) - (emergency.longitude || 80.648);
    const distKm = Math.sqrt(dLat * dLat + dLon * dLon) * 111;
    const estEta = Math.round((distKm / 30) * 60 + 5);

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
      match_score: Math.max(0, Math.min(100, Math.round(score))),
      eta_minutes: estEta,
      match_reasons: reasons
    };
  }).sort((a, b) => b.match_score - a.match_score);
}
