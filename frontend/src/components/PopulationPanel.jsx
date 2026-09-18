import React, { useState, useEffect } from 'react';
import { Users, AlertOctagon, UserPlus, CheckCircle, ShieldAlert } from 'lucide-react';
import { fetchPopulationAccounting, fetchMissingPersons, confirmMissingPerson } from '../api';

export default function PopulationPanel() {
  const [popRecords, setPopRecords] = useState([]);
  const [missingPersons, setMissingPersons] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const pRecs = await fetchPopulationAccounting();
      const mList = await fetchMissingPersons(true); // include unconfirmed for coordinator view
      setPopRecords(pRecs);
      setMissingPersons(mList);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleConfirmMissing = async (id) => {
    await confirmMissingPerson(id);
    loadData();
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
      {/* Population Accounting */}
      <div className="glass-panel">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Users size={18} color="#10b981" />
            Zone Population Accounting (ADR-010)
          </h2>
          <span className="badge badge-success">Live Reconciliation</span>
        </div>

        {loading ? (
          <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Calculating population discrepancies...</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            {popRecords.map((r) => (
              <div key={r.id} style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#f8fafc' }}>Zone ID: {r.zone_id}</span>
                  <span className={`badge ${r.status === 'CRITICAL' ? 'badge-critical' : r.status === 'ATTENTION' ? 'badge-high' : 'badge-success'}`}>
                    {r.status} ({r.gap_percentage}%)
                  </span>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.5rem', margin: '0.5rem 0', textAlign: 'center' }}>
                  <div style={{ background: 'rgba(30, 41, 59, 0.6)', padding: '0.4rem', borderRadius: '6px' }}>
                    <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Expected</div>
                    <div style={{ fontSize: '0.9rem', fontWeight: 700 }}>{r.expected_population}</div>
                  </div>
                  <div style={{ background: 'rgba(30, 41, 59, 0.6)', padding: '0.4rem', borderRadius: '6px' }}>
                    <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Accounted</div>
                    <div style={{ fontSize: '0.9rem', fontWeight: 700, color: '#10b981' }}>{r.accounted_population}</div>
                  </div>
                  <div style={{ background: 'rgba(30, 41, 59, 0.6)', padding: '0.4rem', borderRadius: '6px' }}>
                    <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Gap</div>
                    <div style={{ fontSize: '0.9rem', fontWeight: 700, color: '#ef4444' }}>{r.gap_count}</div>
                  </div>
                </div>

                {r.gap_percentage > 30 && (
                  <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', padding: '0.5rem', borderRadius: '6px', fontSize: '0.75rem', color: '#fca5a5', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    <AlertOctagon size={14} />
                    <strong>Human Review Required:</strong> Zone discrepancy alert dispatched to coordinator inbox.
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Missing Persons Verification Gate */}
      <div className="glass-panel">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <ShieldAlert size={18} color="#f59e0b" />
            Missing Persons (Human Confirmation Gate)
          </h2>
          <span className="badge badge-high">Coordinator Verification</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', maxHeight: '420px', overflowY: 'auto' }}>
          {missingPersons.length === 0 ? (
            <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>No missing person entries recorded.</p>
          ) : (
            missingPersons.map((mp) => (
              <div key={mp.id} style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#f8fafc' }}>{mp.full_name}</span>
                  <span className={`badge ${mp.human_confirmed ? 'badge-success' : 'badge-high'}`}>
                    {mp.human_confirmed ? 'HUMAN CONFIRMED' : 'UNCONFIRMED GATE'}
                  </span>
                </div>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginBottom: '0.4rem' }}>
                  Age: {mp.age || 'Unknown'} • Source: {mp.source} • Status: {mp.status}
                </div>

                {!mp.human_confirmed && (
                  <button
                    onClick={() => handleConfirmMissing(mp.id)}
                    className="btn btn-warning"
                    style={{ padding: '0.3rem 0.6rem', fontSize: '0.75rem', width: '100%', justifyContent: 'center' }}
                  >
                    <CheckCircle size={14} /> Coordinator Verify & Confirm Listing
                  </button>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
