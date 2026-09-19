import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import { sendWebSocketEvent } from '../services/websocket';
import { NavigationOff, GitMerge, AlertTriangle, CheckCircle2, ShieldCheck, RefreshCw } from 'lucide-react';

export default function RoadDashboard({ orgData }) {
  const [roads, setRoads] = useState([
    {
      id: "R12",
      name: "Prakasam Barrage Main Arterial Road",
      location: "Prakasam Barrage Sector",
      status: "BLOCKED",
      reason: "Severe Inundation & Debris Accumulation",
      reported_by: "Police Field Patrol 04",
      source_type: "POLICE_REPORT",
      verification_status: "VERIFIED",
      confidence: 0.95,
      affected_assignments_count: 2,
      last_updated: new Date().toISOString()
    },
    {
      id: "R20",
      name: "Eluru Road Alternate Bypass",
      location: "Eluru Sector",
      status: "OPEN",
      reason: "Clear Highway Corridor",
      reported_by: "Road Division Monitor",
      source_type: "AUTHORITY_SENSOR",
      verification_status: "VERIFIED",
      confidence: 1.0,
      affected_assignments_count: 0,
      last_updated: new Date().toISOString()
    }
  ]);

  const [selectedRoadId, setSelectedRoadId] = useState('R12');
  const [newStatus, setNewStatus] = useState('BLOCKED');
  const [blockageReason, setBlockageReason] = useState('Flooding & Submerged Asphalt');
  const [msg, setMsg] = useState('');

  const handleUpdateRoadStatus = (e) => {
    e.preventDefault();
    setRoads(prev => prev.map(r => r.id === selectedRoadId ? { ...r, status: newStatus, reason: blockageReason, last_updated: new Date().toISOString() } : r));

    // Broadcast ROAD_STATUS_CHANGED event to trigger Decision Engine Replanning Pipeline
    const payload = {
      event: "ROAD_STATUS_CHANGED",
      road_id: selectedRoadId,
      status: newStatus,
      reason: blockageReason,
      timestamp: new Date().toISOString()
    };
    sendWebSocketEvent("ROAD_STATUS_CHANGED", payload);

    setMsg(`Road ${selectedRoadId} status updated to ${newStatus}. Triggered Dynamic Replanning Pipeline!`);
    setTimeout(() => setMsg(''), 4000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {msg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {msg}
        </div>
      )}

      {/* Infrastructure Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-critical)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>BLOCKED ROADS</span>
            <NavigationOff size={20} color="var(--status-critical)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-critical)', marginTop: '0.35rem' }}>
            {roads.filter(r => r.status === 'BLOCKED').length} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Arterial Arteries</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--status-critical)', fontWeight: 600 }}>
            Prakasam Barrage R12 Inundated
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-safe)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>OPEN BYPASS ROUTES</span>
            <GitMerge size={20} color="var(--status-safe)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-safe)', marginTop: '0.35rem' }}>
            {roads.filter(r => r.status === 'OPEN').length} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Corridors</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Eluru Road R20 Bypass Open</div>
        </div>

      </div>

      {/* Road Pipeline Trigger & Management Form */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        
        {/* Update Road Status Form */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            REPORT ROAD BLOCKAGE & TRIGGER REPLANNING
          </h3>

          <form onSubmit={handleUpdateRoadStatus} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                Select Road Segment
              </label>
              <select
                value={selectedRoadId}
                onChange={e => setSelectedRoadId(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              >
                {roads.map(r => (
                  <option key={r.id} value={r.id}>{r.id}: {r.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                New Road Status
              </label>
              <select
                value={newStatus}
                onChange={e => setNewStatus(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              >
                <option value="OPEN">OPEN</option>
                <option value="PARTIALLY_BLOCKED">PARTIALLY_BLOCKED</option>
                <option value="BLOCKED">BLOCKED</option>
                <option value="RESTRICTED">RESTRICTED</option>
                <option value="UNKNOWN">UNKNOWN</option>
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                Reason / Debris Detail
              </label>
              <input
                type="text"
                value={blockageReason}
                onChange={e => setBlockageReason(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <button type="submit" className="btn-primary" style={{ justifyContent: 'center' }}>
              Broadcast Status & Trigger Replanning Engine
            </button>
          </form>
        </div>

        {/* Road Directory & Verification Table */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            INFRASTRUCTURE ROAD DIRECTORY
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            {roads.map(r => (
              <div key={r.id} style={{ padding: '0.75rem', borderRadius: '6px', border: '1px solid var(--border-color)', backgroundColor: '#FFFFFF' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <strong style={{ fontSize: '0.85rem', color: 'var(--navy-deep)' }}>{r.id}: {r.name}</strong>
                  <StatusBadge status={r.status} />
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Reason: {r.reason} • Reported By: {r.reported_by}
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.7rem', color: 'var(--status-safe)', fontWeight: 700, marginTop: '0.35rem' }}>
                  <span>✓ {r.verification_status} ({Math.round(r.confidence * 100)}% Confidence)</span>
                  <span style={{ color: 'var(--text-sub)' }}>{new Date(r.last_updated).toLocaleTimeString()}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
}
