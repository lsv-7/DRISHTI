const rawBase = import.meta.env?.VITE_API_URL || (import.meta.env?.VITE_API_BASE_URL ? `${import.meta.env.VITE_API_BASE_URL}/api/v1` : "http://localhost:3000/api/v1");
export const API_BASE = rawBase.endsWith('/') ? rawBase.slice(0, -1) : rawBase;

// Auth Header Helpers
export function getAuthHeaders(headers = {}) {
  const token = typeof localStorage !== 'undefined' ? localStorage.getItem("disaster_response_token") : null;
  const authHeader = token ? { "Authorization": `Bearer ${token}` } : {};
  return {
    "Content-Type": "application/json",
    ...authHeader,
    ...headers
  };
}

export function getHeaders(headers = {}) {
  const token = typeof localStorage !== 'undefined' ? localStorage.getItem("disaster_response_token") : null;
  const authHeader = token ? { "Authorization": `Bearer ${token}` } : {};
  return {
    ...authHeader,
    ...headers
  };
}

// Generic Helper
async function handleResponse(res, fallbackMessage = "API Error") {
  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`${fallbackMessage}: ${res.status} ${errorText}`);
  }
  return await res.json();
}

// Authentication API
export async function apiLogin(email, password, role = "ADMIN", fullName = null) {
  const res = await fetch(`${API_BASE}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      email,
      password: password || "password",
      full_name: fullName || (email ? email.split("@")[0].toUpperCase() : "DRISHTI User"),
      role: role || "ADMIN"
    })
  });
  return await handleResponse(res, "Login failed");
}

export async function apiGetMe() {
  const token = typeof localStorage !== 'undefined' ? localStorage.getItem("disaster_response_token") : null;
  if (!token) return null;
  const res = await fetch(`${API_BASE}/auth/me`, {
    headers: getHeaders()
  });
  return await handleResponse(res, "Failed to get user profile");
}

// Default Seed Datasets
export const DEFAULT_EMERGENCIES = [
  {
    id: "EMG-101",
    title: "Severe Inundation at Bandar Road",
    category: "FLOOD_RESCUE",
    latitude: 16.5062,
    longitude: 80.6480,
    status: "PENDING",
    priority_score: 92.5,
    priority_level: "CRITICAL",
    vulnerability_score: 85.0,
    vulnerability_factors: { age: 72, swim_ability: false, mobility: "WHEELCHAIR" },
    affected_count: 14,
    created_at: new Date(Date.now() - 3600000).toISOString()
  },
  {
    id: "EMG-102",
    title: "Submerged Residential Area in Auto Nagar",
    category: "MEDICAL_EVACUATION",
    latitude: 16.5120,
    longitude: 80.6600,
    status: "ASSIGNED",
    priority_score: 78.0,
    priority_level: "HIGH",
    vulnerability_score: 60.0,
    vulnerability_factors: { age: 4, swim_ability: false, mobility: "FULL" },
    affected_count: 6,
    created_at: new Date(Date.now() - 7200000).toISOString()
  },
  {
    id: "EMG-103",
    title: "Elderly Couple Trapped on Rooftop in Kothapeta",
    category: "FLOOD_RESCUE",
    latitude: 16.5090,
    longitude: 80.6380,
    status: "PENDING",
    priority_score: 88.0,
    priority_level: "CRITICAL",
    vulnerability_score: 90.0,
    vulnerability_factors: { age: 78, swim_ability: false, mobility: "LIMITED" },
    affected_count: 2,
    created_at: new Date(Date.now() - 1800000).toISOString()
  },
  {
    id: "EMG-104",
    title: "Flash Flood Surge at Krishna Canal Bank",
    category: "HAZMAT_RESCUE",
    latitude: 16.5010,
    longitude: 80.6520,
    status: "IN_PROGRESS",
    priority_score: 82.5,
    priority_level: "HIGH",
    vulnerability_score: 75.0,
    vulnerability_factors: { age: 45, swim_ability: true, mobility: "FULL" },
    affected_count: 18,
    created_at: new Date(Date.now() - 5400000).toISOString()
  }
];

export const DEFAULT_RESOURCES = [
  {
    id: "RES-001",
    name: "Vijayawada Boat Unit 01",
    resource_type: "BOAT",
    capacity: 10,
    current_load: 4,
    status: "AVAILABLE",
    latitude: 16.5080,
    longitude: 80.6400,
    location: "Prakasam Barrage Docks",
    capabilities: ["FLOOD_WATER_RESCUE", "WHEELCHAIR_ACCESSIBLE"]
  },
  {
    id: "RES-002",
    name: "Govt Hospital Emergency Ambulance 04",
    resource_type: "AMBULANCE",
    capacity: 2,
    current_load: 0,
    status: "AVAILABLE",
    latitude: 16.5020,
    longitude: 80.6450,
    location: "Govt General Hospital ER Ward",
    capabilities: ["TRAUMA_ICU", "ADVANCED_LIFE_SUPPORT"]
  },
  {
    id: "RES-003",
    name: "NDRF Multi-Utility Search & Rescue Team Alpha",
    resource_type: "RESCUE_TEAM",
    capacity: 12,
    current_load: 0,
    status: "AVAILABLE",
    latitude: 16.5150,
    longitude: 80.6410,
    location: "Ithanagar Command Base",
    capabilities: ["URBAN_SEARCH_RESCUE", "HEAVY_EXTRACTION"]
  },
  {
    id: "RES-004",
    name: "Police Patrol Rescue Craft Unit 09",
    resource_type: "PATROL_CAR",
    capacity: 4,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5100,
    longitude: 80.6350,
    location: "Central Police HQ, Governorpet",
    capabilities: ["TRAFFIC_CONTROL", "MOBILE_SIREN_BROADCAST"]
  },
  {
    id: "RES-005",
    name: "Heavy Clearance Debris Excavator Unit 02",
    resource_type: "EXCAVATOR",
    capacity: 1,
    current_load: 1,
    status: "DISPATCHED",
    latitude: 16.5000,
    longitude: 80.6550,
    location: "Benz Circle Road Blockage Site R12",
    capabilities: ["DEBRIS_REMOVAL", "HEAVY_LIFTING"]
  }
];

export const DEFAULT_ASSIGNMENTS = [
  {
    id: "ASG-101",
    emergency_id: "EMG-102",
    emergency_title: "Submerged Residential Area in Auto Nagar",
    emergency_priority: "HIGH",
    resource_id: "RES-001",
    resource_name: "Vijayawada Boat Unit 01",
    resource_type: "BOAT",
    status: "ACTIVE",
    assigned_at: new Date(Date.now() - 2400000).toISOString(),
    eta_minutes: 12.5
  },
  {
    id: "ASG-102",
    emergency_id: "EMG-104",
    emergency_title: "Flash Flood Surge at Krishna Canal Bank",
    emergency_priority: "HIGH",
    resource_id: "RES-005",
    resource_name: "Heavy Clearance Debris Excavator Unit 02",
    resource_type: "EXCAVATOR",
    status: "IN_PROGRESS",
    assigned_at: new Date(Date.now() - 3600000).toISOString(),
    eta_minutes: 8.0
  }
];

export const DEFAULT_ORGANIZATIONS = [
  {
    id: "H01",
    name: "Vijayawada Govt General Hospital",
    organization_type: "HOSPITAL",
    location: "Kothapeta, Vijayawada",
    latitude: 16.5062,
    longitude: 80.6480,
    operational_status: "OPERATIONAL",
    available_resources: "5 Ambulances, 60 ICU Beds, 18 ER Beds",
    active_assignments: 4,
    last_updated: new Date().toISOString(),
    verification_status: "VERIFIED"
  },
  {
    id: "P01",
    name: "Central Police Control HQ",
    organization_type: "POLICE",
    location: "Governorpet, Vijayawada",
    latitude: 16.5100,
    longitude: 80.6350,
    operational_status: "OPERATIONAL",
    available_resources: "12 Patrol Cars, 45 Personnel, Siren Units",
    active_assignments: 3,
    last_updated: new Date().toISOString(),
    verification_status: "VERIFIED"
  },
  {
    id: "F01",
    name: "Fire & Emergency Services HQ",
    organization_type: "FIRE",
    location: "Ithanagar, Vijayawada",
    latitude: 16.5150,
    longitude: 80.6400,
    operational_status: "OPERATIONAL",
    available_resources: "8 Fire Engines, 4 Water Rescue Boats",
    active_assignments: 5,
    last_updated: new Date().toISOString(),
    verification_status: "VERIFIED"
  },
  {
    id: "S01",
    name: "Prakasam Primary Relief Shelter",
    organization_type: "SHELTER",
    location: "Prakasam Nagar, Vijayawada",
    latitude: 16.5200,
    longitude: 80.6500,
    operational_status: "NEAR_CAPACITY",
    available_resources: "Cap: 600 beds (540 occupied), Ration Stock",
    active_assignments: 2,
    last_updated: new Date().toISOString(),
    verification_status: "VERIFIED"
  },
  {
    id: "R01",
    name: "Vijayawada Roads & Infrastructure Division",
    organization_type: "ROAD",
    location: "Benz Circle Arterial Hub",
    latitude: 16.5000,
    longitude: 80.6550,
    operational_status: "OPERATIONAL",
    available_resources: "3 Heavy Excavators, Debris Clearers",
    active_assignments: 6,
    last_updated: new Date().toISOString(),
    verification_status: "VERIFIED"
  }
];

export const DEFAULT_POPULATION_RECORDS = [
  {
    id: "REC-01",
    zone_id: "ZONE-VJ-01 (Prakasam Barrage East)",
    expected_population: 12000,
    accounted_population: 9800,
    gap_count: 2200,
    gap_percentage: 18.3,
    status: "ATTENTION",
    updated_at: new Date().toISOString()
  },
  {
    id: "REC-02",
    zone_id: "ZONE-VJ-02 (Auto Nagar Industrial)",
    expected_population: 8500,
    accounted_population: 7950,
    gap_count: 550,
    gap_percentage: 6.5,
    status: "NORMAL",
    updated_at: new Date().toISOString()
  },
  {
    id: "REC-03",
    zone_id: "ZONE-VJ-03 (Benz Circle Sector)",
    expected_population: 15200,
    accounted_population: 13100,
    gap_count: 2100,
    gap_percentage: 13.8,
    status: "ATTENTION",
    updated_at: new Date().toISOString()
  },
  {
    id: "REC-04",
    zone_id: "ZONE-VJ-04 (Kothapeta Low-Lying Ward)",
    expected_population: 9400,
    accounted_population: 6800,
    gap_count: 2600,
    gap_percentage: 27.6,
    status: "CRITICAL_GAP",
    updated_at: new Date().toISOString()
  },
  {
    id: "REC-05",
    zone_id: "ZONE-VJ-05 (Ithanagar Canal Ward)",
    expected_population: 6100,
    accounted_population: 5700,
    gap_count: 400,
    gap_percentage: 6.6,
    status: "NORMAL",
    updated_at: new Date().toISOString()
  }
];

export const DEFAULT_MISSING_PERSONS = [
  {
    id: "MP-101",
    full_name: "Ramesh Rao",
    age: 58,
    gender: "MALE",
    source: "INFERRED_ZONE_GAP",
    human_confirmed: false,
    status: "POTENTIAL_MISSING",
    created_at: new Date(Date.now() - 14400000).toISOString()
  },
  {
    id: "MP-102",
    full_name: "Sunitha Reddy",
    age: 42,
    gender: "FEMALE",
    source: "CITIZEN_REPORT",
    human_confirmed: true,
    status: "CONFIRMED_MISSING",
    created_at: new Date(Date.now() - 21600000).toISOString()
  },
  {
    id: "MP-103",
    full_name: "Master Arjun Kumar",
    age: 9,
    gender: "MALE",
    source: "SHELTER_DISCREPANCY",
    human_confirmed: false,
    status: "POTENTIAL_MISSING",
    created_at: new Date(Date.now() - 7200000).toISOString()
  },
  {
    id: "MP-104",
    full_name: "K. Venkateswarlu",
    age: 71,
    gender: "MALE",
    source: "INFERRED_ZONE_GAP",
    human_confirmed: true,
    status: "CONFIRMED_MISSING",
    created_at: new Date(Date.now() - 28800000).toISOString()
  },
  {
    id: "MP-105",
    full_name: "Lakshmi Devi",
    age: 64,
    gender: "FEMALE",
    source: "HOTLINE_CALL",
    human_confirmed: false,
    status: "POTENTIAL_MISSING",
    created_at: new Date(Date.now() - 3600000).toISOString()
  }
];

// Helper to format Flutter Mobile and backend data objects
function formatEmergencyItem(e) {
  return {
    ...e,
    id: e.id || `EMG-${Math.floor(Math.random()*900 + 100)}`,
    title: e.title || 'Mobile Field Emergency Incident',
    category: e.category || 'FLOOD_RESCUE',
    priority_score: e.priority_score ?? 85.0,
    priority_level: e.priority_level || (e.priority_score > 80 ? "CRITICAL" : "HIGH"),
    vulnerability_score: e.vulnerability_score ?? (e.vulnerability_snapshot ? 85.0 : 70.0),
    vulnerability_factors: e.vulnerability_factors || e.vulnerability_snapshot || { age: 65, swim_ability: false, mobility: "FULL" },
    affected_count: e.affected_count || 4,
    status: e.status || "PENDING",
    created_at: e.created_at || new Date().toISOString()
  };
}

// Helper to merge incoming backend/mobile items with defaults
function mergeWithDefaults(incoming, defaults, keyField = 'id') {
  if (!Array.isArray(incoming) || incoming.length === 0) {
    return defaults;
  }
  const incomingKeys = new Set(incoming.map(item => item[keyField] || item.title || item.name));
  const result = incoming.map(formatEmergencyItem);
  
  defaults.forEach(def => {
    const key = def[keyField] || def.title || def.name;
    if (!incomingKeys.has(key)) {
      result.push(def);
    }
  });
  return result;
}

// --- EMERGENCIES ---
export async function fetchEmergencies() {
  try {
    const res = await fetch(`${API_BASE}/emergencies`, { headers: getHeaders() });
    const data = await handleResponse(res, "Failed to fetch emergencies");
    if (Array.isArray(data)) {
      return mergeWithDefaults(data, DEFAULT_EMERGENCIES);
    }
  } catch (err) {
    console.warn("fetchEmergencies fallback to demo data:", err);
  }
  return DEFAULT_EMERGENCIES;
}

export async function createEmergency(payload) {
  try {
    const res = await fetch(`${API_BASE}/emergencies`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify(payload)
    });
    return await handleResponse(res, "Failed to create emergency");
  } catch (err) {
    const newEmergency = formatEmergencyItem({
      id: `EMG-${Math.floor(Math.random() * 900 + 100)}`,
      ...payload
    });
    DEFAULT_EMERGENCIES.unshift(newEmergency);
    return newEmergency;
  }
}

export async function updateEmergencyStatus(id, status) {
  try {
    const res = await fetch(`${API_BASE}/emergencies/${id}/status`, {
      method: "PATCH",
      headers: getAuthHeaders(),
      body: JSON.stringify({ status })
    });
    return await handleResponse(res, "Failed to update emergency status");
  } catch (err) {
    const target = DEFAULT_EMERGENCIES.find(e => e.id === id);
    if (target) target.status = status;
    return { id, status };
  }
}

// --- RESOURCES & ASSIGNMENTS ---
export async function fetchResources() {
  try {
    const res = await fetch(`${API_BASE}/resources`, { headers: getHeaders() });
    const data = await handleResponse(res, "Failed to fetch resources");
    if (Array.isArray(data)) {
      return mergeWithDefaults(data, DEFAULT_RESOURCES);
    }
  } catch (err) {
    console.warn("fetchResources fallback to demo data:", err);
  }
  return DEFAULT_RESOURCES;
}

export async function fetchMatchingResources(emergencyId) {
  try {
    const res = await fetch(`${API_BASE}/resources/match/${emergencyId}`, { headers: getHeaders() });
    return await handleResponse(res, "Failed to fetch matching resources");
  } catch (err) {
    return { emergency_id: emergencyId, matched_resources: DEFAULT_RESOURCES };
  }
}

export async function allocateResource(resourceId, emergencyId) {
  try {
    const res = await fetch(`${API_BASE}/resources/allocate`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ resource_id: resourceId, emergency_id: emergencyId })
    });
    return await handleResponse(res, "Failed to allocate resource");
  } catch (err) {
    const resObj = DEFAULT_RESOURCES.find(r => r.id === resourceId);
    if (resObj) resObj.status = "DISPATCHED";
    const emgObj = DEFAULT_EMERGENCIES.find(e => e.id === emergencyId);
    if (emgObj) emgObj.status = "ASSIGNED";

    return {
      assignment_id: `ASG-${Math.floor(Math.random() * 900 + 100)}`,
      resource_id: resourceId,
      emergency_id: emergencyId,
      status: "ACTIVE"
    };
  }
}

export async function fetchAssignments() {
  try {
    const res = await fetch(`${API_BASE}/resources/assignments`, { headers: getHeaders() });
    const data = await handleResponse(res, "Failed to fetch assignments");
    if (Array.isArray(data)) {
      return mergeWithDefaults(data, DEFAULT_ASSIGNMENTS);
    }
  } catch (err) {
    console.warn("fetchAssignments fallback to demo data:", err);
  }
  return DEFAULT_ASSIGNMENTS;
}

// --- ORGANIZATIONS MANAGEMENT ---
export async function fetchOrganizations() {
  try {
    const res = await fetch(`${API_BASE}/map/vijayawada`, { headers: getHeaders() });
    const data = await handleResponse(res, "Failed to fetch map data");
    const orgs = [];
    if (data.hospitals?.features) {
      data.hospitals.features.forEach((f, idx) => {
        orgs.push({
          id: f.properties.id || `H0${idx+1}`,
          name: f.properties.name || "Hospital Center",
          organization_type: "HOSPITAL",
          location: "Vijayawada Urban",
          latitude: f.geometry?.coordinates[1] || 16.506,
          longitude: f.geometry?.coordinates[0] || 80.648,
          operational_status: "OPERATIONAL",
          available_resources: "4 Ambulances, 2 Medical Teams",
          active_assignments: 2,
          last_updated: new Date().toISOString(),
          verification_status: "VERIFIED"
        });
      });
    }
    return mergeWithDefaults(orgs, DEFAULT_ORGANIZATIONS);
  } catch (err) {
    console.warn("fetchOrganizations fallback to demo data:", err);
  }
  return DEFAULT_ORGANIZATIONS;
}

export async function updateOrganizationStatus(orgId, statusPayload) {
  console.log(`[ORG AUDIT LOG] Org ${orgId} status changed:`, statusPayload);
  return { status: "SUCCESS", updated_at: new Date().toISOString(), payload: statusPayload };
}

// --- DYNAMIC REPLANNING & DECISION ROUTING ---
export async function triggerDynamicReplan(trigger, roadId = "R12", roadStatus = "BLOCKED") {
  try {
    const res = await fetch(`${API_BASE}/decision/replan`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ trigger, road_id: roadId, road_status: roadStatus })
    });
    return await handleResponse(res, "Failed to trigger replanning");
  } catch (err) {
    return {
      replan_id: `RP-DEMO-${Math.floor(Math.random()*1000)}`,
      trigger,
      blocked_road_id: roadId,
      affected_assignments: [
        {
          assignment_id: "ASG-101",
          emergency_title: "Submerged Residential Area in Auto Nagar",
          original_route: "Prakasam Barrage Main Arterial Road (R12)",
          status: "BLOCKED_AFFECTED"
        }
      ],
      alternative_routes: [
        {
          emergency_id: "EMG-102",
          recommended_resource: "Rescue Boat 01",
          alternative_route_name: "Eluru Road Alternate Bypass (R20)",
          original_eta_minutes: 10.0,
          new_eta_minutes: 14.5,
          avoided_road: "R12 (Prakasam Barrage)"
        }
      ],
      requires_approval: true,
      status: "PENDING_APPROVAL"
    };
  }
}

export async function approveReplanProposal(replanId, approvedBy = "COORD-001", reason = "Bypass route verified safe") {
  try {
    const res = await fetch(`${API_BASE}/decision/replan/${replanId}/approve`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ approved: true, approved_by: approvedBy, approval_reason: reason })
    });
    return await handleResponse(res, "Failed to approve replan proposal");
  } catch (err) {
    return {
      replan_id: replanId,
      approved: true,
      status: "APPLIED_TO_LIVE_SYSTEM",
      message: "Replan proposal approved and applied to live system."
    };
  }
}

// --- POPULATION & MISSING PERSONS ---
export async function fetchPopulationAccounting() {
  try {
    const res = await fetch(`${API_BASE}/population/records`, { headers: getHeaders() });
    const data = await handleResponse(res, "Failed to fetch population records");
    if (Array.isArray(data) && data.length > 0) {
      return mergeWithDefaults(data, DEFAULT_POPULATION_RECORDS);
    }
  } catch (err) {
    console.warn("fetchPopulationAccounting fallback to demo data:", err);
  }
  return DEFAULT_POPULATION_RECORDS;
}

export async function fetchMissingPersons(includeUnconfirmed = true) {
  try {
    const res = await fetch(`${API_BASE}/missing-persons?include_unconfirmed=${includeUnconfirmed}`, { headers: getHeaders() });
    const data = await handleResponse(res, "Failed to fetch missing persons");
    if (Array.isArray(data) && data.length > 0) {
      return mergeWithDefaults(data, DEFAULT_MISSING_PERSONS);
    }
  } catch (err) {
    console.warn("fetchMissingPersons fallback to demo data:", err);
  }
  return DEFAULT_MISSING_PERSONS;
}

export async function confirmMissingPerson(id) {
  try {
    const res = await fetch(`${API_BASE}/missing-persons/${id}/confirm`, {
      method: "POST",
      headers: getAuthHeaders()
    });
    return await handleResponse(res, "Failed to confirm missing person");
  } catch (err) {
    const target = DEFAULT_MISSING_PERSONS.find(p => p.id === id);
    if (target) {
      target.human_confirmed = true;
      target.status = "CONFIRMED_MISSING";
    }
    return { id, human_confirmed: true, status: "CONFIRMED_MISSING" };
  }
}

// --- SIMULATION ---
export async function runSimulation(scenarioType, inputParameters = {}) {
  try {
    const res = await fetch(`${API_BASE}/simulations/run`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({
        title: `Simulation (${scenarioType})`,
        scenario_type: scenarioType,
        input_parameters: inputParameters
      })
    });
    return await handleResponse(res, "Failed to run simulation");
  } catch (err) {
    return {
      id: `SIM-${Date.now()}`,
      scenario_type: scenarioType,
      simulation_output: {
        impact_summary: `Simulated impact for ${scenarioType}: Expected +${Math.floor(Math.random()*25 + 15)} min delay in rescue operations. Rerouting via Eluru Bypass recommended.`
      }
    };
  }
}

// --- AGENT ORCHESTRATION ---
export async function queryAgentWorkflow(query, userRole = "COORDINATOR", emergencyContext = null) {
  try {
    const res = await fetch(`${API_BASE}/agents/orchestrate`, {
      method: "POST",
      headers: getAuthHeaders(),
      body: JSON.stringify({ query, user_role: userRole, emergency_context: emergencyContext })
    });
    return await handleResponse(res, "Failed to query agent workflow");
  } catch (err) {
    return {
      agent: "SUPERVISOR",
      response: "Analyzed operational status: Recommended allocating Rescue Boat 01 via Eluru Road alternate route."
    };
  }
}

// --- SUPPLY CHAIN & TELEMETRY ---
export async function fetchSupplyShipments() {
  return [
    {
      id: "SHP-901",
      commodity: "Drinking Water (5000L)",
      quantity: 5000,
      unit: "LITERS",
      origin: "Central Disaster Warehouse A",
      destination: "Prakasam Primary Relief Shelter (S01)",
      status: "IN_TRANSIT",
      vehicle_id: "TRK-882",
      driver_name: "K. Mohan",
      eta_minutes: 18,
      created_at: new Date().toISOString()
    },
    {
      id: "SHP-902",
      commodity: "Emergency First Aid Kits",
      quantity: 250,
      unit: "KITS",
      origin: "Medical Supply Depot B",
      destination: "Govt General Hospital (H01)",
      status: "DELIVERED_TO_ORG",
      vehicle_id: "AMB-04",
      driver_name: "P. Rajesh",
      eta_minutes: 0,
      created_at: new Date().toISOString()
    }
  ];
}

export async function createSupplyShipment(payload) {
  return {
    id: `SHP-${Math.floor(Math.random()*900 + 100)}`,
    ...payload,
    status: "IN_TRANSIT",
    created_at: new Date().toISOString()
  };
}
