
clc;
clear;
close all;

%% 1. Load configuration and trained DQN agent
cfg = config();

load('UAV_RIS_DQN_Results.mat', 'agent');

% Disable random exploration during testing
agent.UseExplorationPolicy = false;

%% 2. Create the RL environment
obsInfo = rlNumericSpec([4 1]);
obsInfo.Name = "UAV Observation";
obsInfo.LowerLimit = [0; 0; cfg.uav.minAltitude; -pi];
obsInfo.UpperLimit = [cfg.area.width; ...
                      cfg.area.height; ...
                      cfg.uav.maxAltitude; pi];

actInfo = rlFiniteSetSpec(1:7);
actInfo.Name = "UAV Movement";

resetFcn = @() resetEnvironment(cfg);

stepFcn = @(action, loggedSignals) ...
    stepEnvironment(action, loggedSignals, cfg);

env = rlFunctionEnv(obsInfo, actInfo, stepFcn, resetFcn);
validateEnvironment(env);

%% 3. Display the 3D environment
createEnvironment(cfg);
ax = gca;
hold(ax, 'on');
grid(ax, 'on');

xlabel(ax, 'X Position (m)');
ylabel(ax, 'Y Position (m)');
zlabel(ax, 'Altitude (m)');
title(ax, 'DQN-Controlled UAV Flight');

%% 4. Reset the UAV to its initial position
obs = reset(env);

position = obs(1:3);
path = position';

% Animated UAV marker
hUAV = plot3(ax, position(1), position(2), position(3), ...
    'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 9);

% UAV trajectory
hPath = plot3(ax, path(:,1), path(:,2), path(:,3), ...
    'r-', 'LineWidth', 2);

% RIS marker, positioned 5 meters below the UAV
hRIS = plot3(ax, position(1), position(2), position(3)-5, ...
    'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 7);

legend(ax, [hUAV, hPath, hRIS], ...
    {'UAV', 'Flight Path', 'RIS'}, 'Location', 'best');

drawnow;

%% 5. Run the trained DQN policy
totalReward = 0;

for k = 1:cfg.maxSteps

    % Choose the next action using the trained agent
    action = getAction(agent, obs);

    % Apply the action to the environment
    [nextObs, reward, isDone] = step(env, action);

    obs = nextObs;
    position = obs(1:3);

    % Update trajectory
    path(end+1,:) = position';

    set(hUAV, 'XData', position(1), ...
              'YData', position(2), ...
              'ZData', position(3));

    set(hPath, 'XData', path(:,1), ...
               'YData', path(:,2), ...
               'ZData', path(:,3));

    set(hRIS, 'XData', position(1), ...
              'YData', position(2), ...
              'ZData', position(3)-5);

    totalReward = totalReward + reward;

    title(ax, sprintf('DQN UAV Flight - Step %d / %d', ...
        k, cfg.maxSteps));

    drawnow;
    pause(0.15);

    if isDone
        break;
    end
end

%% 6. Display evaluation results
fprintf('\n===== DQN Flight Results =====\n');
fprintf('Steps completed: %d\n', k);
fprintf('Total reward: %.4f\n', totalReward);
fprintf('Final X position: %.2f m\n', obs(1));
fprintf('Final Y position: %.2f m\n', obs(2));
fprintf('Final altitude: %.2f m\n', obs(3));

disp('DQN flight simulation completed.');
