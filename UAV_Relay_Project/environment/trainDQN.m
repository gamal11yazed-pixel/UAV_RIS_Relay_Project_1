
clc;
clear;
close all;

%% =========================================================
% 1. SET PROJECT PATHS
% ==========================================================

projectFolder = ...
    'C:\Users\Eng Abdelrahman\Documents\UAV_Relay_Project';

environmentFolder = fullfile(projectFolder, 'environment');

assert(isfolder(projectFolder), ...
    'Project folder does not exist.');

assert(isfolder(environmentFolder), ...
    'Environment folder does not exist.');

addpath(projectFolder);
addpath(environmentFolder);

clear functions;
rehash;

%% =========================================================
% 2. LOAD CONFIGURATION
% ==========================================================

cfg = config();

assert(isfield(cfg.wireless, 'referenceDistanceM'), ...
    'referenceDistanceM is missing from config.m');

fprintf('Configuration loaded successfully.\n');

%% =========================================================
% 3. CREATE A NEW RL ENVIRONMENT
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

fprintf('Environment created and validated successfully.\n');

%% =========================================================
% 4. GET OBSERVATION AND ACTION SPECIFICATIONS
% ==========================================================

obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);

numObservations = prod(obsInfo.Dimension);
numActions = numel(actInfo.Elements);

fprintf('Observations: %d\n', numObservations);
fprintf('Actions: %d\n', numActions);

%% =========================================================
% 5. CREATE DQN NEURAL NETWORK
% ==========================================================

layers = [
    featureInputLayer(numObservations, ...
        Normalization="none", Name="observation")

    fullyConnectedLayer(64, Name="fc1")
    reluLayer(Name="relu1")

    fullyConnectedLayer(64, Name="fc2")
    reluLayer(Name="relu2")

    fullyConnectedLayer(numActions, Name="qValues")
];

net = dlnetwork(layers);

%% =========================================================
% 6. CREATE Q-VALUE CRITIC
% ==========================================================

critic = rlVectorQValueFunction( ...
    net, obsInfo, actInfo);

%% =========================================================
% 7. CONFIGURE DQN AGENT
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

agentOptions.EpsilonGreedyExploration.Epsilon = 1.0;
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.05;
agentOptions.EpsilonGreedyExploration.EpsilonDecay = 1e-3;

agent = rlDQNAgent(critic, agentOptions);

fprintf('DQN agent created successfully.\n');

%% =========================================================
% 8. CONFIGURE TRAINING
% ==========================================================

trainOptions = rlTrainingOptions( ...
    MaxEpisodes=cfg.maxEpisodes, ...
    MaxStepsPerEpisode=cfg.maxSteps, ...
    ScoreAveragingWindowLength=10, ...
    Verbose=true, ...
    Plots="training-progress");

%% =========================================================
% 9. TRAIN AGENT
% ==========================================================

fprintf('\nStarting DQN training...\n');

trainingStats = train(agent, env, trainOptions);

fprintf('\nDQN training completed.\n');

%% =========================================================
% 10. PLOT LEARNING CURVE
% ==========================================================

episodeRewards = trainingStats.EpisodeReward;

figure('Name', 'DQN Learning Curve');

plot(1:numel(episodeRewards), episodeRewards, ...
    'b-', 'LineWidth', 1.2);

hold on;

if numel(episodeRewards) >= 10

    movingAverage = movmean(episodeRewards, [9 0]);

    plot(1:numel(episodeRewards), movingAverage, ...
        'r-', 'LineWidth', 2);

    legend('Episode Reward', ...
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
% 11. TRAINING SUMMARY
% ==========================================================

fprintf('\n========== TRAINING SUMMARY ==========\n');

fprintf('Episodes completed: %d\n', ...
    numel(episodeRewards));

if ~isempty(episodeRewards)
    fprintf('Final episode reward: %.4f\n', ...
        episodeRewards(end));

    fprintf('Best episode reward: %.4f\n', ...
        max(episodeRewards));
end

%% =========================================================
% 12. SAVE RESULTS
% ==========================================================

resultsFile = fullfile( ...
    projectFolder, 'UAV_RIS_DQN_Results.mat');

save(resultsFile, ...
    'agent', 'trainingStats', 'trainOptions', 'cfg');

fprintf('\nResults saved to:\n%s\n', resultsFile);

%% =========================================================
% 13. EVALUATE TRAINED AGENT WITHOUT EXPLORATION
% ==========================================================

evalAgent = agent;
evalAgent.UseExplorationPolicy = false;

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
fprintf('Evaluation total reward: %.6f\n', totalReward);

fprintf('\nTraining and evaluation finished.\n');

