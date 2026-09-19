/**
 * Calculates Inventory Burn Rates & Automated Re-supply Thresholds
 */
export function calculateSupplyDepletion(inventory = {}, occupancyCount = 100) {
  // Average daily consumption per person
  const waterDailyPerPerson = 3; // 3 Liters
  const foodDailyPerPerson = 2;  // 2 Rations

  const waterTotal = inventory.water_liters || 1500;
  const foodTotal = inventory.food_rations || 800;

  const waterDaysRemaining = occupancyCount > 0 ? (waterTotal / (occupancyCount * waterDailyPerPerson)) : 99;
  const foodDaysRemaining = occupancyCount > 0 ? (foodTotal / (occupancyCount * foodDailyPerPerson)) : 99;

  let alertLevel = "SAFE"; // SAFE, WARNING, CRITICAL
  const warnings = [];

  if (waterDaysRemaining < 1 || foodDaysRemaining < 1) {
    alertLevel = "CRITICAL";
    if (waterDaysRemaining < 1) warnings.push("Water stock critical (< 24 hours remaining)");
    if (foodDaysRemaining < 1) warnings.push("Food rations critical (< 24 hours remaining)");
  } else if (waterDaysRemaining < 2 || foodDaysRemaining < 2) {
    alertLevel = "WARNING";
    if (waterDaysRemaining < 2) warnings.push("Water stock low (< 48 hours remaining)");
    if (foodDaysRemaining < 2) warnings.push("Food rations low (< 48 hours remaining)");
  }

  return {
    occupancy_count: occupancyCount,
    water_days_remaining: parseFloat(waterDaysRemaining.toFixed(1)),
    food_days_remaining: parseFloat(foodDaysRemaining.toFixed(1)),
    alert_level: alertLevel,
    warnings,
    needs_replenishment: alertLevel !== "SAFE"
  };
}
