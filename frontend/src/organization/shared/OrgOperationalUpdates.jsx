import React from 'react';

export default function OrgOperationalUpdates() {
  return (
    <div className="glass-card" style={{ padding: '1.25rem' }}>
      <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
        OPERATIONAL UPDATES LOG
      </h3>
      <div style={{ fontSize: '0.85rem', color: 'var(--text-sub)' }}>
        Time-stamped audit records of all capacity, status, and field observations submitted to the command center.
      </div>
    </div>
  );
}
