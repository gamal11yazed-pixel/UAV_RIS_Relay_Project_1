function createEnvironment(cfg)

% =========================================================
% UAV + RIS Wireless Environment
% RIS is mounted on the UAV
% =========================================================

figure('Name', 'UAV + RIS Environment');
clf;
hold on;
grid on;
box on;
axis equal;

xlim([0 cfg.area.width]);
ylim([0 cfg.area.height]);
zlim([0 cfg.area.maxAltitude]);

xlabel('X (meters)');
ylabel('Y (meters)');
zlabel('Height (meters)');
title('UAV + RIS Wireless Environment');

%% 1. Draw Buildings

for k = 1:size(cfg.buildings, 1)

    b = cfg.buildings(k, :);

    x = b(1);
    y = b(2);
    w = b(3);
    d = b(4);
    h = b(5);

    [X, Y, Z] = cuboidData(x, y, 0, w, d, h);

    surf(X, Y, Z, ...
        'FaceColor', [0.65 0.65 0.70], ...
        'EdgeColor', 'k', ...
        'FaceAlpha', 0.75);

end

%% 2. Ground Base Station (GBS)

bs = cfg.baseStation;

plot3(bs(1), bs(2), bs(3), ...
    'r^', ...
    'MarkerSize', 12, ...
    'MarkerFaceColor', 'r');

text(bs(1), bs(2), bs(3)+8, ...
    'GBS', 'FontWeight', 'bold');

%% 3. User 1

u1 = cfg.user1;

plot3(u1(1), u1(2), u1(3), ...
    'bo', ...
    'MarkerSize', 10, ...
    'MarkerFaceColor', 'b');

text(u1(1), u1(2), u1(3)+8, ...
    'User 1', 'FontWeight', 'bold');

%% 4. User 2

u2 = cfg.user2;

plot3(u2(1), u2(2), u2(3), ...
    'bo', ...
    'MarkerSize', 10, ...
    'MarkerFaceColor', 'b');

text(u2(1), u2(2), u2(3)+8, ...
    'User 2', 'FontWeight', 'bold');

%% 5. UAV

uav = cfg.uav.initialPosition;

hUAV = plot3(uav(1), uav(2), uav(3), ...
    'gp', ...
    'MarkerSize', 16, ...
    'MarkerFaceColor', 'g');

hUAVText = text(uav(1), uav(2), uav(3)+8, ...
    'UAV - Flying BS + RIS', ...
    'FontWeight', 'bold');


%% 6. RIS Mounted on UAV

% RIS follows the UAV position
risOffset = cfg.ris.mountingOffset(:).';
ris = uav + risOffset;

% Square RIS dimensions
rw = cfg.ris.width;
rh = cfg.ris.height;

% Draw the RIS as a square plate.
% The plate is displayed horizontally in the XY plane.
halfThickness = 0.002;  % 2 mm visualization thickness

x1 = ris(1) - rw/2;
x2 = ris(1) + rw/2;

y1 = ris(2) - rh/2;
y2 = ris(2) + rh/2;

z1 = ris(3) - halfThickness;
z2 = ris(3) + halfThickness;

hRIS = patch( ...
    [x1 x2 x2 x1], ...
    [y1 y1 y2 y2], ...
    [z1 z1 z1 z1], ...
    'c', ...
    'FaceAlpha', 0.8, ...
    'EdgeColor', 'k', ...
    'LineWidth', 1.5);

hRISText = text(ris(1), ris(2), ris(3)+2, ...
    'RIS (256 elements)', ...
    'FontWeight', 'bold');

%% 7. Communication Links

% GBS -> UAV
hGBS_UAV = plot3( ...
    [bs(1) uav(1)], ...
    [bs(2) uav(2)], ...
    [bs(3) uav(3)], ...
    'g--', 'LineWidth', 1.5);

% UAV -> User 1
hUAV_User1 = plot3( ...
    [uav(1) u1(1)], ...
    [uav(2) u1(2)], ...
    [uav(3) u1(3)], ...
    'b--', 'LineWidth', 1.5);

% UAV -> User 2
hUAV_User2 = plot3( ...
    [uav(1) u2(1)], ...
    [uav(2) u2(2)], ...
    [uav(3) u2(3)], ...
    'b--', 'LineWidth', 1.5);

% GBS -> RIS
hGBS_RIS = plot3( ...
    [bs(1) ris(1)], ...
    [bs(2) ris(2)], ...
    [bs(3) ris(3)], ...
    'm--', 'LineWidth', 1.5);

% RIS -> User 1
hRIS_User1 = plot3( ...
    [ris(1) u1(1)], ...
    [ris(2) u1(2)], ...
    [ris(3) u1(3)], ...
    'c--', 'LineWidth', 1.5);

% RIS -> User 2
hRIS_User2 = plot3( ...
    [ris(1) u2(1)], ...
    [ris(2) u2(2)], ...
    [ris(3) u2(3)], ...
    'c--', 'LineWidth', 1.5);

%% 8. View Settings

view(45, 30);
hold off;

end

% =========================================================
% Helper function: draw a 3D building
% =========================================================
function [X, Y, Z] = cuboidData(x, y, z, w, d, h)

X = [x x+w x+w x x;
     x x+w x+w x x];

Y = [y y y+d y+d y;
     y y y+d y+d y];

Z = [z z z z z;
     z+h z+h z+h z+h z+h];

end