import React, { useState } from 'react';
import { allocateResource } from '../services/api';
import { rankMatchingOrganizations } from '../decision_engine/organizationMatcher';
import StatusBadge from './StatusBadge';
import { sendWebSocketEvent } from '../services/websocket';
import { ShieldCheck, X, CheckCircle2, ArrowRight, Package } from 'lucide-react';

export default function AllocateResourceModal({ emergency, resources = [], isOpen, onClose, onAllocationComplete }) {
  const [selectedResourceId, setSelectedResourceId] = useState('');
  const [allocating, setAllocating] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');

  if (!isOpen || !emergency) return null;

  const rankedCandidates = rankMatchingOrganizations(emergency, resources);

  const handleAllocate = async () => {
    const resId = selectedResourceId || rankedCandidates[0]?.resource_id;
    if (!resId) return;

    setAllocating(true);
    setSuccessMsg('');
    try {
      await allocateResource(resId, emergency.id);

      const payload = {
        event: "RESOURCE_ALLOCATED",
        emergency_id: emergency.id,
        resource_id: resId,
        timestamp: new Date().toISOString()
      };
      sendWebSocketEvent("RESOURCE_ALLOCATED", payload);

      setSuccessMsg(`Resource ${resId} successfully allocated and dispatched to ${emergency.title}!`);
      setAllocating(false);

      setTimeout(() => {
        if (onAllocationComplete) onAllocationComplete();
        onClose();
      }, 1500);
    } catch (err) {
      setAllocating(false);
      alert(err.message || "Failed to allocate resource");
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: '600px' }}>
        
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <div style={{ backgroundColor: 'var(--blue-light)', padding: '0.5rem', borderRadius: '8px' }}>
              <ShieldCheck size={22} color="var(--blue-primary)" />
            </div>
            <div>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                Allocate Resource to Incident
              </h3>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-sub)', margin: 0 }}>
                Parameter-Driven Decision Engine Candidate Ranking
              </p>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <X size={18} color="#64748B" />
          </button>
        </div>

        {successMsg && (
          <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700, marginBottom: '1rem' }}>
            <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
            {successMsg}
          </div>
        )}

        {/* Emergency Incident Context Card */}
        <div style={{ backgroundColor: '#F8FAFC', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', marginBottom: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
            <strong style={{ fontSize: '0.95rem', color: 'var(--navy-deep)' }}>{emergency.title}</strong>
            <StatusBadge status={emergency.priority_level} />
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', display: 'flex', gap: '1rem' }}>
            <span>Category: <strong>{emergency.category}</strong></span> •
            <span>Vulnerability Score: <strong style={{ color: 'var(--status-critical)' }}>{emergency.vulnerability_score}</strong></span> •
            <span>Affected: <strong>{emergency.affected_count}</strong></span>
          </div>
        </div>

        {/* Decision Engine Candidate Rankings */}
        <div style={{ marginBottom: '1rem' }}>
          <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
            Select Candidate Resource (Ranked by Decision Engine)
          </label>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxHeight: '240px', overflowY: 'auto' }}>
            {rankedCandidates.map((cand, idx) => (
              <div
                key={cand.resource_id}
                onClick={() => setSelectedResourceId(cand.resource_id)}
                style={{
                  padding: '0.75rem',
                  borderRadius: '6px',
                  border: (selectedResourceId === cand.resource_id || (!selectedResourceId && idx === 0)) ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                  backgroundColor: (selectedResourceId === cand.resource_id || (!selectedResourceId && idx === 0)) ? 'var(--blue-light)' : '#FFFFFF',
                  cursor: 'pointer'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexWrap: 'wrap' }}>
                      <span style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--blue-primary)' }}>
                        #{idx + 1} MATCH
                      </span>
                      <strong style={{ fontSize: '0.85rem', color: 'var(--navy-deep)' }}>{cand.name}</strong>
                      <span className="badge badge-navy" style={{ fontSize: '0.65rem' }}>{cand.resource_type}</span>
                      <span style={{ fontSize: '0.65rem', backgroundColor: '#F1F5F9', color: '#475569', padding: '1px 5px', borderRadius: '4px', fontWeight: 600 }}>
                        Source: {cand.source}
                      </span>
                    </div>
                    {cand.match_reasons && cand.match_reasons.length > 0 && (
                      <div style={{ fontSize: '0.7rem', color: '#16a34a', marginTop: '0.2rem', fontWeight: 600 }}>
                        ✓ {cand.match_reasons[0]}
                      </div>
                    )}
                  </div>
                  <div style={{ textAlign: 'right', minWidth: '100px' }}>
                    <div style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--blue-primary)' }}>{cand.match_score}% Match</div>
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ETA ~{cand.eta_minutes} mins</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Dispatch Action */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', borderTop: '1px solid var(--border-light)', paddingTop: '0.75rem' }}>
          <button className="btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn-primary" onClick={handleAllocate} disabled={allocating}>
            {allocating ? 'Dispatching...' : 'Confirm Allocation & Dispatch Resource'}
          </button>
        </div>

      </div>
    </div>
  );
}
