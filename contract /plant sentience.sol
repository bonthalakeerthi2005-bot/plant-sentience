// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PlantSentience
 * @dev A smart contract that creates digital identities for plants and tracks their health data
 * @author Plant Sentience Team
 */
contract PlantSentience {
    
    struct Plant {
        uint256 id;
        string name;
        string species;
        address owner;
        uint256 birthTimestamp;
        bool isAlive;
        uint256 lastUpdateTimestamp;
        PlantMetrics metrics;
    }
    
    struct PlantMetrics {
        uint256 soilMoisture;      // 0-100%
        uint256 lightExposure;     // 0-100%
        uint256 temperature;       // in Celsius * 10 (e.g., 235 = 23.5°C)
        uint256 healthScore;       // 0-100%
        uint256 growthStage;       // 0=seed, 1=sprout, 2=young, 3=mature, 4=flowering
    }
    
    // State variables
    uint256 private nextPlantId;
    mapping(uint256 => Plant) public plants;
    mapping(address => uint256[]) public ownerToPlants;
    mapping(uint256 => address[]) public plantCaregivers;
    
    // Events
    event PlantRegistered(uint256 indexed plantId, string name, address indexed owner);
    event PlantMetricsUpdated(uint256 indexed plantId, uint256 healthScore, uint256 timestamp);
    event PlantStatusChanged(uint256 indexed plantId, bool isAlive);
    event CaregiverAdded(uint256 indexed plantId, address indexed caregiver);
    
    // Modifiers
    modifier onlyPlantOwner(uint256 _plantId) {
        require(plants[_plantId].owner == msg.sender, "Not the plant owner");
        _;
    }
    
    modifier plantExists(uint256 _plantId) {
        require(_plantId < nextPlantId, "Plant does not exist");
        _;
    }
    
    /**
     * @dev Register a new plant and create its digital identity
     * @param _name The name of the plant
     * @param _species The species of the plant
     */
    function registerPlant(string memory _name, string memory _species) external returns (uint256) {
        require(bytes(_name).length > 0, "Plant name cannot be empty");
        require(bytes(_species).length > 0, "Plant species cannot be empty");
        
        uint256 plantId = nextPlantId++;
        
        Plant storage newPlant = plants[plantId];
        newPlant.id = plantId;
        newPlant.name = _name;
        newPlant.species = _species;
        newPlant.owner = msg.sender;
        newPlant.birthTimestamp = block.timestamp;
        newPlant.isAlive = true;
        newPlant.lastUpdateTimestamp = block.timestamp;
        
        // Initialize with default metrics
        newPlant.metrics = PlantMetrics({
            soilMoisture: 50,
            lightExposure: 50,
            temperature: 220, // 22.0°C
            healthScore: 100,
            growthStage: 0 // seed stage
        });
        
        ownerToPlants[msg.sender].push(plantId);
        
        emit PlantRegistered(plantId, _name, msg.sender);
        
        return plantId;
    }
    
    /**
     * @dev Update plant metrics based on sensor data
     * @param _plantId The ID of the plant
     * @param _soilMoisture Soil moisture percentage (0-100)
     * @param _lightExposure Light exposure percentage (0-100)
     * @param _temperature Temperature in Celsius * 10
     */
    function updatePlantMetrics(
        uint256 _plantId,
        uint256 _soilMoisture,
        uint256 _lightExposure,
        uint256 _temperature
    ) external plantExists(_plantId) {
        Plant storage plant = plants[_plantId];
        
        // Only owner or authorized caregivers can update metrics
        require(
            plant.owner == msg.sender || _isCaregiver(_plantId, msg.sender),
            "Not authorized to update metrics"
        );
        
        // Validate input ranges
        require(_soilMoisture <= 100, "Soil moisture must be 0-100%");
        require(_lightExposure <= 100, "Light exposure must be 0-100%");
        require(_temperature >= 0 && _temperature <= 500, "Invalid temperature range");
        
        // Update metrics
        plant.metrics.soilMoisture = _soilMoisture;
        plant.metrics.lightExposure = _lightExposure;
        plant.metrics.temperature = _temperature;
        plant.lastUpdateTimestamp = block.timestamp;
        
        // Calculate health score based on optimal ranges
        uint256 newHealthScore = _calculateHealthScore(_soilMoisture, _lightExposure, _temperature);
        plant.metrics.healthScore = newHealthScore;
        
        // Update growth stage based on age and health
        plant.metrics.growthStage = _calculateGrowthStage(_plantId);
        
        // Check if plant should be marked as unhealthy
        if (newHealthScore < 20) {
            plant.isAlive = false;
            emit PlantStatusChanged(_plantId, false);
        }
        
        emit PlantMetricsUpdated(_plantId, newHealthScore, block.timestamp);
    }
    
    /**
     * @dev Add a caregiver who can update plant metrics
     * @param _plantId The ID of the plant
     * @param _caregiver Address of the caregiver to add
     */
    function addCaregiver(uint256 _plantId, address _caregiver) 
        external 
        plantExists(_plantId) 
        onlyPlantOwner(_plantId) 
    {
        require(_caregiver != address(0), "Invalid caregiver address");
        require(!_isCaregiver(_plantId, _caregiver), "Already a caregiver");
        
        plantCaregivers[_plantId].push(_caregiver);
        
        emit CaregiverAdded(_plantId, _caregiver);
    }
    
    // View functions
    
    /**
     * @dev Get plant information by ID
     */
    function getPlant(uint256 _plantId) external view plantExists(_plantId) returns (Plant memory) {
        return plants[_plantId];
    }
    
    /**
     * @dev Get all plants owned by an address
     */
    function getPlantsByOwner(address _owner) external view returns (uint256[] memory) {
        return ownerToPlants[_owner];
    }
    
    /**
     * @dev Get plant metrics
     */
    function getPlantMetrics(uint256 _plantId) external view plantExists(_plantId) returns (PlantMetrics memory) {
        return plants[_plantId].metrics;
    }
    
    /**
     * @dev Get total number of registered plants
     */
    function getTotalPlants() external view returns (uint256) {
        return nextPlantId;
    }
    
    // Internal functions
    
    function _isCaregiver(uint256 _plantId, address _address) internal view returns (bool) {
        address[] memory caregivers = plantCaregivers[_plantId];
        for (uint256 i = 0; i < caregivers.length; i++) {
            if (caregivers[i] == _address) {
                return true;
            }
        }
        return false;
    }
    
    function _calculateHealthScore(uint256 _moisture, uint256 _light, uint256 _temp) internal pure returns (uint256) {
        uint256 moistureScore = _moisture >= 30 && _moisture <= 70 ? 100 : (_moisture < 30 ? _moisture * 100 / 30 : (100 - _moisture) * 100 / 30);
        uint256 lightScore = _light >= 40 && _light <= 80 ? 100 : (_light < 40 ? _light * 100 / 40 : (100 - _light) * 100 / 20);
        uint256 tempScore = _temp >= 180 && _temp <= 280 ? 100 : (_temp < 180 ? _temp * 100 / 180 : (350 - _temp) * 100 / 70);
        
        return (moistureScore + lightScore + tempScore) / 3;
    }
    
    function _calculateGrowthStage(uint256 _plantId) internal view returns (uint256) {
        Plant memory plant = plants[_plantId];
        uint256 age = block.timestamp - plant.birthTimestamp;
        uint256 healthScore = plant.metrics.healthScore;
        
        if (healthScore < 30) return plant.metrics.growthStage; // Don't progress if unhealthy
        
        if (age < 7 days) return 0; // seed
        if (age < 30 days) return 1; // sprout
        if (age < 90 days) return 2; // young
        if (age < 180 days) return 3; // mature
        return 4; // flowering
    }
}
