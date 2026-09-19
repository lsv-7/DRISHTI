import React from 'react';
import StatusBadge from '../components/StatusBadge';
import { FileText, ShieldCheck } from 'lucide-react';

export default function PoliciesAdmin() {
  const policies = [
    { id: "POL-01", title: "Mandatory Low-Lying Evacuation Corridor Mandate", category: "EVACUATION", role_target: "ALL", reconstruction: false },
    { id: "POL-02", title: "Post-Flood Rainwater Harvesting Space Requirement for New Constructions", category: "RECONSTRUCTION", role_target: "AUTHORITY", reconstruction: true }
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          DISASTER ZONE POLICIES & RECONSTRUCTION ADVISOR
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Jurisdiction-Specific Legal Requirements, Emergency Policies & Post-Disaster Reconstruction Norms
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Policy ID & Title</th>
              <th>Category</th>
              <th>Target Audience</th>
              <th>Reconstruction Norm</th>
            </tr>
          </thead>
          <tbody>
            {policies.map(p => (
              <tr key={p.id}>
                <td><strong style={{ color: 'var(--navy-deep)' }}>{p.title}</strong></td>
                <td><span className="badge badge-navy">{p.category}</span></td>
                <td>{p.role_target}</td>
                <td>
                  {p.reconstruction ? (
                    <StatusBadge status="SAFE" text="RECONSTRUCTION NORM" />
                  ) : (
                    <StatusBadge status="WARNING" text="OPERATIONAL POLICY" />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
