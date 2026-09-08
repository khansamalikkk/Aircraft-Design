%% Empty Weight Fraction vs W0 (Raymer, Aircraft Design)
% We/W0 = A * W0^C * K_vs
clear; clc; close all;

%% Data from Table 3.1
names = { ...
    'Sailplane - unpowered'; ...
    'Sailplane - powered'; ...
    'Homebuilt - metal/wood'; ...
    'Homebuilt - composite'; ...
    'General aviation - single engine'; ...
    'General aviation - twin engine'; ...
    'Agricultural aircraft'; ...
    'Twin turboprop'; ...
    'Flying boat'; ...
    'Jet trainer'; ...
    'Jet fighter'; ...
    'Military cargo/bomber'; ...
    'Jet transport'};

A = [0.86; 0.91; 1.19; 0.99; 2.36; 1.51; 0.74; 0.96; 1.09; 1.59; 2.34; 0.93; 1.02];
C = [-0.05; -0.05; -0.09; -0.09; -0.18; -0.10; -0.03; -0.05; -0.05; -0.10; -0.13; -0.07; -0.06];

K_vs = 1.00;   % fixed sweep (use 1.04 if variable sweep)

% Each aircraft type only makes sense over a realistic W0 range
% (approximate ranges matching Raymer Fig 3.1)
Wmin = [  200;   200;   500;   500;  1000;  2000;  2000;  5000;  5000;  3000;  5000; 50000; 50000];
Wmax = [ 1000;  1000;  2000;  2000; 10000; 10000; 10000; 50000; 200000; 30000; 100000; 1000000; 1000000];

%% Compute and plot 
figure('Color','w','Position',[100 100 900 650]);
hold on; box on;

for i = 1:length(names)
    W0 = logspace(log10(Wmin(i)), log10(Wmax(i)), 100);
    WeW0 = A(i) .* W0.^C(i) .* K_vs;
    plot(W0, WeW0, 'k-', 'LineWidth', 1.3);

    % Label near the midpoint of each line, like Fig 3.1
    idx = round(length(W0)*0.5);
    text(W0(idx), WeW0(idx), ['  ' names{i}], ...
        'FontSize', 7, 'Rotation', 0, 'Interpreter', 'none');
end

set(gca, 'XScale', 'log');
grid on;
xlabel('Takeoff Gross Weight, W_0 (lb)');
ylabel('W_e/W_0');
title('Fig. 3.1  Empty Weight Fraction Trends');
xlim([100 1e6]);
ylim([0.35 0.8]);
hold off;

%% save figure
saveas(gcf, 'WeW0_vs_W0.png');
