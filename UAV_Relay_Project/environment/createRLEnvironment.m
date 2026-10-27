
clc;
clear;
close all;

% Load configuration
cfg = config();

% Define observation information
obsInfo = rlNumericSpec([4 1]);

obsInfo.Name = "UAV Observation";

obsInfo.LowerLimit = [0; 0; cfg.uav.minAltitude; -pi];

obsInfo.UpperLimit = [cfg.area.width; ...
                      cfg.area.height; ...
                      cfg.uav.maxAltitude; pi];

% Define the 7 possible UAV actions
actInfo = rlFiniteSetSpec(1:7);

actInfo.Name = "UAV Movement";

% Create reset and step functions
resetFcn = @() resetEnvironment(cfg);

stepFcn = @(action, loggedSignals) ...
    stepEnvironment(action, loggedSignals, cfg);

% Create reinforcement learning environment
env = rlFunctionEnv(obsInfo, actInfo, stepFcn, resetFcn);

% Validate environment
validateEnvironment(env);

% Display environment
disp("UAV-RIS RL environment created successfully.");

% Visualize the environment
createEnvironment(cfg);
