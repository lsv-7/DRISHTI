import React from 'react';
import {
  LayoutDashboard, Map, AlertTriangle, Building2, Package, Users, GitMerge, RefreshCw,
  UserCheck, UserSearch, FileText, PlayCircle, Truck, Bell, ShieldCheck, History, Radio
} from 'lucide-react';

export default function Sidebar({ activeTab, setActiveTab }) {
  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'live_map', label: 'Live Map', icon: Map },
    { id: 'emergencies', label: 'Emergencies', icon: AlertTriangle, badge: 'CRITICAL' },
    { id: 'organizations', label: 'Organizations', icon: Building2 },
    { id: 'decision_routing', label: 'Decision Routing', icon: GitMerge },
    { id: 'resources', label: 'Resources', icon: Package },
    { id: 'rescue_teams', label: 'Rescue Teams', icon: Users },
    { id: 'assignments', label: 'Assignments', icon: ShieldCheck },
    { id: 'replanning', label: 'Replanning', icon: RefreshCw, badge: 'PROPOSAL' },
    { id: 'supply_chain', label: 'Supply Chain & Telemetry', icon: Truck },
    { id: 'lora_mesh', label: 'LoRa Radio Mesh', icon: Radio, badge: '868MHz' },
    { id: 'population', label: 'Population Accounting', icon: UserCheck },
    { id: 'missing_persons', label: 'Missing Persons', icon: UserSearch },
    { id: 'policies', label: 'Policies & Compliance', icon: FileText },
    { id: 'simulator', label: 'What-If Simulator', icon: PlayCircle },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'audit_logs', label: 'Audit Logs', icon: History }
  ];

  return (
    <aside style={{
      width: '260px',
      backgroundColor: '#FFFFFF',
      borderRight: '1px solid var(--border-color)',
      padding: '1.25rem 0.75rem',
      display: 'flex',
      flexDirection: 'column',
      gap: '0.35rem',
      boxShadow: 'var(--shadow-sm)'
    }}>
      <div style={{
        fontSize: '0.75rem',
        fontWeight: 800,
        color: 'var(--text-sub)',
        textTransform: 'uppercase',
        letterSpacing: '0.06em',
        padding: '0.5rem 0.75rem 0.75rem 0.75rem',
        borderBottom: '1px solid var(--border-light)',
        marginBottom: '0.5rem'
      }}>
        ADMIN NAVIGATION
      </div>

      <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
        {menuItems.map(item => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '0.65rem 0.85rem',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: isActive ? 'var(--blue-light)' : 'transparent',
                color: isActive ? 'var(--blue-primary)' : 'var(--text-main)',
                fontWeight: isActive ? 700 : 500,
                fontSize: '0.875rem',
                cursor: 'pointer',
                transition: 'all 0.15 ease',
                textAlign: 'left'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
                <Icon size={18} color={isActive ? 'var(--blue-primary)' : '#64748B'} />
                <span>{item.label}</span>
              </div>
              {item.badge && (
                <span style={{
                  fontSize: '0.65rem',
                  fontWeight: 800,
                  backgroundColor: item.badge === 'CRITICAL' ? 'var(--status-critical-bg)' : 'var(--status-high-bg)',
                  color: item.badge === 'CRITICAL' ? 'var(--status-critical)' : 'var(--status-high)',
                  padding: '2px 6px',
                  borderRadius: '4px'
                }}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>
    </aside>
  );
}
