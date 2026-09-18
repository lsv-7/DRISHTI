import React, { useState, useEffect } from 'react';
import { Truck, Activity, CheckCircle2, AlertCircle, Navigation, Shield, User, Clock, Check } from 'lucide-react';
import { fetchResources, fetchEmergencies, fetchMatchingResources, fetchAssignments, allocateResource } from '../api';

export default function ResourcesPanel() {
  const [resources, setResources] = useState([]);
  const [emergencies, setEmergencies] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [selectedResource, setSelectedResource] = useState(null);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const rList = await fetchResources();
      const eList = await fetchEmergencies();
      const aList = await fetchAssignments();
      setResources(rList);
      setEmergencies(eList);
      setAssignments(aList);
      if (rList.length > 0 && !selectedResource) {
        setSelectedResource(rList[0]);
      } else if (selectedResource) {
        const updated = rList.find(r => r.id === selectedResource.id);
        if (updated) setSelectedResource(updated);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const totalCapacity = resources.reduce((acc, r) => acc + (r.capacity || 0), 0);
  const totalLoad = resources.reduce((acc, r) => acc + (r.current_load || 0), 0);
  const availableCount = resources.filter(r => r.status === 'AVAILABLE').length;

  const getTypeBadge = (type) => {
    switch (type?.toUpperCase()) {
      case 'BOAT':
      case 'BOAT_TEAM': return 'badge-high';
      case 'AMBULANCE': return 'badge-critical';
      case 'MEDICAL_TEAM': return 'badge-success';
      case 'SHELTER': return 'badge-low';
      default: return 'badge-medium';
    }
  };

  // Find assignments for the currently selected resource
  const resourceAssignments = assignments.filter(a => a.resource_id === selectedResource?.id);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* KPI Stats Header */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem' }}>
        <div className="glass-panel" style={{ padding: '1rem', textAlign: 'center' }}>
          <div style={{ fontSize: '0.75rem', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 700 }}>Total Fleet Units</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f8fafc', marginTop: '0.25rem' }}>{resources.length}</div>
          <div style={{ fontSize: '0.7rem', color: '#10b981', marginTop: '0.2rem' }}>Registered Relief Resources</div>
        </div>

        <div className="glass-panel" style={{ padding: '1rem', textAlign: 'center' }}>
          <div style={{ fontSize: '0.75rem', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 700 }}>Available Units</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: availableCount > 0 ? '#10b981' : '#f59e0b', marginTop: '0.25rem' }}>{availableCount} / {resources.length}</div>
          <div style={{ fontSize: '0.7rem', color: '#94a3b8', marginTop: '0.2rem' }}>Ready for Instant Deployment</div>
        </div>

        <div className="glass-panel" style={{ padding: '1rem', textAlign: 'center' }}>
          <div style={{ fontSize: '0.75rem', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 700 }}>Passenger / Rescue Capacity</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#3b82f6', marginTop: '0.25rem' }}>{totalLoad} / {totalCapacity}</div>
          <div style={{ fontSize: '0.7rem', color: '#94a3b8', marginTop: '0.2rem' }}>Active Personnel Load</div>
        </div>

        <div className="glass-panel" style={{ padding: '1rem', textAlign: 'center' }}>
          <div style={{ fontSize: '0.75rem', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 700 }}>Active Allocations</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f59e0b', marginTop: '0.25rem' }}>
            {assignments.length}
          </div>
          <div style={{ fontSize: '0.7rem', color: '#f59e0b', marginTop: '0.2rem' }}>Dispatched Fleet Assignments</div>
        </div>
      </div>

      {/* Main Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1.6fr', gap: '1.25rem' }}>
        {/* Resource List */}
        <div className="glass-panel">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <h2 style={{ fontSize: '1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Truck size={18} color="#3b82f6" />
              Resource Fleet & Capability Management ({resources.length})
            </h2>
            <span className="badge badge-low">Live Operational Fleet</span>
          </div>

          {loading ? (
            <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Loading resource fleet inventory...</p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', maxHeight: '520px', overflowY: 'auto' }}>
              {resources.map((r) => (
                <div
                  key={r.id}
                  onClick={() => setSelectedResource(r)}
                  style={{
                    background: selectedResource?.id === r.id ? 'rgba(59, 130, 246, 0.15)' : 'rgba(15, 23, 42, 0.5)',
                    border: selectedResource?.id === r.id ? '1px solid #3b82f6' : '1px solid var(--border-color)',
                    borderRadius: '8px',
                    padding: '0.85rem',
                    cursor: 'pointer',
                    transition: 'all 0.2s ease'
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <span style={{ fontSize: '0.9rem', fontWeight: 700, color: '#f8fafc' }}>{r.name}</span>
                      <span className={`badge ${getTypeBadge(r.resource_type)}`} style={{ fontSize: '0.65rem' }}>{r.resource_type}</span>
                    </div>
                    <span className={`badge ${r.status === 'AVAILABLE' ? 'badge-success' : 'badge-high'}`}>
                      {r.status}
                    </span>
                  </div>

                  <div style={{ fontSize: '0.75rem', color: '#94a3b8', marginBottom: '0.5rem' }}>
                    GPS Position: ({r.latitude}, {r.longitude}) • Capacity: {r.capacity} pax (Load: {r.current_load})
                  </div>

                  {/* Capabilities */}
                  <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap' }}>
                    {(r.capabilities || []).map((cap, i) => (
                      <span key={i} style={{ fontSize: '0.65rem', color: '#93c5fd', background: 'rgba(59, 130, 246, 0.1)', padding: '0.15rem 0.4rem', borderRadius: '4px', border: '1px solid rgba(59, 130, 246, 0.2)' }}>
                        {cap}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Selected Resource Detail & Incident Allocation View */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Selected Resource Control Panel */}
          <div className="glass-panel">
            <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '0.85rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Activity size={18} color="#10b981" />
              Resource Dispatch & Allocation Controller
            </h2>

            {selectedResource ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                <div style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '1rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ fontSize: '1rem', fontWeight: 800, color: '#3b82f6' }}>{selectedResource.name}</div>
                    <span className={`badge ${selectedResource.status === 'AVAILABLE' ? 'badge-success' : 'badge-high'}`}>
                      {selectedResource.status}
                    </span>
                  </div>
                  <div style={{ fontSize: '0.8rem', color: '#94a3b8', marginTop: '0.3rem' }}>
                    Resource Type: <strong>{selectedResource.resource_type}</strong> • Capacity: <strong>{selectedResource.current_load} / {selectedResource.capacity} pax</strong>
                  </div>
                  <div style={{ fontSize: '0.8rem', color: '#94a3b8', marginTop: '0.15rem' }}>
                    GPS Coordinates: ({selectedResource.latitude}, {selectedResource.longitude})
                  </div>
                </div>

                {/* Status Notice if Dispatched */}
                {selectedResource.status === 'DISPATCHED' && (
                  <div style={{ background: 'rgba(245, 158, 11, 0.15)', border: '1px solid rgba(245, 158, 11, 0.3)', borderRadius: '8px', padding: '0.65rem 0.85rem', fontSize: '0.78rem', color: '#fde68a', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Clock size={16} color="#f59e0b" />
                    <div>
                      <strong>Active Dispatch Status:</strong> This resource is currently deployed in the field. Re-allocating below will re-assign this resource.
                    </div>
                  </div>
                )}

                {/* Allocate Resource to Incident Dropdown Form */}
                <div style={{ background: 'rgba(30, 41, 59, 0.6)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)' }}>
                  <h4 style={{ fontSize: '0.8rem', fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', marginBottom: '0.5rem' }}>
                    Select Target Incident for Allocation
                  </h4>
                  {emergencies.length > 0 ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
                      <select
                        id="targetEmergencySelect"
                        style={{
                          background: 'rgba(15, 23, 42, 0.9)',
                          color: '#f8fafc',
                          border: '1px solid var(--border-color)',
                          borderRadius: '6px',
                          padding: '0.5rem',
                          fontSize: '0.8rem',
                          fontWeight: 600
                        }}
                      >
                        {emergencies.map((e) => (
                          <option key={e.id} value={e.id}>
                            [{e.status === 'ASSIGNED' ? 'ASSIGNED' : 'PENDING'}] [{e.priority_level}] {e.title} (Vuln: {e.vulnerability_score})
                          </option>
                        ))}
                      </select>

                      <button
                        onClick={async () => {
                          const selectEl = document.getElementById('targetEmergencySelect');
                          const emergencyId = selectEl ? selectEl.value : (emergencies[0] && emergencies[0].id);
                          if (!emergencyId) return;

                          const res = await allocateResource(selectedResource.id, emergencyId);
                          if (res.status === 'SUCCESS') {
                            alert(res.message);
                            await loadData();
                          } else {
                            alert(res.message || 'Allocation failed');
                          }
                        }}
                        className="btn btn-primary"
                        style={{ padding: '0.5rem 0.85rem', fontSize: '0.8rem', justifyContent: 'center' }}
                      >
                        <CheckCircle2 size={16} /> Allocate & Dispatch {selectedResource.name}
                      </button>
                    </div>
                  ) : (
                    <p style={{ fontSize: '0.75rem', color: '#94a3b8' }}>No active emergency incidents available.</p>
                  )}
                </div>
              </div>
            ) : (
              <p style={{ color: '#94a3b8', fontSize: '0.85rem' }}>Select a resource from the list to view capability details and allocation status.</p>
            )}
          </div>

          {/* Active Allocations Record Table */}
          <div className="glass-panel">
            <h2 style={{ fontSize: '0.95rem', fontWeight: 700, marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Shield size={16} color="#3b82f6" />
              Live Incident & Resource Allocation Registry ({assignments.length})
            </h2>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxHeight: '220px', overflowY: 'auto' }}>
              {assignments.length === 0 ? (
                <p style={{ color: '#94a3b8', fontSize: '0.8rem' }}>No active resource allocations recorded yet. Allocate a resource above to view live records.</p>
              ) : (
                assignments.map((asg) => (
                  <div key={asg.id} style={{ background: 'rgba(15, 23, 42, 0.6)', padding: '0.65rem 0.85rem', borderRadius: '6px', border: '1px solid var(--border-color)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.2rem' }}>
                      <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#f8fafc' }}>
                        {asg.resource_name} &rarr; {asg.emergency_title}
                      </span>
                      <span className="badge badge-success" style={{ fontSize: '0.65rem' }}>
                        {asg.status}
                      </span>
                    </div>
                    <div style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
                      Assignment ID: {asg.id} • ETA: ~{asg.eta_minutes} mins • Allocated: {new Date(asg.assigned_at).toLocaleTimeString()}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
