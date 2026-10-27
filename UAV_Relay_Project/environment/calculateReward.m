function reward = calculateReward(uavPosition, cfg, previousPosition)

% CALCULATEREWARD
% Calculate a reward for UAV positioning and wireless communication.

%% 1. Prepare positions

uavPosition = uavPosition(:);

% If previous position is not supplied, assume no movement.
if nargin < 3
    previousPosition = uavPosition;
end

previousPosition = previousPosition(:);

%% 2. Calculate estimated SINR for both users

[sinr1, sinr2] = calculateLinkQuality(uavPosition, cfg);

%% 3. Calculate approximate data rates

B = cfg.wireless.bandwidthHz;

rate1Mbps = B * log2(1 + max(sinr1, 0)) / 1e6;
rate2Mbps = B * log2(1 + max(sinr2, 0)) / 1e6;

totalRateMbps = rate1Mbps + rate2Mbps;

%% 4. Normalize the sum-rate score

sumRateScore = totalRateMbps / (totalRateMbps + 200);

%% 5. Calculate QoS score

sinr1dB = 10 * log10(max(sinr1, 1e-12));
sinr2dB = 10 * log10(max(sinr2, 1e-12));

qos1 = double( ...
    sinr1dB >= cfg.qos.minSINRdB && ...
    rate1Mbps >= cfg.qos.minRateMbps);

qos2 = double( ...
    sinr2dB >= cfg.qos.minSINRdB && ...
    rate2Mbps >= cfg.qos.minRateMbps);

qosScore = (qos1 + qos2) / 2;

%% 6. Calculate Jain fairness index

denominator = 2 * (rate1Mbps^2 + rate2Mbps^2);

if denominator > 0
    fairnessScore = ...
        (rate1Mbps + rate2Mbps)^2 / denominator;
else
    fairnessScore = 0;
end

fairnessScore = min(max(fairnessScore, 0), 1);

%% 7. Calculate movement penalty

movementDistance = norm(uavPosition - previousPosition);

referenceStep = max(cfg.uav.horizontalStep, 1);

movementCost = cfg.reward.movementPenalty * ...
    (movementDistance / referenceStep);

%% 8. Check whether the UAV center is inside a building

collisionDetected = false;

for k = 1:size(cfg.buildings, 1)

    b = cfg.buildings(k, :);

    buildingX = b(1);
    buildingY = b(2);
    buildingWidth = b(3);
    buildingDepth = b(4);
    buildingHeight = b(5);

    insideX = uavPosition(1) >= buildingX && ...
              uavPosition(1) <= buildingX + buildingWidth;

    insideY = uavPosition(2) >= buildingY && ...
              uavPosition(2) <= buildingY + buildingDepth;

    belowRoof = uavPosition(3) <= buildingHeight;

    if insideX && insideY && belowRoof
        collisionDetected = true;
        break;
    end

end

%% 9. Apply collision penalty

collisionCost = 0;

if collisionDetected
    collisionCost = cfg.reward.collisionPenalty;
end

%% 10. Calculate the final reward

reward = ...
    cfg.reward.sumRateWeight * sumRateScore + ...
    cfg.reward.qosWeight * qosScore + ...
    cfg.reward.fairnessWeight * fairnessScore - ...
    movementCost - collisionCost;

%% 11. Protect against invalid numerical results

if ~isfinite(reward)
    reward = -cfg.reward.collisionPenalty;
end

end