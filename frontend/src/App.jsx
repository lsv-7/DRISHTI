import React, { useState, useEffect } from 'react';
import Navbar from './components/Navbar';
import VijayawadaMap from './components/VijayawadaMap';
import EmergencyPanel from './components/EmergencyPanel';
import ResourcesPanel from './components/ResourcesPanel';
import PolicyAdvisorPanel from './components/PolicyAdvisorPanel';
import PopulationPanel from './components/PopulationPanel';
import SimulatorPanel from './components/SimulatorPanel';
import AnalyticsPanel from './components/AnalyticsPanel';
import AgentAssistantPanel from './components/AgentAssistantPanel';
import { fetchEmergencies, fetchResources, fetchDisasterZones } from './api';
import './App.css';

function App() {
  const [currentRole, setCurrentRole] = useState('COORDINATOR');
  const [activeTab, setActiveTab] = useState('dashboard');
  const [emergencies, setEmergencies] = useState([]);
  const [resources, setResources] = useState([]);
  const [zones, setZones] = useState([]);
  const [selectedEmergency, setSelectedEmergency] = useState(null);

  const loadData = async () => {
    try {
      const eList = await fetchEmergencies();
      const rList = await fetchResources();
      const zList = await fetchDisasterZones();
      setEmergencies(eList);
      setResources(rList);
      setZones(zList);
      if (eList.length > 0 && !selectedEmergency) {
        setSelectedEmergency(eList[0]);
      }
    } catch (err) {
      console.error("Data loading error:", err);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 10000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar
        currentRole={currentRole}
        setCurrentRole={setCurrentRole}
        activeTab={activeTab}
        setActiveTab={setActiveTab}
      />

      <main style={{ padding: '0 1.5rem 2rem 1.5rem', flex: 1 }}>
        {activeTab === 'dashboard' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <VijayawadaMap
              emergencies={emergencies}
              resources={resources}
              selectedEmergency={selectedEmergency}
              onSelectEmergency={setSelectedEmergency}
            />
            <EmergencyPanel
              emergencies={emergencies}
              selectedEmergency={selectedEmergency}
              setSelectedEmergency={setSelectedEmergency}
              onRefreshData={loadData}
            />
          </div>
        )}

        {activeTab === 'resources' && (
          <ResourcesPanel
            resources={resources}
            emergencies={emergencies}
            onRefreshData={loadData}
          />
        )}

        {activeTab === 'policies' && (
          <PolicyAdvisorPanel currentRole={currentRole} />
        )}

        {activeTab === 'population' && (
          <PopulationPanel />
        )}

        {activeTab === 'simulator' && (
          <SimulatorPanel />
        )}

        {activeTab === 'analytics' && (
          <AnalyticsPanel />
        )}

        {activeTab === 'agent' && (
          <AgentAssistantPanel
            currentRole={currentRole}
            selectedEmergency={selectedEmergency}
          />
        )}
      </main>
    </div>
  );
}

export default App;
