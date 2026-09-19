import React from 'react';
import { History, ShieldCheck } from 'lucide-react';

export default function AuditLogsAdmin() {
  const logs = [
    { id: "LOG-1001", action: "OPERATIONAL_STATUS_CHANGED", entity: "Hospital H01", actor: "Admin Sarah Jenkins", timestamp: "12 mins ago", details: "Changed status from LIMITED to OPERATIONAL" },
    { id: "LOG-1002", action: "REPLAN_PROPOSAL_APPROVED", entity: "Replan RP-8812", actor: "Coordinator Commander", timestamp: "35 mins ago", details: "Approved bypass route R22 for Auto Nagar rescue" },
    { id: "LOG-1003", action: "RESOURCE_ALLOCATED", entity: "Boat Unit 01", actor: "Decision Engine", timestamp: "1 hour ago", details: "Matched to high vulnerability incident EMG-101" }
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          SYSTEM AUDIT LOGS & OPERATIONAL PROVENANCE
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Immutable Audit Trail for Consequential System Actions
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Log ID</th>
              <th>Consequential Action</th>
              <th>Target Entity</th>
              <th>Actor / Role</th>
              <th>Timestamp</th>
              <th>Audit Details</th>
            </tr>
          </thead>
          <tbody>
            {logs.map(l => (
              <tr key={l.id}>
                <td><strong>{l.id}</strong></td>
                <td><span className="badge badge-navy">{l.action}</span></td>
                <td>{l.entity}</td>
                <td>{l.actor}</td>
                <td><span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>{l.timestamp}</span></td>
                <td style={{ fontSize: '0.8rem' }}>{l.details}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
