import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import VijayawadaMap, { VIJAYAWADA_PLACES } from '../components/VijayawadaMap';
import { Radio, Signal, Battery, Cpu, Activity, RefreshCw, Send, CheckCircle2, AlertTriangle, MapPin, Zap } from 'lucide-react';

export default function LoRaSimulatorAdmin() {
  const [selectedPlaceId, setSelectedPlaceId] = useState("PRAKASAM");
  const [nodes, setNodes] = useState([
    {
      id: "LORA-NODE-01",
      name: "Node-Alpha (Prakasam Gateway)",
      location: "Prakasam Barrage Control Tower",
      freq: "868.1 MHz",
      rssi: -85,
      snr: 9.5,
      battery: 98,
      pdr: 99.2,
      hops: 1,
      status: "ONLINE",
      latitude: 16.5062,
      longitude: 80.6480,
      placeId: "PRAKASAM"
    },
    {
      id: "LORA-NODE-02",
      name: "Node-Beta (Auto Nagar Relay)",
      location: "Auto Nagar Industrial Staging",
      freq: "868.3 MHz",
      rssi: -102,
      snr: 4.2,
      battery: 84,
      pdr: 94.0,
      hops: 2,
      status: "ONLINE",
      latitude: 16.5120,
      longitude: 80.6600,
      placeId: "AUTO_NAGAR"
    },
    {
      id: "LORA-NODE-03",
      name: "Node-Gamma (Benz Circle Node)",
      location: "Benz Circle Traffic Relay",
      freq: "868.5 MHz",
      rssi: -94,
      snr: 7.8,
      battery: 91,
      pdr: 97.8,
      hops: 1,
      status: "ONLINE",
      latitude: 16.5000,
      longitude: 80.6550,
      placeId: "BENZ_CIRCLE"
    },
    {
      id: "LORA-NODE-04",
      name: "Node-Delta (Bandar Road Mesh)",
      location: "Bandar Road Low-Lying Sector",
      freq: "868.1 MHz",
      rssi: -112,
      snr: 1.5,
      battery: 72,
      pdr: 88.5,
      hops: 3,
      status: "LIMITED",
      latitude: 16.5090,
      longitude: 80.6380,
      placeId: "BANDAR_ROAD"
    }
  ]);

  const [packetLogs, setPacketLogs] = useState([
    {
      id: "PKT-8801",
      timestamp: new Date(Date.now() - 120000).toLocaleTimeString(),
      node_id: "LORA-NODE-01",
      payload: "0x454D473A20464C4F4F445F564A3031 (Emergency: Flood VJ01)",
      bytes: 28,
      rssi: -85,
      snr: 9.5,
      status: "DECODED_OK"
    },
    {
      id: "PKT-8802",
      timestamp: new Date(Date.now() - 60000).toLocaleTimeString(),
      node_id: "LORA-NODE-02",
      payload: "0x54454C454D3A20424154545F383456 (Telemetry: Battery 84%)",
      bytes: 24,
      rssi: -102,
      snr: 4.2,
      status: "DECODED_OK"
    }
  ]);

  const [txPayload, setTxPayload] = useState("EMERGENCY_RESCUE_REQ: Bandar Road Flood Evac");
  const [broadcastMsg, setBroadcastMsg] = useState('');

  const stringToHex = (str) => {
    let hex = '';
    for (let i = 0; i < str.length; i++) {
      hex += str.charCodeAt(i).toString(16).padStart(2, '0');
    }
    return hex.toUpperCase();
  };

  const handleSimulateBroadcast = () => {
    const activePlace = VIJAYAWADA_PLACES.find(p => p.id === selectedPlaceId) || VIJAYAWADA_PLACES[0];
    const newPkt = {
      id: `PKT-${Math.floor(Math.random()*9000 + 1000)}`,
      timestamp: new Date().toLocaleTimeString(),
      node_id: activePlace.nodeId,
      payload: `0x${stringToHex(txPayload)} (${txPayload})`,
      bytes: txPayload.length,
      rssi: activePlace.rssi,
      snr: activePlace.snr,
      status: "DECODED_OK"
    };

    setPacketLogs(prev => [newPkt, ...prev]);
    setBroadcastMsg(`Simulated LoRa 868MHz Mesh Packet Broadcasted from ${activePlace.name}!`);
    setTimeout(() => setBroadcastMsg(''), 4500);
  };

  const toggleNodeStatus = (id) => {
    setNodes(prev => prev.map(n => {
      if (n.id === id) {
        const nextState = n.status === 'ONLINE' ? 'OFFLINE' : 'ONLINE';
        return { ...n, status: nextState };
      }
      return n;
    }));
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            SOFTWARE-BASED LORA MESH RADIO NETWORK SIMULATOR
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Simulated 868MHz Radio Transport • Live 4-Place Vijayawada Mesh Topology & Telemetry
          </p>
        </div>

        <button className="btn-primary" onClick={handleSimulateBroadcast}>
          <Send size={16} /> Simulate LoRa Packet Broadcast
        </button>
      </div>

      {broadcastMsg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {broadcastMsg}
        </div>
      )}

      {/* Embedded Geospatial Leaflet Map Simulation over 4 Places */}
      <div className="glass-card" style={{ padding: '1rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
          <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Radio size={18} color="var(--blue-primary)" /> VIJAYAWADA LORA MESH RADIO MAP SIMULATION (4 PLACES)
          </h3>
          <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)', fontWeight: 600 }}>
            Click buttons or map nodes to focus simulation target
          </span>
        </div>

        <VijayawadaMap
          externalNodes={nodes}
          activeSimulationPlace={selectedPlaceId}
          onSelectPlace={(placeId) => setSelectedPlaceId(placeId)}
        />
      </div>

      {/* 4 LoRa Mesh Gateway Node Status Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1rem' }}>
        {nodes.map(n => {
          const isSelected = selectedPlaceId === n.placeId;
          return (
            <div
              key={n.id}
              className="glass-card"
              onClick={() => setSelectedPlaceId(n.placeId)}
              style={{
                padding: '1rem',
                borderLeft: `4px solid ${n.status === 'ONLINE' ? 'var(--status-safe)' : 'var(--status-critical)'}`,
                border: isSelected ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                backgroundColor: isSelected ? '#F0F7FF' : '#FFFFFF'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
                <div>
                  <strong style={{ fontSize: '0.9rem', color: 'var(--navy-deep)' }}>{n.name}</strong>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>{n.location}</div>
                </div>
                <StatusBadge status={n.status} />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem', fontSize: '0.75rem', marginTop: '0.75rem', backgroundColor: isSelected ? '#E2EFFE' : '#F8FAFC', padding: '0.65rem', borderRadius: '6px' }}>
                <div>RSSI: <strong style={{ color: 'var(--navy-deep)' }}>{n.rssi} dBm</strong></div>
                <div>SNR: <strong>{n.snr} dB</strong></div>
                <div>Battery: <strong style={{ color: n.battery < 80 ? 'var(--status-warning)' : 'var(--status-safe)' }}>{n.battery}%</strong></div>
                <div>PDR: <strong>{n.pdr}%</strong></div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '0.75rem' }}>
                <span style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>Freq: {n.freq} • Hops: {n.hops}</span>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleNodeStatus(n.id);
                  }}
                  style={{ fontSize: '0.7rem', border: '1px solid var(--border-color)', background: '#FFFFFF', padding: '0.2rem 0.5rem', borderRadius: '4px', cursor: 'pointer' }}
                >
                  Toggle {n.status === 'ONLINE' ? 'Offline' : 'Online'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Broadcast Simulator Form & Live Radio Packet Log */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        
        {/* Simulate Transmission */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            OFFLINE LORA RADIO PACKET TRANSMITTER
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                Simulated Radio Payload String
              </label>
              <textarea
                rows={3}
                value={txPayload}
                onChange={e => setTxPayload(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <button className="btn-primary" onClick={handleSimulateBroadcast} style={{ justifyContent: 'center' }}>
              <Send size={16} /> Broadcast Over 868MHz Mesh Radio
            </button>
          </div>
        </div>

        {/* Live Packet Log Table */}
        <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
          <div style={{ padding: '0.85rem 1rem', borderBottom: '1px solid var(--border-light)', background: '#F8FAFC' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
              LIVE LORA MESH PACKET DECODE LOG
            </h3>
          </div>

          <div style={{ maxHeight: '240px', overflowY: 'auto' }}>
            <table className="custom-table">
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Gateway Node</th>
                  <th>Decoded Payload (Hex / Text)</th>
                  <th>RSSI / SNR</th>
                </tr>
              </thead>
              <tbody>
                {packetLogs.map(p => (
                  <tr key={p.id}>
                    <td><span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>{p.timestamp}</span></td>
                    <td><strong>{p.node_id}</strong></td>
                    <td style={{ fontSize: '0.75rem', fontFamily: 'monospace' }}>{p.payload}</td>
                    <td>{p.rssi} dBm / {p.snr} dB</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>

    </div>
  );
}
