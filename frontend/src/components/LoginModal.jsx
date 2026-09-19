import React, { useState, useEffect } from 'react';
import { useAuth, SEED_ACCOUNTS } from '../context/AuthContext';
import { Shield, Lock, Mail, AlertCircle, X, Building2, Check } from 'lucide-react';

export default function LoginModal({ isOpen, onClose }) {
  const { loginWithCredentials, loginWithDemoAccount, authLoading } = useAuth();
  
  const [portalType, setPortalType] = useState('ADMIN'); // 'ADMIN' or 'ORGANISATION'
  const [orgType, setOrgType] = useState('HOSPITAL'); // 'HOSPITAL', 'POLICE', 'FIRE', 'SHELTER', 'ROAD'
  
  const [email, setEmail] = useState('admin@disaster.gov');
  const [password, setPassword] = useState('AdminPass123!');
  const [errorMsg, setErrorMsg] = useState('');

  // Auto-fill credentials based on portal selection
  useEffect(() => {
    if (portalType === 'ADMIN') {
      setEmail('admin@disaster.gov');
      setPassword('AdminPass123!');
    } else {
      const defaultCreds = {
        HOSPITAL: { email: 'hospital@disaster.gov', pass: 'Hospital123!' },
        POLICE: { email: 'police@disaster.gov', pass: 'Police123!' },
        FIRE: { email: 'fire@disaster.gov', pass: 'Fire123!' },
        SHELTER: { email: 'shelter@disaster.gov', pass: 'Shelter123!' },
        ROAD: { email: 'road@disaster.gov', pass: 'Road123!' }
      };
      const c = defaultCreds[orgType] || defaultCreds.HOSPITAL;
      setEmail(c.email);
      setPassword(c.pass);
    }
  }, [portalType, orgType]);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrorMsg('');
    try {
      await loginWithCredentials(email, password, portalType, orgType);
      onClose();
    } catch (err) {
      setErrorMsg(err.message || "Failed to authenticate with Firebase credentials");
    }
  };

  const handleQuickSeedClick = (key) => {
    loginWithDemoAccount(key);
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content" style={{ maxWidth: '520px', padding: '1.75rem' }}>
        
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <div style={{ backgroundColor: 'var(--blue-light)', padding: '0.5rem', borderRadius: '8px' }}>
              <Shield size={24} color="var(--blue-primary)" />
            </div>
            <div>
              <h2 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                Portal Authentication
              </h2>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-sub)', margin: 0 }}>
                Select Portal Category & Organization Credentials
              </p>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <X size={20} color="#64748B" />
          </button>
        </div>

        {errorMsg && (
          <div style={{
            backgroundColor: 'var(--status-critical-bg)',
            color: 'var(--status-critical)',
            padding: '0.65rem 0.85rem',
            borderRadius: '6px',
            fontSize: '0.85rem',
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            marginBottom: '1rem'
          }}>
            <AlertCircle size={18} />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Step 1: Select Portal Category (Admin vs Organisation) */}
        <div style={{ marginBottom: '1.25rem' }}>
          <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
            1. Select Portal Category
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
            <button
              type="button"
              onClick={() => setPortalType('ADMIN')}
              style={{
                padding: '0.75rem',
                borderRadius: '8px',
                border: portalType === 'ADMIN' ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                backgroundColor: portalType === 'ADMIN' ? 'var(--blue-light)' : '#FFFFFF',
                color: portalType === 'ADMIN' ? 'var(--blue-primary)' : 'var(--text-main)',
                fontWeight: 700,
                fontSize: '0.9rem',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem'
              }}
            >
              <Shield size={18} /> Admin Command
            </button>

            <button
              type="button"
              onClick={() => setPortalType('ORGANISATION')}
              style={{
                padding: '0.75rem',
                borderRadius: '8px',
                border: portalType === 'ORGANISATION' ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                backgroundColor: portalType === 'ORGANISATION' ? 'var(--blue-light)' : '#FFFFFF',
                color: portalType === 'ORGANISATION' ? 'var(--blue-primary)' : 'var(--text-main)',
                fontWeight: 700,
                fontSize: '0.9rem',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem'
              }}
            >
              <Building2 size={18} /> Organisation Portal
            </button>
          </div>
        </div>

        {/* Step 2: If Organisation is selected, select Organisation Type */}
        {portalType === 'ORGANISATION' && (
          <div style={{ marginBottom: '1.25rem' }}>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.5rem' }}>
              2. Select Organisation Type
            </label>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '0.35rem' }}>
              {['HOSPITAL', 'POLICE', 'FIRE', 'SHELTER', 'ROAD'].map(type => (
                <button
                  key={type}
                  type="button"
                  onClick={() => setOrgType(type)}
                  style={{
                    padding: '0.5rem 0.25rem',
                    borderRadius: '6px',
                    border: orgType === type ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                    backgroundColor: orgType === type ? 'var(--blue-primary)' : '#FFFFFF',
                    color: orgType === type ? '#FFFFFF' : 'var(--text-main)',
                    fontWeight: 700,
                    fontSize: '0.7rem',
                    cursor: 'pointer',
                    textAlign: 'center'
                  }}
                >
                  {type}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Step 3: Enter Firebase Email & Password Credentials */}
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem', color: 'var(--navy-deep)' }}>
              Firebase Email Address
            </label>
            <div style={{ position: 'relative' }}>
              <Mail size={16} color="#64748B" style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="email"
                required
                value={email}
                onChange={e => setEmail(e.target.value)}
                style={{
                  width: '100%',
                  padding: '0.6rem 0.75rem 0.6rem 2.4rem',
                  borderRadius: '6px',
                  border: '1px solid var(--border-color)',
                  fontSize: '0.85rem'
                }}
              />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem', color: 'var(--navy-deep)' }}>
              Password
            </label>
            <div style={{ position: 'relative' }}>
              <Lock size={16} color="#64748B" style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                style={{
                  width: '100%',
                  padding: '0.6rem 0.75rem 0.6rem 2.4rem',
                  borderRadius: '6px',
                  border: '1px solid var(--border-color)',
                  fontSize: '0.85rem'
                }}
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn-primary"
            disabled={authLoading}
            style={{ width: '100%', justifyContent: 'center', marginTop: '0.5rem', padding: '0.75rem', fontSize: '0.9rem' }}
          >
            {authLoading ? 'Validating Firebase Credentials...' : `Sign In to ${portalType === 'ADMIN' ? 'Admin Portal' : `${orgType} Portal`}`}
          </button>
        </form>

        {/* Quick Demo Helper Links */}
        <div style={{ marginTop: '1.25rem', paddingTop: '0.85rem', borderTop: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--text-sub)', marginBottom: '0.4rem', textTransform: 'uppercase' }}>
            Quick 1-Click Test Sign In:
          </div>
          <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
            {['ADMIN', 'HOSPITAL', 'POLICE', 'FIRE', 'SHELTER', 'ROAD'].map(key => (
              <button
                key={key}
                type="button"
                onClick={() => handleQuickSeedClick(key)}
                style={{
                  fontSize: '0.7rem',
                  fontWeight: 700,
                  padding: '0.25rem 0.5rem',
                  borderRadius: '4px',
                  border: '1px solid var(--border-color)',
                  backgroundColor: '#F1F5F9',
                  color: 'var(--navy-deep)',
                  cursor: 'pointer'
                }}
              >
                {key}
              </button>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
}
