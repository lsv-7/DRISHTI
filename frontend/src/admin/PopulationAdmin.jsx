import React, { useState, useEffect } from 'react';
import { fetchPopulationAccounting, DEFAULT_POPULATION_RECORDS } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { UserCheck, AlertTriangle, Search } from 'lucide-react';

export default function PopulationAdmin() {
  const [records, setRecords] = useState(DEFAULT_POPULATION_RECORDS);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    async function loadData() {
      const data = await fetchPopulationAccounting();
      setRecords((data && data.length > 0) ? data : DEFAULT_POPULATION_RECORDS);
    }
    loadData();
  }, []);

  const filteredRecords = records.filter(r => 
    r.zone_id.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            POPULATION ACCOUNTING & ZONE GAP INFERENCE
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Zone Population Census vs Shelter Registration Accounting Data
          </p>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="glass-card" style={{ padding: '0.85rem 1rem', display: 'flex', gap: '1rem', alignItems: 'center' }}>
        <Search size={18} color="#64748B" />
        <input
          type="text"
          placeholder="Filter population records by zone name or ID..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          style={{ width: '100%', border: 'none', background: 'transparent', fontSize: '0.85rem', outline: 'none' }}
        />
      </div>

      {/* Table */}
      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Zone ID & Sector</th>
              <th>Expected Census Population</th>
              <th>Accounted Population</th>
              <th>Unaccounted Gap Count</th>
              <th>Gap Percentage</th>
              <th>Accounting Status</th>
            </tr>
          </thead>
          <tbody>
            {filteredRecords.map(r => (
              <tr key={r.id}>
                <td><strong style={{ color: 'var(--navy-deep)' }}>{r.zone_id}</strong></td>
                <td>{r.expected_population.toLocaleString()} citizens</td>
                <td>{r.accounted_population.toLocaleString()} evacuated / sheltered</td>
                <td>
                  <strong style={{ color: r.gap_count > 1000 ? 'var(--status-critical)' : 'var(--status-warning)' }}>
                    {r.gap_count.toLocaleString()} Unaccounted
                  </strong>
                </td>
                <td>
                  <span className={`badge ${r.gap_percentage > 15 ? 'badge-critical' : 'badge-navy'}`}>
                    {r.gap_percentage}%
                  </span>
                </td>
                <td><StatusBadge status={r.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
