import React, { useState } from 'react';
import Sidebar from '../components/Sidebar';
import AdminDashboard from './AdminDashboard';
import LeafletMap from '../components/LeafletMap';
import EmergenciesAdmin from './EmergenciesAdmin';
import OrganizationsManager from './OrganizationsManager';
import DecisionRoutingAdmin from './DecisionRoutingAdmin';
import ResourcesAdmin from './ResourcesAdmin';
import RescueTeamsAdmin from './RescueTeamsAdmin';
import AssignmentsAdmin from './AssignmentsAdmin';
import ReplanningAdmin from './ReplanningAdmin';
import SupplyChainAdmin from './SupplyChainAdmin';
import PopulationAdmin from './PopulationAdmin';
import MissingPersonsAdmin from './MissingPersonsAdmin';
import PoliciesAdmin from './PoliciesAdmin';
import SimulatorAdmin from './SimulatorAdmin';
import NotificationsAdmin from './NotificationsAdmin';
import ReportsAdmin from './ReportsAdmin';
import AuditLogsAdmin from './AuditLogsAdmin';
import LoRaSimulatorAdmin from './LoRaSimulatorAdmin';

export default function AdminLayout() {
  const [activeTab, setActiveTab] = useState('dashboard');

  return (
    <div style={{ display: 'flex', flex: 1, minHeight: 'calc(100vh - 120px)' }}>
      {/* 15-Item Admin Navigation Sidebar */}
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main Content Area */}
      <main style={{ flex: 1, padding: '1.5rem', backgroundColor: 'var(--bg-page)', overflowY: 'auto' }}>
        {activeTab === 'dashboard' && <AdminDashboard />}
        {activeTab === 'live_map' && (
          <div style={{ height: '750px' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--navy-deep)', marginBottom: '1rem' }}>
              FULL-SCREEN LIVE COMMAND MAP LAYER
            </h2>
            <LeafletMap />
          </div>
        )}
        {activeTab === 'emergencies' && <EmergenciesAdmin />}
        {activeTab === 'organizations' && <OrganizationsManager />}
        {activeTab === 'decision_routing' && <DecisionRoutingAdmin />}
        {activeTab === 'resources' && <ResourcesAdmin />}
        {activeTab === 'rescue_teams' && <RescueTeamsAdmin />}
        {activeTab === 'assignments' && <AssignmentsAdmin />}
        {activeTab === 'replanning' && <ReplanningAdmin />}
        {activeTab === 'supply_chain' && <SupplyChainAdmin />}
        {activeTab === 'lora_mesh' && <LoRaSimulatorAdmin />}
        {activeTab === 'population' && <PopulationAdmin />}
        {activeTab === 'missing_persons' && <MissingPersonsAdmin />}
        {activeTab === 'policies' && <PoliciesAdmin />}
        {activeTab === 'simulator' && <SimulatorAdmin />}
        {activeTab === 'notifications' && <NotificationsAdmin />}
        {activeTab === 'reports' && <ReportsAdmin />}
        {activeTab === 'audit_logs' && <AuditLogsAdmin />}
      </main>
    </div>
  );
}
