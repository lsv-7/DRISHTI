import React, { useState } from 'react';
import { AlertTriangle, UserCheck, ShieldAlert, Navigation, ChevronRight, CheckCircle2 } from 'lucide-react';
import { fetchMatchingResources, allocateResource } from '../api';

export default function EmergencyPanel({ emergencies = [], selectedEmergency, setSelectedEmergency, onRefreshData }) {
  const [matchingResults, setMatchingResults] = useState(null);
  const [loadingMatch, setLoadingMatch] = useState(false);

  const handleMatchResources = async (emergency) => {
    setSelectedEmergency(emergency);
    setLoadingMatch(true);
    try {
      const res = await fetchMatchingResources(emergency.id);
      setMatchingResults(res.matched_resources || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoadingMatch(false);
    }
  };

  const getPriorityBadgeClass = (level) => {
    switch (level?.toUpperCase()) {
      case 'CRITICAL': return 'badge-critical';
      case 'HIGH': return 'badge-high';
      case 'MEDIUM': return 'badge-medium';
      default: return 'badge-low';
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
      {/* Emergency Queue */}
      <div className="glass-panel">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <AlertTriangle size={18} color="#ef4444" />
            Live Emergency Queue ({emergencies.length})
          </h2>
          <span className="badge badge-low">Vulnerability Adjusted</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', maxHeight: '480px', overflowY: 'auto', paddingRight: '0.25rem' }}>
          {emergencies.length === 0 ? (
            <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>No active emergencies reported.</p>
          ) : (
            emergencies.map((e) => (
              <div
                key={e.id}
                onClick={() => setSelectedEmergency(e)}
                style={{
                  background: selectedEmergency?.id === e.id ? 'rgba(59, 130, 246, 0.15)' : 'rgba(15, 23, 42, 0.5)',
                  border: selectedEmergency?.id === e.id ? '1px solid #3b82f6' : '1px solid var(--border-color)',
                  borderRadius: '10px',
                  padding: '1rem',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.5rem' }}>
                  <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
                    <span className={`badge ${getPriorityBadgeClass(e.priority_level)}`}>
                      {e.priority_level} ({e.priority_score})
                    </span>
                    {e.status === 'ASSIGNED' && (
                      <span className="badge badge-success" style={{ fontSize: '0.65rem' }}>
                        ASSIGNED & DISPATCHED
                      </span>
                    )}
                  </div>
                  <span style={{ fontSize: '0.75rem', color: '#94a3b8' }}>
                    {new Date(e.created_at).toLocaleTimeString()}
                  </span>
                </div>

                <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#f8fafc', marginBottom: '0.35rem' }}>{e.title}</h3>
                <p style={{ fontSize: '0.8rem', color: '#94a3b8', marginBottom: '0.6rem', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                  {e.description}
                </p>

                {/* Vulnerability factors */}
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '0.65rem' }}>
                  {e.vulnerability_score > 0 && (
                    <span style={{ fontSize: '0.7rem', color: '#fca5a5', background: 'rgba(239, 68, 68, 0.1)', padding: '0.15rem 0.4rem', borderRadius: '4px', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
                      Vulnerability Score: {e.vulnerability_score}
                    </span>
                  )}
                  <span style={{ fontSize: '0.7rem', color: '#93c5fd', background: 'rgba(59, 130, 246, 0.1)', padding: '0.15rem 0.4rem', borderRadius: '4px' }}>
                    Affected: {e.affected_count}
                  </span>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ fontSize: '0.75rem', color: '#94a3b8' }}>
                    Status: <strong style={{ color: e.status === 'ASSIGNED' ? '#3b82f6' : '#10b981' }}>{e.status}</strong>
                  </div>
                  <button
                    onClick={(evt) => { evt.stopPropagation(); handleMatchResources(e); }}
                    className="btn btn-primary"
                    style={{ padding: '0.3rem 0.65rem', fontSize: '0.75rem' }}
                  >
                    Match Resources <ChevronRight size={14} />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Capability Resource Matcher */}
      <div className="glass-panel">
        <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Navigation size={18} color="#3b82f6" />
          Capability & Vulnerability Resource Matcher
        </h2>

        {selectedEmergency ? (
          <div>
            <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.85rem', borderRadius: '8px', marginBottom: '1rem', border: '1px solid var(--border-color)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h4 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#3b82f6' }}>Target Emergency:</h4>
                <span className={`badge ${selectedEmergency.status === 'ASSIGNED' ? 'badge-success' : 'badge-low'}`}>
                  Status: {selectedEmergency.status}
                </span>
              </div>
              <p style={{ fontSize: '0.9rem', fontWeight: 600, marginTop: '0.2rem' }}>{selectedEmergency.title}</p>
              <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginTop: '0.25rem' }}>
                Priority Reasons: {(selectedEmergency.priority_reasons || []).join(' • ')}
              </div>
            </div>

            {loadingMatch ? (
              <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Running capability & vulnerability fit algorithms...</p>
            ) : matchingResults ? (
              <div>
                <h4 style={{ fontSize: '0.8rem', fontWeight: 700, color: '#94a3b8', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
                  Ranked Candidates ({matchingResults.length})
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', maxHeight: '340px', overflowY: 'auto' }}>
                  {matchingResults.map((r, idx) => (
                    <div key={r.id} style={{ background: 'rgba(30, 41, 59, 0.6)', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                        <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#f8fafc' }}>
                          #{idx + 1} {r.name}
                        </span>
                        <div style={{ display: 'flex', gap: '0.3rem', alignItems: 'center' }}>
                          {r.status === 'DISPATCHED' && (
                            <span className="badge badge-high" style={{ fontSize: '0.65rem' }}>DISPATCHED</span>
                          )}
                          <span className="badge badge-success" style={{ fontSize: '0.7rem' }}>
                            {r.match_score}% Match
                          </span>
                        </div>
                      </div>
                      <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginBottom: '0.35rem' }}>
                        {r.distance_km} km away • ETA ~{r.eta_minutes} mins • Status: <strong style={{ color: r.status === 'DISPATCHED' ? '#f59e0b' : '#10b981' }}>{r.status}</strong>
                      </div>
                      <div style={{ fontSize: '0.75rem', color: '#cbd5e1', marginBottom: '0.5rem' }}>
                        {(r.match_reasons || []).map((reason, i) => (
                          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                            <CheckCircle2 size={12} color="#10b981" /> {reason}
                          </div>
                        ))}
                      </div>

                      <button
                        onClick={async () => {
                          const res = await allocateResource(r.id, selectedEmergency.id);
                          if (res.status === 'SUCCESS') {
                            alert(res.message);
                            if (onRefreshData) await onRefreshData();
                            await handleMatchResources(selectedEmergency);
                          } else {
                            alert(res.message || 'Allocation failed');
                          }
                        }}
                        className={`btn ${r.status === 'DISPATCHED' ? 'btn-outline' : 'btn-primary'}`}
                        style={{ padding: '0.3rem 0.6rem', fontSize: '0.75rem', width: '100%', justifyContent: 'center' }}
                      >
                        <CheckCircle2 size={14} /> {r.status === 'DISPATCHED' ? 'Re-Dispatch / Re-Allocate Resource' : 'Allocate & Dispatch Resource'}
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            ) : (
              <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Click "Match Resources" on any emergency to generate capability rankings.</p>
            )}
          </div>
        ) : (
          <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Select an emergency from the queue to view vulnerability reasons and matching resources.</p>
        )}
      </div>
    </div>
  );
}
