import React from 'react';
import StatusBadge from '../../components/StatusBadge';

export default function OrgIncidents() {
  return (
    <div className="glass-card" style={{ padding: '1.25rem' }}>
      <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
        ORGANIZATION INCIDENTS DIRECTORY
      </h3>
      <div style={{ fontSize: '0.85rem', color: 'var(--text-sub)' }}>
        Active emergency incidents requiring organization response or resource support.
      </div>
    </div>
  );
}
