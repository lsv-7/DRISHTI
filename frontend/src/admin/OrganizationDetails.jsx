import React from 'react';
import { X, Building2, MapPin, Activity, CheckCircle, Clock, ShieldCheck, FileText } from 'lucide-react';
import StatusBadge from '../components/StatusBadge';

export default function OrganizationDetails({ org, onClose }) {
  if (!org) return null;

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: '680px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <div style={{ backgroundColor: 'var(--blue-light)', padding: '0.5rem', borderRadius: '8px' }}>
              <Building2 size={24} color="var(--blue-primary)" />
            </div>
            <div>
              <h2 style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                {org.name}
              </h2>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.8rem', color: 'var(--text-sub)' }}>
                <span>Type: <strong>{org.organization_type}</strong></span> •
                <span>ID: {org.id}</span>
              </div>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <X size={20} color="#64748B" />
          </button>
        </div>

        {/* Info Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
          <div style={{ backgroundColor: '#F8FAFC', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)', display: 'block', marginBottom: '0.25rem' }}>LOCATION</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.85rem', fontWeight: 600 }}>
              <MapPin size={15} color="var(--blue-primary)" />
              {org.location || 'Vijayawada Urban Zone'}
            </div>
          </div>

          <div style={{ backgroundColor: '#F8FAFC', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)', display: 'block', marginBottom: '0.25rem' }}>OPERATIONAL STATUS</span>
            <StatusBadge status={org.operational_status} />
          </div>

          <div style={{ backgroundColor: '#F8FAFC', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)', display: 'block', marginBottom: '0.25rem' }}>VERIFICATION STATUS</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.85rem', fontWeight: 600, color: 'var(--status-safe)' }}>
              <ShieldCheck size={15} />
              {org.verification_status || 'VERIFIED'}
            </div>
          </div>

          <div style={{ backgroundColor: '#F8FAFC', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)', display: 'block', marginBottom: '0.25rem' }}>ACTIVE ASSIGNMENTS</span>
            <div style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)' }}>
              {org.active_assignments || 0} Incident Assignments
            </div>
          </div>
        </div>

        {/* Organization Type-Specific Data Parameters */}
        <div style={{ marginBottom: '1.25rem' }}>
          <h3 style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
            OPERATIONAL DATA PARAMETERS
          </h3>
          <div style={{ backgroundColor: '#FFFFFF', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '0.85rem', fontSize: '0.85rem' }}>
            {org.organization_type === 'HOSPITAL' && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.75rem' }}>
                <div>Total Beds: <strong>{org.total_beds || 500}</strong></div>
                <div>Occupied: <strong>{org.occupied_beds || 380}</strong></div>
                <div>Available: <strong style={{ color: 'var(--status-safe)' }}>{(org.total_beds || 500) - (org.occupied_beds || 380)}</strong></div>
                <div>ICU Available: <strong style={{ color: org.icu_available > 0 ? 'var(--status-safe)' : 'var(--status-critical)' }}>{org.icu_available ?? 12}</strong></div>
                <div>Emergency Beds: <strong>{org.emergency_beds_available ?? 18}</strong></div>
                <div>Ambulances: <strong>{org.ambulances_available ?? 5}</strong></div>
              </div>
            )}

            {org.organization_type === 'POLICE' && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>Available Personnel: <strong>{org.personnel_available || 45}</strong></div>
                <div>Patrol Units: <strong>{org.patrol_units_available || 12}</strong></div>
                <div>Active Checkpoints: <strong>{org.active_checkpoints || 6}</strong></div>
                <div>Restricted Areas: <strong>2 Corridors</strong></div>
              </div>
            )}

            {org.organization_type === 'FIRE' && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>Fire Teams Available: <strong>{org.teams_available || 6}</strong></div>
                <div>Water Rescue Boats: <strong>{org.boats_available || 4}</strong></div>
                <div>Fire Engines: <strong>{org.fire_engines || 8}</strong></div>
                <div>Specialist Equipment: <strong>High-Cap Pumps</strong></div>
              </div>
            )}

            {org.organization_type === 'SHELTER' && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>Total Capacity: <strong>{org.capacity || 600}</strong></div>
                <div>Current Occupancy: <strong>{org.current_occupancy || 540}</strong></div>
                <div>Food Status: <StatusBadge status={org.food_status || 'ADEQUATE'} /></div>
                <div>Water Status: <StatusBadge status={org.water_status || 'HIGH_DEMAND'} /></div>
              </div>
            )}

            {org.organization_type === 'ROAD' && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>Blocked Roads Count: <strong style={{ color: 'var(--status-critical)' }}>{org.blocked_roads_count || 3}</strong></div>
                <div>Active Road Incidents: <strong>{org.active_incidents || 4}</strong></div>
                <div>Key Arterial R12: <StatusBadge status="BLOCKED" /></div>
                <div>Bypass R22: <StatusBadge status="OPEN" /></div>
              </div>
            )}
          </div>
        </div>

        {/* Operational Audit History */}
        <div>
          <h3 style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
            OPERATIONAL HISTORY & AUDIT LOG
          </h3>
          <div style={{ backgroundColor: '#F8FAFC', borderRadius: '8px', border: '1px solid var(--border-color)', padding: '0.75rem', fontSize: '0.75rem', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Status changed to <strong>{org.operational_status}</strong></span>
              <span style={{ color: 'var(--text-sub)' }}>12 mins ago by Admin</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span>Resource allocation acknowledged</span>
              <span style={{ color: 'var(--text-sub)' }}>45 mins ago by Operator</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
