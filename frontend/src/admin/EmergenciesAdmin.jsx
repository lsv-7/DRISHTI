import React, { useState, useEffect } from 'react';
import { fetchEmergencies, fetchResources, DEFAULT_EMERGENCIES, DEFAULT_RESOURCES } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import AllocateResourceModal from '../components/AllocateResourceModal';
import { AlertTriangle, Plus, Search, ShieldCheck } from 'lucide-react';

export default function EmergenciesAdmin() {
  const [emergencies, setEmergencies] = useState(DEFAULT_EMERGENCIES);
  const [resources, setResources] = useState(DEFAULT_RESOURCES);
  const [selectedEmergency, setSelectedEmergency] = useState(null);
  const [isAllocateOpen, setIsAllocateOpen] = useState(false);

  const loadData = async () => {
    const [eData, rData] = await Promise.all([fetchEmergencies(), fetchResources()]);
    setEmergencies((eData && eData.length > 0) ? eData : DEFAULT_EMERGENCIES);
    setResources((rData && rData.length > 0) ? rData : DEFAULT_RESOURCES);
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleOpenAllocate = (emergency) => {
    setSelectedEmergency(emergency);
    setIsAllocateOpen(true);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            EMERGENCY INCIDENTS & VULNERABILITY PRIORITY ENGINE
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Vulnerability-Adjusted Priority Scoring System & Resource Dispatch
          </p>
        </div>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Incident ID & Title</th>
              <th>Category</th>
              <th>Priority Level & Score</th>
              <th>Vulnerability Score</th>
              <th>Affected Count</th>
              <th>Status</th>
              <th>Submitted Timestamp</th>
              <th>Dispatch Action</th>
            </tr>
          </thead>
          <tbody>
            {emergencies.map(e => (
              <tr key={e.id}>
                <td>
                  <strong style={{ color: 'var(--navy-deep)' }}>{e.title}</strong>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {e.id}</div>
                </td>
                <td><span className="badge badge-navy">{e.category}</span></td>
                <td>
                  <StatusBadge status={e.priority_level} text={`${e.priority_level} (${e.priority_score})`} />
                </td>
                <td>
                  <strong style={{ color: 'var(--status-critical)' }}>{e.vulnerability_score}</strong>
                </td>
                <td>{e.affected_count} Individuals</td>
                <td><StatusBadge status={e.status} /></td>
                <td><span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>{new Date(e.created_at).toLocaleTimeString()}</span></td>
                <td>
                  <button
                    className="btn-primary"
                    style={{ padding: '0.35rem 0.65rem', fontSize: '0.75rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}
                    onClick={() => handleOpenAllocate(e)}
                  >
                    <ShieldCheck size={14} /> Allocate Resource
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <AllocateResourceModal
        emergency={selectedEmergency}
        resources={resources}
        isOpen={isAllocateOpen}
        onClose={() => setIsAllocateOpen(false)}
        onAllocationComplete={loadData}
      />
    </div>
  );
}
