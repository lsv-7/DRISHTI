import React, { useState } from 'react';
import { runSimulation } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { PlayCircle, RefreshCw, AlertTriangle, Cpu, TrendingUp, ShieldAlert, CheckCircle2, ArrowRight } from 'lucide-react';

export default function SimulatorAdmin() {
  const [scenarioType, setScenarioType] = useState('ROAD_BLOCKAGE');
  const [waterLevelSurge, setWaterLevelSurge] = useState(1.5);
  const [demandSurgeMultiplier, setDemandSurgeMultiplier] = useState(2.5);
  const [meshNodesLost, setMeshNodesLost] = useState(1);
  const [loading, setLoading] = useState(false);
  
  const [simResult, setSimResult] = useState({
    scenario_type: "ROAD_BLOCKAGE",
    impact_delay_minutes: 24,
    vulnerable_citizens_at_risk: 48,
    affected_routes: ["Prakasam Barrage Main Arterial (R12)", "Bandar Road Low-Lying Sector"],
    hospital_bed_exhaustion_hours: 6.5,
    recommended_bypasses: [
      "Reroute 4 Rescue Boats via Eluru Canal Alternate Corridor (R20)",
      "Activate Prakasam Emergency Relief Shelter Overflow Wing B",
      "Deploy Mobile LoRa Relay Node Delta to restore 868MHz signal"
    ],
    timestamp: new Date().toLocaleTimeString()
  });

  const handleRunSimulation = async () => {
    setLoading(true);
    try {
      const inputParams = {
        water_level_surge: waterLevelSurge,
        demand_surge_multiplier: demandSurgeMultiplier,
        mesh_nodes_lost: meshNodesLost
      };

      const res = await runSimulation(scenarioType, inputParams);

      // Compute dynamic simulation outputs based on chosen parameters
      const delay = Math.round(15 + waterLevelSurge * 6 + demandSurgeMultiplier * 4);
      const citizens = Math.round(18 + demandSurgeMultiplier * 14 + waterLevelSurge * 10);
      const hoursLeft = Math.max(1.5, Math.round((12 - demandSurgeMultiplier * 2 - waterLevelSurge) * 10) / 10);

      setSimResult({
        scenario_type: scenarioType,
        impact_delay_minutes: delay,
        vulnerable_citizens_at_risk: citizens,
        affected_routes: scenarioType === 'ROAD_BLOCKAGE' 
          ? ["Prakasam Barrage Main Arterial (R12)", "Bandar Road Low-Lying Sector"]
          : ["Auto Nagar Industrial Bypass", "Krishna River Barrage Lock"],
        hospital_bed_exhaustion_hours: hoursLeft,
        recommended_bypasses: [
          `Reroute ${Math.min(6, Math.ceil(demandSurgeMultiplier * 2))} Rescue Boats via Eluru Canal Alternate Corridor (R20)`,
          "Activate Prakasam Emergency Relief Shelter Overflow Wing B",
          `Deploy Mobile LoRa Relay Node Delta to restore ${meshNodesLost > 0 ? '868MHz Mesh Coverage' : 'Telemetry Stream'}`
        ],
        timestamp: new Date().toLocaleTimeString(),
        server_response: res
      });
    } catch (err) {
      console.error("Simulation run error:", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            WHAT-IF DISASTER SCENARIO SIMULATION WORKBENCH
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Predictive Disaster Modeling • Parameterized Risk Stress-Testing Without Modifying Live Production State
          </p>
        </div>

        <button className="btn-primary" onClick={handleRunSimulation} disabled={loading}>
          <PlayCircle size={16} /> {loading ? 'Running Simulation Models...' : 'Execute What-If Simulation'}
        </button>
      </div>

      {/* Main Simulation Control Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        
        {/* Scenario Parameter Configuration */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Cpu size={18} color="var(--blue-primary)" /> SCENARIO INPUT PARAMETERS
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.35rem' }}>
                Primary Hazard Scenario Category
              </label>
              <select
                value={scenarioType}
                onChange={e => setScenarioType(e.target.value)}
                style={{ width: '100%', padding: '0.6rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem', fontWeight: 600 }}
              >
                <option value="ROAD_BLOCKAGE">Scenario A: Prakasam Barrage R12 Arterial Road Blockage</option>
                <option value="WATER_SURGE">Scenario B: Extreme Flood Water Surge (+2.5m Level Rise)</option>
                <option value="DEMAND_SURGE">Scenario C: 300% Spike in Evacuation & Medical Help Requests</option>
                <option value="LORA_MESH_FAILURE">Scenario D: LoRa Gateway Radio Mesh Failover</option>
              </select>
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.35rem' }}>
                <span>Flood Water Level Surge:</span>
                <span style={{ color: 'var(--blue-primary)' }}>+{waterLevelSurge} meters</span>
              </div>
              <input
                type="range"
                min="0.5"
                max="3.5"
                step="0.5"
                value={waterLevelSurge}
                onChange={e => setWaterLevelSurge(parseFloat(e.target.value))}
                style={{ width: '100%', accentColor: 'var(--blue-primary)' }}
              />
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.35rem' }}>
                <span>Evacuation Request Demand Surge:</span>
                <span style={{ color: 'var(--status-critical)' }}>{demandSurgeMultiplier}x Normal Volume</span>
              </div>
              <input
                type="range"
                min="1.0"
                max="5.0"
                step="0.5"
                value={demandSurgeMultiplier}
                onChange={e => setDemandSurgeMultiplier(parseFloat(e.target.value))}
                style={{ width: '100%', accentColor: 'var(--status-critical)' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.35rem' }}>
                Simulated Offline LoRa Radio Mesh Nodes Lost
              </label>
              <select
                value={meshNodesLost}
                onChange={e => setMeshNodesLost(parseInt(e.target.value))}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              >
                <option value={0}>0 Nodes (Mesh Fully Intact)</option>
                <option value={1}>1 Node Lost (Node-Delta Offline)</option>
                <option value={2}>2 Nodes Lost (Node-Beta & Node-Delta Offline)</option>
              </select>
            </div>

            <button className="btn-primary" onClick={handleRunSimulation} disabled={loading} style={{ justifyContent: 'center', marginTop: '0.5rem' }}>
              <PlayCircle size={16} /> Re-Calculate Simulation Metrics
            </button>
          </div>
        </div>

        {/* Real-time Computed Simulation Matrix */}
        <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '4px solid var(--blue-primary)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.5rem' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
              SIMULATED IMPACT MATRIX & PREDICTIVE METRICS
            </h3>
            <span style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>Computed at {simResult.timestamp}</span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem', marginBottom: '1rem' }}>
            <div style={{ backgroundColor: 'var(--status-critical-bg)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--status-critical)' }}>PROJECTED DELAY</span>
              <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-critical)' }}>
                +{simResult.impact_delay_minutes} mins
              </div>
              <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>Without bypass rerouting</div>
            </div>

            <div style={{ backgroundColor: 'var(--status-high-bg)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--status-high)' }}>CITIZENS AT RISK</span>
              <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-high)' }}>
                {simResult.vulnerable_citizens_at_risk} Individuals
              </div>
              <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>Low-lying sector stranded</div>
            </div>
          </div>

          <div style={{ backgroundColor: '#F8FAFC', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', marginBottom: '1rem' }}>
            <h4 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--navy-deep)', margin: '0 0 0.35rem 0' }}>
              Affected Bottleneck Corridors:
            </h4>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
              {simResult.affected_routes.map((rt, idx) => (
                <span key={idx} className="badge badge-critical" style={{ fontSize: '0.75rem' }}>
                  ⚠ {rt}
                </span>
              ))}
            </div>
          </div>

          <div>
            <h4 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.35rem' }}>
              Automated Decision Engine Bypass Recommendations:
            </h4>
            <ul style={{ paddingLeft: '1.2rem', fontSize: '0.8rem', color: 'var(--text-main)', margin: 0, display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
              {simResult.recommended_bypasses.map((rec, idx) => (
                <li key={idx} style={{ color: 'var(--blue-primary)', fontWeight: 600 }}>
                  {rec}
                </li>
              ))}
            </ul>
          </div>

        </div>

      </div>

    </div>
  );
}
