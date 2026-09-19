import React, { useState, useEffect } from 'react';
import { fetchMissingPersons, confirmMissingPerson, DEFAULT_MISSING_PERSONS } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { UserSearch, CheckCircle, Search, Filter } from 'lucide-react';

export default function MissingPersonsAdmin() {
  const [persons, setPersons] = useState(DEFAULT_MISSING_PERSONS);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  useEffect(() => {
    async function loadData() {
      const data = await fetchMissingPersons();
      setPersons((data && data.length > 0) ? data : DEFAULT_MISSING_PERSONS);
    }
    loadData();
  }, []);

  const handleConfirm = async (id) => {
    await confirmMissingPerson(id);
    setPersons(prev => prev.map(p => p.id === id ? { ...p, human_confirmed: true, status: "CONFIRMED_MISSING" } : p));
  };

  const filteredPersons = persons.filter(p => {
    const matchesSearch = p.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          p.source.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' ||
                          (statusFilter === 'CONFIRMED' && p.human_confirmed) ||
                          (statusFilter === 'PENDING' && !p.human_confirmed);
    return matchesSearch && matchesStatus;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            MISSING PERSON RECONCILIATION & CONFIRMATION GATE
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Mandatory Human Review Gate Before Public Confirmation & Broadcast
          </p>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="glass-card" style={{ padding: '0.85rem 1rem', display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flex: 1, minWidth: '220px' }}>
          <Search size={18} color="#64748B" />
          <input
            type="text"
            placeholder="Search missing persons by name or source..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            style={{ width: '100%', border: 'none', background: 'transparent', fontSize: '0.85rem', outline: 'none' }}
          />
        </div>

        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          style={{ padding: '0.4rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
        >
          <option value="ALL">All Confirmation States</option>
          <option value="PENDING">Pending Human Confirmation</option>
          <option value="CONFIRMED">Human Confirmed</option>
        </select>
      </div>

      {/* Table */}
      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Full Name & ID</th>
              <th>Age & Gender</th>
              <th>Source Provenance</th>
              <th>Human Confirmation Gate</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredPersons.map(p => (
              <tr key={p.id}>
                <td>
                  <strong style={{ color: 'var(--navy-deep)' }}>{p.full_name}</strong>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {p.id}</div>
                </td>
                <td>{p.age || 'N/A'} yrs • {p.gender || 'UNKNOWN'}</td>
                <td><span className="badge badge-navy">{p.source}</span></td>
                <td>
                  {p.human_confirmed ? (
                    <span style={{ color: 'var(--status-safe)', fontWeight: 700, fontSize: '0.8rem', display: 'inline-flex', alignItems: 'center', gap: '0.25rem' }}>
                      ✓ Human Confirmed
                    </span>
                  ) : (
                    <span style={{ color: 'var(--status-warning)', fontWeight: 700, fontSize: '0.8rem' }}>
                      Pending Confirmation
                    </span>
                  )}
                </td>
                <td><StatusBadge status={p.status} /></td>
                <td>
                  {!p.human_confirmed ? (
                    <button className="btn-primary" onClick={() => handleConfirm(p.id)} style={{ fontSize: '0.75rem', padding: '0.3rem 0.65rem' }}>
                      <CheckCircle size={14} /> Confirm Missing Person
                    </button>
                  ) : (
                    <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Reconciled</span>
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
