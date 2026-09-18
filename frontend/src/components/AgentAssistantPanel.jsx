import React, { useState } from 'react';
import { Bot, Send, Sparkles, CheckCircle2 } from 'lucide-react';
import { queryAgentWorkflow } from '../api';

export default function AgentAssistantPanel({ currentRole, selectedEmergency }) {
  const [query, setQuery] = useState('Evaluate flood situation and recommend resources for high-vulnerability citizens.');
  const [agentResponse, setAgentResponse] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleQueryAgent = async () => {
    if (!query.trim()) return;
    setLoading(true);
    try {
      const res = await queryAgentWorkflow(query, currentRole, selectedEmergency);
      setAgentResponse(res);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '1.25rem' }}>
      {/* Agent Workflow Execution Status */}
      <div className="glass-panel">
        <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.85rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Bot size={18} color="#06b6d4" />
          LangGraph Agent Workflow
        </h2>
        <p style={{ fontSize: '0.8rem', color: '#94a3b8', marginBottom: '1rem' }}>
          Deterministic decision engines compute facts; Agentic AI orchestrates tools and explains results.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
          {[
            { name: 'Supervisor Agent', desc: 'Orchestrates step flow' },
            { name: 'Situation Understanding Agent', desc: 'Analyzes emergency context' },
            { name: 'Policy & Compliance Agent', desc: 'Fetches zone policies & norms (ADR-012)' },
            { name: 'Resource Management Agent', desc: 'Calculates capability & vulnerability fit' },
            { name: 'Explanation Agent', desc: 'Synthesizes facts into operational narrative' }
          ].map((agent, i) => (
            <div key={i} style={{ background: 'rgba(15, 23, 42, 0.5)', padding: '0.65rem', borderRadius: '6px', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <CheckCircle2 size={16} color="#10b981" />
              <div>
                <div style={{ fontSize: '0.8rem', fontWeight: 700, color: '#f8fafc' }}>{agent.name}</div>
                <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>{agent.desc}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Query & Explanation Output */}
      <div className="glass-panel">
        <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Sparkles size={18} color="#3b82f6" />
          Ask Agentic AI Assistant
        </h2>

        <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.25rem' }}>
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Ask agent to evaluate situation, policy, or resource matching..."
            style={{
              flex: 1,
              background: 'rgba(15, 23, 42, 0.8)',
              border: '1px solid var(--border-color)',
              borderRadius: '8px',
              padding: '0.65rem 1rem',
              color: '#f8fafc',
              fontSize: '0.85rem'
            }}
          />
          <button onClick={handleQueryAgent} disabled={loading} className="btn btn-primary">
            <Send size={16} /> {loading ? 'Executing...' : 'Ask AI'}
          </button>
        </div>

        {agentResponse ? (
          <div>
            <div style={{ background: 'rgba(59, 130, 246, 0.1)', border: '1px solid rgba(59, 130, 246, 0.2)', padding: '1rem', borderRadius: '8px', marginBottom: '1rem' }}>
              <h4 style={{ fontSize: '0.85rem', fontWeight: 700, color: '#93c5fd', marginBottom: '0.5rem' }}>
                Agent Synthesized Operational Explanation:
              </h4>
              <pre style={{ whiteSpace: 'pre-wrap', fontFamily: 'Inter, sans-serif', fontSize: '0.85rem', color: '#e2e8f0', lineHeight: 1.5 }}>
                {agentResponse.final_explanation}
              </pre>
            </div>

            {agentResponse.reconstruction_norms?.length > 0 && (
              <div style={{ background: 'rgba(139, 92, 246, 0.1)', padding: '0.75rem', borderRadius: '6px', fontSize: '0.75rem', color: '#c084fc' }}>
                Reconstruction Norms Surfaced by Agent: {agentResponse.reconstruction_norms.map(rn => rn.title).join(', ')}
              </div>
            )}
          </div>
        ) : (
          <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Submit a query to trigger the multi-agent LangGraph workflow execution.</p>
        )}
      </div>
    </div>
  );
}
