%% ============================================================
%  GENERIC PAYLOAD TRADE STUDY  (Raymer Box 3.3 / Fig 3.12)
%
%  Re-sizes the aircraft (solves for W0) for several different
%  payload weights, keeping the mission profile (Wx/W0, Wf/W0)
%  and crew weight fixed, so you can see how TOGW grows with
%  payload.
%
%  If you already ran ASW_sizing.m in this folder, this script
%  will offer to load its saved mission data automatically -
%  no need to re-enter the aircraft type or mission profile.
% ============================================================
clear; clc; close all;

fprintf('=====================================================\n');
fprintf('        GENERIC PAYLOAD TRADE STUDY\n');
fprintf('=====================================================\n\n');

loaded = false;
if exist('mission_data.mat', 'file')
    ans_load = input('Found "mission_data.mat" from a previous sizing run. Load it? (y/n): ', 's');
    if lower(ans_load) == 'y'
        load('mission_data.mat');
        loaded = true;
        fprintf('\nLoaded mission: %s\n', acType);
        fprintf('  A = %.3f, C = %.3f, K_vs = %.2f\n', A, C, K_vs);
        fprintf('  Wx/W0 = %.4f   Wf/W0 = %.4f\n', Wx_W0, Wf_W0);
        fprintf('  Crew weight = %.1f lb, Baseline payload = %.1f lb\n', Wcrew, Wpayload);
    end
end

%% ---------------------------------------------------------
%  IF NOT LOADED: define the essentials manually (fallback path)
%  Note: since payload trade does NOT change the mission profile,
%  we only need Wx/W0 (or Wf/W0 directly), A, C, K_vs, and Wcrew.
% ---------------------------------------------------------
if ~loaded
    names = { ...
        'Sailplane - unpowered'; 'Sailplane - powered'; ...
        'Homebuilt - metal/wood'; 'Homebuilt - composite'; ...
        'General aviation - single engine'; 'General aviation - twin engine'; ...
        'Agricultural aircraft'; 'Twin turboprop'; 'Flying boat'; ...
        'Jet trainer'; 'Jet fighter'; 'Military cargo/bomber'; 'Jet transport'};
    A_tab = [0.86 0.91 1.19 0.99 2.36 1.51 0.74 0.96 1.09 1.59 2.34 0.93 1.02];
    C_tab = [-0.05 -0.05 -0.09 -0.09 -0.18 -0.10 -0.03 -0.05 -0.05 -0.10 -0.13 -0.07 -0.06];

    fprintf('Select aircraft type for empty weight fraction (Table 3.1):\n');
    for i = 1:length(names)
        fprintf('  %2d) %s\n', i, names{i});
    end
    fprintf('  %2d) Custom (enter A and C manually)\n', length(names)+1);
    sel = input('\nEnter choice number: ');
    if sel == length(names)+1
        A = input('Enter A: ');
        C = input('Enter C: ');
    else
        A = A_tab(sel);
        C = C_tab(sel);
    end
    vs = input('Variable sweep wing? (y/n): ', 's');
    if lower(vs) == 'y', K_vs = 1.04; else, K_vs = 1.00; end

    fprintf('\nEnter the fixed mission fuel fraction directly\n');
    fprintf('(from your mission analysis, e.g. Wf/W0 = 0.387):\n');
    Wf_W0 = input('  Wf/W0 = ');

    Wcrew = input('\nEnter crew weight (lb): ');
end

trapped_reserve = 1.06;   %#ok<NASGU> % kept for reference; Wf/W0 is already final here

%% ---------------------------------------------------------
%  DEFINE PAYLOAD SWEEP
% ---------------------------------------------------------
fprintf('\n---------------------------------------------------\n');
fprintf('DEFINE PAYLOAD SWEEP\n');
fprintf('---------------------------------------------------\n');
fprintf('  1) Enter a list of payload weights (e.g. 5000, 15000, 20000)\n');
fprintf('  2) Enter a linear sweep (start:step:end)\n');
pmode = input('  Select option: ');

if pmode == 1
    Plist = input('  Enter payload values as a vector, e.g. [5000 15000 20000]: ');
else
    p0 = input('  Start payload: ');
    ps = input('  Step: ');
    pf = input('  End payload: ');
    Plist = p0:ps:pf;
end

%% ---------------------------------------------------------
%  SWEEP - RESIZE AIRCRAFT FOR EACH PAYLOAD
% ---------------------------------------------------------
nP = length(Plist);
W0_results   = zeros(nP,1);
WeW0_results = zeros(nP,1);

W0_guess0 = input('\nEnter initial W0 guess (lb) for the iteration: ');
tol = 1e-4; maxIter = 200;

fprintf('\n=====================================================\n');
fprintf('PAYLOAD TRADE RESULTS\n');
fprintf('=====================================================\n');

for p = 1:nP
    Wfixed = Wcrew + Plist(p);   % crew stays fixed, payload varies

    W0_guess = W0_guess0;
    err = 1; iter = 0;
    fprintf('\n--- Payload = %.0f lb ---\n', Plist(p));
    fprintf('%-10s %-14s %-14s\n', 'Iter', 'W0 Guess', 'We/W0');
    while err > tol && iter < maxIter
        iter = iter + 1;
        WeW0 = A * W0_guess^C * K_vs;
        W0_new = Wfixed / (1 - Wf_W0 - WeW0);
        fprintf('%-10d %-14.1f %-14.4f\n', iter, W0_guess, WeW0);
        err = abs(W0_new - W0_guess) / W0_new;
        W0_guess = W0_new;
    end

    W0_results(p)   = W0_guess;
    WeW0_results(p) = A * W0_guess^C * K_vs;
end

%% ---------------------------------------------------------
%  SUMMARY TABLE
% ---------------------------------------------------------
fprintf('\n=====================================================\n');
fprintf('SUMMARY: PAYLOAD TRADE\n');
fprintf('=====================================================\n');
fprintf('%-14s %-12s %-14s\n', 'Payload (lb)', 'We/W0', 'W0 (lb)');
for p = 1:nP
    fprintf('%-14.0f %-12.4f %-14.1f\n', Plist(p), WeW0_results(p), W0_results(p));
end

%% ---------------------------------------------------------
%  PLOT - TOGW vs PAYLOAD  (like Fig 3.12)
% ---------------------------------------------------------
figure('Color','w');
plot(Plist, W0_results/1000, '-o', 'LineWidth', 1.6, 'MarkerFaceColor','b');
grid on;
xlabel('Payload - lb');
ylabel('TOGW, 1000 lb');
title('Payload Trade');