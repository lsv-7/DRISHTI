import React, { useState } from 'react';
import { triggerDynamicReplan, approveReplanProposal } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { RefreshCw, CheckCircle2, AlertTriangle, ArrowRight, ShieldAlert } from 'lucide-react';

export default function ReplanningAdmin() {
  const [proposal, setProposal] = useState({
    replan_id: "RP-DEMO-902",
    trigger: "ROAD_BLOCKAGE_DETECTED",
    blocked_road_id: "R12",
    affected_assignments: [
      {
        assignment_id: "ASG-101",
        emergency_title: "Submerged Residential Area in Auto Nagar",
        original_route: "Prakasam Barrage Main Arterial Road (R12)",
        status: "BLOCKED_AFFECTED"
      }
    ],
    alternative_routes: [
      {
        emergency_id: "EMG-102",
        recommended_resource: "Vijayawada Boat Unit 01",
        alternative_route_name: "Eluru Road Alternate Bypass Corridor (R20)",
        original_eta_minutes: 10.0,
        new_eta_minutes: 14.5,
        avoided_road: "R12 (Prakasam Barrage)"
      }
    ],
    requires_approval: true,
    status: "PENDING_APPROVAL"
  });
  const [loading, setLoading] = useState(false);
  const [appliedMsg, setAppliedMsg] = useState('');

  const handleTriggerReplan = async () => {
    setLoading(true);
    setAppliedMsg('');
    const prop = await triggerDynamicReplan('ROAD_STATUS_CHANGED', 'R12', 'BLOCKED');
    setProposal(prop);
    setLoading(false);
  };

  const handleApprove = async () => {
    if (!proposal) return;
    const res = await approveReplanProposal(proposal.replan_id);
    setAppliedMsg(res.message || "Replan Proposal Approved and Applied to Live System!");
    setProposal(null);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            HUMAN-IN-THE-LOOP DYNAMIC REPLANNING ENGINE
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Requires Human Approval Before Consequential Response-Plan Changes
          </p>
        </div>

        <button className="btn-primary" onClick={handleTriggerReplan} disabled={loading}>
          <RefreshCw size={16} /> {loading ? 'Simulating Dynamic Replan...' : 'Simulate Road Blockage Event (R12)'}
        </button>
      </div>

      {appliedMsg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '1rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {appliedMsg}
        </div>
      )}

      {proposal ? (
        <div className="glass-card" style={{ padding: '1.25rem', border: '2px solid var(--status-warning)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
            <div>
              <span className="badge badge-warning">HUMAN APPROVAL REQUIRED</span>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: '0.25rem 0 0 0' }}>
                Replan Proposal #{proposal.replan_id}
              </h3>
            </div>
            <StatusBadge status={proposal.status} />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.25rem' }}>
            <div style={{ backgroundColor: '#FFF5F5', padding: '0.85rem', borderRadius: '8px', border: '1px solid #FEB2B2' }}>
              <h4 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--status-critical)', margin: '0 0 0.5rem 0' }}>
                AFFECTED ASSIGNMENTS
              </h4>
              {proposal.affected_assignments.map((a, i) => (
                <div key={i} style={{ fontSize: '0.8rem', color: 'var(--text-main)' }}>
                  • <strong>{a.emergency_title}</strong> (Original: {a.original_route})
                </div>
              ))}
            </div>

            <div style={{ backgroundColor: '#F0F9FF', padding: '0.85rem', borderRadius: '8px', border: '1px solid #BAE6FD' }}>
              <h4 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--blue-primary)', margin: '0 0 0.5rem 0' }}>
                RECOMMENDED ALTERNATIVE ROUTE & RE-REROUTING
              </h4>
              {proposal.alternative_routes.map((alt, i) => (
                <div key={i} style={{ fontSize: '0.8rem', color: 'var(--text-main)' }}>
                  • Bypass: <strong>{alt.alternative_route_name}</strong>
                  <br />
                  ETA Adjustment: {alt.original_eta_minutes} min → <strong style={{ color: 'var(--blue-primary)' }}>{alt.new_eta_minutes} min</strong>
                </div>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end' }}>
            <button className="btn-secondary" onClick={() => setProposal(null)}>Reject Proposal</button>
            <button className="btn-primary" onClick={handleApprove}>Approve & Apply to Live System</button>
          </div>
        </div>
      ) : (
        <div className="glass-card" style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-sub)' }}>
          <ShieldAlert size={36} color="var(--blue-primary)" style={{ marginBottom: '0.5rem' }} />
          <h3>No Pending Replanning Proposals</h3>
          <p style={{ fontSize: '0.85rem', marginTop: '0.25rem' }}>
            Click "Simulate Road Blockage Event" above to trigger a dynamic replanning proposal requiring human approval.
          </p>
        </div>
      )}
    </div>
  );
}
