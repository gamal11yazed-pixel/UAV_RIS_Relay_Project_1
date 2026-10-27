function cfg = config()

% =========================================================
% UAV + RIS WIRELESS ENVIRONMENT CONFIGURATION
% =========================================================

% 1. Simulation area (meters)
cfg.area.width  = 500;
cfg.area.height = 500;
cfg.area.maxAltitude = 100;

% 2. Ground Base Station (GBS)
% Position: [X, Y, Z] in meters
cfg.baseStation = [50, 250, 30];

% 3. Users
% Position: [X, Y, Z] in meters
cfg.user1 = [450, 200, 0];
cfg.user2 = [450, 450, 0];

% 4. UAV configuration
cfg.uav.initialPosition = [250, 250, 100];
cfg.uav.minAltitude = 20;
cfg.uav.maxAltitude = 100;

% UAV movement
cfg.uav.horizontalStep = 20;
cfg.uav.verticalStep = 10;

% UAV rotation: Actions 8 and 9
cfg.uav.yawStep = deg2rad(15);

% 5. RIS configuration
% RIS is mounted directly underneath the UAV.
% The RIS and UAV share the same X and Y coordinates.
% Their vertical separation is zero in this simplified model.
cfg.ris.mountingOffset = [0; 0; 0];

% Square RIS dimensions
% Side length = 8.6 cm = 0.086 m
cfg.ris.sideLengthM = 0.086;
cfg.ris.width = cfg.ris.sideLengthM;
cfg.ris.height = cfg.ris.sideLengthM;
cfg.ris.areaM2 = cfg.ris.sideLengthM^2;

% Number of reflecting elements
cfg.ris.numElements = 256;

% RIS hardware settings
cfg.ris.elementEfficiency = 0.8;
cfg.ris.phaseBits = 2;

% 6. Building locations
% Each row: [X, Y, Width, Depth, Height]
% Maximum building height = 30 meters
cfg.buildings = [
    150, 150, 60, 100, 20;
    250, 220, 80, 100, 30;
    350, 120, 70, 100, 15;
    350, 320, 70,  80, 25
];

% 7. Episode settings
cfg.maxSteps = 100;
cfg.maxEpisodes = 2000;

% 8. Wireless channel settings
cfg.wireless.frequencyGHz = 2.4;
cfg.wireless.noisePowerdBm = -100;

% Transmit power
cfg.wireless.bsTransmitPowerdBm = 30;
cfg.wireless.uavTransmitPowerdBm = 20;

% Bandwidth
cfg.wireless.bandwidthHz = 10e6;

% Simplified channel model
cfg.wireless.pathLossExponent = 2.2;
cfg.wireless.referenceDistanceM = 1;
cfg.wireless.referencePathLossdB = 40;

% Rician fading factor (linear scale)
cfg.wireless.ricianK = 3;

% 9. QoS requirements
cfg.qos.minSINRdB = 5;
cfg.qos.minRateMbps = 2;

% 10. Reward weights
cfg.reward.sumRateWeight = 0.60;
cfg.reward.qosWeight = 0.25;
cfg.reward.fairnessWeight = 0.15;

% 11. Movement and safety penalties
cfg.reward.movementPenalty = 0.01;
cfg.reward.collisionPenalty = 10;

end