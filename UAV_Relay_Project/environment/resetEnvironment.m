function [initialObservation, info] = resetEnvironment(cfg)

% 1. Initialize UAV position
initialPosition = cfg.uav.initialPosition(:);

% 2. Initialize UAV orientation
initialYaw = 0;

% 3. Initialize episode step counter
initialStep = 0;

% 4. Store UAV state
info.Position = initialPosition;
info.Yaw = initialYaw;
info.StepCount = initialStep;

% 5. Attach RIS directly to the UAV
% The mounting offset is defined in config.m
info.RISPosition = ...
    info.Position + cfg.ris.mountingOffset(:);

% 6. Initialize communication metrics
info.LinkQualityUser1 = 0;
info.LinkQualityUser2 = 0;

% 7. Initial observation
% Observation = [X; Y; Z; Yaw]
initialObservation = [
    info.Position;
    info.Yaw
];

end