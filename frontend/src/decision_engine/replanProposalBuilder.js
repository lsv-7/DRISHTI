/**
 * Generates Human-in-the-Loop Dynamic Replanning Proposals
 * when road blockages or org capacity shifts occur.
 */
export function buildReplanProposal(triggerType, eventData, activeAssignments = []) {
  const replanId = `RP-${Math.floor(Math.random()*9000 + 1000)}`;

  let affectedAssignments = [];
  let alternativeRoutes = [];

  if (triggerType === "ROAD_STATUS_CHANGED" && eventData.status === "BLOCKED") {
    affectedAssignments = activeAssignments.map(asg => ({
      assignment_id: asg.id,
      emergency_title: asg.emergency_title || "Active Rescue Operation",
      original_route: `Main Arterial (${eventData.road_id || 'R12'})`,
      status: "BLOCKED_AFFECTED"
    }));

    alternativeRoutes = activeAssignments.map(asg => ({
      assignment_id: asg.id,
      recommended_resource: asg.resource_name || "Assigned Relief Unit",
      alternative_route_name: "Northern Ring Road Bypass (R22)",
      original_eta_minutes: asg.eta_minutes || 12,
      new_eta_minutes: (asg.eta_minutes || 12) + 4.5,
      avoided_road: eventData.road_id || "R12 (Prakasam Barrage)"
    }));
  } else if (triggerType === "HOSPITAL_CAPACITY_CHANGED" && eventData.icu_available === 0) {
    affectedAssignments = [
      {
        assignment_id: "ASG-MED-09",
        emergency_title: "Critical Trauma Evacuation",
        original_route: "Direct to Vijayawada General Hospital",
        status: "OVERCAPACITY_DIVERT"
      }
    ];

    alternativeRoutes = [
      {
        assignment_id: "ASG-MED-09",
        recommended_resource: "St. Mary Medical Center ICU Unit",
        alternative_route_name: "Highway 16 Medical Corridor",
        original_eta_minutes: 8,
        new_eta_minutes: 14,
        avoided_road: "Vijayawada General (ICU Full)"
      }
    ];
  }

  return {
    replan_id: replanId,
    trigger: triggerType,
    event_summary: eventData,
    affected_assignments: affectedAssignments,
    alternative_routes: alternativeRoutes,
    requires_approval: true,
    status: "PENDING_APPROVAL",
    created_at: new Date().toISOString()
  };
}
