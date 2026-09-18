const API_BASE = "http://localhost:3000/api/v1";

export async function fetchEmergencies() {
  try {
    const res = await fetch(`${API_BASE}/emergencies`);
    if (!res.ok) throw new Error("Failed to fetch emergencies");
    return await res.json();
  } catch (err) {
    console.error("fetchEmergencies error:", err);
    return [];
  }
}

export async function createEmergency(payload) {
  const res = await fetch(`${API_BASE}/emergencies`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  return await res.json();
}

export async function fetchResources() {
  try {
    const res = await fetch(`${API_BASE}/resources`);
    if (!res.ok) throw new Error("Failed to fetch resources");
    return await res.json();
  } catch (err) {
    console.error("fetchResources error:", err);
    return [];
  }
}

export async function fetchMatchingResources(emergencyId) {
  const res = await fetch(`${API_BASE}/resources/match/${emergencyId}`);
  return await res.json();
}

export async function allocateResource(resourceId, emergencyId) {
  const res = await fetch(`${API_BASE}/resources/allocate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ resource_id: resourceId, emergency_id: emergencyId })
  });
  return await res.json();
}

export async function fetchAssignments() {
  try {
    const res = await fetch(`${API_BASE}/resources/assignments`);
    if (!res.ok) throw new Error("Failed to fetch assignments");
    return await res.json();
  } catch (err) {
    console.error("fetchAssignments error:", err);
    return [];
  }
}

export async function fetchDisasterZones() {
  try {
    const res = await fetch(`${API_BASE}/policies/zones`);
    if (!res.ok) throw new Error("Failed to fetch zones");
    return await res.json();
  } catch (err) {
    console.error("fetchDisasterZones error:", err);
    return [];
  }
}

export async function resolveZonePolicies(lat, lon, role = "ALL", reconstructionOnly = false) {
  const url = `${API_BASE}/policies/resolve?latitude=${lat}&longitude=${lon}&role=${role}&reconstruction_norms_only=${reconstructionOnly}`;
  const res = await fetch(url);
  return await res.json();
}

export async function fetchPopulationAccounting() {
  try {
    const res = await fetch(`${API_BASE}/population/records`);
    if (!res.ok) throw new Error("Failed to fetch population records");
    return await res.json();
  } catch (err) {
    console.error("fetchPopulationAccounting error:", err);
    return [];
  }
}

export async function fetchMissingPersons(includeUnconfirmed = true) {
  try {
    const res = await fetch(`${API_BASE}/missing-persons?include_unconfirmed=${includeUnconfirmed}`);
    if (!res.ok) throw new Error("Failed to fetch missing persons");
    return await res.json();
  } catch (err) {
    console.error("fetchMissingPersons error:", err);
    return [];
  }
}

export async function confirmMissingPerson(id) {
  const res = await fetch(`${API_BASE}/missing-persons/${id}/confirm`, { method: "POST" });
  return await res.json();
}

export async function runSimulation(scenarioType, inputParameters = {}) {
  const res = await fetch(`${API_BASE}/simulations/run`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      title: `Simulation (${scenarioType})`,
      scenario_type: scenarioType,
      input_parameters: inputParameters
    })
  });
  return await res.json();
}

export async function queryAgentWorkflow(query, userRole = "COORDINATOR", emergencyContext = null) {
  const res = await fetch(`${API_BASE}/agents/orchestrate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      query,
      user_role: userRole,
      emergency_context: emergencyContext
    })
  });
  return await res.json();
}
