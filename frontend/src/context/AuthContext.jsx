import React, { createContext, useContext, useState, useEffect } from 'react';
import { auth } from '../services/firebase';
import { signInWithEmailAndPassword, signOut as fbSignOut } from 'firebase/auth';
import { apiLogin } from '../services/api';

const AuthContext = createContext(null);

export const SEED_ACCOUNTS = {
  ADMIN: {
    id: "USR-ADMIN-01",
    email: "admin@disaster.gov",
    full_name: "Commander Sarah Jenkins",
    portal_type: "ADMIN",
    role: "ADMIN",
    organization_id: "HQ-01",
    organization_name: "Disaster Command Center HQ",
    organization_type: "ADMIN"
  },
  HOSPITAL: {
    id: "USR-HOSP-01",
    email: "hospital@disaster.gov",
    full_name: "Dr. A. Sharma (Chief Medical Officer)",
    portal_type: "ORGANISATION",
    role: "ORGANISATION",
    organization_id: "H01",
    organization_name: "Vijayawada Govt General Hospital",
    organization_type: "HOSPITAL"
  },
  POLICE: {
    id: "USR-POL-01",
    email: "police@disaster.gov",
    full_name: "Inspector R. Verma",
    portal_type: "ORGANISATION",
    role: "ORGANISATION",
    organization_id: "P01",
    organization_name: "Central Police Control HQ",
    organization_type: "POLICE"
  },
  FIRE: {
    id: "USR-FIRE-01",
    email: "fire@disaster.gov",
    full_name: "Captain K. Mohan",
    portal_type: "ORGANISATION",
    role: "ORGANISATION",
    organization_id: "F01",
    organization_name: "Fire & Emergency Services HQ",
    organization_type: "FIRE"
  },
  SHELTER: {
    id: "USR-SHEL-01",
    email: "shelter@disaster.gov",
    full_name: "Manager P. Rao",
    portal_type: "ORGANISATION",
    role: "ORGANISATION",
    organization_id: "S01",
    organization_name: "Prakasam Primary Relief Shelter",
    organization_type: "SHELTER"
  },
  ROAD: {
    id: "USR-ROAD-01",
    email: "road@disaster.gov",
    full_name: "Engineer S. Reddy",
    portal_type: "ORGANISATION",
    role: "ORGANISATION",
    organization_id: "R01",
    organization_name: "Vijayawada Roads & Infrastructure Division",
    organization_type: "ROAD"
  }
};

export function AuthProvider({ children }) {
  const [currentUser, setCurrentUser] = useState(() => {
    const saved = localStorage.getItem("disaster_response_user");
    return saved ? JSON.parse(saved) : null;
  });

  const [authLoading, setAuthLoading] = useState(false);

  useEffect(() => {
    if (currentUser) {
      localStorage.setItem("disaster_response_user", JSON.stringify(currentUser));
    } else {
      localStorage.removeItem("disaster_response_user");
    }
  }, [currentUser]);

  const loginWithDemoAccount = (key) => {
    const account = SEED_ACCOUNTS[key] || SEED_ACCOUNTS.ADMIN;
    // Attempt background login against backend to acquire live JWT token if backend is reachable
    apiLogin(
      account.email,
      "password",
      account.role === "ADMIN" ? "ADMIN" : "COORDINATOR",
      account.full_name
    ).then(authData => {
      if (authData?.access_token) {
        localStorage.setItem("disaster_response_token", authData.access_token);
      }
    }).catch(err => {
      // Offline fallback: silent ignore
    });

    setCurrentUser(account);
    return account;
  };

  const loginWithCredentials = async (email, password, portalType = "ADMIN", orgType = "HOSPITAL") => {
    setAuthLoading(true);
    try {
      // 1. Attempt FastAPI backend authentication first
      let backendUser = null;
      try {
        const authData = await apiLogin(
          email,
          password,
          portalType === "ADMIN" ? "ADMIN" : "COORDINATOR",
          email ? email.split('@')[0].toUpperCase() : "DRISHTI User"
        );
        if (authData?.access_token) {
          localStorage.setItem("disaster_response_token", authData.access_token);
          backendUser = authData.user;
        }
      } catch (backendErr) {
        console.warn("Backend auth unavailable or offline, proceeding with offline credentials:", backendErr);
      }

      // 2. Attempt Firebase Login if configured
      await signInWithEmailAndPassword(auth, email, password).catch(() => {
        // Fallback for demo credentials if offline
      });

      const matchedSeed = Object.values(SEED_ACCOUNTS).find(acc => acc.email.toLowerCase() === email.toLowerCase());
      
      const userObj = matchedSeed || {
        id: backendUser?.id || `USR-${Date.now()}`,
        email: backendUser?.email || email,
        full_name: backendUser?.full_name || email.split('@')[0].toUpperCase(),
        portal_type: portalType,
        role: portalType === "ADMIN" ? "ADMIN" : "ORGANISATION",
        organization_id: `${orgType}-01`,
        organization_name: `${orgType} Department`,
        organization_type: portalType === "ADMIN" ? "ADMIN" : orgType
      };

      setCurrentUser(userObj);
      setAuthLoading(false);
      return userObj;
    } catch (err) {
      setAuthLoading(false);
      throw err;
    }
  };

  const logout = async () => {
    try {
      await fbSignOut(auth).catch(() => {});
    } catch (e) {}
    localStorage.removeItem("disaster_response_token");
    setCurrentUser(null);
  };

  return (
    <AuthContext.Provider value={{
      currentUser,
      isAuthenticated: !!currentUser,
      authLoading,
      loginWithDemoAccount,
      loginWithCredentials,
      logout,
      SEED_ACCOUNTS
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
