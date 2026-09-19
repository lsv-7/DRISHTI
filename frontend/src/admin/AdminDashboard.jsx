import React, { useState, useEffect } from 'react';
import LeafletMap from '../components/LeafletMap';
import StatusBadge from '../components/StatusBadge';
import AllocateResourceModal from '../components/AllocateResourceModal';
import {
  AlertTriangle, Flame, ShieldAlert, Home, NavigationOff, Users,
  Activity, ArrowRight, RefreshCw, CheckCircle, Clock, ShieldCheck
} from 'lucide-react';
import {
  fetchEmergencies, fetchResources, fetchOrganizations, fetchAssignments, fetchSupplyShipments,
  DEFAULT_EMERGENCIES, DEFAULT_RESOURCES, DEFAULT_ORGANIZATIONS, DEFAULT_ASSIGNMENTS
} from '../services/api';

export default function AdminDashboard() {
  const [emergencies, setEmergencies] = useState(DEFAULT_EMERGENCIES);
  const [resources, setResources] = useState(DEFAULT_RESOURCES);
  const [orgs, setOrgs] = useState(DEFAULT_ORGANIZATIONS);
  const [assignments, setAssignments] = useState(DEFAULT_ASSIGNMENTS);
  const [shipments, setShipments] = useState([]);
  const [selectedEmergency, setSelectedEmergency] = useState(DEFAULT_EMERGENCIES[0]);
  const [isAllocateModalOpen, setIsAllocateModalOpen] = useState(false);

  const loadAllData = async () => {
    try {
      const [eList, rList, oList, aList, sList] = await Promise.all([
        fetchEmergencies(),
        fetchResources(),
        fetchOrganizations(),
        fetchAssignments(),
        fetchSupplyShipments()
      ]);
      const validE = (eList && eList.length > 0) ? eList : DEFAULT_EMERGENCIES;
      const validR = (rList && rList.length > 0) ? rList : DEFAULT_RESOURCES;
      const validO = (oList && oList.length > 0) ? oList : DEFAULT_ORGANIZATIONS;
      const validA = (aList && aList.length > 0) ? aList : DEFAULT_ASSIGNMENTS;

      setEmergencies(validE);
      setResources(validR);
      setOrgs(validO);
      setAssignments(validA);
      setShipments(sList || []);
      if (validE.length > 0 && !selectedEmergency) {
        setSelectedEmergency(validE[0]);
      }
    } catch (err) {
      console.error("Error loading dashboard data:", err);
    }
  };

  useEffect(() => {
    loadAllData();
    const interval = setInterval(loadAllData, 3000);
    return () => clearInterval(interval);
  }, []);

  // Compute metrics
  const activeEmergenciesCount = emergencies.filter(e => e.status !== 'RESOLVED').length;
  const criticalEmergenciesCount = emergencies.filter(e => e.priority_level === 'CRITICAL' && e.status !== 'RESOLVED').length;
  const activeOperationsCount = assignments.filter(a => a.status === 'ACTIVE' || a.status === 'IN_PROGRESS').length;
  const availableResourcesCount = resources.filter(r => r.status === 'AVAILABLE').length;
  const unavailableResourcesCount = resources.filter(r => r.status !== 'AVAILABLE').length;
  
  const hospitalsWithCapacity = orgs.filter(o => o.organization_type === 'HOSPITAL' && (o.icu_available > 0 || o.emergency_beds_available > 0)).length;
  const sheltersNearCapacity = orgs.filter(o => o.organization_type === 'SHELTER' && o.operational_status === 'NEAR_CAPACITY').length;
  const blockedRoadsCount = orgs.filter(o => o.organization_type === 'ROAD' && o.blocked_roads_count > 0).length + 1; // R12 demo blockage

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Top Banner Overview */}
      <div style={{
        background: 'linear-gradient(135deg, #0B1F3A 0%, #1565D8 100%)',
        color: '#FFFFFF',
        padding: '1.25rem 1.5rem',
        borderRadius: 'var(--radius-md)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '1rem',
        boxShadow: 'var(--shadow-md)'
      }}>
        <div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: 800, margin: 0 }}>
            COMMAND CENTER REAL-TIME OPERATIONAL DASHBOARD
          </h2>
          <p style={{ fontSize: '0.85rem', color: '#EAF2FF', margin: '0.25rem 0 0 0' }}>
            Multi-Agency Unified Coordination • Live Emergency Priority Engine • Parameter-Driven Routing
          </p>
        </div>
        <button className="btn-secondary" onClick={loadAllData} style={{ background: '#FFFFFF', color: 'var(--navy-deep)', border: 'none' }}>
          <RefreshCw size={16} /> Sync Live Feeds
        </button>
      </div>

      {/* 9 Operational Information Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(230px, 1fr))',
        gap: '1rem'
      }}>
        
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-critical)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>ACTIVE EMERGENCIES</span>
            <AlertTriangle size={18} color="var(--status-critical)" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--text-main)', marginTop: '0.35rem' }}>
            {activeEmergenciesCount}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--status-critical)', fontWeight: 600 }}>
            Requires Priority Dispatch
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-critical)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>CRITICAL EMERGENCIES</span>
            <Flame size={18} color="var(--status-critical)" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--status-critical)', marginTop: '0.35rem' }}>
            {criticalEmergenciesCount}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Vulnerability Priority &gt; 80
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--blue-primary)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>RESCUE OPERATIONS</span>
            <Activity size={18} color="var(--blue-primary)" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--blue-primary)', marginTop: '0.35rem' }}>
            {activeOperationsCount}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Active Assignments En Route
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-safe)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>AVAILABLE RESOURCES</span>
            <CheckCircle size={18} color="var(--status-safe)" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--status-safe)', marginTop: '0.35rem' }}>
            {availableResourcesCount}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Boats, Ambulances & Teams
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid #64748B' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>UNAVAILABLE / BUSY</span>
            <Clock size={18} color="#64748B" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#64748B', marginTop: '0.35rem' }}>
            {unavailableResourcesCount}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Deployed or Maintenance
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid #8B5CF6' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>HOSPITALS WITH CAP</span>
            <ShieldAlert size={18} color="#8B5CF6" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#8B5CF6', marginTop: '0.35rem' }}>
            {hospitalsWithCapacity || 1}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            ICU & Emergency Beds Open
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-warning)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>SHELTERS NEAR CAP</span>
            <Home size={18} color="var(--status-warning)" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#B45309', marginTop: '0.35rem' }}>
            {sheltersNearCapacity || 1}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Occupancy &gt; 85% Capacity
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-critical)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>BLOCKED ROADS</span>
            <NavigationOff size={18} color="var(--status-critical)" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--status-critical)', marginTop: '0.35rem' }}>
            {blockedRoadsCount}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--status-critical)', fontWeight: 600 }}>
            Prakasam Barrage R12 Blocked
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid #0EA5E9' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>MISSING PERSON GAPS</span>
            <Users size={18} color="#0EA5E9" />
          </div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#0EA5E9', marginTop: '0.35rem' }}>
            1 Alert
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Zone 01 Population Discrepancy
          </div>
        </div>

      </div>

      {/* Main Interactive Map & Incident Queue Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.25rem' }}>
        
        {/* Leaflet Command Map */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)' }}>
              LIVE OPERATIONAL MAP (VIJAYAWADA DISASTER ZONE)
            </h3>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
              Layers: Emergencies, Responders, Hospitals, Shelters, Blocked Roads (R12), Evacuation Corridors
            </span>
          </div>

          <LeafletMap
            emergencies={emergencies}
            resources={resources}
            selectedEmergency={selectedEmergency}
            onSelectEmergency={setSelectedEmergency}
          />
        </div>

        {/* Live Priority Incident Stream */}
        <div className="glass-card" style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.5rem' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--navy-deep)' }}>
              PRIORITY INCIDENTS
            </h3>
            <span className="badge badge-critical">{emergencies.length} Active</span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', overflowY: 'auto', maxHeight: '480px' }}>
            {emergencies.map(e => (
              <div
                key={e.id}
                onClick={() => setSelectedEmergency(e)}
                style={{
                  padding: '0.75rem',
                  borderRadius: '8px',
                  border: selectedEmergency?.id === e.id ? '2px solid var(--blue-primary)' : '1px solid var(--border-color)',
                  backgroundColor: selectedEmergency?.id === e.id ? 'var(--blue-light)' : '#FFFFFF',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '0.35rem' }}>
                  <h4 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                    {e.title}
                  </h4>
                  <StatusBadge status={e.priority_level} />
                </div>

                <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', display: 'flex', justifyContent: 'space-between', marginTop: '0.25rem' }}>
                  <span>Vulnerability Score: <strong style={{ color: 'var(--status-critical)' }}>{e.vulnerability_score}</strong></span>
                  <span>Affected: <strong>{e.affected_count}</strong></span>
                </div>

                {e.vulnerability_factors && (
                  <div style={{ marginTop: '0.35rem', fontSize: '0.7rem', color: '#64748B', backgroundColor: 'rgba(255,255,255,0.7)', padding: '0.25rem 0.4rem', borderRadius: '4px' }}>
                    Traits: Age {e.vulnerability_factors.age || 70}, {e.vulnerability_factors.swim_ability === false ? 'Non-swimmer' : 'Can swim'}, Mobility: {e.vulnerability_factors.mobility || 'FULL'}
                  </div>
                )}

                <button
                  className="btn-primary"
                  style={{ width: '100%', marginTop: '0.5rem', padding: '0.35rem', fontSize: '0.75rem', justifyContent: 'center' }}
                  onClick={(event) => {
                    event.stopPropagation();
                    setSelectedEmergency(e);
                    setIsAllocateModalOpen(true);
                  }}
                >
                  <ShieldCheck size={14} /> Allocate Resource Now
                </button>
              </div>
            ))}
          </div>
        </div>

      </div>

      <AllocateResourceModal
        emergency={selectedEmergency}
        resources={resources}
        isOpen={isAllocateModalOpen}
        onClose={() => setIsAllocateModalOpen(false)}
        onAllocationComplete={loadAllData}
      />

    </div>
  );
}
