import React, { useState, useEffect } from 'react';
import { fetchOrganizations, DEFAULT_ORGANIZATIONS } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import OrganizationDetails from './OrganizationDetails';
import { Building2, Search, Filter, Eye, Edit, ToggleLeft, ToggleRight, ShieldCheck, Plus } from 'lucide-react';

export default function OrganizationsManager() {
  const [organizations, setOrganizations] = useState(DEFAULT_ORGANIZATIONS);
  const [filterType, setFilterType] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedOrg, setSelectedOrg] = useState(null);

  useEffect(() => {
    async function loadOrgs() {
      const data = await fetchOrganizations();
      setOrganizations((data && data.length > 0) ? data : DEFAULT_ORGANIZATIONS);
    }
    loadOrgs();
  }, []);

  const filteredOrgs = organizations.filter(o => {
    const matchesType = filterType === 'ALL' || o.organization_type === filterType;
    const matchesSearch = o.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          o.organization_type.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesType && matchesSearch;
  });

  const toggleActivate = (id) => {
    setOrganizations(prev => prev.map(o => {
      if (o.id === id) {
        const nextStatus = o.operational_status === 'OFFLINE' ? 'OPERATIONAL' : 'OFFLINE';
        return { ...o, operational_status: nextStatus };
      }
      return o;
    }));
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Title Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            ORGANIZATION MANAGEMENT
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Single Reusable Organization Directory & Capability Control
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button className="btn-primary">
            <Plus size={16} /> Register New Organization
          </button>
        </div>
      </div>

      {/* Filter & Search Controls */}
      <div className="glass-card" style={{ padding: '1rem', display: 'flex', gap: '1rem', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between' }}>
        
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flex: 1, minWidth: '240px' }}>
          <Search size={18} color="#64748B" />
          <input
            type="text"
            placeholder="Search organizations by name or type..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            style={{
              width: '100%',
              padding: '0.5rem 0.75rem',
              borderRadius: '6px',
              border: '1px solid var(--border-color)',
              fontSize: '0.85rem'
            }}
          />
        </div>

        {/* Type Filter Tabs */}
        <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
          {['ALL', 'HOSPITAL', 'POLICE', 'FIRE', 'SHELTER', 'ROAD'].map(type => (
            <button
              key={type}
              onClick={() => setFilterType(type)}
              style={{
                backgroundColor: filterType === type ? 'var(--blue-primary)' : 'var(--bg-page)',
                color: filterType === type ? '#FFFFFF' : 'var(--text-main)',
                border: '1px solid var(--border-color)',
                borderRadius: '6px',
                padding: '0.4rem 0.75rem',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer'
              }}
            >
              {type}
            </button>
          ))}
        </div>

      </div>

      {/* Organization Table */}
      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Organization Name</th>
              <th>Type</th>
              <th>Location</th>
              <th>Operational Status</th>
              <th>Available Resources</th>
              <th>Active Assignments</th>
              <th>Last Updated</th>
              <th>Verification</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredOrgs.map(org => (
              <tr key={org.id}>
                <td>
                  <strong style={{ color: 'var(--navy-deep)' }}>{org.name}</strong>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {org.id}</div>
                </td>
                <td>
                  <span className="badge badge-navy">{org.organization_type}</span>
                </td>
                <td>{org.location || 'Vijayawada Central'}</td>
                <td>
                  <StatusBadge status={org.operational_status} />
                </td>
                <td>
                  <span style={{ fontSize: '0.85rem' }}>{org.available_resources || 'Resources Configured'}</span>
                </td>
                <td>
                  <strong>{org.active_assignments || 0}</strong> Active
                </td>
                <td>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
                    {new Date(org.last_updated).toLocaleTimeString()}
                  </span>
                </td>
                <td>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem', color: 'var(--status-safe)', fontWeight: 700, fontSize: '0.75rem' }}>
                    <ShieldCheck size={14} /> {org.verification_status || 'VERIFIED'}
                  </span>
                </td>
                <td>
                  <div style={{ display: 'flex', gap: '0.35rem' }}>
                    <button
                      onClick={() => setSelectedOrg(org)}
                      title="View Details"
                      style={{ background: 'var(--blue-light)', border: 'none', padding: '0.35rem 0.5rem', borderRadius: '4px', cursor: 'pointer', color: 'var(--blue-primary)' }}
                    >
                      <Eye size={15} />
                    </button>
                    <button
                      onClick={() => toggleActivate(org.id)}
                      title="Activate / Deactivate Status"
                      style={{ background: '#F1F5F9', border: 'none', padding: '0.35rem 0.5rem', borderRadius: '4px', cursor: 'pointer', color: org.operational_status === 'OFFLINE' ? 'var(--status-safe)' : 'var(--status-critical)' }}
                    >
                      {org.operational_status === 'OFFLINE' ? <ToggleLeft size={16} /> : <ToggleRight size={16} />}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Details Modal */}
      {selectedOrg && (
        <OrganizationDetails org={selectedOrg} onClose={() => setSelectedOrg(null)} />
      )}

    </div>
  );
}
