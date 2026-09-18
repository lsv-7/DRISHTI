import React, { useState } from 'react';
import { Cpu, Play, CheckCircle2, XCircle, AlertTriangle } from 'lucide-react';
import { runSimulation } from '../api';

export default function SimulatorPanel() {
  const [scenario, setScenario] = useState('RESOURCE_FAILURE');
  const [simulationResult, setSimulationResult] = useState(null);
  const [running, setRunning] = useState(false);

  const handleRunSimulation = async () => {
    setRunning(true);
    try {
      const params = scenario === 'RESOURCE_FAILURE' ? { fail_all_boats: true }
        : scenario === 'ROAD_BLOCKAGE' ? { block_all: true }
        : scenario === 'DEMAND_SURGE' ? { surge_count: 5 }
        : { cluster_severity: 'HIGH' };

      const res = await runSimulation(scenario, params);
      setSimulationResult(res);
    } catch (err) {
      console.error(err);
    } finally {
      setRunning(false);
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1.25rem' }}>
      {/* Scenario Controls */}
      <div className="glass-panel">
        <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.85rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Cpu size={18} color="#8b5cf6" />
          What-If Simulator Setup
        </h2>
        <p style={{ fontSize: '0.8rem', color: '#94a3b8', marginBottom: '1rem' }}>
          Run hypothetical disaster scenarios on isolated state snapshots without mutating live operations (ADR-005).
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', marginBottom: '1.25rem' }}>
          {[
            { id: 'RESOURCE_FAILURE', label: 'Resource Failure (Disable Rescue Boats)' },
            { id: 'ROAD_BLOCKAGE', label: 'Road Blockage (Landslide / Bridge Cut)' },
            { id: 'DEMAND_SURGE', label: 'Emergency Demand Surge (+5 Requests)' },
            { id: 'HIGH_VULNERABILITY_CLUSTER', label: 'High-Vulnerability Cluster (Elderly Surge)' }
          ].map((sc) => (
            <button
              key={sc.id}
              onClick={() => setScenario(sc.id)}
              className={`btn ${scenario === sc.id ? 'btn-primary' : 'btn-outline'}`}
              style={{ justifyContent: 'flex-start', fontSize: '0.8rem' }}
            >
              {sc.label}
            </button>
          ))}
        </div>

        <button
          onClick={handleRunSimulation}
          disabled={running}
          className="btn btn-primary"
          style={{ width: '100%', justifyContent: 'center', background: 'linear-gradient(135deg, #8b5cf6, #7c3aed)' }}
        >
          <Play size={16} /> {running ? 'Simulating...' : 'Run What-If Simulation'}
        </button>
      </div>

      {/* Simulation Output & Live Comparison */}
      <div className="glass-panel">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700 }}>Simulation Output & Live State Comparison</h2>
          <span className="badge badge-low">Isolated State Copy</span>
        </div>

        {simulationResult ? (
          <div>
            <div style={{ background: 'rgba(139, 92, 246, 0.15)', border: '1px solid rgba(139, 92, 246, 0.3)', padding: '0.85rem', borderRadius: '8px', marginBottom: '1rem' }}>
              <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#c084fc', marginBottom: '0.25rem' }}>
                Scenario: {simulationResult.scenario_type}
              </div>
              <div style={{ fontSize: '0.8rem', color: '#e2e8f0' }}>
                {(simulationResult.impact_summary || []).join(' • ')}
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.75rem', marginBottom: '1rem', textAlign: 'center' }}>
              <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.6rem', borderRadius: '8px' }}>
                <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Live Emergencies</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 700 }}>{simulationResult.live_emergency_count}</div>
              </div>
              <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.6rem', borderRadius: '8px' }}>
                <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Simulated Count</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#8b5cf6' }}>{simulationResult.simulated_emergency_count}</div>
              </div>
              <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.6rem', borderRadius: '8px' }}>
                <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Re-assigned</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#10b981' }}>{simulationResult.simulated_assignments?.length || 0}</div>
              </div>
            </div>

            <h4 style={{ fontSize: '0.8rem', fontWeight: 700, color: '#94a3b8', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
              Simulated Re-allocations
            </h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxHeight: '200px', overflowY: 'auto', marginBottom: '1rem' }}>
              {(simulationResult.simulated_assignments || []).map((sa, i) => (
                <div key={i} style={{ background: 'rgba(30, 41, 59, 0.6)', padding: '0.6rem', borderRadius: '6px', fontSize: '0.8rem', display: 'flex', justifyContent: 'space-between' }}>
                  <span>{sa.emergency_title}</span>
                  <span style={{ color: '#10b981', fontWeight: 600 }}>→ {sa.resource_name} (ETA ~{sa.eta_minutes}m)</span>
                </div>
              ))}
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', borderTop: '1px solid var(--border-color)', paddingTop: '0.85rem' }}>
              <button className="btn btn-primary" style={{ flex: 1, justifyContent: 'center' }}>
                <CheckCircle2 size={16} /> Coordinator Apply Plan to Live System
              </button>
              <button onClick={() => setSimulationResult(null)} className="btn btn-outline" style={{ flex: 1, justifyContent: 'center' }}>
                <XCircle size={16} /> Cancel Simulation
              </button>
            </div>
          </div>
        ) : (
          <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Select a scenario and click "Run What-If Simulation" to preview hypothetical response plans.</p>
        )}
      </div>
    </div>
  );
}
