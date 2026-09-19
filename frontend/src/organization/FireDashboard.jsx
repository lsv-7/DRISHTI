import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import { sendWebSocketEvent } from '../services/websocket';
import { Flame, Anchor, Truck, AlertTriangle, CheckCircle2, ArrowRight } from 'lucide-react';

export default function FireDashboard({ orgData }) {
  const [assignmentState, setAssignmentState] = useState('EN_ROUTE'); // EN_ROUTE, ARRIVED, IN_PROGRESS, COMPLETED
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectModal, setShowRejectModal] = useState(false);

  const [fieldObs, setFieldObs] = useState('WATER_RESCUE_REQUIRED');
  const [obsMsg, setObsMsg] = useState('');

  const handleUpdateAssignmentState = (newState) => {
    setAssignmentState(newState);
    const payload = {
      event: "RESOURCE_STATUS_CHANGED",
      organization_id: orgData?.id || "F01",
      resource_id: "RES-001",
      assignment_status: newState,
      timestamp: new Date().toISOString()
    };
    sendWebSocketEvent("RESOURCE_STATUS_CHANGED", payload);
    setObsMsg(`Fire Rescue Team state updated to ${newState}`);
    setTimeout(() => setObsMsg(''), 4000);
  };

  const handleReportFieldObservation = (e) => {
    e.preventDefault();
    const payload = {
      event: "FIRE_FIELD_OBSERVATION",
      organization_id: orgData?.id || "F01",
      observation: fieldObs,
      timestamp: new Date().toISOString()
    };
    sendWebSocketEvent("FIRE_FIELD_OBSERVATION", payload);
    setObsMsg(`Fire Field Observation (${fieldObs}) reported!`);
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

      {/* Fire Fleet & Team Metrics */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-critical)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>RESCUE TEAMS</span>
            <Flame size={20} color="var(--status-critical)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-critical)', marginTop: '0.35rem' }}>
            6 <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>/ 8 Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>2 Teams Deployed</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid #0EA5E9' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>WATER RESCUE BOATS</span>
            <Anchor size={20} color="#0EA5E9" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#0EA5E9', marginTop: '0.35rem' }}>
            4 <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>High-Capacity Inflatable Boats</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-high)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>FIRE ENGINES</span>
            <Truck size={20} color="var(--status-high)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-high)', marginTop: '0.35rem' }}>
            8 <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Engines</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>High-Pressure Water Pumps</div>
        </div>

      </div>

      {/* Active Assignment Mission Workflow Tracker */}
      <div className="glass-card" style={{ padding: '1.25rem' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
          ACTIVE FIRE & RESCUE MISSION WORKFLOW
        </h3>

        <div style={{ padding: '1rem', borderRadius: '8px', border: '1px solid var(--border-color)', backgroundColor: '#F8FAFC', marginBottom: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
            <div>
              <strong style={{ fontSize: '0.95rem', color: 'var(--navy-deep)' }}>Incident #EMG-101: Bandar Road Inundation Rescue</strong>
              <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Assigned Team: Water Rescue Boat Unit 01</div>
            </div>
            <StatusBadge status={assignmentState} />
          </div>

          {/* Stepper Buttons */}
          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginTop: '0.75rem' }}>
            <button
              className={assignmentState === 'EN_ROUTE' ? 'btn-primary' : 'btn-secondary'}
              onClick={() => handleUpdateAssignmentState('EN_ROUTE')}
              style={{ fontSize: '0.8rem' }}
            >
              1. Mark EN_ROUTE
            </button>
            <button
              className={assignmentState === 'ARRIVED' ? 'btn-primary' : 'btn-secondary'}
              onClick={() => handleUpdateAssignmentState('ARRIVED')}
              style={{ fontSize: '0.8rem' }}
            >
              2. Mark ARRIVED
            </button>
            <button
              className={assignmentState === 'IN_PROGRESS' ? 'btn-primary' : 'btn-secondary'}
              onClick={() => handleUpdateAssignmentState('IN_PROGRESS')}
              style={{ fontSize: '0.8rem' }}
            >
              3. Mark IN_PROGRESS
            </button>
            <button
              className={assignmentState === 'COMPLETED' ? 'btn-primary' : 'btn-secondary'}
              onClick={() => handleUpdateAssignmentState('COMPLETED')}
              style={{ fontSize: '0.8rem', backgroundColor: assignmentState === 'COMPLETED' ? 'var(--status-safe)' : undefined }}
            >
              4. Mark COMPLETED
            </button>
          </div>
        </div>
      </div>

      {/* Field Observation Submission Form */}
      <div className="glass-card" style={{ padding: '1.25rem' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
          FIRE FIELD OBSERVATION REPORT
        </h3>

        <form onSubmit={handleReportFieldObservation} style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
          <select
            value={fieldObs}
            onChange={e => setFieldObs(e.target.value)}
            style={{ flex: 1, padding: '0.6rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
          >
            <option value="WATER_RESCUE_REQUIRED">WATER_RESCUE_REQUIRED</option>
            <option value="FIRE_SPREAD">FIRE_SPREAD</option>
            <option value="PERSON_TRAPPED">PERSON_TRAPPED</option>
            <option value="ROAD_BLOCKED">ROAD_BLOCKED</option>
            <option value="BUILDING_DAMAGED">BUILDING_DAMAGED</option>
            <option value="ADDITIONAL_TEAM_REQUIRED">ADDITIONAL_TEAM_REQUIRED</option>
            <option value="EQUIPMENT_FAILURE">EQUIPMENT_FAILURE</option>
          </select>

          <button type="submit" className="btn-primary">
            Submit Observation
          </button>
        </form>
      </div>

    </div>
  );
}
