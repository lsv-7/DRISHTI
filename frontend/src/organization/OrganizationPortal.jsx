import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import CommonOrgHeader from './CommonOrgHeader';
import HospitalDashboard from './HospitalDashboard';
import PoliceDashboard from './PoliceDashboard';
import FireDashboard from './FireDashboard';
import ShelterDashboard from './ShelterDashboard';
import RoadDashboard from './RoadDashboard';
import OrgIncidents from './shared/OrgIncidents';
import OrgAssignments from './shared/OrgAssignments';
import OrgResources from './shared/OrgResources';
import OrgSupplyChain from './shared/OrgSupplyChain';
import OrgAlerts from './shared/OrgAlerts';
import OrgOperationalUpdates from './shared/OrgOperationalUpdates';
import OrgProfile from './shared/OrgProfile';
import { fetchOrganizations } from '../services/api';
import {
  LayoutDashboard, AlertTriangle, ShieldCheck, Package, Truck, Bell, History, User
} from 'lucide-react';

export default function OrganizationPortal() {
  const { currentUser } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [orgData, setOrgData] = useState({
    id: currentUser.organization_id || "H01",
    name: currentUser.organization_name || "Vijayawada General Hospital",
    organization_type: currentUser.organization_type || "HOSPITAL",
    operational_status: "OPERATIONAL",
    location: "Vijayawada Central Sector",
    active_assignments: 3,
    available_resources: "Operational Fleet"
  });

  useEffect(() => {
    async function loadOrgInfo() {
      const allOrgs = await fetchOrganizations();
      const match = allOrgs.find(o => o.organization_type === currentUser.organization_type);
      if (match) {
        setOrgData(match);
      } else {
        setOrgData({
          id: currentUser.organization_id || `${currentUser.organization_type}-01`,
          name: currentUser.organization_name || `${currentUser.organization_type} Center`,
          organization_type: currentUser.organization_type,
          operational_status: "OPERATIONAL",
          location: "Vijayawada Sector",
          active_assignments: 3,
          available_resources: "Operational"
        });
      }
    }
    loadOrgInfo();
  }, [currentUser.organization_type]);

  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'resources', label: 'Resources Available', icon: Package },
    { id: 'assignments', label: 'Allocation', icon: ShieldCheck },
    { id: 'profile', label: 'Profile', icon: User },
    { id: 'alerts', label: 'Alerts', icon: Bell },
    { id: 'incidents', label: 'Disaster Incidents', icon: AlertTriangle },
    { id: 'supply_chain', label: 'Supply Chain & Inventory', icon: Truck }
  ];

  return (
    <div style={{ padding: '1.5rem', backgroundColor: 'var(--bg-page)', flex: 1 }}>
      
      {/* Common Organization Header with Live Status Selector & Audit Logger */}
      <CommonOrgHeader
        orgData={orgData}
        onStatusUpdated={(newStatus) => setOrgData(prev => ({ ...prev, operational_status: newStatus }))}
      />

      {/* Shared Organization Navigation Bar */}
      <div style={{
        display: 'flex',
        gap: '0.35rem',
        borderBottom: '2px solid var(--border-color)',
        marginBottom: '1.25rem',
        overflowX: 'auto',
        paddingBottom: '2px'
      }}>
        {tabs.map(t => {
          const Icon = t.icon;
          const isActive = activeTab === t.id;
          return (
            <button
              key={t.id}
              onClick={() => setActiveTab(t.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.45rem',
                padding: '0.65rem 1rem',
                border: 'none',
                borderBottom: isActive ? '3px solid var(--blue-primary)' : '3px solid transparent',
                backgroundColor: 'transparent',
                color: isActive ? 'var(--blue-primary)' : 'var(--text-sub)',
                fontWeight: isActive ? 800 : 500,
                fontSize: '0.85rem',
                cursor: 'pointer',
                whiteSpace: 'nowrap'
              }}
            >
              <Icon size={16} color={isActive ? 'var(--blue-primary)' : '#64748B'} />
              <span>{t.label}</span>
            </button>
          );
        })}
      </div>

      {/* Dynamic Content View */}
      <div>
        {activeTab === 'dashboard' && (
          <>
            {orgData.organization_type === 'HOSPITAL' && <HospitalDashboard orgData={orgData} />}
            {orgData.organization_type === 'POLICE' && <PoliceDashboard orgData={orgData} />}
            {orgData.organization_type === 'FIRE' && <FireDashboard orgData={orgData} />}
            {orgData.organization_type === 'SHELTER' && <ShelterDashboard orgData={orgData} />}
            {orgData.organization_type === 'ROAD' && <RoadDashboard orgData={orgData} />}
          </>
        )}

        {activeTab === 'incidents' && <OrgIncidents />}
        {activeTab === 'assignments' && <OrgAssignments />}
        {activeTab === 'resources' && <OrgResources />}
        {activeTab === 'supply_chain' && <OrgSupplyChain orgData={orgData} />}
        {activeTab === 'alerts' && <OrgAlerts />}
        {activeTab === 'updates' && <OrgOperationalUpdates />}
        {activeTab === 'profile' && <OrgProfile />}
      </div>

    </div>
  );
}
