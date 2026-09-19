import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import { sendWebSocketEvent } from '../services/websocket';
import { Shield, ShieldAlert, Users, Car, AlertTriangle, Plus, CheckCircle2 } from 'lucide-react';

export default function PoliceDashboard({ orgData }) {
  const [personnelAvailable, setPersonnelAvailable] = useState(45);
  const [patrolUnitsAvailable, setPatrolUnitsAvailable] = useState(12);
  const [activeCheckpoints, setActiveCheckpoints] = useState(6);

  const [obsType, setObsType] = useState('ROAD_BLOCKED');
  const [location, setLocation] = useState('Prakasam Barrage Approach Road');
  const [obsMsg, setObsMsg] = useState('');

  const handleReportObservation = (e) => {
    e.preventDefault();
    const payload = {
      event: "SECURITY_OBSERVATION",
      organization_id: orgData?.id || "P01",
      observation_type: obsType,
      location_name: location,
      status: "RESTRICTED",
      reported_by: "Police Field Unit 04",
      timestamp: new Date().toISOString()
    };
    sendWebSocketEvent("SECURITY_OBSERVATION", payload);
    setObsMsg(`Security Field Observation (${obsType}) submitted to Command Center!`);
    setTimeout(() => setObsMsg(''), 4000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {obsMsg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {obsMsg}
        </div>
      )}

      {/* Police Metrics Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--navy-deep)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>AVAILABLE PERSONNEL</span>
            <Users size={20} color="var(--navy-deep)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--navy-deep)', marginTop: '0.35rem' }}>
            {personnelAvailable} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Officers</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>15 Deployed on Evacuation</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--blue-primary)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>PATROL UNITS</span>
            <Car size={20} color="var(--blue-primary)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--blue-primary)', marginTop: '0.35rem' }}>
            {patrolUnitsAvailable} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Units</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>4 Active Sector Patrols</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-warning)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>ACTIVE CHECKPOINTS</span>
            <ShieldAlert size={20} color="var(--status-warning)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#B45309', marginTop: '0.35rem' }}>
            {activeCheckpoints} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Locations</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Perimeter Security Control</div>
        </div>

      </div>

      {/* Field Observation Form & Active Incidents */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        
        {/* Submit Field Observation */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            SUBMIT VERIFIED POLICE FIELD OBSERVATION
          </h3>

          <form onSubmit={handleReportObservation} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                Observation Type
              </label>
              <select
                value={obsType}
                onChange={e => setObsType(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              >
                <option value="ROAD_BLOCKED">ROAD_BLOCKED</option>
                <option value="AREA_RESTRICTED">AREA_RESTRICTED</option>
                <option value="TRAFFIC_DISRUPTION">TRAFFIC_DISRUPTION</option>
                <option value="SECURITY_INCIDENT">SECURITY_INCIDENT</option>
                <option value="EVACUATION_SUPPORT_REQUIRED">EVACUATION_SUPPORT_REQUIRED</option>
              </select>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                Location Name / Sector
              </label>
              <input
                type="text"
                value={location}
                onChange={e => setLocation(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <button type="submit" className="btn-primary" style={{ justifyContent: 'center' }}>
              Broadcast Security Observation
            </button>
          </form>
        </div>

        {/* Active Police Incidents */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            ACTIVE POLICE SECURITY ASSIGNMENTS
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            <div style={{ padding: '0.65rem', borderRadius: '6px', border: '1px solid var(--border-color)', backgroundColor: '#FFFFFF' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                <strong>Prakasam Barrage Perimeter Blockade</strong>
                <StatusBadge status="IN_PROGRESS" />
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', marginTop: '0.2rem' }}>
                Assigned Unit: Patrol 04 • Status: Restricting flood traffic
              </div>
            </div>

            <div style={{ padding: '0.65rem', borderRadius: '6px', border: '1px solid var(--border-color)', backgroundColor: '#FFFFFF' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                <strong>Shelter S01 Crowd Control</strong>
                <StatusBadge status="ACTIVE" />
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', marginTop: '0.2rem' }}>
                Assigned Unit: Patrol 02 • Status: Assisting registration queue
              </div>
            </div>
          </div>
        </div>

      </div>

    </div>
  );
}
