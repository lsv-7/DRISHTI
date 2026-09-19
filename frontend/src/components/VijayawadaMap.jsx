import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon, Polyline, GeoJSON, Circle, Tooltip, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Eye, EyeOff, Layers, MapPin, Navigation, Radio, Zap, ShieldAlert, Send, Activity, CheckCircle2 } from 'lucide-react';

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

const loraIconOnline = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-orange.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [28, 45],
  iconAnchor: [14, 45],
  popupAnchor: [1, -34],
});

const loraIconActive = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [30, 48],
  iconAnchor: [15, 48],
  popupAnchor: [1, -34],
});

const loraIconOffline = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-grey.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

// 4 Specific Vijayawada Places for Simulation
export const VIJAYAWADA_PLACES = [
  {
    id: "PRAKASAM",
    name: "Prakasam Barrage Gateway",
    nodeId: "LORA-NODE-01",
    nodeName: "Node-Alpha (Prakasam Gateway)",
    lat: 16.5062,
    lon: 80.6480,
    freq: "868.1 MHz",
    rssi: -85,
    snr: 9.5,
    status: "ONLINE",
    role: "Primary Barrage Control Gateway",
    coverageRadius: 1500,
    color: "#3b82f6"
  },
  {
    id: "BANDAR_ROAD",
    name: "Bandar Road Low-Lying Sector",
    nodeId: "LORA-NODE-04",
    nodeName: "Node-Delta (Bandar Road Mesh)",
    lat: 16.5090,
    lon: 80.6380,
    freq: "868.1 MHz",
    rssi: -112,
    snr: 1.5,
    status: "LIMITED",
    role: "Inundated Residential Response Zone",
    coverageRadius: 1000,
    color: "#f59e0b"
  },
  {
    id: "BENZ_CIRCLE",
    name: "Benz Circle Junction Relay",
    nodeId: "LORA-NODE-03",
    nodeName: "Node-Gamma (Benz Circle Relay)",
    lat: 16.5000,
    lon: 80.6550,
    freq: "868.5 MHz",
    rssi: -94,
    snr: 7.8,
    status: "ONLINE",
    role: "Traffic Intersection Multi-Hop Router",
    coverageRadius: 1400,
    color: "#10b981"
  },
  {
    id: "AUTO_NAGAR",
    name: "Auto Nagar Staging Hub",
    nodeId: "LORA-NODE-02",
    nodeName: "Node-Beta (Auto Nagar Relay)",
    lat: 16.5120,
    lon: 80.6600,
    freq: "868.3 MHz",
    rssi: -102,
    snr: 4.2,
    status: "ONLINE",
    role: "Industrial Emergency Staging Area",
    coverageRadius: 1300,
    color: "#8b5cf6"
  }
];

// Component to programmatically pan/zoom map view
function MapPanController({ center, zoom }) {
  const map = useMap();
  useEffect(() => {
    if (center && center[0] && center[1]) {
      map.flyTo(center, zoom || 14, { duration: 1.2 });
    }
  }, [center, zoom, map]);
  return null;
}

export default function VijayawadaMap({
  emergencies = [],
  resources = [],
  selectedEmergency = null,
  onSelectEmergency = () => {},
  externalNodes = null,
  activeSimulationPlace = null,
  onSelectPlace = null
}) {
  const vjCenter = [16.5062, 80.6480];

  const [mapData, setMapData] = useState(null);
  const [selectedPlaceId, setSelectedPlaceId] = useState(activeSimulationPlace || "PRAKASAM");
  const [mapCenter, setMapCenter] = useState(vjCenter);
  const [mapZoom, setMapZoom] = useState(13.5);
  
  // Simulation Packet Hop State
  const [transmittingHop, setTransmittingHop] = useState(null); // null, 0, 1, 2
  const [isSimulatingPacket, setIsSimulatingPacket] = useState(false);
  const [lastPacketLog, setLastPacketLog] = useState(null);

  // Layer Visibility
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
    loraMesh: true,
    loraCoverage: true,
    loraHopPath: true
  });
  const [showLayerControl, setShowLayerControl] = useState(false);

  // Mesh nodes merging props or default places
  const currentNodes = externalNodes || VIJAYAWADA_PLACES.map(p => ({
    id: p.nodeId,
    name: p.nodeName,
    location: p.name,
    freq: p.freq,
    rssi: p.rssi,
    snr: p.snr,
    status: p.status,
    lat: p.lat,
    lon: p.lon,
    coverageRadius: p.coverageRadius,
    placeId: p.id
  }));

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

  useEffect(() => {
    if (activeSimulationPlace) {
      setSelectedPlaceId(activeSimulationPlace);
      const place = VIJAYAWADA_PLACES.find(p => p.id === activeSimulationPlace);
      if (place) {
        setMapCenter([place.lat, place.lon]);
        setMapZoom(14.5);
      }
    }
  }, [activeSimulationPlace]);

  const handlePlaceClick = (place) => {
    setSelectedPlaceId(place.id);
    setMapCenter([place.lat, place.lon]);
    setMapZoom(14.5);
    if (onSelectPlace) {
      onSelectPlace(place.id);
    }
  };

  const toggleLayer = (key) => {
    setLayers((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  // Trigger Live LoRa Mesh Packet Hop Simulation across the 4 Vijayawada Places
  const triggerPacketSimulation = () => {
    setIsSimulatingPacket(true);
    setTransmittingHop(0);
    setLastPacketLog({
      timestamp: new Date().toLocaleTimeString(),
      text: "SOS Packet originated at Bandar Road Low-Lying Sector..."
    });

    setTimeout(() => {
      setTransmittingHop(1);
      setLastPacketLog({
        timestamp: new Date().toLocaleTimeString(),
        text: "Relayed via Benz Circle 868.5MHz Mesh Router (RSSI: -94 dBm)"
      });
    }, 1200);

    setTimeout(() => {
      setTransmittingHop(2);
      setLastPacketLog({
        timestamp: new Date().toLocaleTimeString(),
        text: "Packet Received & Decoded at Prakasam Barrage Primary Gateway! (Status: OK)"
      });
    }, 2400);

    setTimeout(() => {
      setIsSimulatingPacket(false);
      setTransmittingHop(null);
    }, 3800);
  };

  // Mesh lines topology coordinates connecting 4 places
  const meshLines = [
    // Bandar Road (Node-Delta) -> Benz Circle (Node-Gamma)
    { from: [16.5090, 80.6380], to: [16.5000, 80.6550], label: "Mesh Link 1 (868.1MHz)", color: "#f59e0b", hopIdx: 0 },
    // Benz Circle (Node-Gamma) -> Prakasam Barrage (Node-Alpha)
    { from: [16.5000, 80.6550], to: [16.5062, 80.6480], label: "Mesh Link 2 (868.5MHz Backbone)", color: "#10b981", hopIdx: 1 },
    // Benz Circle (Node-Gamma) -> Auto Nagar (Node-Beta)
    { from: [16.5000, 80.6550], to: [16.5120, 80.6600], label: "Mesh Link 3 (868.3MHz Relay)", color: "#8b5cf6", hopIdx: 2 }
  ];

  // Flood Inundation Polygon over Bandar Road & River Bank
  const floodPolygonCoords = [
    [16.5080, 80.6350],
    [16.5110, 80.6400],
    [16.5075, 80.6450],
    [16.5040, 80.6390]
  ];

  return (
    <div className="glass-panel" style={{ height: '620px', padding: 0, overflow: 'hidden', position: 'relative', border: '1px solid var(--border-color)', borderRadius: '12px' }}>
      
      {/* Dynamic 4-Place Quick Selection Bar */}
      <div style={{
        position: 'absolute',
        top: '12px',
        left: '12px',
        zIndex: 1000,
        display: 'flex',
        gap: '0.5rem',
        flexWrap: 'wrap',
        maxWidth: 'calc(100% - 240px)'
      }}>
        {VIJAYAWADA_PLACES.map((p) => {
          const isSelected = selectedPlaceId === p.id;
          return (
            <button
              key={p.id}
              onClick={() => handlePlaceClick(p)}
              style={{
                background: isSelected ? 'var(--blue-primary)' : 'rgba(15, 23, 42, 0.85)',
                color: isSelected ? '#FFFFFF' : '#e2e8f0',
                border: isSelected ? '2px solid #60a5fa' : '1px solid var(--border-color)',
                borderRadius: '8px',
                padding: '0.4rem 0.75rem',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer',
                backdropFilter: 'blur(8px)',
                boxShadow: isSelected ? '0 0 12px rgba(59, 130, 246, 0.6)' : '0 2px 8px rgba(0,0,0,0.4)',
                display: 'flex',
                alignItems: 'center',
                gap: '0.35rem',
                transition: 'all 0.2s ease'
              }}
            >
              <Radio size={14} color={isSelected ? '#FFFFFF' : p.color} />
              {p.name}
            </button>
          );
        })}

        {/* Live Packet Simulation Trigger Button */}
        <button
          onClick={triggerPacketSimulation}
          disabled={isSimulatingPacket}
          style={{
            background: isSimulatingPacket ? '#059669' : 'linear-gradient(135deg, #10b981, #059669)',
            color: '#FFFFFF',
            border: 'none',
            borderRadius: '8px',
            padding: '0.4rem 0.85rem',
            fontSize: '0.75rem',
            fontWeight: 800,
            cursor: isSimulatingPacket ? 'wait' : 'pointer',
            boxShadow: '0 4px 14px rgba(16, 185, 129, 0.4)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.35rem'
          }}
        >
          <Zap size={14} className={isSimulatingPacket ? 'spin' : ''} />
          {isSimulatingPacket ? 'Transmitting Packet Across Mesh...' : 'Simulate 868MHz Mesh Hop'}
        </button>
      </div>

      {/* Layer Toggle Floating Button */}
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
          fontSize: '0.75rem'
        }}
      >
        <Layers size={14} /> Map Layers ({Object.values(layers).filter(Boolean).length}/13)
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
          maxHeight: '480px',
          overflowY: 'auto',
          backdropFilter: 'blur(12px)',
          boxShadow: '0 8px 32px rgba(0,0,0,0.6)'
        }}>
          <h4 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#3b82f6', marginBottom: '0.75rem', textTransform: 'uppercase' }}>
            Vijayawada Layer Controls
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.45rem' }}>
            {[
              { key: 'loraMesh', label: '📡 LoRa 868MHz Gateway Nodes (4 Places)' },
              { key: 'loraCoverage', label: '⭕ Radio Coverage Radii (Circles)' },
              { key: 'loraHopPath', label: '⚡ Active Mesh Signal Hop Lines' },
              { key: 'boundary', label: '1. Vijayawada Boundary' },
              { key: 'wards', label: '2. Ward Boundaries' },
              { key: 'roads', label: '3. Road Network (OSM)' },
              { key: 'zones', label: '4. Inundation Disaster Zones' },
              { key: 'emergencies', label: '5. Emergency Incidents' },
              { key: 'shelters', label: '6. Relief Shelters' },
              { key: 'hospitals', label: '7. Hospitals' },
              { key: 'resources', label: '8. Responders / Resources' },
              { key: 'evacuation', label: '9. Evacuation Routes' },
              { key: 'blockedRoads', label: '10. Blocked Roads (R12)' }
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

      {/* Live Simulation Banner Overlay */}
      {lastPacketLog && (
        <div style={{
          position: 'absolute',
          top: '56px',
          left: '12px',
          zIndex: 1000,
          background: 'rgba(15, 23, 42, 0.92)',
          border: '1px solid var(--blue-primary)',
          borderRadius: '8px',
          padding: '0.5rem 0.85rem',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          gap: '0.6rem',
          maxWidth: '520px',
          color: '#f8fafc',
          boxShadow: '0 4px 16px rgba(0,0,0,0.5)'
        }}>
          <Activity size={16} color="#10b981" className="spin" />
          <div style={{ fontSize: '0.75rem' }}>
            <span style={{ color: '#3b82f6', fontWeight: 700 }}>[{lastPacketLog.timestamp}]</span> {lastPacketLog.text}
          </div>
        </div>
      )}

      {/* Map Container */}
      <MapContainer center={vjCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
        <MapPanController center={mapCenter} zoom={mapZoom} />

        <TileLayer
          attribution='&copy; OpenStreetMap'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Boundary */}
        {layers.boundary && mapData?.boundary && (
          <GeoJSON
            data={mapData.boundary}
            style={{ color: '#3b82f6', weight: 3, fillOpacity: 0.05 }}
          />
        )}

        {/* Ward Boundaries */}
        {layers.wards && mapData?.wards && (
          <GeoJSON
            data={mapData.wards}
            style={{ color: '#06b6d4', weight: 1.5, dashArray: '4,4', fillOpacity: 0.08 }}
            onEachFeature={(feat, layer) => {
              layer.bindPopup(`<strong>${feat.properties.ward_name}</strong><br/>Expected Pop: ${feat.properties.expected_population}`);
            }}
          />
        )}

        {/* Road Network */}
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

        {/* Disaster Inundation Zone Overlay (Bandar Road Low-Lying Sector) */}
        {layers.zones && (
          <Polygon
            positions={floodPolygonCoords}
            pathOptions={{
              color: '#ef4444',
              fillColor: '#ef4444',
              fillOpacity: 0.3,
              weight: 2,
              dashArray: '4,4'
            }}
          >
            <Tooltip permanent direction="center" className="custom-leaflet-tooltip">
              <strong style={{ color: '#dc2626' }}>🌊 Bandar Road Flood Inundation Sector</strong>
              <br />Water Level: +2.1m Surge
            </Tooltip>
          </Polygon>
        )}

        {/* Evacuation Routes */}
        {layers.evacuation && mapData?.evacuation_routes && (
          <GeoJSON
            data={mapData.evacuation_routes}
            style={{ color: '#10b981', weight: 4 }}
            onEachFeature={(feat, layer) => {
              layer.bindPopup(`<strong>${feat.properties.name}</strong><br/>Destination: ${feat.properties.destination_shelter}`);
            }}
          />
        )}

        {/* Emergency Markers */}
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
                Affected: {e.affected_count} individuals
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Responders / Resources */}
        {layers.resources && resources.map((r) => (
          <Marker key={r.id} position={[r.latitude, r.longitude]} icon={resourceIcon}>
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#3b82f6' }}>{r.name}</strong>
                <br />
                Type: {r.resource_type} • Status: {r.status}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Shelters */}
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
                Capacity: {sf.properties.capacity} | Available: {sf.properties.available}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Hospitals */}
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
              </div>
            </Popup>
          </Marker>
        ))}

        {/* LoRa 868MHz Mesh Nodes across 4 Places */}
        {layers.loraMesh && VIJAYAWADA_PLACES.map((place) => {
          const isSelected = selectedPlaceId === place.id;
          const nodeIcon = isSelected 
            ? loraIconActive 
            : place.status === 'ONLINE' ? loraIconOnline : loraIconOffline;

          return (
            <React.Fragment key={place.id}>
              {/* Radio Signal Coverage Circle Radius */}
              {layers.loraCoverage && (
                <Circle
                  center={[place.lat, place.lon]}
                  radius={place.coverageRadius}
                  pathOptions={{
                    color: isSelected ? '#3b82f6' : place.color,
                    fillColor: place.color,
                    fillOpacity: isSelected ? 0.22 : 0.1,
                    weight: isSelected ? 2.5 : 1,
                    dashArray: isSelected ? '6,6' : null
                  }}
                />
              )}

              {/* Marker with Interactive Popup */}
              <Marker
                position={[place.lat, place.lon]}
                icon={nodeIcon}
                eventHandlers={{
                  click: () => handlePlaceClick(place)
                }}
              >
                <Tooltip permanent direction="top" offset={[0, -32]}>
                  <div style={{ fontWeight: 800, fontSize: '0.75rem', color: place.color }}>
                    📡 {place.name}
                  </div>
                </Tooltip>
                <Popup>
                  <div style={{ color: '#0f172a', minWidth: '200px' }}>
                    <div style={{ borderBottom: '1px solid #e2e8f0', pb: '0.35rem', mb: '0.35rem' }}>
                      <strong style={{ color: place.color, fontSize: '0.9rem' }}>📡 {place.name}</strong>
                      <div style={{ fontSize: '0.7rem', color: '#64748b' }}>{place.role}</div>
                    </div>
                    <div style={{ fontSize: '0.75rem', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.25rem', margin: '0.35rem 0' }}>
                      <div>Node ID: <strong>{place.nodeId}</strong></div>
                      <div>Freq: <strong>{place.freq}</strong></div>
                      <div>RSSI: <strong style={{ color: '#2563eb' }}>{place.rssi} dBm</strong></div>
                      <div>SNR: <strong>{place.snr} dB</strong></div>
                    </div>
                    <div style={{ fontSize: '0.7rem', background: '#f1f5f9', padding: '0.35rem', borderRadius: '4px', textAlign: 'center', fontWeight: 700, color: place.status === 'ONLINE' ? '#16a34a' : '#d97706' }}>
                      STATUS: {place.status} (Coverage: {place.coverageRadius}m)
                    </div>
                  </div>
                </Popup>
              </Marker>
            </React.Fragment>
          );
        })}

        {/* LoRa Mesh Signal Topology Links (`Polyline`) connecting the 4 places */}
        {layers.loraHopPath && meshLines.map((line, idx) => {
          const isHopActive = transmittingHop === line.hopIdx;
          return (
            <Polyline
              key={idx}
              positions={[line.from, line.to]}
              pathOptions={{
                color: isHopActive ? '#10b981' : line.color,
                weight: isHopActive ? 5 : 3,
                dashArray: isHopActive ? '8,8' : '4,4',
                opacity: isHopActive ? 1.0 : 0.75
              }}
            >
              <Tooltip sticky>
                <span style={{ fontSize: '0.7rem', fontWeight: 700 }}>
                  ⚡ {line.label} {isHopActive ? ' [ACTIVE HOP TRANSMITTING]' : ''}
                </span>
              </Tooltip>
            </Polyline>
          );
        })}

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
        gap: '0.85rem',
        alignItems: 'center',
        flexWrap: 'wrap'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#3b82f6', borderRadius: '50%' }}></span> Prakasam Gateway</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#f59e0b', borderRadius: '50%' }}></span> Bandar Road Low-Lying</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#10b981', borderRadius: '50%' }}></span> Benz Circle Junction</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 10, height: 10, background: '#8b5cf6', borderRadius: '50%' }}></span> Auto Nagar Staging</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><span style={{ width: 14, height: 3, background: '#10b981', borderStyle: 'dashed' }}></span> 868MHz Mesh Hop</div>
      </div>
    </div>
  );
}

