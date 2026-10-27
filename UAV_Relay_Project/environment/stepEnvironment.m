function [nextObservation, reward, isDone, loggedSignals] = ...
    stepEnvironment(action, loggedSignals, cfg)

% 1. Read current UAV state
position = loggedSignals.Position;
newYaw = loggedSignals.Yaw;

% 2. Initialize movement
move = [0; 0; 0];

% 3. Apply the selected action
switch double(action)

    case 1
        % X+
        move = [cfg.uav.horizontalStep; 0; 0];

    case 2
        % X-
        move = [-cfg.uav.horizontalStep; 0; 0];

    case 3
        % Y+
        move = [0; cfg.uav.horizontalStep; 0];

    case 4
        % Y-
        move = [0; -cfg.uav.horizontalStep; 0];

    case 5
        % X+ and Z+
        move = [cfg.uav.horizontalStep; 0; cfg.uav.verticalStep];

    case 6
        % X- and Z-
        move = [-cfg.uav.horizontalStep; 0; -cfg.uav.verticalStep];

    case 7
        % Y+ and Z+
        move = [0; cfg.uav.horizontalStep; cfg.uav.verticalStep];

    case 8
        % Y- and Z-
        move = [0; -cfg.uav.horizontalStep; -cfg.uav.verticalStep];

    case 9
        % Reset yaw to zero
        newYaw = 0;

    otherwise
        error('Action must be an integer from 1 to 9.');

end

% 4. Update UAV position
newPosition = position + move;

% 5. Apply environment boundaries
newPosition(1) = min(max(newPosition(1), 0), cfg.area.width);
newPosition(2) = min(max(newPosition(2), 0), cfg.area.height);
newPosition(3) = min(max(newPosition(3), cfg.uav.minAltitude), ...
    cfg.uav.maxAltitude);

% 6. Update yaw
loggedSignals.Yaw = newYaw;

% 7. Update UAV state
loggedSignals.Position = newPosition;
loggedSignals.StepCount = loggedSignals.StepCount + 1;

% 8. Keep RIS attached to UAV
loggedSignals.RISPosition = ...
    newPosition + cfg.ris.mountingOffset(:);

% 9. Calculate link quality
[q1, q2] = calculateLinkQuality(newPosition, cfg);

loggedSignals.LinkQualityUser1 = q1;
loggedSignals.LinkQualityUser2 = q2;

% 10. Calculate reward
reward = calculateReward(newPosition, cfg, position);

% 11. End episode after maximum steps
isDone = loggedSignals.StepCount >= cfg.maxSteps;

% 12. Return observation [X; Y; Z; Yaw]
nextObservation = [
    newPosition;
    loggedSignals.Yaw
];

end