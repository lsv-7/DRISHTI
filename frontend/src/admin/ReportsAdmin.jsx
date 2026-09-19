import React from 'react';
import { FileText, Download } from 'lucide-react';

export default function ReportsAdmin() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          COMPREHENSIVE OPERATIONAL REPORTS
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Post-Incident Analytics, Vulnerability Response Metrics & Resource Efficiency
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
            Daily Response Summary Report
          </h3>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)' }}>
            Summary of 14 emergency rescue operations, 4 hospital patient transfers, and 500+ shelter registrations.
          </p>
          <button className="btn-secondary" style={{ marginTop: '0.75rem' }}>
            <Download size={15} /> Export PDF Report
          </button>
        </div>

        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
            Supply Chain & Resource Audit Report
          </h3>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)' }}>
            Complete traceability audit log for relief commodities and vehicle fleet telemetry.
          </p>
          <button className="btn-secondary" style={{ marginTop: '0.75rem' }}>
            <Download size={15} /> Export CSV Audit Trace
          </button>
        </div>
      </div>
    </div>
  );
}
