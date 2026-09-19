import React, { useState, useEffect } from 'react';
import { fetchAssignments } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { ShieldCheck, Clock } from 'lucide-react';

export default function AssignmentsAdmin() {
  const [assignments, setAssignments] = useState([]);

  useEffect(() => {
    async function loadData() {
      const data = await fetchAssignments();
      setAssignments(data);
    }
    loadData();
  }, []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          ACTIVE INCIDENT ASSIGNMENTS
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Dispatch Routing, ETA Tracking & Operational Progress
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Assignment ID</th>
              <th>Emergency Incident</th>
              <th>Priority</th>
              <th>Allocated Resource</th>
              <th>ETA</th>
              <th>Status</th>
              <th>Assigned Timestamp</th>
            </tr>
          </thead>
          <tbody>
            {assignments.map(a => (
              <tr key={a.id}>
                <td><strong>{a.id}</strong></td>
                <td><strong style={{ color: 'var(--navy-deep)' }}>{a.emergency_title}</strong></td>
                <td><StatusBadge status={a.emergency_priority || 'HIGH'} /></td>
                <td>{a.resource_name} ({a.resource_type})</td>
                <td>~{a.eta_minutes} mins</td>
                <td><StatusBadge status={a.status} /></td>
                <td><span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>{new Date(a.assigned_at).toLocaleTimeString()}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
