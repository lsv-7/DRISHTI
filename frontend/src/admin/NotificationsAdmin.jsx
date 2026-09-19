import React from 'react';
import StatusBadge from '../components/StatusBadge';
import { Bell } from 'lucide-react';

export default function NotificationsAdmin() {
  const notifications = [
    { id: "N1", title: "Road Blockage Verified (R12)", message: "Police verified heavy inundation on Prakasam Barrage road.", time: "10 mins ago", category: "ALERT" },
    { id: "N2", title: "Hospital ICU Capacity Reached Threshold", message: "Vijayawada General Hospital ICU beds remaining: 2.", time: "25 mins ago", category: "WARNING" }
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          SYSTEM NOTIFICATIONS & BROADCAST STREAM
        </h2>
        <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Real-time Alerts Broadcasted to Responders and Organizations
        </p>
      </div>

      <div className="glass-card" style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
        {notifications.map(n => (
          <div key={n.id} style={{ padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', backgroundColor: '#FFFFFF' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.25rem' }}>
              <strong style={{ fontSize: '0.9rem', color: 'var(--navy-deep)' }}>{n.title}</strong>
              <span style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>{n.time}</span>
            </div>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-main)', margin: 0 }}>{n.message}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
