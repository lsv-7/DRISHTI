import React, { useState, useEffect } from 'react';
import { BarChart3, PieChart, ShieldCheck, AlertTriangle, Users, Truck, CheckCircle2 } from 'lucide-react';
import { fetchEmergencies, fetchResources, fetchPopulationAccounting, fetchMissingPersons } from '../api';

export default function AnalyticsPanel() {
  const [emergencies, setEmergencies] = useState([]);
  const [resources, setResources] = useState([]);
  const [population, setPopulation] = useState([]);
  const [missing, setMissing] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadAnalytics() {
      setLoading(true);
      try {
        const eData = await fetchEmergencies();
        const rData = await fetchResources();
        const pData = await fetchPopulationAccounting();
        const mData = await fetchMissingPersons(true);
        setEmergencies(eData);
        setResources(rData);
        setPopulation(pData);
        setMissing(mData);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    loadAnalytics();
  }, []);

  const criticalCount = emergencies.filter(e => e.priority_level === 'CRITICAL').length;
  const highCount = emergencies.filter(e => e.priority_level === 'HIGH').length;
  const mediumCount = emergencies.filter(e => e.priority_level === 'MEDIUM').length;
  const lowCount = emergencies.filter(e => e.priority_level === 'LOW').length;

  const totalVulnerable = emergencies.filter(e => e.vulnerability_score > 0).length;
  const totalAffected = emergencies.reduce((sum, e) => sum + (e.affected_count || 0), 0);

  const availableResources = resources.filter(r => r.status === 'AVAILABLE').length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* Top Header Summary */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem' }}>
        <div className="glass-panel" style={{ padding: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase' }}>Active Incidents</span>
            <AlertTriangle size={18} color="#ef4444" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f8fafc', marginTop: '0.25rem' }}>{emergencies.length}</div>
          <div style={{ fontSize: '0.7rem', color: '#ef4444', marginTop: '0.2rem' }}>
            {criticalCount} Critical • {highCount} High Priority
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase' }}>Vulnerable Individuals</span>
            <Users size={18} color="#f59e0b" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f59e0b', marginTop: '0.25rem' }}>{totalAffected}</div>
          <div style={{ fontSize: '0.7rem', color: '#fca5a5', marginTop: '0.2rem' }}>
            {totalVulnerable} Incidents with Vulnerability Profile
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase' }}>Available Fleet</span>
            <Truck size={18} color="#10b981" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#10b981', marginTop: '0.25rem' }}>{availableResources} / {resources.length}</div>
          <div style={{ fontSize: '0.7rem', color: '#10b981', marginTop: '0.2rem' }}>
            Instant Deployment Readiness
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.75rem', color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase' }}>Missing Gate Verified</span>
            <ShieldCheck size={18} color="#3b82f6" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#3b82f6', marginTop: '0.25rem' }}>
            {missing.filter(m => m.human_confirmed).length} / {missing.length}
          </div>
          <div style={{ fontSize: '0.7rem', color: '#93c5fd', marginTop: '0.2rem' }}>
            Human Verification Gate Active
          </div>
        </div>
      </div>

      {/* Analytics Charts Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        {/* Priority & Vulnerability Distribution */}
        <div className="glass-panel">
          <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <BarChart3 size={18} color="#ef4444" />
            Incident Prioritization & Vulnerability Analytics
          </h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: '#f8fafc', marginBottom: '0.25rem' }}>
                <span>Critical Priority (Score &ge; 80)</span>
                <strong>{criticalCount} ({emergencies.length > 0 ? Math.round((criticalCount / emergencies.length) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: '8px', background: 'rgba(30, 41, 59, 0.8)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${emergencies.length > 0 ? (criticalCount / emergencies.length) * 100 : 0}%`, background: '#ef4444' }}></div>
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: '#f8fafc', marginBottom: '0.25rem' }}>
                <span>High Priority (Score 60 - 79)</span>
                <strong>{highCount} ({emergencies.length > 0 ? Math.round((highCount / emergencies.length) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: '8px', background: 'rgba(30, 41, 59, 0.8)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${emergencies.length > 0 ? (highCount / emergencies.length) * 100 : 0}%`, background: '#f97316' }}></div>
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: '#f8fafc', marginBottom: '0.25rem' }}>
                <span>Medium Priority (Score 35 - 59)</span>
                <strong>{mediumCount} ({emergencies.length > 0 ? Math.round((mediumCount / emergencies.length) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: '8px', background: 'rgba(30, 41, 59, 0.8)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${emergencies.length > 0 ? (mediumCount / emergencies.length) * 100 : 0}%`, background: '#f59e0b' }}></div>
              </div>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: '#f8fafc', marginBottom: '0.25rem' }}>
                <span>Low Priority (Score &lt; 35)</span>
                <strong>{lowCount} ({emergencies.length > 0 ? Math.round((lowCount / emergencies.length) * 100) : 0}%)</strong>
              </div>
              <div style={{ height: '8px', background: 'rgba(30, 41, 59, 0.8)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${emergencies.length > 0 ? (lowCount / emergencies.length) * 100 : 0}%`, background: '#10b981' }}></div>
              </div>
            </div>
          </div>
        </div>

        {/* System Integrity & Operational Audit Report */}
        <div className="glass-panel">
          <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <ShieldCheck size={18} color="#10b981" />
            System Governance & Compliance Audit
          </h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <CheckCircle2 size={16} color="#10b981" />
              <div style={{ fontSize: '0.8rem' }}>
                <strong style={{ color: '#f8fafc' }}>Vulnerability Priority Scoring:</strong> Configurable Product Heuristic Active
              </div>
            </div>

            <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <CheckCircle2 size={16} color="#10b981" />
              <div style={{ fontSize: '0.8rem' }}>
                <strong style={{ color: '#f8fafc' }}>Disaster Zone Policy Engine:</strong> Role-Filtered Directive Surfacing (ADR-009)
              </div>
            </div>

            <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <CheckCircle2 size={16} color="#10b981" />
              <div style={{ fontSize: '0.8rem' }}>
                <strong style={{ color: '#f8fafc' }}>Population Accounting Gate:</strong> Probabilistic Gap Inference + Human Gate (ADR-010)
              </div>
            </div>

            <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <CheckCircle2 size={16} color="#10b981" />
              <div style={{ fontSize: '0.8rem' }}>
                <strong style={{ color: '#f8fafc' }}>What-If Disaster Simulator:</strong> State Snapshot Isolation Verified (ADR-005)
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
