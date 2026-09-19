import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import { sendWebSocketEvent } from '../services/websocket';
import { HeartPulse, Bed, ShieldAlert, Truck, Users, Plus, CheckCircle2, AlertCircle } from 'lucide-react';

export default function HospitalDashboard({ orgData }) {
  const [totalBeds, setTotalBeds] = useState(500);
  const [occupiedBeds, setOccupiedBeds] = useState(380);
  const [emergencyBedsAvailable, setEmergencyBedsAvailable] = useState(18);
  const [icuAvailable, setIcuAvailable] = useState(12);

  const [ambulancesAvailable, setAmbulancesAvailable] = useState(5);
  const [ambulancesDeployed, setAmbulancesDeployed] = useState(3);
  const [medicalTeamsAvailable, setMedicalTeamsAvailable] = useState(8);

  const [msg, setMsg] = useState('');

  const broadcastCapacityChange = (newIcu, newEmergencyBeds) => {
    const payload = {
      event: "HOSPITAL_CAPACITY_CHANGED",
      organization_id: orgData?.id || "H01",
      icu_available: newIcu,
      emergency_beds_available: newEmergencyBeds,
      total_beds: totalBeds,
      occupied_beds: occupiedBeds,
      timestamp: new Date().toISOString()
    };
    sendWebSocketEvent("HOSPITAL_CAPACITY_CHANGED", payload);
    setMsg("Hospital Capacity Update Broadcasted to Admin Command Center via WebSocket!");
    setTimeout(() => setMsg(''), 4000);
  };

  const handleUpdateCapacity = () => {
    const nextOccupied = Math.min(totalBeds, occupiedBeds + 5);
    const nextEmg = Math.max(0, emergencyBedsAvailable - 2);
    setOccupiedBeds(nextOccupied);
    setEmergencyBedsAvailable(nextEmg);
    broadcastCapacityChange(icuAvailable, nextEmg);
  };

  const handleUpdateICU = () => {
    const nextIcu = Math.max(0, icuAvailable - 2);
    setIcuAvailable(nextIcu);
    broadcastCapacityChange(nextIcu, emergencyBedsAvailable);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {msg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {msg}
        </div>
      )}

      {/* Main Metric Cards Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        
        {/* Beds Card */}
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--blue-primary)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>GENERAL BEDS</span>
            <Bed size={20} color="var(--blue-primary)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--navy-deep)', marginTop: '0.35rem' }}>
            {totalBeds - occupiedBeds} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>/ {totalBeds} Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Occupied: {occupiedBeds} beds
          </div>
        </div>

        {/* Emergency Beds Card */}
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-critical)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>EMERGENCY BEDS</span>
            <HeartPulse size={20} color="var(--status-critical)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-critical)', marginTop: '0.35rem' }}>
            {emergencyBedsAvailable} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Total Dedicated ER Beds: 30
          </div>
        </div>

        {/* ICU Beds Card */}
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid #8B5CF6' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>ICU BEDS</span>
            <ShieldAlert size={20} color="#8B5CF6" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: '#8B5CF6', marginTop: '0.35rem' }}>
            {icuAvailable} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>/ 60 Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            Critical Care Capacity
          </div>
        </div>

        {/* Medical Teams Card */}
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-safe)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>MEDICAL TEAMS</span>
            <Users size={20} color="var(--status-safe)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-safe)', marginTop: '0.35rem' }}>
            {medicalTeamsAvailable} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            2 Busy • 1 Unavailable
          </div>
        </div>

        {/* Ambulances Card */}
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-high)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>AMBULANCES</span>
            <Truck size={20} color="var(--status-high)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--status-high)', marginTop: '0.35rem' }}>
            {ambulancesAvailable} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>Available</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>
            {ambulancesDeployed} Deployed on Calls
          </div>
        </div>

      </div>

      {/* Capabilities & Actions Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        
        {/* Hospital Capabilities */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            CONFIGURED MEDICAL CAPABILITIES
          </h3>
          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
            {['Emergency Care', 'ICU Level 3', 'Trauma Surgery', 'Pediatric Care', 'Burn Unit', 'Blood Bank'].map((cap, i) => (
              <span key={i} className="badge badge-navy" style={{ padding: '0.4rem 0.75rem', fontSize: '0.8rem' }}>
                ✓ {cap}
              </span>
            ))}
          </div>
        </div>

        {/* Operational Actions */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            QUICK HOSPITAL OPERATIONAL ACTIONS
          </h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.65rem' }}>
            <button className="btn-primary" onClick={handleUpdateCapacity} style={{ fontSize: '0.8rem' }}>
              Log Patient Admissions (+5)
            </button>
            <button className="btn-secondary" onClick={handleUpdateICU} style={{ fontSize: '0.8rem' }}>
              Update ICU Capacity (-2)
            </button>
            <button className="btn-secondary" onClick={() => broadcastCapacityChange(icuAvailable, emergencyBedsAvailable)} style={{ fontSize: '0.8rem' }}>
              Acknowledge Patient Transfer
            </button>
            <button className="btn-danger" onClick={() => broadcastCapacityChange(0, 0)} style={{ fontSize: '0.8rem' }}>
              Report ER Overload Incident
            </button>
          </div>
        </div>

      </div>

    </div>
  );
}
