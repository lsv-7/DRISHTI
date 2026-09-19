import React, { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import { sendWebSocketEvent } from '../services/websocket';
import { Home, Users, Utensils, Droplets, Plus, CheckCircle2, UserPlus, ArrowUpRight } from 'lucide-react';

export default function ShelterDashboard({ orgData }) {
  const [capacity, setCapacity] = useState(600);
  const [occupancy, setOccupancy] = useState(540);
  const [foodStatus, setFoodStatus] = useState('ADEQUATE');
  const [waterStatus, setWaterStatus] = useState('HIGH_DEMAND');

  const [registrations, setRegistrations] = useState([
    { id: "REG-901", name: "Lakshmi Narayana", age: 64, gender: "FEMALE", origin: "Ward 12 Bandar", time: "10 mins ago" },
    { id: "REG-902", name: "K. Venkatesh", age: 38, gender: "MALE", origin: "Auto Nagar", time: "25 mins ago" }
  ]);

  const [personName, setPersonName] = useState('');
  const [personAge, setPersonAge] = useState('');
  const [personGender, setPersonGender] = useState('FEMALE');

  const [msg, setMsg] = useState('');

  const broadcastShelterUpdate = (newOccupied, newFood, newWater) => {
    const payload = {
      event: "SHELTER_CAPACITY_CHANGED",
      organization_id: orgData?.id || "S01",
      occupied: newOccupied,
      available: Math.max(0, capacity - newOccupied),
      food_status: newFood,
      water_status: newWater,
      timestamp: new Date().toISOString()
    };
    sendWebSocketEvent("SHELTER_CAPACITY_CHANGED", payload);
    setMsg("Shelter Capacity & Inventory update broadcasted to Command Center!");
    setTimeout(() => setMsg(''), 4000);
  };

  const handleRegisterPerson = (e) => {
    e.preventDefault();
    if (!personName) return;
    const newReg = {
      id: `REG-${Math.floor(Math.random()*900 + 100)}`,
      name: personName,
      age: Number(personAge) || 30,
      gender: personGender,
      origin: "Flood Evacuation Zone",
      time: "Just now"
    };

    const nextOccupancy = Math.min(capacity, occupancy + 1);
    setOccupancy(nextOccupancy);
    setRegistrations(prev => [newReg, ...prev]);
    setPersonName('');
    setPersonAge('');
    broadcastShelterUpdate(nextOccupancy, foodStatus, waterStatus);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {msg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {msg}
        </div>
      )}

      {/* Shelter Metrics Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--navy-deep)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>SHELTER OCCUPANCY</span>
            <Home size={20} color="var(--navy-deep)" />
          </div>
          <div style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--navy-deep)', marginTop: '0.35rem' }}>
            {occupancy} <span style={{ fontSize: '0.9rem', color: 'var(--text-sub)', fontWeight: 400 }}>/ {capacity} Occupied</span>
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--status-warning)', fontWeight: 700 }}>
            {capacity - occupancy} Available Beds Remaining
          </div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-safe)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>FOOD INVENTORY</span>
            <Utensils size={20} color="var(--status-safe)" />
          </div>
          <div style={{ fontSize: '1.4rem', fontWeight: 800, color: 'var(--status-safe)', marginTop: '0.35rem' }}>
            <StatusBadge status={foodStatus} />
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>800 Rations Stored</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-warning)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-sub)' }}>WATER INVENTORY</span>
            <Droplets size={20} color="var(--status-warning)" />
          </div>
          <div style={{ fontSize: '1.4rem', fontWeight: 800, color: '#B45309', marginTop: '0.35rem' }}>
            <StatusBadge status={waterStatus} />
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>1,500 Liters (Re-supply Requested)</div>
        </div>

      </div>

      {/* Person Registration & Evacuee Log */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem' }}>
        
        {/* Register Evacuee Form */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            REGISTER ARRIVING PERSON AT SHELTER
          </h3>

          <form onSubmit={handleRegisterPerson} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                Full Name
              </label>
              <input
                type="text"
                required
                placeholder="e.g. Ramesh Kumar"
                value={personName}
                onChange={e => setPersonName(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                  Age
                </label>
                <input
                  type="number"
                  placeholder="e.g. 45"
                  value={personAge}
                  onChange={e => setPersonAge(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                  Gender
                </label>
                <select
                  value={personGender}
                  onChange={e => setPersonGender(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                >
                  <option value="FEMALE">FEMALE</option>
                  <option value="MALE">MALE</option>
                  <option value="OTHER">OTHER</option>
                </select>
              </div>
            </div>

            <button type="submit" className="btn-primary" style={{ justifyContent: 'center' }}>
              <UserPlus size={16} /> Register Person & Update Occupancy
            </button>
          </form>
        </div>

        {/* Recent Registrations Log */}
        <div className="glass-card" style={{ padding: '1.25rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '0.75rem' }}>
            RECENT SHELTER REGISTRATIONS LOG
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxHeight: '280px', overflowY: 'auto' }}>
            {registrations.map(r => (
              <div key={r.id} style={{ padding: '0.65rem', borderRadius: '6px', border: '1px solid var(--border-color)', backgroundColor: '#FFFFFF' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                  <strong style={{ color: 'var(--navy-deep)' }}>{r.name} ({r.age} yrs, {r.gender})</strong>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>{r.time}</span>
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)', marginTop: '0.2rem' }}>
                  Origin: {r.origin} • Reg ID: {r.id}
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>

    </div>
  );
}
