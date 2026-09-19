import React, { useState, useEffect } from 'react';
import { fetchResources, DEFAULT_RESOURCES } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { Package, Plus } from 'lucide-react';

export default function ResourcesAdmin() {
  const [resources, setResources] = useState(DEFAULT_RESOURCES);

  useEffect(() => {
    async function loadData() {
      const data = await fetchResources();
      setResources((data && data.length > 0) ? data : DEFAULT_RESOURCES);
    }
    loadData();
  }, []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          HETEROGENEOUS RESOURCE ALLOCATIONS
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Rescue Boats, Ambulances, Medical Teams, Supplies & Heavy Equipment
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Resource Name</th>
              <th>Type</th>
              <th>Capacity / Load</th>
              <th>Status</th>
              <th>Capabilities</th>
            </tr>
          </thead>
          <tbody>
            {resources.map(r => (
              <tr key={r.id}>
                <td>
                  <strong style={{ color: 'var(--navy-deep)' }}>{r.name}</strong>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {r.id}</div>
                </td>
                <td><span className="badge badge-navy">{r.resource_type}</span></td>
                <td>{r.current_load} / {r.capacity} Capacity</td>
                <td><StatusBadge status={r.status} /></td>
                <td>
                  <div style={{ display: 'flex', gap: '0.25rem', flexWrap: 'wrap' }}>
                    {(r.capabilities || []).map((c, i) => (
                      <span key={i} style={{ fontSize: '0.7rem', background: '#F1F5F9', padding: '2px 6px', borderRadius: '4px' }}>
                        {c}
                      </span>
                    ))}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
