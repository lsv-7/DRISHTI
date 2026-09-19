import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import Topbar from './components/Topbar';
import LoginModal from './components/LoginModal';
import LandingPage from './pages/LandingPage';
import AdminLayout from './admin/AdminLayout';
import OrganizationPortal from './organization/OrganizationPortal';
import './App.css';

function MainAppContent() {
  const { isAuthenticated, currentUser } = useAuth();
  const [showLoginModal, setShowLoginModal] = useState(false);

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column', backgroundColor: 'var(--bg-page)' }}>
      {/* Sleek, Clean Topbar Navigation */}
      <Topbar onOpenLogin={() => setShowLoginModal(true)} />

      {/* Dynamic View Router */}
      <div style={{ display: 'flex', flex: 1, flexDirection: 'column' }}>
        {!isAuthenticated ? (
          <LandingPage onOpenLogin={() => setShowLoginModal(true)} />
        ) : (
          <>
            {(currentUser.portal_type === 'ADMIN' || currentUser.role === 'ADMIN') ? (
              <AdminLayout />
            ) : (
              <OrganizationPortal />
            )}
          </>
        )}
      </div>

      {/* Firebase & Role Authentication Modal */}
      <LoginModal isOpen={showLoginModal} onClose={() => setShowLoginModal(false)} />
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <MainAppContent />
    </AuthProvider>
  );
}
