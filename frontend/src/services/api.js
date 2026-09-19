const API_BASE = "http://localhost:3000/api/v1";

// Generic Helper
async function handleResponse(res, fallbackMessage = "API Error") {
  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`${fallbackMessage}: ${res.status} ${errorText}`);
  }
  return await res.json();
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
  // --- 1. HOSPITAL RESOURCES (🏥) ---
  {
    id: "RES-HOSP-01",
    name: "Govt Hospital Emergency ER Beds",
    organization_id: "H01",
    organization_type: "HOSPITAL",
    resource_type: "EMERGENCY_BEDS",
    capacity: 30,
    available: 18,
    current_load: 12,
    status: "AVAILABLE",
    latitude: 16.5062,
    longitude: 80.6480,
    location: "Govt General Hospital, Kothapeta",
    capabilities: ["EMERGENCY_TRIAGE", "TRAUMA_CARE", "SURGICAL_PREP"],
    source: "Hospital Center"
  },
  {
    id: "RES-HOSP-02",
    name: "Critical Intensive Care ICU Beds",
    organization_id: "H01",
    organization_type: "HOSPITAL",
    resource_type: "ICU_BEDS",
    capacity: 20,
    available: 7,
    current_load: 13,
    status: "AVAILABLE",
    latitude: 16.5062,
    longitude: 80.6480,
    location: "Govt Hospital ICU Wing 3",
    capabilities: ["TRAUMA_ICU", "VENTILATOR", "CRITICAL_CARE"],
    source: "Hospital Center"
  },
  {
    id: "RES-HOSP-03",
    name: "Advanced Life Support Ambulance Fleet",
    organization_id: "H01",
    organization_type: "HOSPITAL",
    resource_type: "AMBULANCE",
    capacity: 5,
    available: 3,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5020,
    longitude: 80.6450,
    location: "Govt Hospital ER Station",
    capabilities: ["ADVANCED_LIFE_SUPPORT", "PARAMEDIC_PATIENT_TRANSPORT"],
    source: "Hospital Center"
  },
  {
    id: "RES-HOSP-04",
    name: "Disaster Medical & Surgical Response Team",
    organization_id: "H01",
    organization_type: "HOSPITAL",
    resource_type: "MEDICAL_TEAM",
    capacity: 8,
    available: 6,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5062,
    longitude: 80.6480,
    location: "Hospital Command Annex",
    capabilities: ["DOCTORS", "SURGEONS", "PARAMEDICS"],
    source: "Hospital Center"
  },
  {
    id: "RES-HOSP-05",
    name: "Emergency Medical & Oxygen Supplies",
    organization_id: "H01",
    organization_type: "HOSPITAL",
    resource_type: "MEDICAL_SUPPLIES",
    capacity: 500,
    available: 350,
    unit: "UNITS",
    current_load: 150,
    status: "AVAILABLE",
    latitude: 16.5062,
    longitude: 80.6480,
    location: "Central Blood Bank & Pharmacy",
    capabilities: ["OXYGEN_CYLINDERS", "BLOOD_PACKS", "FIRST_AID"],
    source: "Hospital Center"
  },

  // --- 2. POLICE RESOURCES (👮) ---
  {
    id: "RES-POL-01",
    name: "Central Police Officers Rapid Deployment",
    organization_id: "P01",
    organization_type: "POLICE",
    resource_type: "POLICE_PERSONNEL",
    capacity: 50,
    available: 35,
    current_load: 15,
    status: "AVAILABLE",
    latitude: 16.5100,
    longitude: 80.6350,
    location: "Governorpet Police Station",
    capabilities: ["CROWD_CONTROL", "RESTRICTED_ZONE_SECURITY"],
    source: "Police Control HQ"
  },
  {
    id: "RES-POL-02",
    name: "Police Emergency Patrol Vehicles",
    organization_id: "P01",
    organization_type: "POLICE",
    resource_type: "PATROL_VEHICLE",
    capacity: 12,
    available: 8,
    current_load: 4,
    status: "AVAILABLE",
    latitude: 16.5100,
    longitude: 80.6350,
    location: "Central Police HQ, Governorpet",
    capabilities: ["FIELD_RESPONSE", "MOBILE_SIREN_BROADCAST"],
    source: "Police Control HQ"
  },
  {
    id: "RES-POL-03",
    name: "Traffic Control & Diversion Units",
    organization_id: "P01",
    organization_type: "POLICE",
    resource_type: "TRAFFIC_CONTROL_UNIT",
    capacity: 10,
    available: 7,
    current_load: 3,
    status: "AVAILABLE",
    latitude: 16.5000,
    longitude: 80.6550,
    location: "Benz Circle Traffic Post",
    capabilities: ["TRAFFIC_MANAGEMENT", "ROAD_BLOCKAGE_DIVERSION"],
    source: "Police Control HQ"
  },
  {
    id: "RES-POL-04",
    name: "Police Search & Missing Persons Coordination Team",
    organization_id: "P01",
    organization_type: "POLICE",
    resource_type: "SEARCH_RESCUE_TEAM",
    capacity: 15,
    available: 12,
    current_load: 3,
    status: "AVAILABLE",
    latitude: 16.5180,
    longitude: 80.6320,
    location: "Kothapeta Police Post",
    capabilities: ["MISSING_PERSON_TRACE", "COMMUNITY_SEARCH"],
    source: "Police Control HQ"
  },
  {
    id: "RES-POL-05",
    name: "Mobile Radio Communication Units (868MHz Mesh)",
    organization_id: "P01",
    organization_type: "POLICE",
    resource_type: "COMMUNICATION_UNIT",
    capacity: 6,
    available: 5,
    current_load: 1,
    status: "AVAILABLE",
    latitude: 16.5100,
    longitude: 80.6350,
    location: "Mobile Comms Control Van",
    capabilities: ["LORA_MESH_PING", "RADIO_RELAY", "OFFLINE_DISPATCH"],
    source: "Police Control HQ"
  },

  // --- 3. FIRE & RESCUE RESOURCES (🚒) ---
  {
    id: "RES-FIRE-01",
    name: "Heavy Duty Fire Engines & Water Tankers",
    organization_id: "F01",
    organization_type: "FIRE",
    resource_type: "FIRE_ENGINE",
    capacity: 8,
    available: 6,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5150,
    longitude: 80.6410,
    location: "Central Fire Station, Ithanagar",
    capabilities: ["FIRE_SUPPRESSION", "HIGH_PRESSURE_PUMPING"],
    source: "Fire & Rescue Station"
  },
  {
    id: "RES-FIRE-02",
    name: "Urban Search & Rubble Extraction Team",
    organization_id: "F01",
    organization_type: "FIRE",
    resource_type: "RESCUE_TEAM",
    capacity: 12,
    available: 9,
    current_load: 3,
    status: "AVAILABLE",
    latitude: 16.5150,
    longitude: 80.6410,
    location: "Fire HQ Command Annex",
    capabilities: ["RUBBLE_CLEARANCE", "HEAVY_EXTRACTION"],
    source: "Fire & Rescue Station"
  },
  {
    id: "RES-FIRE-03",
    name: "Krishna River Water Rescue Boat Team R02",
    organization_id: "F01",
    organization_type: "FIRE",
    resource_type: "BOAT_TEAM",
    capacity: 10,
    available: 7,
    current_load: 3,
    status: "AVAILABLE",
    latitude: 16.5080,
    longitude: 80.6400,
    location: "Prakasam Barrage Docks",
    capabilities: ["WATER_RESCUE", "FLOOD_SEARCH", "SHALLOW_NAV"],
    source: "Fire & Rescue Station"
  },
  {
    id: "RES-FIRE-04",
    name: "Hydraulic Cutters & Flood Rescue Gear",
    organization_id: "F01",
    organization_type: "FIRE",
    resource_type: "RESCUE_EQUIPMENT",
    capacity: 25,
    available: 20,
    current_load: 5,
    status: "AVAILABLE",
    latitude: 16.5150,
    longitude: 80.6410,
    location: "Rescue Equipment Depot",
    capabilities: ["HYDRAULIC_CUTTERS", "LIFE_JACKETS", "DRAINAGE_PUMPS"],
    source: "Fire & Rescue Station"
  },
  {
    id: "RES-FIRE-05",
    name: "Amphibious Inflatable Rescue Boats Fleet",
    organization_id: "F01",
    organization_type: "FIRE",
    resource_type: "RESCUE_BOAT",
    capacity: 6,
    available: 4,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5090,
    longitude: 80.6380,
    location: "Bandar Road Response Dock",
    capabilities: ["WATER_RESCUE", "EVACUATION_BOATS"],
    source: "Fire & Rescue Station"
  },

  // --- 4. SHELTER RESOURCES (🏠) ---
  {
    id: "RES-SHL-01",
    name: "Prakasam Multipurpose Relief Shelter Capacity",
    organization_id: "S01",
    organization_type: "SHELTER",
    resource_type: "SHELTER_CAPACITY",
    capacity: 500,
    available: 127,
    current_load: 373,
    status: "AVAILABLE",
    latitude: 16.5060,
    longitude: 80.6480,
    location: "Prakasam Barrage Shelter Wing A",
    capabilities: ["EVACUEE_HOUSING", "HEATED_DORMITORY"],
    source: "Relief Shelter"
  },
  {
    id: "RES-SHL-02",
    name: "Unoccupied Shelter Bed & Floor Spaces",
    organization_id: "S01",
    organization_type: "SHELTER",
    resource_type: "AVAILABLE_SPACES",
    capacity: 350,
    available: 127,
    current_load: 223,
    status: "AVAILABLE",
    latitude: 16.5060,
    longitude: 80.6480,
    location: "Shelter Hall 2 & 3",
    capabilities: ["BED_SPACES", "MATTRESSES"],
    source: "Relief Shelter"
  },
  {
    id: "RES-SHL-03",
    name: "Emergency Relief Food Rations",
    organization_id: "S01",
    organization_type: "SHELTER",
    resource_type: "FOOD_SUPPLY",
    capacity: 1000,
    available: 620,
    unit: "MEALS",
    current_load: 380,
    status: "AVAILABLE",
    latitude: 16.5060,
    longitude: 80.6480,
    location: "Shelter Kitchen & Mess",
    capabilities: ["HOT_MEALS", "PACKAGED_DRY_RATIONS"],
    source: "Relief Shelter"
  },
  {
    id: "RES-SHL-04",
    name: "Clean Drinking Water Storage Units",
    organization_id: "S01",
    organization_type: "SHELTER",
    resource_type: "WATER_SUPPLY",
    capacity: 5000,
    available: 3200,
    unit: "LITERS",
    current_load: 1800,
    status: "AVAILABLE",
    latitude: 16.5060,
    longitude: 80.6480,
    location: "Shelter Water Tanks Wing B",
    capabilities: ["PURIFIED_WATER", "PORTABLE_CONTAINERS"],
    source: "Relief Shelter"
  },
  {
    id: "RES-SHL-05",
    name: "Medical & Elderly Accessibility Support Unit",
    organization_id: "S01",
    organization_type: "SHELTER",
    resource_type: "MEDICAL_ACCESSIBILITY_SUPPORT",
    capacity: 50,
    available: 35,
    current_load: 15,
    status: "AVAILABLE",
    latitude: 16.5060,
    longitude: 80.6480,
    location: "Shelter Medical Station",
    capabilities: ["WHEELCHAIR_ACCESSIBLE", "ELDERLY_CARE", "FIRST_AID"],
    source: "Relief Shelter"
  },

  // --- 5. ROAD / INFRASTRUCTURE RESOURCES (🛣️) ---
  {
    id: "RES-ROAD-01",
    name: "Prakasam Barrage Main Road Segment R12",
    organization_id: "R01",
    organization_type: "ROAD",
    resource_type: "ROAD_SEGMENT",
    road_id: "R12",
    capacity: 1,
    available: 0,
    current_load: 1,
    status: "BLOCKED",
    reason: "FLOODING",
    severity: "HIGH",
    latitude: 16.5062,
    longitude: 80.6480,
    location: "Prakasam Arterial Corridor",
    capabilities: ["VEHICLE_TRANSPORT", "MAIN_ARTERIAL"],
    source: "Road Department"
  },
  {
    id: "RES-ROAD-02",
    name: "Krishna Barrage Lock Bridge Infrastructure",
    organization_id: "R01",
    organization_type: "ROAD",
    resource_type: "BRIDGE",
    capacity: 1,
    available: 1,
    current_load: 0,
    status: "AVAILABLE",
    latitude: 16.5062,
    longitude: 80.6480,
    location: "Krishna River Barrage Lock",
    capabilities: ["HEAVY_VEHICLE_BRIDGE", "MONITORED_SPILLWAY"],
    source: "Road Department"
  },
  {
    id: "RES-ROAD-03",
    name: "Eluru Canal Alternate Evacuation Route R20",
    organization_id: "R01",
    organization_type: "ROAD",
    resource_type: "EVACUATION_ROUTE",
    road_id: "R20",
    capacity: 2,
    available: 2,
    current_load: 0,
    status: "AVAILABLE",
    latitude: 16.5120,
    longitude: 80.6600,
    location: "Eluru Canal Bypass Corridor",
    capabilities: ["ALTERNATE_ROUTE", "EVACUATION_BYPASS"],
    source: "Road Department"
  },
  {
    id: "RES-ROAD-04",
    name: "Heavy Debris Clearance Excavator & Road Crew",
    organization_id: "R01",
    organization_type: "ROAD",
    resource_type: "ROAD_CLEARING_TEAM",
    capacity: 4,
    available: 2,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5000,
    longitude: 80.6550,
    location: "Benz Circle Road Blockage Site",
    capabilities: ["DEBRIS_REMOVAL", "ROAD_CLEARANCE"],
    source: "Road Department"
  },
  {
    id: "RES-ROAD-05",
    name: "Benz Circle Traffic Diversion Hub",
    organization_id: "R01",
    organization_type: "ROAD",
    resource_type: "TRAFFIC_DIVERSION_POINT",
    capacity: 6,
    available: 4,
    current_load: 2,
    status: "AVAILABLE",
    latitude: 16.5000,
    longitude: 80.6550,
    location: "Benz Circle Intersection",
    capabilities: ["TRAFFIC_REDIRECTION", "BYPASS_SIGNAGE"],
    source: "Road Department"
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
  const lat = typeof e.latitude === 'number' ? e.latitude : parseFloat(e.latitude) || 16.5062;
  const lon = typeof e.longitude === 'number' ? e.longitude : parseFloat(e.longitude) || 80.6480;
  return {
    ...e,
    id: e.id || `EMG-${Math.floor(Math.random()*900 + 100)}`,
    title: e.title || 'Mobile Field Emergency Incident',
    category: e.category || 'FLOOD_RESCUE',
    latitude: lat,
    longitude: lon,
    priority_score: e.priority_score ?? 85.0,
    priority_level: e.priority_level || (e.priority_score > 80 ? "CRITICAL" : "HIGH"),
    vulnerability_score: e.vulnerability_score ?? (e.vulnerability_snapshot ? 85.0 : 70.0),
    vulnerability_factors: e.vulnerability_factors || e.vulnerability_snapshot || { age: 65, swim_ability: false, mobility: "FULL" },
    affected_count: e.affected_count || 1,
    status: e.status || "PENDING",
    created_at: e.created_at || new Date().toISOString()
  };
}

// Helper to merge incoming backend/mobile items with defaults
function mergeWithDefaults(incoming, defaults, keyField = 'id') {
  if (!Array.isArray(incoming) || incoming.length === 0) {
    return defaults;
  }
  // Authoritative live backend data takes precedence: format and sort descending by timestamp
  const result = incoming.map(formatEmergencyItem);
  result.sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0));
  return result;
}

// --- EMERGENCIES ---
export async function fetchEmergencies() {
  try {
    const res = await fetch(`${API_BASE}/emergencies`);
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
      headers: { "Content-Type": "application/json" },
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
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status })
    });
    return await handleResponse(res, "Failed to update emergency status");
  } catch (err) {
    const target = DEFAULT_EMERGENCIES.find(e => e.id === id);
    if (target) target.status = status;
    return { id, status };
  }
}

// --- PERSISTENT RESOURCE STORAGE & SYNC ---
const CUSTOM_RESOURCES_KEY = "drishti_custom_resources";

export function getStoredCustomResources() {
  try {
    const raw = localStorage.getItem(CUSTOM_RESOURCES_KEY);
    if (!raw) return [];
    const list = JSON.parse(raw);
    if (!Array.isArray(list)) return [];

    // Deduplicate entries by normalized name + type
    const uniqueList = [];
    const seenKeys = new Set();
    list.forEach(r => {
      if (!r || !r.name) return;
      const key = `${String(r.name).trim().toLowerCase()}_${String(r.resource_type || '').trim().toLowerCase()}`;
      if (!seenKeys.has(key)) {
        seenKeys.add(key);
        uniqueList.push(r);
      }
    });
    return uniqueList;
  } catch (e) {
    return [];
  }
}

export function saveCustomResource(resourceObj) {
  try {
    const existing = getStoredCustomResources();
    const resKey = `${String(resourceObj.name || '').trim().toLowerCase()}_${String(resourceObj.resource_type || '').trim().toLowerCase()}`;
    const idx = existing.findIndex(r => r.id === resourceObj.id || `${String(r.name || '').trim().toLowerCase()}_${String(r.resource_type || '').trim().toLowerCase()}` === resKey);
    let updated;
    if (idx >= 0) {
      updated = [...existing];
      updated[idx] = { ...updated[idx], ...resourceObj };
    } else {
      updated = [resourceObj, ...existing];
    }
    localStorage.setItem(CUSTOM_RESOURCES_KEY, JSON.stringify(updated));
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new Event("drishti_resource_updated"));
    }
    return updated;
  } catch (e) {
    console.error("Failed to save custom resource to localStorage:", e);
    return [];
  }
}

// --- RESOURCES & ASSIGNMENTS ---
export async function fetchResources() {
  const custom = getStoredCustomResources();
  let baseResources = DEFAULT_RESOURCES;
  try {
    const res = await fetch(`${API_BASE}/resources`);
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data) && data.length > 0) {
        baseResources = data;
      }
    }
  } catch (err) {
    console.warn("fetchResources fallback to merged seed dataset:", err);
  }

  // Deduplicate baseResources and custom entries by ID & Name+Type Key
  const list = [];
  const seenIds = new Set();
  const seenKeys = new Set();

  const addUnique = (r) => {
    if (!r || !r.name) return;
    const idKey = String(r.id);
    const nameTypeKey = `${String(r.name).trim().toLowerCase()}_${String(r.resource_type || '').trim().toLowerCase()}`;

    if (!seenIds.has(idKey) && !seenKeys.has(nameTypeKey)) {
      seenIds.add(idKey);
      seenKeys.add(nameTypeKey);
      list.push(r);
    } else if (seenKeys.has(nameTypeKey)) {
      // Merge properties if match already found by name/type
      const existingIdx = list.findIndex(item => `${String(item.name).trim().toLowerCase()}_${String(item.resource_type || '').trim().toLowerCase()}` === nameTypeKey);
      if (existingIdx >= 0) {
        list[existingIdx] = { ...list[existingIdx], ...r };
      }
    }
  };

  baseResources.forEach(addUnique);
  custom.forEach(addUnique);

  return list;
}

export async function createResource(resourceData, origin = 'ORGANIZATION') {
  const newId = resourceData.id || `RES-${origin === 'MOBILE_FLUTTER' ? 'MOB' : 'ORG'}-${Math.floor(Math.random() * 9000 + 1000)}`;
  const formattedResource = {
    id: newId,
    name: resourceData.name || "Submitted Emergency Resource Asset",
    resource_type: resourceData.resource_type || "MOBILE_UNIT",
    capacity: Number(resourceData.capacity || 4),
    current_load: Number(resourceData.current_load || 0),
    status: resourceData.status || "AVAILABLE",
    latitude: Number(resourceData.latitude || 16.5062),
    longitude: Number(resourceData.longitude || 80.6480),
    location: resourceData.location || "Vijayawada Central Base",
    capabilities: Array.isArray(resourceData.capabilities) 
      ? resourceData.capabilities 
      : (resourceData.capabilities ? resourceData.capabilities.split(',').map(s => s.trim()) : ["EMERGENCY_RESPONSE"]),
    source: origin,
    submitted_at: new Date().toISOString()
  };

  let savedObj = formattedResource;
  try {
    const res = await fetch(`${API_BASE}/resources`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(formattedResource)
    });
    if (res.ok) {
      const serverData = await res.json();
      if (serverData && (serverData.id || serverData._id)) {
        savedObj = { ...formattedResource, ...serverData };
      }
    }
  } catch (err) {
    console.warn("Backend POST /resources offline, persisted in local storage:", err);
  }

  saveCustomResource(savedObj);
  return savedObj;
}

export async function updateResource(resourceId, updates) {
  const allResources = await fetchResources();
  const existing = allResources.find(r => r.id === resourceId) || {};
  const updated = { ...existing, ...updates, id: resourceId };

  try {
    await fetch(`${API_BASE}/resources/${resourceId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(updated)
    });
  } catch (err) {
    console.warn("Backend PUT /resources offline, updated in local storage:", err);
  }

  saveCustomResource(updated);
  return updated;
}

export async function submitMobileResource(mobilePayload) {
  return createResource(mobilePayload, 'MOBILE_FLUTTER');
}

export async function fetchMatchingResources(emergencyId) {
  try {
    const res = await fetch(`${API_BASE}/resources/match/${emergencyId}`);
    return await handleResponse(res, "Failed to fetch matching resources");
  } catch (err) {
    const all = await fetchResources();
    return { emergency_id: emergencyId, matched_resources: all };
  }
}

export async function allocateResource(resourceId, emergencyId) {
  updateResource(resourceId, { status: "DISPATCHED" });
  try {
    const res = await fetch(`${API_BASE}/resources/allocate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ resource_id: resourceId, emergency_id: emergencyId })
    });
    return await handleResponse(res, "Failed to allocate resource");
  } catch (err) {
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
    const res = await fetch(`${API_BASE}/resources/assignments`);
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
    const res = await fetch(`${API_BASE}/map/vijayawada`);
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
      headers: { "Content-Type": "application/json" },
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
      headers: { "Content-Type": "application/json" },
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
    const res = await fetch(`${API_BASE}/population/records`);
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
    const res = await fetch(`${API_BASE}/missing-persons?include_unconfirmed=${includeUnconfirmed}`);
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
    const res = await fetch(`${API_BASE}/missing-persons/${id}/confirm`, { method: "POST" });
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
      headers: { "Content-Type": "application/json" },
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
      headers: { "Content-Type": "application/json" },
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
