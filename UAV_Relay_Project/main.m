clc;
clear;
close all;

%% 1. Set Project Paths
projectFolder = fileparts(mfilename('fullpath'));

addpath(projectFolder);
addpath(fullfile(projectFolder, 'environment'));
addpath(fullfile(projectFolder, 'agents'));
addpath(fullfile(projectFolder, 'baselines'));
addpath(fullfile(projectFolder, 'evaluation'));

fprintf('Project paths configured successfully.\n');

%% 2. Load Configuration
cfg = config();

% Train for 2000 episodes
cfg.maxEpisodes = 2000;

fprintf('Maximum Episodes: %d\n', cfg.maxEpisodes);
fprintf('Maximum Steps per Episode: %d\n', cfg.maxSteps);

%% 3. Define Observation Space
% Observation = [X; Y; Z; Yaw]

obsInfo = rlNumericSpec([4 1]);

obsInfo.Name = "UAV Observation";

obsInfo.LowerLimit = [
    0;
    0;
    cfg.uav.minAltitude;
    -pi
];

obsInfo.UpperLimit = [
    cfg.area.width;
    cfg.area.height;
    cfg.uav.maxAltitude;
    pi
];

%% 4. Define Action Space
% 1 = X+
% 2 = X-
% 3 = Y+
% 4 = Y-
% 5 = X+ and Z+
% 6 = X- and Z-
% 7 = Y+ and Z+
% 8 = Y- and Z-
% 9 = Reset Yaw

actInfo = rlFiniteSetSpec(1:9);
actInfo.Name = "UAV Movement";

%% 5. Connect Reset and Step Functions

resetFcn = @() resetEnvironment(cfg);

stepFcn = @(action, loggedSignals) ...
    stepEnvironment(action, loggedSignals, cfg);

%% 6. Create Reinforcement Learning Environment

env = rlFunctionEnv( ...
    obsInfo, ...
    actInfo, ...
    stepFcn, ...
    resetFcn);

%% 7. Validate Environment

validateEnvironment(env);

fprintf('\n====================================\n');
fprintf('UAV + RIS Environment Created\n');
fprintf('Environment Validation Passed\n');
fprintf('Number of Actions: %d\n', 9);
fprintf('====================================\n');

%% 8. Display the 3D Environment

createEnvironment(cfg);

%% 9. Set Random Seed

rng(0, "twister");

%% 10. Create DQN Agent

agent = rlDQNAgent(obsInfo, actInfo);

%% 11. Configure DQN Agent

agent.AgentOptions.UseDoubleDQN = true;
agent.AgentOptions.DiscountFactor = 0.99;

agent.AgentOptions.ExperienceBufferLength = 100000;
agent.AgentOptions.MiniBatchSize = 128;
agent.AgentOptions.TargetUpdateFrequency = 4;

%% 12. Configure Critic Optimizer

agent.AgentOptions.CriticOptimizerOptions.LearnRate = 1e-3;

agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;

fprintf('\n====================================\n');
fprintf('DQN Agent Created Successfully\n');
fprintf('Observation Dimensions: %d\n', 4);
fprintf('Available Actions: %d\n', 9);
fprintf('====================================\n');

%% 13. Configure Training Options

trainOpts = rlTrainingOptions( ...
    MaxEpisodes = cfg.maxEpisodes, ...
    MaxStepsPerEpisode = cfg.maxSteps, ...
    ScoreAveragingWindowLength = 20, ...
    Verbose = true, ...
    Plots = "training-progress", ...
    StopTrainingCriteria = "none");

%% 14. Create Results Folder

resultsFolder = fullfile(projectFolder, 'results');

if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

%% 15. Start DQN Training

fprintf('\n====================================\n');
fprintf('Starting DQN Training...\n');
fprintf('Episodes: %d\n', cfg.maxEpisodes);
fprintf('Maximum Steps per Episode: %d\n', cfg.maxSteps);
fprintf('====================================\n');

trainingStats = train(agent, env, trainOpts);

%% 16. Save Trained Agent

save( ...
    fullfile(resultsFolder, 'trainedDQNAgent.mat'), ...
    'agent', '-v7.3');

%% 17. Save Training Statistics

save( ...
    fullfile(resultsFolder, 'DQNTrainingStats.mat'), ...
    'trainingStats');

%% 18. Training Completed

fprintf('\n====================================\n');
fprintf('DQN TRAINING COMPLETED!\n');
fprintf('Trained agent saved successfully.\n');
fprintf('Training statistics saved successfully.\n');
fprintf('Results folder:\n%s\n', resultsFolder);
fprintf('====================================\n');