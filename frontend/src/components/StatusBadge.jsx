import React from 'react';

export default function StatusBadge({ status, text }) {
  const normalized = (status || "").toUpperCase();

  let badgeClass = "badge-navy";
  if (["CRITICAL", "BLOCKED", "UNAVAILABLE", "OFFLINE", "FULL", "HIGH_DEMAND"].includes(normalized)) {
    badgeClass = "badge-critical";
  } else if (["HIGH", "LIMITED", "OVERLOADED", "PARTIALLY_BLOCKED", "NEAR_CAPACITY", "ATTENTION", "WARNING", "IN_TRANSIT"].includes(normalized)) {
    badgeClass = "badge-high";
  } else if (["MEDIUM", "PENDING", "ASSIGNED", "TEMPORARILY_CLOSED", "UNDER_VERIFICATION"].includes(normalized)) {
    badgeClass = "badge-warning";
  } else if (["SAFE", "OPERATIONAL", "AVAILABLE", "OPEN", "VERIFIED", "NORMAL", "DELIVERED", "DELIVERED_TO_ORG", "FOUND", "COMPLETED"].includes(normalized)) {
    badgeClass = "badge-safe";
  }

  return (
    <span className={`badge ${badgeClass}`}>
      {text || status}
    </span>
  );
}
