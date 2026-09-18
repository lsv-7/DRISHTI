import React, { useState, useEffect } from 'react';
import { BookOpen, FileCheck, Landmark, AlertCircle } from 'lucide-react';
import { resolveZonePolicies, fetchDisasterZones } from '../api';

export default function PolicyAdvisorPanel({ currentRole }) {
  const [zones, setZones] = useState([]);
  const [selectedZone, setSelectedZone] = useState(null);
  const [policies, setPolicies] = useState([]);
  const [reconstructionNorms, setReconstructionNorms] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function loadData() {
      const zList = await fetchDisasterZones();
      setZones(zList);
      if (zList.length > 0) {
        handleSelectZone(zList[0]);
      }
    }
    loadData();
  }, [currentRole]);

  const handleSelectZone = async (zone) => {
    setSelectedZone(zone);
    setLoading(true);
    try {
      const coords = zone.geometry_geojson?.coordinates?.[0]?.[0] || [77.5920, 12.9780];
      const res = await resolveZonePolicies(coords[1], coords[0], currentRole);
      setPolicies(res.applicable_policies || []);
      setReconstructionNorms(res.reconstruction_norms || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1.25rem' }}>
      {/* Zone Selector */}
      <div className="glass-panel">
        <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.85rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Landmark size={18} color="#06b6d4" />
          Active Disaster Zones
        </h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
          {zones.map((z) => (
            <div
              key={z.id}
              onClick={() => handleSelectZone(z)}
              style={{
                background: selectedZone?.id === z.id ? 'rgba(6, 182, 212, 0.15)' : 'rgba(15, 23, 42, 0.5)',
                border: selectedZone?.id === z.id ? '1px solid #06b6d4' : '1px solid var(--border-color)',
                borderRadius: '8px',
                padding: '0.85rem',
                cursor: 'pointer'
              }}
            >
              <div style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>{z.name}</div>
              <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginTop: '0.2rem' }}>
                Code: {z.code} • Pop: {z.expected_population}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Policies & Reconstruction Norms */}
      <div className="glass-panel">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <BookOpen size={18} color="#06b6d4" />
            Policy & Reconstruction Compliance Advisor
          </h2>
          <span className="badge badge-low">ADR-009 & ADR-011 Policy Engine</span>
        </div>

        {loading ? (
          <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Resolving zone policies for {currentRole}...</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {/* Reconstruction Norms Highlight */}
            {reconstructionNorms.length > 0 && (
              <div style={{ background: 'rgba(139, 92, 246, 0.15)', border: '1px solid rgba(139, 92, 246, 0.3)', borderRadius: '8px', padding: '0.85rem' }}>
                <h4 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#c084fc', display: 'flex', alignItems: 'center', gap: '0.4rem', marginBottom: '0.35rem' }}>
                  <FileCheck size={16} /> Post-Disaster Reconstruction Norms (Mandatory Surfacing)
                </h4>
                {reconstructionNorms.map((rn) => (
                  <div key={rn.id} style={{ fontSize: '0.8rem', color: '#e2e8f0', marginTop: '0.25rem' }}>
                    <strong>{rn.title}:</strong> {rn.description}
                    <div style={{ fontSize: '0.7rem', color: '#a78bfa', marginTop: '0.15rem' }}>
                      Source: {rn.source}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Applicable Zone Policies */}
            <div>
              <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#94a3b8', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
                Delivered Directives for {currentRole} ({policies.length})
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', maxHeight: '340px', overflowY: 'auto' }}>
                {policies.map((p) => (
                  <div key={p.id} style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.3rem' }}>
                      <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#f8fafc' }}>{p.title}</span>
                      <span className="badge badge-high" style={{ fontSize: '0.65rem' }}>{p.policy_type}</span>
                    </div>
                    <p style={{ fontSize: '0.8rem', color: '#cbd5e1', marginBottom: '0.35rem' }}>{p.description}</p>
                    <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>
                      Authority Source: {p.source || 'Municipal Authority'}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ fontSize: '0.75rem', color: '#94a3b8', fontStyle: 'italic', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
              <AlertCircle size={14} color="#06b6d4" />
              Policy information is sourced from official zone directives as a decision aid and does not constitute legal enforcement.
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
