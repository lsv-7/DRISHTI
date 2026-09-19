import React, { useState, useEffect } from 'react';
import { fetchSupplyShipments, createSupplyShipment } from '../services/api';
import { calculateSupplyDepletion } from '../decision_engine/supplyChainTracker';
import StatusBadge from '../components/StatusBadge';
import { Truck, Package, AlertTriangle, Plus, CheckCircle2, Clock, MapPin, X } from 'lucide-react';

export default function SupplyChainAdmin() {
  const [shipments, setShipments] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [commodity, setCommodity] = useState('Drinking Water (5000L)');
  const [quantity, setQuantity] = useState(5000);
  const [destination, setDestination] = useState('Prakasam Primary Relief Shelter (S01)');

  useEffect(() => {
    async function loadData() {
      const data = await fetchSupplyShipments();
      setShipments(data);
    }
    loadData();
  }, []);

  const depletionForecast = calculateSupplyDepletion({ water_liters: 1500, food_rations: 800 }, 540);

  const handleCreateShipment = async (e) => {
    e.preventDefault();
    const newShipment = await createSupplyShipment({
      commodity,
      quantity: Number(quantity),
      unit: "UNITS",
      origin: "Central Warehouse Alpha",
      destination,
      vehicle_id: `TRK-${Math.floor(Math.random()*800 + 100)}`,
      driver_name: "S. Varma",
      eta_minutes: 25
    });
    setShipments(prev => [newShipment, ...prev]);
    setShowModal(false);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            RELIEF SUPPLY CHAIN & INVENTORY TRACKING
          </h2>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-sub)', margin: '0.2rem 0 0 0' }}>
            Pipeline Tracking: Warehouse → Staging → Delivered to Org → Distributed
          </p>
        </div>

        <button className="btn-primary" onClick={() => setShowModal(true)}>
          <Plus size={16} /> Dispatch Relief Shipment
        </button>
      </div>

      {/* Depletion Forecast Alert Banner */}
      {depletionForecast.needs_replenishment && (
        <div style={{
          backgroundColor: depletionForecast.alert_level === 'CRITICAL' ? 'var(--status-critical-bg)' : 'var(--status-warning-bg)',
          color: depletionForecast.alert_level === 'CRITICAL' ? 'var(--status-critical)' : '#B45309',
          padding: '0.85rem 1.25rem',
          borderRadius: 'var(--radius-md)',
          border: '1px solid var(--border-color)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <AlertTriangle size={20} />
            <div>
              <strong style={{ fontSize: '0.9rem' }}>SUPPLY CHAIN DEPLETION FORECAST ALERT</strong>
              <div style={{ fontSize: '0.8rem' }}>
                Prakasam Shelter (S01): Water remaining ~{depletionForecast.water_days_remaining} days • Food remaining ~{depletionForecast.food_days_remaining} days.
              </div>
            </div>
          </div>
          <button className="btn-primary" onClick={() => setShowModal(true)} style={{ fontSize: '0.8rem', padding: '0.4rem 0.75rem' }}>
            Re-Supply Now
          </button>
        </div>
      )}

      {/* Metric Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--navy-deep)' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-sub)' }}>CENTRAL WAREHOUSE</span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--navy-deep)', marginTop: '0.25rem' }}>
            50,000 Liters Water
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>15,000 Food Rations</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--blue-primary)' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-sub)' }}>SHIPMENTS IN TRANSIT</span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--blue-primary)', marginTop: '0.25rem' }}>
            {shipments.filter(s => s.status === 'IN_TRANSIT').length}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Active Conveyance</div>
        </div>

        <div className="glass-card" style={{ padding: '1rem', borderLeft: '4px solid var(--status-safe)' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-sub)' }}>DELIVERED TODAY</span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--status-safe)', marginTop: '0.25rem' }}>
            {shipments.filter(s => s.status === 'DELIVERED_TO_ORG').length}
          </div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-sub)' }}>Verified Digital Receipt</div>
        </div>
      </div>

      {/* Shipment Tracker Table */}
      <div className="glass-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)', background: '#F8FAFC' }}>
          <h3 style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
            ACTIVE RELIEF SHIPMENTS & PIPELINE TELEMETRY
          </h3>
        </div>

        <table className="custom-table">
          <thead>
            <tr>
              <th>Shipment ID</th>
              <th>Commodity & Quantity</th>
              <th>Origin Depot</th>
              <th>Destination Org</th>
              <th>Vehicle & Driver</th>
              <th>ETA</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {shipments.map(s => (
              <tr key={s.id}>
                <td><strong>{s.id}</strong></td>
                <td>
                  <strong>{s.commodity}</strong>
                </td>
                <td>{s.origin}</td>
                <td>{s.destination}</td>
                <td>
                  <span style={{ fontSize: '0.8rem' }}>{s.vehicle_id} ({s.driver_name})</span>
                </td>
                <td>{s.eta_minutes > 0 ? `~${s.eta_minutes} mins` : 'Arrived'}</td>
                <td>
                  <StatusBadge status={s.status} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Dispatch Modal */}
      {showModal && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '500px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
                Dispatch Relief Shipment
              </h3>
              <button onClick={() => setShowModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                <X size={18} color="#64748B" />
              </button>
            </div>

            <form onSubmit={handleCreateShipment} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                  Commodity Package
                </label>
                <input
                  type="text"
                  required
                  value={commodity}
                  onChange={e => setCommodity(e.target.value)}
                  style={{ width: '100%', padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border-color)' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                  Quantity
                </label>
                <input
                  type="number"
                  required
                  value={quantity}
                  onChange={e => setQuantity(e.target.value)}
                  style={{ width: '100%', padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border-color)' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>
                  Destination Organization
                </label>
                <select
                  value={destination}
                  onChange={e => setDestination(e.target.value)}
                  style={{ width: '100%', padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border-color)' }}
                >
                  <option value="Prakasam Primary Relief Shelter (S01)">Prakasam Primary Relief Shelter (S01)</option>
                  <option value="Vijayawada Govt General Hospital (H01)">Vijayawada Govt General Hospital (H01)</option>
                </select>
              </div>

              <button type="submit" className="btn-primary" style={{ marginTop: '0.5rem', justifyContent: 'center' }}>
                Dispatch Vehicle
              </button>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
