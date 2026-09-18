import React from 'react';
import { Shield, Radio, Activity, UserCheck } from 'lucide-react';

export default function Navbar({ currentRole, setCurrentRole, activeTab, setActiveTab }) {
  return (
    <header className="glass-panel" style={{ borderRadius: 0, borderTop: 0, borderLeft: 0, borderRight: 0, padding: '0.85rem 1.5rem', marginBottom: '1.25rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <div style={{ background: 'linear-gradient(135deg, #ef4444, #f97316)', padding: '0.5rem', borderRadius: '10px', display: 'flex' }}>
            <Shield size={24} color="#ffffff" />
          </div>
          <div>
            <h1 style={{ fontSize: '1.15rem', fontWeight: 800, letterSpacing: '-0.02em', background: 'linear-gradient(90deg, #f8fafc, #94a3b8)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
              DISASTER RESPONSE & RELIEF COORDINATOR
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: '#94a3b8' }}>
              <span className="badge badge-critical" style={{ padding: '0.1rem 0.4rem', fontSize: '0.65rem' }}>FLOOD RESPONSE MVP</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem', color: '#10b981' }}>
                <Activity size={12} /> LIVE CONNECTED
              </span>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div style={{ display: 'flex', gap: '0.4rem', background: 'rgba(15, 23, 42, 0.6)', padding: '0.25rem', borderRadius: '8px', border: '1px solid var(--border-color)', flexWrap: 'wrap' }}>
          {[
            { id: 'dashboard', label: 'Command Map' },
            { id: 'resources', label: 'Resources & Allocation' },
            { id: 'policies', label: 'Zone Policies' },
            { id: 'population', label: 'Population & Missing' },
            { id: 'simulator', label: 'What-If Simulator' },
            { id: 'analytics', label: 'Analytics & Reports' },
            { id: 'agent', label: 'AI Assistant' }
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`btn ${activeTab === tab.id ? 'btn-primary' : 'btn-outline'}`}
              style={{ padding: '0.35rem 0.75rem', fontSize: '0.78rem', textTransform: 'capitalize' }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Admin Role Indicator */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'rgba(30, 41, 59, 0.9)', padding: '0.35rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-color)' }}>
          <UserCheck size={16} color="#10b981" />
          <span style={{ fontSize: '0.75rem', color: '#94a3b8' }}>Role:</span>
          <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#f8fafc' }}>
            Admin / Disaster Coordinator
          </span>
        </div>
      </div>
    </header>
  );
}
