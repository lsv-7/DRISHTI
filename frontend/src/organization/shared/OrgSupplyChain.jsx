import React, { useState, useEffect } from 'react';
import { fetchSupplyShipments } from '../../services/api';
import StatusBadge from '../../components/StatusBadge';
import { Truck, CheckCircle2, Package, RefreshCw } from 'lucide-react';

export default function OrgSupplyChain({ orgData }) {
  const [shipments, setShipments] = useState([]);

  useEffect(() => {
    async function loadData() {
      const data = await fetchSupplyShipments();
      setShipments(data);
    }
    loadData();
  }, []);

  const handleVerifyDelivery = (id) => {
    setShipments(prev => prev.map(s => s.id === id ? { ...s, status: 'DELIVERED_TO_ORG' } : s));
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      <div>
        <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
          ORGANIZATION INBOUND SUPPLY CHAIN & INVENTORY
        </h3>
        <p style={{ fontSize: '0.8rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
          Verify and Receipt Inbound Relief Shipments from Central Warehouse
        </p>
      </div>

      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <table className="custom-table">
          <thead>
            <tr>
              <th>Shipment ID</th>
              <th>Commodity Package</th>
              <th>Dispatch Origin</th>
              <th>Vehicle & Driver</th>
              <th>ETA</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {shipments.map(s => (
              <tr key={s.id}>
                <td><strong>{s.id}</strong></td>
                <td><strong>{s.commodity}</strong></td>
                <td>{s.origin}</td>
                <td>{s.vehicle_id} ({s.driver_name})</td>
                <td>{s.eta_minutes > 0 ? `~${s.eta_minutes} mins` : 'Arrived'}</td>
                <td><StatusBadge status={s.status} /></td>
                <td>
                  {s.status === 'IN_TRANSIT' ? (
                    <button className="btn-primary" onClick={() => handleVerifyDelivery(s.id)} style={{ fontSize: '0.75rem', padding: '0.3rem 0.6rem' }}>
                      <CheckCircle2 size={14} /> Verify & Accept Receipt
                    </button>
                  ) : (
                    <span style={{ color: 'var(--status-safe)', fontWeight: 700, fontSize: '0.75rem' }}>✓ Stock Added</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
