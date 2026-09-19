import React, { useState, useEffect } from 'react';
import StatusBadge from '../../components/StatusBadge';
import { fetchResources } from '../../services/api';
import { sendWebSocketEvent } from '../../services/websocket';
import { Package, Plus, Edit3, CheckCircle2, X, Filter, ShieldCheck } from 'lucide-react';

export default function OrgResources({ orgData }) {
  const [resources, setResources] = useState([
    {
      id: "RES-001",
      name: "Vijayawada Boat Unit 01",
      resource_type: "BOAT",
      capacity: 10,
      current_load: 4,
      status: "AVAILABLE",
      latitude: 16.5080,
      longitude: 80.6400,
      location: "Prakasam Barrage Docks",
      capabilities: ["FLOOD_WATER_RESCUE", "WHEELCHAIR_ACCESSIBLE"]
    },
    {
      id: "RES-002",
      name: "Govt Hospital Emergency Ambulance 04",
      resource_type: "AMBULANCE",
      capacity: 2,
      current_load: 0,
      status: "AVAILABLE",
      latitude: 16.5020,
      longitude: 80.6450,
      location: "Govt General Hospital ER Ward",
      capabilities: ["TRAUMA_ICU", "ADVANCED_LIFE_SUPPORT"]
    },
    {
      id: "RES-003",
      name: "Police Emergency Patrol Unit 09",
      resource_type: "PATROL_CAR",
      capacity: 4,
      current_load: 0,
      status: "AVAILABLE",
      latitude: 16.5100,
      longitude: 80.6350,
      location: "Central Police HQ, Governorpet",
      capabilities: ["TRAFFIC_CONTROL", "MOBILE_SIREN_BROADCAST"]
    },
    {
      id: "RES-004",
      name: "Heavy Duty Debris Clearance Excavator",
      resource_type: "EXCAVATOR",
      capacity: 1,
      current_load: 1,
      status: "DISPATCHED",
      latitude: 16.5000,
      longitude: 80.6550,
      location: "Benz Circle Road Blockage Site R12",
      capabilities: ["DEBRIS_REMOVAL", "HEAVY_LIFTING"]
    }
  ]);

  const [filterType, setFilterType] = useState('ALL');
  const [filterStatus, setFilterStatus] = useState('ALL');

  // Modal State for Add/Edit
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingResource, setEditingResource] = useState(null);

  // Form State
  const [formName, setFormName] = useState('');
  const [formType, setFormType] = useState('BOAT');
  const [formCapacity, setFormCapacity] = useState(5);
  const [formStatus, setFormStatus] = useState('AVAILABLE');
  const [formLocation, setFormLocation] = useState('Vijayawada Central Base');
  const [formCapabilities, setFormCapabilities] = useState('FLOOD_WATER_RESCUE, MEDICAL_EVAC');
  const [notificationMsg, setNotificationMsg] = useState('');

  useEffect(() => {
    async function loadData() {
      try {
        const fetched = await fetchResources();
        if (fetched && fetched.length > 0) {
          setResources(fetched);
        }
      } catch (err) {
        console.warn("Using default resource state");
      }
    }
    loadData();
  }, []);

  const handleOpenAddModal = () => {
    setEditingResource(null);
    setFormName('');
    setFormType('BOAT');
    setFormCapacity(5);
    setFormStatus('AVAILABLE');
    setFormLocation('Vijayawada Central Base');
    setFormCapabilities('FLOOD_WATER_RESCUE, MEDICAL_EVAC');
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (resItem) => {
    setEditingResource(resItem);
    setFormName(resItem.name);
    setFormType(resItem.resource_type || 'BOAT');
    setFormCapacity(resItem.capacity || 5);
    setFormStatus(resItem.status || 'AVAILABLE');
    setFormLocation(resItem.location || 'Vijayawada Base');
    setFormCapabilities(Array.isArray(resItem.capabilities) ? resItem.capabilities.join(', ') : (resItem.capabilities || ''));
    setIsModalOpen(true);
  };

  const handleSaveResource = (e) => {
    e.preventDefault();
    const capArray = formCapabilities.split(',').map(c => c.trim()).filter(Boolean);

    if (editingResource) {
      // Edit
      const updatedList = resources.map(r => {
        if (r.id === editingResource.id) {
          return {
            ...r,
            name: formName,
            resource_type: formType,
            capacity: Number(formCapacity),
            status: formStatus,
            location: formLocation,
            capabilities: capArray
          };
        }
        return r;
      });
      setResources(updatedList);
      setNotificationMsg(`Resource "${formName}" updated successfully!`);

      // WebSocket broadcast
      sendWebSocketEvent("RESOURCE_UPDATED", {
        event: "RESOURCE_UPDATED",
        resource_id: editingResource.id,
        name: formName,
        status: formStatus,
        timestamp: new Date().toISOString()
      });
    } else {
      // Add
      const newRes = {
        id: `RES-${Math.floor(Math.random() * 900 + 100)}`,
        name: formName,
        resource_type: formType,
        capacity: Number(formCapacity),
        current_load: 0,
        status: formStatus,
        latitude: 16.506,
        longitude: 80.648,
        location: formLocation,
        capabilities: capArray
      };
      setResources([newRes, ...resources]);
      setNotificationMsg(`New resource "${formName}" added and broadcasted to Command Center!`);

      sendWebSocketEvent("RESOURCE_ADDED", {
        event: "RESOURCE_ADDED",
        resource: newRes,
        timestamp: new Date().toISOString()
      });
    }

    setIsModalOpen(false);
    setTimeout(() => setNotificationMsg(''), 4000);
  };

  const filteredResources = resources.filter(r => {
    const matchesType = filterType === 'ALL' || r.resource_type === filterType;
    const matchesStatus = filterStatus === 'ALL' || r.status === filterStatus;
    return matchesType && matchesStatus;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            ORGANIZATION RESOURCE INVENTORY & STATUS MANAGEMENT
          </h3>
          <p style={{ fontSize: '0.8rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Register, Update Operational Availability, and Manage Asset Capabilities
          </p>
        </div>

        <button className="btn-primary" onClick={handleOpenAddModal}>
          <Plus size={16} /> Add New Resource
        </button>
      </div>

      {notificationMsg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {notificationMsg}
        </div>
      )}

      {/* Filter Toolbar */}
      <div className="glass-card" style={{ padding: '0.85rem 1rem', display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem', fontWeight: 700, color: 'var(--navy-deep)' }}>
          <Filter size={16} /> Filters:
        </div>

        <select
          value={filterType}
          onChange={e => setFilterType(e.target.value)}
          style={{ padding: '0.4rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
        >
          <option value="ALL">All Resource Types</option>
          <option value="BOAT">Boats & Watercraft</option>
          <option value="AMBULANCE">Ambulances</option>
          <option value="PATROL_CAR">Patrol Units</option>
          <option value="FIRE_ENGINE">Fire Engines</option>
          <option value="EXCAVATOR">Excavators & Heavy Equipment</option>
        </select>

        <select
          value={filterStatus}
          onChange={e => setFilterStatus(e.target.value)}
          style={{ padding: '0.4rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
        >
          <option value="ALL">All Statuses</option>
          <option value="AVAILABLE">Available</option>
          <option value="DISPATCHED">Dispatched / Busy</option>
          <option value="MAINTENANCE">Maintenance</option>
          <option value="UNAVAILABLE">Unavailable</option>
        </select>
      </div>

      {/* Resources Table */}
      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Resource Name & ID</th>
              <th>Type</th>
              <th>Capacity & Load</th>
              <th>Current Location</th>
              <th>Capabilities</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {filteredResources.map(r => (
              <tr key={r.id}>
                <td>
                  <strong style={{ color: 'var(--navy-deep)' }}>{r.name}</strong>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {r.id}</div>
                </td>
                <td><span className="badge badge-navy">{r.resource_type}</span></td>
                <td>
                  <strong>{r.capacity} Seats / Units</strong>
                  {r.current_load !== undefined && (
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>Load: {r.current_load}</div>
                  )}
                </td>
                <td><span style={{ fontSize: '0.8rem' }}>{r.location || 'Base Station'}</span></td>
                <td>
                  <div style={{ display: 'flex', gap: '0.25rem', flexWrap: 'wrap' }}>
                    {Array.isArray(r.capabilities) ? r.capabilities.map((c, i) => (
                      <span key={i} style={{ fontSize: '0.65rem', backgroundColor: 'var(--blue-light)', color: 'var(--blue-primary)', padding: '2px 6px', borderRadius: '4px', fontWeight: 600 }}>
                        {c}
                      </span>
                    )) : <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Standard</span>}
                  </div>
                </td>
                <td><StatusBadge status={r.status} /></td>
                <td>
                  <button
                    className="btn-secondary"
                    style={{ padding: '0.35rem 0.65rem', fontSize: '0.75rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}
                    onClick={() => handleOpenEditModal(r)}
                  >
                    <Edit3 size={14} /> Edit Status
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Add / Edit Resource Modal Overlay */}
      {isModalOpen && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '520px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.75rem' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                {editingResource ? `Edit Resource Status: ${editingResource.name}` : 'Register New Resource Asset'}
              </h3>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                <X size={18} color="#64748B" />
              </button>
            </div>

            <form onSubmit={handleSaveResource} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
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
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Resource Type</label>
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
                    <option value="MEDICAL_TEAM">MEDICAL_TEAM</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Status</label>
                  <select
                    value={formStatus}
                    onChange={e => setFormStatus(e.target.value)}
                    style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                  >
                    <option value="AVAILABLE">AVAILABLE</option>
                    <option value="DISPATCHED">DISPATCHED</option>
                    <option value="MAINTENANCE">MAINTENANCE</option>
                    <option value="UNAVAILABLE">UNAVAILABLE</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.85rem' }}>
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

                <div>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Location Description</label>
                  <input
                    type="text"
                    value={formLocation}
                    onChange={e => setFormLocation(e.target.value)}
                    style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Capabilities (Comma Separated)</label>
                <input
                  type="text"
                  value={formCapabilities}
                  onChange={e => setFormCapabilities(e.target.value)}
                  placeholder="FLOOD_WATER_RESCUE, ADVANCED_LIFE_SUPPORT"
                  style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem', marginTop: '0.5rem', borderTop: '1px solid var(--border-light)', paddingTop: '0.75rem' }}>
                <button type="button" className="btn-secondary" onClick={() => setIsModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary">
                  {editingResource ? 'Save Resource Updates' : 'Register Resource'}
                </button>
              </div>
            </form>

          </div>
        </div>
      )}

    </div>
  );
}
