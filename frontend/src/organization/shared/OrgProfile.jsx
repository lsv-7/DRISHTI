import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { sendWebSocketEvent } from '../../services/websocket';
import { Building2, Save, CheckCircle2, Phone, Mail, MapPin, ShieldCheck } from 'lucide-react';

export default function OrgProfile() {
  const { currentUser } = useAuth();

  const [orgName, setOrgName] = useState(currentUser?.organization_name || "Vijayawada Govt General Hospital");
  const [contactPerson, setContactPerson] = useState("Dr. K. Srinivas (Duty Medical Officer)");
  const [phone, setPhone] = useState("+91 866 257 4432");
  const [emergencyHotline, setEmergencyHotline] = useState("108 / +91 944 001 2233");
  const [email, setEmail] = useState("control@hospital.vj.gov.in");
  const [address, setAddress] = useState("Kothapeta Main Road, Vijayawada, AP 520001");
  const [operatingHours, setOperatingHours] = useState("24x7 Emergency Operations");
  const [msg, setMsg] = useState('');

  const handleSaveProfile = (e) => {
    e.preventDefault();
    setMsg("Organization details updated successfully!");

    sendWebSocketEvent("ORG_PROFILE_UPDATED", {
      event: "ORG_PROFILE_UPDATED",
      organization_id: currentUser?.organization_id || "H01",
      name: orgName,
      contact_person: contactPerson,
      phone,
      timestamp: new Date().toISOString()
    });

    setTimeout(() => setMsg(''), 4000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      
      {msg && (
        <div style={{ backgroundColor: 'var(--status-safe-bg)', color: 'var(--status-safe)', padding: '0.85rem', borderRadius: '8px', border: '1px solid var(--border-color)', fontWeight: 700 }}>
          <CheckCircle2 size={18} inline style={{ marginRight: '0.5rem' }} />
          {msg}
        </div>
      )}

      <div className="glass-card" style={{ padding: '1.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.25rem', borderBottom: '1px solid var(--border-light)', paddingBottom: '0.85rem' }}>
          <div style={{ backgroundColor: 'var(--blue-light)', padding: '0.65rem', borderRadius: '8px' }}>
            <Building2 size={24} color="var(--blue-primary)" />
          </div>
          <div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--navy-deep)', margin: 0 }}>
              ORGANIZATION PROFILE & CONTACT DATA MANAGEMENT
            </h3>
            <p style={{ fontSize: '0.8rem', color: 'var(--text-sub)', margin: 0 }}>
              Official Directory Information & Emergency Response Contacts
            </p>
          </div>
        </div>

        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Organization Name</label>
              <input
                type="text"
                required
                value={orgName}
                onChange={e => setOrgName(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Organization Category / Type</label>
              <input
                type="text"
                disabled
                value={currentUser?.organization_type || "HOSPITAL"}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem', backgroundColor: '#F1F5F9' }}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Duty Officer / Contact Person</label>
              <input
                type="text"
                required
                value={contactPerson}
                onChange={e => setContactPerson(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Official Contact Number</label>
              <input
                type="text"
                required
                value={phone}
                onChange={e => setPhone(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Emergency Dispatch Hotline</label>
              <input
                type="text"
                value={emergencyHotline}
                onChange={e => setEmergencyHotline(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Official Email Address</label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
              />
            </div>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.25rem' }}>Physical Address & Location</label>
            <input
              type="text"
              value={address}
              onChange={e => setAddress(e.target.value)}
              style={{ width: '100%', padding: '0.55rem', borderRadius: '6px', border: '1px solid var(--border-color)', fontSize: '0.85rem' }}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '0.5rem', borderTop: '1px solid var(--border-light)', paddingTop: '1rem' }}>
            <button type="submit" className="btn-primary">
              <Save size={16} /> Save Profile Data
            </button>
          </div>

        </form>
      </div>

    </div>
  );
}
