function [quality1, quality2] = calculateLinkQuality(uavPosition, cfg)

% CALCULATELINKQUALITY
% Estimate the SINR for two users in the UAV + RIS environment.
%
% Inputs:
%   uavPosition : UAV position [X; Y; Z] or [X, Y, Z]
%   cfg         : Configuration structure from config.m
%
% Outputs:
%   quality1    : Estimated SINR for User 1 (linear scale)
%   quality2    : Estimated SINR for User 2 (linear scale)
%
% Note:
% This is a simplified link-budget model, not a full physical
% RIS channel model or a phase-optimized wireless simulation.

%% 1. Convert positions to column vectors

uavPosition = uavPosition(:);
bsPosition  = cfg.baseStation(:);
user1       = cfg.user1(:);
user2       = cfg.user2(:);

%% 2. Calculate the current RIS position
% The RIS moves together with the UAV.

risPosition = uavPosition + cfg.ris.mountingOffset(:);

%% 3. Calculate distances in meters

dBSUAV    = max(norm(bsPosition - uavPosition), 1);
dUAVUser1 = max(norm(uavPosition - user1), 1);
dUAVUser2 = max(norm(uavPosition - user2), 1);

dUAVRIS   = max(norm(uavPosition - risPosition), 0.01);
dRISUser1 = max(norm(risPosition - user1), 1);
dRISUser2 = max(norm(risPosition - user2), 1);

%% 4. Read wireless configuration

PL0 = cfg.wireless.referencePathLossdB;
d0  = cfg.wireless.referenceDistanceM;
n   = cfg.wireless.pathLossExponent;

d0 = max(d0, 0.01);

%% 5. Estimate path loss in dB

PL_BS_UAV = PL0 + 10*n*log10(dBSUAV/d0);

PL_UAV_User1 = PL0 + 10*n*log10(dUAVUser1/d0);
PL_UAV_User2 = PL0 + 10*n*log10(dUAVUser2/d0);

%% 6. Estimate received signal power in dBm

pBSUAV = cfg.wireless.bsTransmitPowerdBm - PL_BS_UAV;

pUser1 = cfg.wireless.uavTransmitPowerdBm - PL_UAV_User1;
pUser2 = cfg.wireless.uavTransmitPowerdBm - PL_UAV_User2;

%% 7. Estimate the RIS gain
% Simplified heuristic based on the number of RIS elements,
% element efficiency, and distances.
%
% This is an approximation. Since the RIS mounting offset is zero,
% the current geometry does not model a physically separated
% UAV-to-RIS propagation path.

N = cfg.ris.numElements;
eta = cfg.ris.elementEfficiency;

risGain1dB = min(20, 10*log10(max(1, ...
    N^2 * eta^2 * dUAVUser1^2 / ...
    (dUAVRIS^2 * dRISUser1^2))));

risGain2dB = min(20, 10*log10(max(1, ...
    N^2 * eta^2 * dUAVUser2^2 / ...
    (dUAVRIS^2 * dRISUser2^2))));

%% 8. Apply the approximate RIS gain

pUser1 = pUser1 + risGain1dB;
pUser2 = pUser2 + risGain2dB;

%% 9. Convert signal power and noise power from dBm to mW

signal1mW = 10^(pUser1 / 10);
signal2mW = 10^(pUser2 / 10);

noiseMilliwatt = 10^(cfg.wireless.noisePowerdBm / 10);

%% 10. Calculate estimated SINR
% Inter-user interference is not included in this simplified model.

quality1 = signal1mW / noiseMilliwatt;
quality2 = signal2mW / noiseMilliwatt;

%% 11. Protect against invalid numerical results

if ~isfinite(quality1) || quality1 < 1e-12
    quality1 = 1e-12;
end

if ~isfinite(quality2) || quality2 < 1e-12
    quality2 = 1e-12;
end

end