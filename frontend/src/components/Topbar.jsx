import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { Shield, Activity, Layers, Wifi, LogIn, LogOut, UserCheck } from 'lucide-react';
import StatusBadge from './StatusBadge';

export default function Topbar({ onOpenLogin }) {
  const { currentUser, isAuthenticated, logout } = useAuth();
  const [timestamp, setTimestamp] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => {
      setTimestamp(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <header style={{
      backgroundColor: 'var(--navy-deep)',
      color: '#FFFFFF',
      padding: '0.75rem 1.75rem',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      boxShadow: 'var(--shadow-md)',
      position: 'sticky',
      top: 0,
      zIndex: 1000,
      borderBottom: '1px solid rgba(255, 255, 255, 0.1)'
    }}>
      {/* Brand & Platform Identity */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
        <div style={{
          backgroundColor: 'var(--blue-primary)',
          padding: '0.5rem',
          borderRadius: '8px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }}>
          <Shield size={22} color="#FFFFFF" />
        </div>

        <div>
          <h1 style={{ fontSize: '1.15rem', fontWeight: 800, letterSpacing: '0.02em', margin: 0, color: '#FFFFFF' }}>
            DRISHTI DISASTER RESPONSE
          </h1>
          <p style={{ fontSize: '0.75rem', color: '#94A3B8', margin: 0 }}>
            {isAuthenticated ? (
              <span>
                Active Mode: <strong style={{ color: '#EAF2FF' }}>{currentUser.role === 'ADMIN' ? 'Command Center Admin' : `${currentUser.organization_type} Portal`}</strong>
              </span>
            ) : (
              'Multi-Agency Response & Relief Coordination Engine'
            )}
          </p>
        </div>
      </div>

      {/* Center Operational Status Badges */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flexWrap: 'wrap' }}>
        
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.8rem', background: 'rgba(255,255,255,0.08)', padding: '0.3rem 0.75rem', borderRadius: '6px' }}>
          <Activity size={15} color="#F97316" />
          <span style={{ color: '#CBD5E1' }}>Disaster:</span>
          <strong style={{ color: '#FFEDD5' }}>FLOOD L3</strong>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.8rem', background: 'rgba(255,255,255,0.08)', padding: '0.3rem 0.75rem', borderRadius: '6px' }}>
          <Layers size={15} color="#0EA5E9" />
          <span style={{ color: '#CBD5E1' }}>Zone:</span>
          <strong style={{ color: '#E0F2FE' }}>Vijayawada Central</strong>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.8rem', background: 'rgba(255,255,255,0.08)', padding: '0.3rem 0.75rem', borderRadius: '6px' }}>
          <Wifi size={15} color="#16A34A" />
          <span style={{ color: '#DCFCE7', fontWeight: 700 }}>ONLINE</span>
        </div>

        <div style={{ fontSize: '0.8rem', color: '#94A3B8', fontFamily: 'monospace', fontWeight: 600 }}>
          {timestamp}
        </div>

      </div>

      {/* User Auth Profile & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        {isAuthenticated ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem' }}>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '0.85rem', fontWeight: 700, color: '#FFFFFF' }}>
                {currentUser.full_name}
              </div>
              <div style={{ fontSize: '0.7rem', color: '#94A3B8' }}>
                {currentUser.organization_name}
              </div>
            </div>

            <button
              onClick={logout}
              title="Sign Out of Operational Portal"
              className="btn-secondary"
              style={{
                backgroundColor: 'rgba(255, 255, 255, 0.1)',
                color: '#FFFFFF',
                border: '1px solid rgba(255, 255, 255, 0.2)',
                padding: '0.4rem 0.75rem',
                fontSize: '0.8rem'
              }}
            >
              <LogOut size={15} /> Sign Out
            </button>
          </div>
        ) : (
          <button
            onClick={onOpenLogin}
            className="btn-primary"
            style={{
              fontSize: '0.85rem',
              padding: '0.5rem 1rem'
            }}
          >
            <LogIn size={16} /> Portal Sign In
          </button>
        )}
      </div>

    </header>
  );
}
