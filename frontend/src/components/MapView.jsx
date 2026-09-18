import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polygon } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix default Leaflet icon assets
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

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

export default function MapView({ emergencies = [], resources = [], zones = [], selectedEmergency = null, onSelectEmergency = () => {} }) {
  const defaultCenter = [12.9780, 77.5920];

  return (
    <div className="glass-panel" style={{ height: '520px', padding: 0, overflow: 'hidden', position: 'relative' }}>
      <MapContainer center={defaultCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {/* Polygon Overlays for Disaster Zones */}
        {zones.map((zone) => {
          const coords = zone.geometry_geojson?.coordinates?.[0] || [];
          const leafletPolygon = coords.map(([lon, lat]) => [lat, lon]);
          if (leafletPolygon.length === 0) return null;

          return (
            <Polygon
              key={zone.id}
              positions={leafletPolygon}
              pathOptions={{ color: '#ef4444', fillColor: '#ef4444', fillOpacity: 0.15, weight: 2 }}
            >
              <Popup>
                <div style={{ color: '#0f172a' }}>
                  <strong>{zone.name}</strong>
                  <br />
                  Code: {zone.code}
                  <br />
                  Expected Population: {zone.expected_population}
                </div>
              </Popup>
            </Polygon>
          );
        })}

        {/* Emergency Markers */}
        {emergencies.map((e) => (
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
                Category: {e.category}
                <br />
                Vulnerability Score: {e.vulnerability_score}
              </div>
            </Popup>
          </Marker>
        ))}

        {/* Resource Markers */}
        {resources.map((r) => (
          <Marker key={r.id} position={[r.latitude, r.longitude]} icon={resourceIcon}>
            <Popup>
              <div style={{ color: '#0f172a' }}>
                <strong style={{ color: '#3b82f6' }}>{r.name}</strong>
                <br />
                Type: {r.resource_type}
                <br />
                Status: {r.status}
                <br />
                Capabilities: {(r.capabilities || []).join(', ')}
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
