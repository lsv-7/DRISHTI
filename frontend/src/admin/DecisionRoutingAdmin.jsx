import React, { useState, useEffect } from 'react';
import { rankMatchingOrganizations } from '../decision_engine/organizationMatcher';
import { fetchEmergencies, fetchResources, DEFAULT_EMERGENCIES, DEFAULT_RESOURCES } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { GitMerge, Cpu, ArrowRight, ShieldCheck, CheckCircle2 } from 'lucide-react';

export default function DecisionRoutingAdmin() {
  const [emergencies, setEmergencies] = useState(DEFAULT_EMERGENCIES);
  const [resources, setResources] = useState(DEFAULT_RESOURCES);
  const [selectedEmergency, setSelectedEmergency] = useState(DEFAULT_EMERGENCIES[0]);

  useEffect(() => {
    async function loadData() {
      const eList = await fetchEmergencies();
      const rList = await fetchResources();
      const validE = (eList && eList.length > 0) ? eList : DEFAULT_EMERGENCIES;
      const validR = (rList && rList.length > 0) ? rList : DEFAULT_RESOURCES;
      setEmergencies(validE);
      setResources(validR);
      if (validE.length > 0 && !selectedEmergency) setSelectedEmergency(validE[0]);
    }
    loadData();
  }, []);

  const rankedMatches = selectedEmergency ? rankMatchingOrganizations(selectedEmergency, resources) : [];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Title */}
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          DECISION ROUTING MATRIX & PARAMETER MATCHING
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Deterministic Evaluation of Organization Data Parameters (ICU, Beds, Patrols, Boats, Occupancy, Road Status)
        </p>
      </div>

      {/* Grid: Emergency Selection + Matching Matrix */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1.25rem' }}>
        
        {/* Incident Selector */}
        <div className="glass-card" style={{ padding: '1rem' }}>
          <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            Select Incident Context
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {emergencies.map(e => (
              <div
                key={e.id}
                onClick={() => setSelectedEmergency(e)}
                style={{
                  padding: '0.75rem',
                  borderRadius: '6px',
                  border: selectedEmergency?.id === e.id ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                  backgroundColor: selectedEmergency?.id === e.id ? 'var(--blue-light)' : '#FFFFFF',
                  cursor: 'pointer'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <strong style={{ fontSize: '0.85rem', color: 'var(--navy-deep)' }}>{e.title}</strong>
                  <StatusBadge status={e.priority_level} />
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Vulnerability Score: <strong style={{ color: 'var(--status-critical)' }}>{e.vulnerability_score}</strong>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Ranked Match Results Matrix */}
        <div className="glass-card" style={{ padding: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.5rem' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--navy-deep)' }}>
              DECISION MATCHING RANKINGS
            </h3>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
              Engine Mode: <strong style={{ color: 'var(--blue-primary)' }}>DETERMINISTIC VALIDATED</strong>
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {rankedMatches.map((m, idx) => (
              <div key={m.resource_id} style={{
                border: '1px solid var(--border-color)',
                borderRadius: '8px',
                padding: '0.85rem',
                backgroundColor: idx === 0 ? '#F0F9FF' : '#FFFFFF',
                borderColor: idx === 0 ? '#0EA5E9' : 'var(--border-color)'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                  <div>
                    <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#0EA5E9', marginRight: '0.5rem' }}>
                      #{idx + 1} RECOMMENDED
                    </span>
                    <strong style={{ fontSize: '0.95rem', color: 'var(--navy-deep)' }}>{m.name}</strong>
                    <span className="badge badge-navy" style={{ marginLeft: '0.5rem' }}>{m.resource_type}</span>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--blue-primary)' }}>
                      {m.match_score}% Match
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>ETA: ~{m.eta_minutes} mins</div>
                  </div>
                </div>

                <div style={{ fontSize: '0.75rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  <strong>Decision Reasons:</strong>
                  <ul style={{ paddingLeft: '1.2rem', marginTop: '0.25rem', color: 'var(--text-sub)' }}>
                    {m.match_reasons.map((r, i) => (
                      <li key={i}>{r}</li>
                    ))}
                  </ul>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
}
