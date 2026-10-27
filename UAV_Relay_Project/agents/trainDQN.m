
clc;
clear;
close all;

%% =========================================================
%  1. SET PROJECT PATHS
% ==========================================================

projectFolder = ...
    'C:\Users\Eng Abdelrahman\Documents\UAV_Relay_Project';

environmentFolder = fullfile(projectFolder, 'environment');

assert(isfolder(projectFolder), ...
    'Project folder was not found. Check projectFolder.');

assert(isfolder(environmentFolder), ...
    'Environment folder was not found. Check environmentFolder.');

addpath(projectFolder);
addpath(environmentFolder);

clear functions;
rehash;

fprintf('Project paths configured successfully.\n');

%% =========================================================
%  2. LOAD CURRENT CONFIGURATION
% ==========================================================

cfg = config();

assert(isfield(cfg.wireless, 'referenceDistanceM'), ...
    'Missing wireless.referenceDistanceM in config.m');

assert(isfield(cfg.wireless, 'referencePathLossdB'), ...
    'Missing wireless.referencePathLossdB in config.m');

assert(isfield(cfg.wireless, 'pathLossExponent'), ...
    'Missing wireless.pathLossExponent in config.m');

fprintf('Configuration loaded successfully.\n');
fprintf('Reference distance: %.2f m\n', ...
    cfg.wireless.referenceDistanceM);

%% =========================================================
%  3. CREATE A FRESH RL ENVIRONMENT
% ==========================================================

obsInfo = rlNumericSpec([4 1]);

obsInfo.Name = "UAV Observation";

obsInfo.LowerLimit = ...
    [0; ...
     0; ...
     cfg.uav.minAltitude; ...
     -pi];

obsInfo.UpperLimit = ...
    [cfg.area.width; ...
     cfg.area.height; ...
     cfg.uav.maxAltitude; ...
     pi];

actInfo = rlFiniteSetSpec(1:7);

actInfo.Name = "UAV Movement";

resetFcn = @() resetEnvironment(cfg);

stepFcn = @(action, loggedSignals) ...
    stepEnvironment(action, loggedSignals, cfg);

env = rlFunctionEnv( ...
    obsInfo, ...
    actInfo, ...
    stepFcn, ...
    resetFcn);

validateEnvironment(env);

fprintf('RL environment created and validated successfully.\n');

%% =========================================================
%  4. GET OBSERVATION AND ACTION INFORMATION
% ==========================================================

obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);

numObservations = prod(obsInfo.Dimension);
numActions = numel(actInfo.Elements);

fprintf('Number of observations: %d\n', numObservations);
fprintf('Number of actions: %d\n', numActions);

%% =========================================================
%  5. CREATE THE DQN NEURAL NETWORK
% ==========================================================

layers = [
    featureInputLayer( ...
        numObservations, ...
        Normalization="none", ...
        Name="observation")

    fullyConnectedLayer(64, Name="fc1")
    reluLayer(Name="relu1")

    fullyConnectedLayer(64, Name="fc2")
    reluLayer(Name="relu2")

    fullyConnectedLayer(numActions, Name="qValues")
];

net = dlnetwork(layers);

%% =========================================================
%  6. CREATE THE Q-VALUE CRITIC
% ==========================================================

critic = rlVectorQValueFunction( ...
    net, ...
    obsInfo, ...
    actInfo);

%% =========================================================
%  7. CONFIGURE THE DQN AGENT
% ==========================================================

criticOptions = rlOptimizerOptions( ...
    LearnRate=1e-3, ...
    GradientThreshold=1);

agentOptions = rlDQNAgentOptions( ...
    SampleTime=1, ...
    UseDoubleDQN=true, ...
    DiscountFactor=0.99, ...
    ExperienceBufferLength=10000, ...
    MiniBatchSize=64, ...
    CriticOptimizerOptions=criticOptions);

% Epsilon-greedy exploration
agentOptions.EpsilonGreedyExploration.Epsilon = 1.0;
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.05;
agentOptions.EpsilonGreedyExploration.EpsilonDecay = 1e-3;

agent = rlDQNAgent(critic, agentOptions);

fprintf('DQN agent created successfully.\n');

%% =========================================================
%  8. CONFIGURE TRAINING
% ==========================================================

trainOptions = rlTrainingOptions( ...
    MaxEpisodes=cfg.maxEpisodes, ...
    MaxStepsPerEpisode=cfg.maxSteps, ...
    ScoreAveragingWindowLength=10, ...
    Verbose=true, ...
    Plots="training-progress");

%% =========================================================
%  9. TRAIN THE DQN AGENT
% ==========================================================

fprintf('\nStarting DQN training...\n');

trainingStats = train(agent, env, trainOptions);

fprintf('\nDQN training completed.\n');

%% =========================================================
%  10. PLOT THE LEARNING CURVE
% ==========================================================

episodeRewards = trainingStats.EpisodeReward;

figure('Name', 'DQN Learning Curve');

plot(1:numel(episodeRewards), ...
    episodeRewards, ...
    'b-', ...
    'LineWidth', 1.2);

hold on;

if numel(episodeRewards) >= 10

    movingAverage = movmean(episodeRewards, [9 0]);

    plot(1:numel(episodeRewards), ...
        movingAverage, ...
        'r-', ...
        'LineWidth', 2);

    legend( ...
        'Episode Reward', ...
        '10-Episode Moving Average', ...
        'Location', 'best');

else

    legend('Episode Reward', 'Location', 'best');

end

xlabel('Episode');
ylabel('Total Episode Reward');
title('DQN Learning Curve');
grid on;
hold off;

%% =========================================================
%  11. DISPLAY TRAINING SUMMARY
% ==========================================================

fprintf('\n========== TRAINING SUMMARY ==========\n');

fprintf('Episodes completed: %d\n', ...
    numel(episodeRewards));

fprintf('Final episode reward: %.4f\n', ...
    episodeRewards(end));

fprintf('Best episode reward: %.4f\n', ...
    max(episodeRewards));

%% =========================================================
%  12. SAVE THE TRAINED AGENT AND RESULTS
% ==========================================================

resultsFile = fullfile( ...
    projectFolder, ...
    'UAV_RIS_DQN_Results.mat');

save(resultsFile, ...
    'agent', ...
    'trainingStats', ...
    'trainOptions', ...
    'cfg');

fprintf('\nTraining results saved to:\n%s\n', resultsFile);

%% =========================================================
%  13. EVALUATE THE TRAINED AGENT
% ==========================================================

% Disable exploration for evaluation
evalAgent = agent;
evalAgent.UseExplorationPolicy = false;

% Reset environment
obs = reset(env);

totalReward = 0;
evaluationSteps = 0;

for k = 1:cfg.maxSteps

    action = getAction(evalAgent, obs);

    [obs, reward, isDone] = step(env, action);

    totalReward = totalReward + reward;
    evaluationSteps = k;

    if isDone
        break;
    end

end

fprintf('\n========== EVALUATION SUMMARY ==========\n');

fprintf('Evaluation steps: %d\n', evaluationSteps);

fprintf('Evaluation total reward: %.6f\n', ...
    totalReward);

fprintf('\nDQN training and evaluation finished.\n');
