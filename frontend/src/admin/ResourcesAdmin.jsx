import React, { useState, useEffect } from 'react';
import { fetchResources, createResource, submitMobileResource, DEFAULT_RESOURCES } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { Package, Plus, Smartphone, Building2, ShieldCheck, CheckCircle2, X } from 'lucide-react';

export default function ResourcesAdmin() {
  const [resources, setResources] = useState(DEFAULT_RESOURCES);
  const [isMobileModalOpen, setIsMobileModalOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [notificationMsg, setNotificationMsg] = useState('');

  // Form states
  const [formName, setFormName] = useState('');
  const [formType, setFormType] = useState('AMBULANCE');
  const [formCapacity, setFormCapacity] = useState(4);
  const [formLocation, setFormLocation] = useState('Vijayawada Mobile Unit');
  const [formCapabilities, setFormCapabilities] = useState('MOBILE_TRIAGE, OXYGEN_SUPPORT');

  const loadData = async () => {
    const data = await fetchResources();
    setResources((data && data.length > 0) ? data : DEFAULT_RESOURCES);
  };

  useEffect(() => {
    loadData();
    window.addEventListener('drishti_resource_updated', loadData);
    const interval = setInterval(loadData, 3000);
    return () => {
      window.removeEventListener('drishti_resource_updated', loadData);
      clearInterval(interval);
    };
  }, []);

  const handleSimulateMobileSubmission = async (e) => {
    e.preventDefault();
    const payload = {
      name: formName || `Citizen Volunteer Ambulance ${Math.floor(Math.random()*90+10)}`,
      resource_type: formType,
      capacity: Number(formCapacity),
      location: formLocation,
      capabilities: formCapabilities.split(',').map(s => s.trim()).filter(Boolean)
    };

    await submitMobileResource(payload);
    setNotificationMsg(`Mobile App Resource "${payload.name}" submitted & synchronized to Admin Dashboard!`);
    setIsMobileModalOpen(false);
    await loadData();
    setTimeout(() => setNotificationMsg(''), 4000);
  };

  const handleAddAdminResource = async (e) => {
    e.preventDefault();
    const payload = {
      name: formName || `Command Center Resource ${Math.floor(Math.random()*90+10)}`,
      resource_type: formType,
      capacity: Number(formCapacity),
      location: formLocation,
      capabilities: formCapabilities.split(',').map(s => s.trim()).filter(Boolean)
    };

    await createResource(payload, 'SYSTEM_COMMAND');
    setNotificationMsg(`System Resource "${payload.name}" registered & broadcasted!`);
    setIsAddModalOpen(false);
    await loadData();
    setTimeout(() => setNotificationMsg(''), 4000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Header with Quick Action Buttons */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            HETEROGENEOUS RESOURCE ALLOCATIONS & INVENTORY
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Unified Real-Time View of Mobile Submissions, Organization Assets & Command Center Resources
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.65rem' }}>
          <button
            className="btn-secondary"
            onClick={() => {
              setFormName("Mobile Emergency Rescue Craft");
              setFormType("BOAT");
              setFormCapacity(6);
              setFormLocation("Kothapeta Low-Lying Sector");
              setFormCapabilities("FLOOD_WATER_RESCUE, SHALLOW_WATER");
              setIsMobileModalOpen(true);
            }}
            style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', border: '1px solid var(--blue-primary)', color: 'var(--blue-primary)', fontWeight: 700 }}
          >
            <Smartphone size={16} /> Simulate Mobile App Submission
          </button>

          <button
            className="btn-primary"
            onClick={() => {
              setFormName("Prakasam Heavy Rescue Crane 01");
              setFormType("EXCAVATOR");
              setFormCapacity(2);
              setFormLocation("Prakasam Control Station");
              setFormCapabilities("HEAVY_LIFTING, DEBRIS_REMOVAL");
              setIsAddModalOpen(true);
            }}
            style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}
          >
            <Plus size={16} /> Register Command Resource
          </button>
        </div>
      </div>

      {notificationMsg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {notificationMsg}
        </div>
      )}

      {/* Resources Table */}
      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Resource Name & ID</th>
              <th>Source / Origin</th>
              <th>Type</th>
              <th>Capacity / Load</th>
              <th>Location</th>
              <th>Status</th>
              <th>Capabilities</th>
            </tr>
          </thead>
          <tbody>
            {resources.map(r => {
              const isMobile = r.source === 'MOBILE_FLUTTER' || r.submitted_by_mobile || r.id?.includes('MOB');
              const isOrg = r.source && r.source !== 'SYSTEM_COMMAND' && !isMobile;

              return (
                <tr key={r.id}>
                  <td>
                    <strong style={{ color: 'var(--navy-deep)' }}>{r.name}</strong>
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {r.id}</div>
                  </td>
                  <td>
                    {isMobile ? (
                      <span className="badge" style={{ backgroundColor: '#E0F2FE', color: '#0369A1', border: '1px solid #7DD3FC', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.3rem' }}>
                        <Smartphone size={12} /> Mobile Flutter App
                      </span>
                    ) : isOrg ? (
                      <span className="badge" style={{ backgroundColor: '#F0FDF4', color: '#15803D', border: '1px solid #86EFAC', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.3rem' }}>
                        <Building2 size={12} /> {r.source || 'Organization'}
                      </span>
                    ) : (
                      <span className="badge" style={{ backgroundColor: '#FEF3C7', color: '#B45309', border: '1px solid #FDE68A', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '0.3rem' }}>
                        <ShieldCheck size={12} /> Command Center
                      </span>
                    )}
                  </td>
                  <td><span className="badge badge-navy">{r.resource_type}</span></td>
                  <td><strong>{r.current_load || 0} / {r.capacity} Seats/Units</strong></td>
                  <td><span style={{ fontSize: '0.8rem' }}>{r.location || 'Vijayawada Base'}</span></td>
                  <td><StatusBadge status={r.status} /></td>
                  <td>
                    <div style={{ display: 'flex', gap: '0.25rem', flexWrap: 'wrap' }}>
                      {(r.capabilities || []).map((c, i) => (
                        <span key={i} style={{ fontSize: '0.7rem', background: '#F1F5F9', padding: '2px 6px', borderRadius: '4px', fontWeight: 600 }}>
                          {c}
                        </span>
                      ))}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Modal for Mobile App Resource Submission Simulation */}
      {isMobileModalOpen && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '500px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Smartphone size={20} color="var(--blue-primary)" />
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Simulate Mobile (Flutter) Resource Submission
                </h3>
              </div>
              <button onClick={() => setIsMobileModalOpen(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                <X size={18} color="#64748B" />
              </button>
            </div>

            <form onSubmit={handleSimulateMobileSubmission} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Resource Name (from Mobile App)</label>
                <input
                  type="text"
                  required
                  value={formName}
                  onChange={e => setFormName(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Type</label>
                  <select
                    value={formType}
                    onChange={e => setFormType(e.target.value)}
                    style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                  >
                    <option value="BOAT">BOAT</option>
                    <option value="AMBULANCE">AMBULANCE</option>
                    <option value="PATROL_CAR">PATROL_CAR</option>
                    <option value="FIRE_ENGINE">FIRE_ENGINE</option>
                    <option value="EXCAVATOR">EXCAVATOR</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Capacity</label>
                  <input
                    type="number"
                    min={1}
                    value={formCapacity}
                    onChange={e => setFormCapacity(e.target.value)}
                    style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>GPS Location Description</label>
                <input
                  type="text"
                  value={formLocation}
                  onChange={e => setFormLocation(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Capabilities (Comma Separated)</label>
                <input
                  type="text"
                  value={formCapabilities}
                  onChange={e => setFormCapabilities(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', marginTop: '0.5rem', borderTop: '1px solid var(--border-light)', paddingTop: '0.75rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setIsMobileModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary">
                  Submit from Mobile App to Dashboard
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal for Admin System Resource Registration */}
      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '500px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <ShieldCheck size={20} color="var(--blue-primary)" />
                <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                  Register Command Center Resource
                </h3>
              </div>
              <button onClick={() => setIsAddModalOpen(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                <X size={18} color="#64748B" />
              </button>
            </div>

            <form onSubmit={handleAddAdminResource} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Resource Name</label>
                <input
                  type="text"
                  required
                  value={formName}
                  onChange={e => setFormName(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Type</label>
                  <select
                    value={formType}
                    onChange={e => setFormType(e.target.value)}
                    style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                  >
                    <option value="EXCAVATOR">EXCAVATOR</option>
                    <option value="BOAT">BOAT</option>
                    <option value="AMBULANCE">AMBULANCE</option>
                    <option value="PATROL_CAR">PATROL_CAR</option>
                    <option value="FIRE_ENGINE">FIRE_ENGINE</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Capacity</label>
                  <input
                    type="number"
                    min={1}
                    value={formCapacity}
                    onChange={e => setFormCapacity(e.target.value)}
                    style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Base Location</label>
                <input
                  type="text"
                  value={formLocation}
                  onChange={e => setFormLocation(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Capabilities</label>
                <input
                  type="text"
                  value={formCapabilities}
                  onChange={e => setFormCapabilities(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', marginTop: '0.5rem', borderTop: '1px solid var(--border-light)', paddingTop: '0.75rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary">
                  Register System Resource
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}

