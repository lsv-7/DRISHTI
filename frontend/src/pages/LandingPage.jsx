import React from 'react';
import { useAuth } from '../context/AuthContext';
import {
  Shield, Activity, ArrowRight, Building2, HeartPulse, ShieldAlert, Flame,
  Home, NavigationOff, CheckCircle2, Lock, Users, Truck, GitMerge
} from 'lucide-react';

export default function LandingPage({ onOpenLogin }) {
  const { loginWithDemoAccount } = useAuth();

  const handleDemoClick = (key) => {
    loginWithDemoAccount(key);
  };

  return (
    <div style={{ backgroundColor: 'var(--bg-page)', minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      
      {/* Landing Page Hero Section */}
      <section style={{
        background: 'linear-gradient(135deg, #0B1F3A 0%, #1565D8 100%)',
        color: '#FFFFFF',
        padding: '3.5rem 2rem 4rem 2rem',
        textAlign: 'center',
        boxShadow: 'var(--shadow-md)'
      }}>
        <div style={{ maxWidth: '1050px', margin: '0 auto', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1.25rem' }}>
          
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.5rem',
            backgroundColor: 'rgba(255,255,255,0.12)',
            padding: '0.4rem 1rem',
            borderRadius: '9999px',
            fontSize: '0.85rem',
            fontWeight: 700,
            color: '#EAF2FF'
          }}>
            <Shield size={18} color="#FFFFFF" />
            DRISHTI DISASTER RESPONSE PLATFORM
          </div>

          <h1 style={{ fontSize: '2.5rem', fontWeight: 800, lineHeight: 1.2, letterSpacing: '-0.02em', margin: 0 }}>
            DRISHTI — Intelligent Disaster Response & Relief Coordination
          </h1>

          <p style={{ fontSize: '1.1rem', color: '#EAF2FF', maxWidth: '820px', margin: 0, lineHeight: 1.6 }}>
            A deterministic multi-agency coordination system converting changing urban flood conditions into explainable, vulnerability-aware action — connecting Command Centers with Hospitals, Police, Fire, Shelters, and Road Infrastructure.
          </p>

          <div style={{ display: 'flex', gap: '1rem', marginTop: '0.75rem', flexWrap: 'wrap', justifyContent: 'center' }}>
            <button
              className="btn-primary"
              onClick={onOpenLogin}
              style={{
                backgroundColor: '#FFFFFF',
                color: 'var(--navy-deep)',
                fontSize: '1rem',
                padding: '0.75rem 1.75rem',
                boxShadow: '0 4px 14px rgba(0,0,0,0.2)'
              }}
            >
              Sign In to Operational Portal <ArrowRight size={18} />
            </button>
          </div>

        </div>
      </section>

      {/* Real-time Situation Summary Bar */}
      <div style={{
        backgroundColor: '#FFFFFF',
        borderBottom: '1px solid var(--border-color)',
        padding: '1rem 2rem',
        boxShadow: 'var(--shadow-sm)'
      }}>
        <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'space-around', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem' }}>
            <Activity size={18} color="var(--status-critical)" />
            <span>Disaster Level: <strong style={{ color: 'var(--status-critical)' }}>URBAN FLOOD L3</strong></span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem' }}>
            <Building2 size={18} color="var(--blue-primary)" />
            <span>Portals: <strong>Admin + 5 Organisation Types</strong></span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem' }}>
            <NavigationOff size={18} color="var(--status-critical)" />
            <span>Infrastructure Warning: <strong style={{ color: 'var(--status-critical)' }}>Prakasam Barrage R12 Blocked</strong></span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem' }}>
            <CheckCircle2 size={18} color="var(--status-safe)" />
            <span>System Status: <strong style={{ color: 'var(--status-safe)' }}>OPERATIONAL</strong></span>
          </div>
        </div>
      </div>

      {/* Main Capabilities Overview & One-Click Test Login Section */}
      <main style={{ maxWidth: '1200px', margin: '0 auto', padding: '3rem 1.5rem', display: 'flex', flexDirection: 'column', gap: '3rem', width: '100%' }}>
        
        {/* Quick Demo Test Credential Logins Section */}
        <section style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ textAlign: 'center' }}>
            <h2 style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
              QUICK SEED CREDENTIAL SIGN IN
            </h2>
            <p style={{ fontSize: '0.9rem', color: 'var(--text-sub)', marginTop: '0.35rem' }}>
              Select a portal category and sign in using verified credentials or 1-click entry.
            </p>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '1.25rem'
          }}>
            
            {/* Admin Seed Card */}
            <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '5px solid var(--navy-deep)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span className="badge badge-navy">ADMIN PORTAL</span>
                  <Shield size={20} color="var(--navy-deep)" />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Admin Command HQ
                </h3>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Email: <strong>admin@disaster.gov</strong>
                </div>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  Full system visibility, priority engine, interactive map, replanning approval, and population gap inference.
                </p>
              </div>
              <button className="btn-primary" onClick={() => handleDemoClick('ADMIN')} style={{ marginTop: '1rem', justifyContent: 'center' }}>
                Sign In to Admin Portal
              </button>
            </div>

            {/* Hospital Seed Card */}
            <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '5px solid #8B5CF6', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span className="badge badge-navy">ORGANISATION: HOSPITAL</span>
                  <HeartPulse size={20} color="#8B5CF6" />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Vijayawada General Hospital
                </h3>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Email: <strong>hospital@disaster.gov</strong>
                </div>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  Hospital dashboard: Beds, ICU capacity, emergency beds, medical teams, ambulances, and capacity update logging.
                </p>
              </div>
              <button className="btn-primary" onClick={() => handleDemoClick('HOSPITAL')} style={{ marginTop: '1rem', justifyContent: 'center', backgroundColor: '#8B5CF6' }}>
                Sign In to Hospital Portal
              </button>
            </div>

            {/* Police Seed Card */}
            <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '5px solid var(--navy-deep)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span className="badge badge-navy">ORGANISATION: POLICE</span>
                  <ShieldAlert size={20} color="var(--navy-deep)" />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Central Police Control HQ
                </h3>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Email: <strong>police@disaster.gov</strong>
                </div>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  Police dashboard: Personnel, patrol units, checkpoints, and security observations (`ROAD_BLOCKED`, `AREA_RESTRICTED`).
                </p>
              </div>
              <button className="btn-primary" onClick={() => handleDemoClick('POLICE')} style={{ marginTop: '1rem', justifyContent: 'center' }}>
                Sign In to Police Portal
              </button>
            </div>

            {/* Fire Seed Card */}
            <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '5px solid var(--status-critical)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span className="badge badge-navy">ORGANISATION: FIRE</span>
                  <Flame size={20} color="var(--status-critical)" />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Fire & Emergency Services
                </h3>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Email: <strong>fire@disaster.gov</strong>
                </div>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  Fire dashboard: Water rescue boats, fire engines, and mission stepper workflow (`EN_ROUTE` → `ARRIVED` → `IN_PROGRESS` → `COMPLETED`).
                </p>
              </div>
              <button className="btn-primary" onClick={() => handleDemoClick('FIRE')} style={{ marginTop: '1rem', justifyContent: 'center', backgroundColor: 'var(--status-critical)' }}>
                Sign In to Fire Portal
              </button>
            </div>

            {/* Shelter Seed Card */}
            <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '5px solid var(--status-warning)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span className="badge badge-navy">ORGANISATION: SHELTER</span>
                  <Home size={20} color="var(--status-warning)" />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Prakasam Relief Shelter
                </h3>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Email: <strong>shelter@disaster.gov</strong>
                </div>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  Shelter dashboard: Occupancy, food/water inventory, evacuee registration, and re-supply alerts.
                </p>
              </div>
              <button className="btn-primary" onClick={() => handleDemoClick('SHELTER')} style={{ marginTop: '1rem', justifyContent: 'center', backgroundColor: '#B45309' }}>
                Sign In to Shelter Portal
              </button>
            </div>

            {/* Road Seed Card */}
            <div className="glass-card" style={{ padding: '1.25rem', borderLeft: '5px solid var(--status-safe)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span className="badge badge-navy">ORGANISATION: ROAD</span>
                  <GitMerge size={20} color="var(--status-safe)" />
                </div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Roads & Infrastructure
                </h3>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-sub)', marginTop: '0.25rem' }}>
                  Email: <strong>road@disaster.gov</strong>
                </div>
                <p style={{ fontSize: '0.8rem', color: 'var(--text-main)', marginTop: '0.5rem' }}>
                  Road dashboard: Road blockage statuses (`OPEN`, `BLOCKED`, `RESTRICTED`) and trigger the replanning pipeline.
                </p>
              </div>
              <button className="btn-primary" onClick={() => handleDemoClick('ROAD')} style={{ marginTop: '1rem', justifyContent: 'center', backgroundColor: 'var(--status-safe)' }}>
                Sign In to Road Portal
              </button>
            </div>

          </div>
        </section>

      </main>

      {/* Footer */}
      <footer style={{
        backgroundColor: 'var(--navy-deep)',
        color: '#94A3B8',
        padding: '1.5rem',
        textAlign: 'center',
        fontSize: '0.8rem',
        marginTop: 'auto'
      }}>
        © 2026 DRISHTI — Intelligent Disaster Response & Relief Coordination Multi-Agency Platform
      </footer>

    </div>
  );
}
