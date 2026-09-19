import React, { useState, useEffect } from 'react';
import { fetchResources, fetchAssignments } from '../services/api';
import StatusBadge from '../components/StatusBadge';
import { Package, MapPin, Clock, ShieldCheck, Activity } from 'lucide-react';

export default function ResourceTrackerAdmin() {
  const [resources, setResources] = useState([]);
  const [assignments, setAssignments] = useState([]);

  useEffect(() => {
    async function loadData() {
      const rList = await fetchResources();
      const aList = await fetchAssignments();
      setResources(rList);
      setAssignments(aList);
    }
    loadData();
  }, []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          RESOURCE ALLOCATION TELEMETRY & ASSET TRACE
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Lifecycle Trace: Available → Allocated → Dispatched → En Route → On Scene → Completed
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Resource ID & Name</th>
              <th>Type</th>
              <th>Current Status</th>
              <th>Assigned Emergency</th>
              <th>Location Coordinates</th>
              <th>ETA</th>
              <th>Milestone Trace</th>
            </tr>
          </thead>
          <tbody>
            {resources.map(r => {
              const matchedAsg = assignments.find(a => a.resource_id === r.id);
              return (
                <tr key={r.id}>
                  <td>
                    <strong style={{ color: 'var(--navy-deep)' }}>{r.name}</strong>
                    <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>ID: {r.id}</div>
                  </td>
                  <td>
                    <span className="badge badge-navy">{r.resource_type}</span>
                  </td>
                  <td>
                    <StatusBadge status={r.status} />
                  </td>
                  <td>
                    {matchedAsg ? (
                      <div>
                        <strong>{matchedAsg.emergency_title}</strong>
                        <div style={{ fontSize: '0.7rem', color: 'var(--text-sub)' }}>{matchedAsg.id}</div>
                      </div>
                    ) : (
                      <span style={{ color: 'var(--text-sub)' }}>Unassigned</span>
                    )}
                  </td>
                  <td>
                    <span style={{ fontSize: '0.8rem', fontFamily: 'monospace' }}>
                      {r.latitude.toFixed(4)}, {r.longitude.toFixed(4)}
                    </span>
                  </td>
                  <td>
                    {matchedAsg ? `~${matchedAsg.eta_minutes} mins` : 'N/A'}
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '0.2rem', alignItems: 'center', fontSize: '0.65rem' }}>
                      <span style={{ background: '#DCFCE7', color: '#16A34A', padding: '2px 4px', borderRadius: '3px' }}>Allocated</span> →
                      <span style={{ background: '#E0F2FE', color: '#0EA5E9', padding: '2px 4px', borderRadius: '3px' }}>En Route</span> →
                      <span style={{ background: '#F3E8FF', color: '#8B5CF6', padding: '2px 4px', borderRadius: '3px' }}>On Scene</span>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

    </div>
  );
}
