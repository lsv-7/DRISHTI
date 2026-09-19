import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import { updateOrganizationStatus } from '../services/api';
import { Building2, MapPin, Activity, ShieldCheck, Clock, RefreshCw } from 'lucide-react';

export default function CommonOrgHeader({ orgData, onStatusUpdated }) {
  const [currentStatus, setCurrentStatus] = useState(orgData.operational_status || 'OPERATIONAL');
  const [reason, setReason] = useState('');
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [lastSync, setLastSync] = useState(new Date().toLocaleTimeString());

  const handleStatusChange = async (newStatus) => {
    const prevStatus = currentStatus;
    setCurrentStatus(newStatus);
    const auditRecord = {
      organization_id: orgData.id,
      previous_status: prevStatus,
      new_status: newStatus,
      updated_by: "Org Admin / Operator",
      timestamp: new Date().toISOString(),
      reason: reason || "Routine operational status update"
    };

    await updateOrganizationStatus(orgData.id, auditRecord);
    setLastSync(new Date().toLocaleTimeString());
    setShowStatusModal(false);
    if (onStatusUpdated) onStatusUpdated(newStatus, auditRecord);
  };

  return (
    <div style={{
      backgroundColor: '#FFFFFF',
      border: '1px solid var(--border-color)',
      borderRadius: 'var(--radius-md)',
      padding: '1.25rem',
      marginBottom: '1.25rem',
      boxShadow: 'var(--shadow-sm)'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem' }}>
        
        {/* Left Org Details */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
          <div style={{
            backgroundColor: 'var(--blue-light)',
            padding: '0.75rem',
            borderRadius: '10px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Building2 size={30} color="var(--blue-primary)" />
          </div>

          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <h2 style={{ fontSize: '1.3rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                {orgData.name}
              </h2>
              <span className="badge badge-navy">{orgData.organization_type}</span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.35rem', flexWrap: 'wrap' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                <MapPin size={14} color="var(--blue-primary)" /> {orgData.location || 'Vijayawada Urban Sector'}
              </span>
              <span>Zone: <strong>Vijayawada Central 01</strong></span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                <Clock size={14} /> Last Synced: <strong>{lastSync}</strong>
              </span>
            </div>
          </div>
        </div>

        {/* Prominent Operational Status Control */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', backgroundColor: '#F8FAFC', padding: '0.65rem 1rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
          <div>
            <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--text-sub)', textTransform: 'uppercase' }}>
              Operational Status Control
            </div>
            <div style={{ marginTop: '0.2rem' }}>
              <StatusBadge status={currentStatus} />
            </div>
          </div>

          <button
            className="btn-primary"
            onClick={() => setShowStatusModal(true)}
            style={{ fontSize: '0.8rem', padding: '0.4rem 0.75rem' }}
          >
            Update Status
          </button>
        </div>

      </div>

      {/* Overview Stat Strip */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
        gap: '0.75rem',
        marginTop: '1rem',
        paddingTop: '0.85rem',
        borderTop: '1px solid var(--border-light)'
      }}>
        <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)' }}>
          Active Assignments: <strong style={{ color: 'var(--navy-deep)' }}>{orgData.active_assignments || 3}</strong>
        </div>
        <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)' }}>
          Pending Requests: <strong style={{ color: 'var(--status-high)' }}>2 Pending</strong>
        </div>
        <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)' }}>
          Critical Alerts: <strong style={{ color: 'var(--status-critical)' }}>1 Active Alert</strong>
        </div>
        <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)' }}>
          Available Resources: <strong style={{ color: 'var(--status-safe)' }}>{orgData.available_resources || 'Operational'}</strong>
        </div>
      </div>

      {/* Status Change Modal */}
      {showStatusModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '460px' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
              Update Organization Operational Status
            </h3>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginBottom: '1rem' }}>
              Select new operational state. Every status change logs an audit record with timestamp and reason.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginBottom: '1rem' }}>
              {['OPERATIONAL', 'LIMITED', 'OVERLOADED', 'UNAVAILABLE', 'OFFLINE'].map(st => (
                <button
                  key={st}
                  onClick={() => handleStatusChange(st)}
                  style={{
                    display: 'flex',
                    justify: 'space-between',
                    alignItems: 'center',
                    padding: '0.65rem 0.85rem',
                    borderRadius: '6px',
                    border: currentStatus === st ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                    backgroundColor: currentStatus === st ? 'var(--blue-light)' : '#FFFFFF',
                    cursor: 'pointer'
                  }}
                >
                  <span style={{ fontWeight: 700, fontSize: '0.85rem' }}>{st}</span>
                  <StatusBadge status={st} />
                </button>
              ))}
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.35rem' }}>
                Reason for Status Change
              </label>
              <input
                type="text"
                placeholder="e.g. Surge in patient arrivals / Equipment failure"
                value={reason}
                onChange={e => setReason(e.target.value)}
                style={{ width: '100%', padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', marginTop: '1rem' }}>
              <button className="btn-secondary" onClick={() => setShowStatusModal(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
