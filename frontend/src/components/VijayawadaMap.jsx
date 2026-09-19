import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon, Polyline, GeoJSON } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Eye, EyeOff, Layers, MapPin, Navigation } from 'lucide-react';

// Custom Leaflet Icons
const emergencyIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

const resourceIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

const shelterIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

const hospitalIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-violet.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

const loraIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-orange.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

const loraNodes = [
  { id: "LORA-NODE-01", name: "Node-Alpha (Prakasam Gateway)", lat: 16.5062, lon: 80.6480, freq: "868.1 MHz", rssi: -85, status: "ONLINE" },
  { id: "LORA-NODE-02", name: "Node-Beta (Auto Nagar Relay)", lat: 16.5120, lon: 80.6600, freq: "868.3 MHz", rssi: -102, status: "ONLINE" },
  { id: "LORA-NODE-03", name: "Node-Gamma (Benz Circle Node)", lat: 16.5000, lon: 80.6550, freq: "868.5 MHz", rssi: -94, status: "ONLINE" },
  { id: "LORA-NODE-04", name: "Node-Delta (Kothapeta Mobile Mesh)", lat: 16.5180, lon: 80.6320, freq: "868.1 MHz", rssi: -112, status: "LIMITED" }
];

export default function VijayawadaMap({
  emergencies = [],
  resources = [],
  selectedEmergency = null,
  onSelectEmergency = () => {}
}) {
  const vjCenter = [16.5062, 80.6480];

  const [mapData, setMapData] = useState(null);
  const [layers, setLayers] = useState({
    boundary: true,
    wards: true,
    roads: true,
    zones: true,
    emergencies: true,
    shelters: true,
    hospitals: true,
    resources: true,
    evacuation: true,
    blockedRoads: true,
    missingSearch: true,
    populationZones: true,
    loraMesh: true
  });
  const [showLayerControl, setShowLayerControl] = useState(false);

  useEffect(() => {
    async function loadVijayawadaData() {
      try {
        const res = await fetch('http://localhost:3000/api/v1/map/vijayawada');
        if (res.ok) {
          const data = await res.json();
          setMapData(data);
        }
      } catch (err) {
        console.error("Vijayawada map fetch error:", err);
      }
    }
    loadVijayawadaData();
  }, []);

  const toggleLayer = (key) => {
    setLayers((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="glass-panel" style={{ height: '560px', padding: 0, overflow: 'hidden', position: 'relative' }}>
      {/* Layer Toggle Floating Control Button */}
      <button
        onClick={() => setShowLayerControl(!showLayerControl)}
        className="btn btn-primary"
        style={{
          position: 'absolute',
          top: '12px',
          right: '12px',
          zIndex: 1000,
          boxShadow: '0 4px 12px rgba(0,0,0,0.5)',
          padding: '0.4rem 0.75rem',
          fontSize: '0.8rem'
        }}
      >
        <Layers size={16} /> Toggle Map Layers ({Object.values(layers).filter(Boolean).length}/12)
      </button>

      {/* Layer Toggle Panel */}
      {showLayerControl && (
        <div style={{
          position: 'absolute',
          top: '50px',
          right: '12px',
          zIndex: 1000,
          background: 'rgba(15, 23, 42, 0.95)',
          border: '1px solid var(--border-color)',
          borderRadius: '8px',
          padding: '1rem',
          maxWidth: '280px',
          maxHeight: '440px',
          overflowY: 'auto',
          backdropFilter: 'blur(12px)',
          boxShadow: '0 8px 32px rgba(0,0,0,0.6)'
        }}>
          <h4 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#3b82f6', marginBottom: '0.75rem', textTransform: 'uppercase' }}>
            12 Offline Layer Controls
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.45rem' }}>
            {[
              { key: 'boundary', label: '1. Vijayawada Boundary' },
              { key: 'wards', label: '2. Ward Boundaries (Demo)' },
              { key: 'roads', label: '3. Road Network (OSM)' },
              { key: 'zones', label: '4. Disaster Zones (DEMO)' },
              { key: 'emergencies', label: '5. Emergency Incidents' },
              { key: 'shelters', label: '6. Relief Shelters' },
              { key: 'hospitals', label: '7. Hospitals' },
              { key: 'resources', label: '8. Responders / Resources' },
              { key: 'evacuation', label: '9. Evacuation Routes' },
              { key: 'blockedRoads', label: '10. Blocked Roads (R12)' },
              { key: 'missingSearch', label: '11. Missing Search Areas' },
              { key: 'populationZones', label: '12. Population Zones' },
              { key: 'loraMesh', label: '13. LoRa Radio Mesh Nodes (868MHz)' }
            ].map((item) => (
              <label key={item.key} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: '#f8fafc', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={layers[item.key]}
                  onChange={() => toggleLayer(item.key)}
                  style={{ accentColor: '#3b82f6' }}
                />
                {item.label}
              </label>
            ))}
          </div>
        </div>
      )}

      {/* Map Container */}
      <MapContainer center={vjCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
        <TileLayer
          attribution='&copy; OpenStreetMap'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Layer 1: Boundary */}
        {layers.boundary && mapData?.boundary && (
          <GeoJSON
            data={mapData.boundary}
            style={{ color: '#3b82f6', weight: 3, fillOpacity: 0.05 }}
          />
        )}

        {/* Layer 2: Ward Boundaries */}
        {layers.wards && mapData?.wards && (
          <GeoJSON
            data={mapData.wards}
            style={{ color: '#06b6d4', weight: 1.5, dashArray: '4,4', fillOpacity: 0.08 }}
            onEachFeature={(feat, layer) => {
              layer.bindPopup(`<strong>${feat.properties.ward_name}</strong><br/>Expected Pop: ${feat.properties.expected_population}`);
            }}
          />
        )}

        {/* Layer 3: Road Network */}
        {layers.roads && mapData?.roads && (
          <GeoJSON
            data={mapData.roads}
            style={(feat) => ({
              color: feat.properties.id === 'R12' && layers.blockedRoads ? '#ef4444' : '#64748b',
              weight: 3,
              dashArray: feat.properties.id === 'R12' && layers.blockedRoads ? '6,6' : null
            })}
            onEachFeature={(feat, layer) => {
              layer.bindPopup(`<strong>${feat.properties.name}</strong><br/>Status: ${feat.properties.id === 'R12' && layers.blockedRoads ? 'BLOCKED' : 'OPEN'}`);
            }}
          />
        )}

        {/* Layer 4: Disaster Zones (DEMO) */}
        {layers.zones && mapData?.disaster_zones && (
          <GeoJSON
            data={mapData.disaster_zones}
            style={{ color: '#ef4444', fillColor: '#ef4444', fillOpacity: 0.25, weight: 2 }}
            onEachFeature={(feat, layer) => {
              layer.bindPopup(`<strong style="color:#ef4444">${feat.properties.name}</strong><br/>Water Level: ${feat.properties.water_level_meters}m<br/>Severity: ${feat.properties.severity}`);
            }}
          />
        )}

        {/* Layer 9: Evacuation Routes */}
        {layers.evacuation && mapData?.evacuation_routes && (
          <GeoJSON
            data={mapData.evacuation_routes}
            style={{ color: '#10b981', weight: 4 }}
            onEachFeature={(feat, layer) => {
              layer.bindPopup(`<strong>${feat.properties.name}</strong><br/>Destination: ${feat.properties.destination_shelter}`);
            }}
          />
        )}

        {/* Layer 5: Emergencies */}
        {layers.emergencies && emergencies.map((e) => (
          <Marker
            key={e.id}
            position={[e.latitude, e.longitude]}
            icon={emergencyIcon}
            eventHandlers={{ click: () => onSelectEmergency(e) }}
          >
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#ef4444' }}>{e.title}</strong>
                <br />
                Priority: {e.priority_level} ({e.priority_score})
                <br />
                Vulnerability Score: {e.vulnerability_score}
                <br />
                Affected: {e.affected_count} individuals
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Layer 8: Responders / Resources */}
        {layers.resources && resources.map((r) => (
          <Marker key={r.id} position={[r.latitude, r.longitude]} icon={resourceIcon}>
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#3b82f6' }}>{r.name}</strong>
                <br />
                Type: {r.resource_type} • Status: {r.status}
                <br />
                Capabilities: {(r.capabilities || []).join(', ')}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Layer 6: Shelters */}
        {layers.shelters && mapData?.shelters?.features?.map((sf, i) => (
          <Marker
            key={i}
            position={[sf.geometry.coordinates[1], sf.geometry.coordinates[0]]}
            icon={shelterIcon}
          >
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#10b981' }}>{sf.properties.name}</strong>
                <br />
                Capacity: {sf.properties.capacity} | Occupied: {sf.properties.occupied}
                <br />
                Available: {sf.properties.available} beds
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Layer 7: Hospitals */}
        {layers.hospitals && mapData?.hospitals?.features?.map((hf, i) => (
          <Marker
            key={i}
            position={[hf.geometry.coordinates[1], hf.geometry.coordinates[0]]}
            icon={hospitalIcon}
          >
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#8b5cf6' }}>{hf.properties.name}</strong>
                <br />
                Available Beds: {hf.properties.available_beds}
                <br />
                ICU Beds Available: {hf.properties.icu_beds_available}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Layer 13: LoRa Mesh Gateway Nodes */}
        {layers.loraMesh && loraNodes.map((node) => (
          <Marker
            key={node.id}
            position={[node.lat, node.lon]}
            icon={loraIcon}
          >
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#f97316' }}>📡 {node.name}</strong>
                <br />
                Freq: {node.freq} • RSSI: {node.rssi} dBm
                <br />
                Mesh Radio Status: <strong>{node.status}</strong>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      {/* Map Legend Overlay */}
      <div style={{
        position: 'absolute',
        bottom: '12px',
        left: '12px',
        zIndex: 1000,
        background: 'rgba(15, 23, 42, 0.9)',
        border: '1px solid var(--border-color)',
        borderRadius: '8px',
        padding: '0.6rem 0.85rem',
        backdropFilter: 'blur(8px)',
        fontSize: '0.7rem',
        color: '#f8fafc',
        display: 'flex',
        gap: '1rem',
        alignItems: 'center',
        flexWrap: 'wrap'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#ef4444', borderRadius: '50%' }}></span> Emergency</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#3b82f6', borderRadius: '50%' }}></span> Responder</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#10b981', borderRadius: '50%' }}></span> Shelter</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#8b5cf6', borderRadius: '50%' }}></span> Hospital</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#f97316', borderRadius: '50%' }}></span> LoRa 868MHz Node</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 12, height: 3, background: '#10b981' }}></span> Evacuation Corridor</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 12, height: 3, background: '#ef4444', borderStyle: 'dashed' }}></span> Blocked Road R12</div>
      </div>
    </div>
  );
}
