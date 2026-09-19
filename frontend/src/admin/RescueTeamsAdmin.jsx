import React from 'react';
import StatusBadge from '../components/StatusBadge';
import { Users, Shield } from 'lucide-react';

export default function RescueTeamsAdmin() {
  const teams = [
    { id: "TEAM-01", name: "NDRF Water Rescue Squad 4", leader: "Insp. V. Kumar", members: 12, status: "AVAILABLE", zone: "Bandar Road Sector" },
    { id: "TEAM-02", name: "Fire & Rescue Boat Team Alpha", leader: "Capt. R. Sharma", members: 8, status: "DISPATCHED", zone: "Auto Nagar Flood Zone" }
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          ACTIVE RESCUE TEAMS & FIELD UNITS
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Deployed Responders & Special Operation Units
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Team Name</th>
              <th>Team Leader</th>
              <th>Personnel Count</th>
              <th>Assigned Sector Zone</th>
              <th>Operational Status</th>
            </tr>
          </thead>
          <tbody>
            {teams.map(t => (
              <tr key={t.id}>
                <td><strong style={{ color: 'var(--navy-deep)' }}>{t.name}</strong></td>
                <td>{t.leader}</td>
                <td>{t.members} Members</td>
                <td>{t.zone}</td>
                <td><StatusBadge status={t.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
