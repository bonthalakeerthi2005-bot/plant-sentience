Here’s a clear description of your Solidity smart contract PlantSentience:

---

### Contract Purpose

The PlantSentience smart contract is designed to create digital identities for plants and track their health using sensor-like data (soil moisture, light exposure, temperature, etc.). It allows plant owners to monitor growth stages, add caregivers, and record health updates on the blockchain.

---

### Main Features

1. Plant Registration

   * Owners can register a new plant by providing its name and species.
   * Each plant is assigned a unique ID and digital identity with default metrics (e.g., soil moisture = 50%, temperature = 22°C).
   * Ownership is tied to the registering Ethereum address.

2. Plant Metrics Management

   * Metrics such as soil moisture, light exposure, temperature, health score, and growth stage can be updated.
   * Updates can only be performed by the owner or authorized caregivers.
   * The contract calculates a health score based on optimal ranges.
   * Growth stages are determined by the plant’s age and health (seed → sprout → young → mature → flowering).
   * If health score drops below 20, the plant is marked as dead (isAlive = false).

3. Caregiver System

   * Owners can authorize other addresses as caregivers.
   * Caregivers can help update plant metrics but cannot transfer ownership.

4. Data Retrieval

   * Anyone can view:

     * Plant details (getPlant)
     * Plant metrics (getPlantMetrics)
     * Plants owned by a user (getPlantsByOwner)
     * Total number of registered plants (getTotalPlants)

---

### Data Structures

* Plant

  * ID, name, species, owner, creation timestamp, alive status, last update timestamp, and metrics.
* PlantMetrics

  * Soil moisture, light exposure, temperature, health score, and growth stage.

---

### Events

* PlantRegistered → Triggered when a new plant is registered.
* PlantMetricsUpdated → Triggered whenever plant metrics are updated.
* PlantStatusChanged → Triggered if a plant dies (health too low).
* CaregiverAdded → Triggered when a caregiver is added.

---

### Internal Logic

* _isCaregiver → Checks if an address is a caregiver for a plant.
* _calculateHealthScore → Computes health based on optimal ranges of soil moisture, light, and temperature.
* _calculateGrowthStage → Determines growth stage from plant age and health.

### **contract address:0xd9145CCE52D386f254917e481eB44e9943F39138
![Plant](https://github.com/user-attachments/assets/b5f2c1a2-7c79-4368-a964-0a6fa9f40dc2)



✅ In short:
This contract acts like a digital “health passport” for plants, enabling owners (and caregivers) to track plant health and lifecycle securely on the blockchain.
