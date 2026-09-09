%% ============================================================
%  GENERIC RANGE TRADE STUDY  (Raymer Box 3.2 / Fig 3.11)
%
%  Re-sizes the aircraft (solves for W0) for several different
%  design ranges, keeping payload/crew and all other mission
%  segments fixed, so you can see how TOGW grows with range.
%
%  If you already ran ASW_sizing.m in this folder, this script
%  will offer to load its saved mission data automatically so
%  you don't have to re-enter the aircraft type, mission profile,
%  or crew/payload from scratch.
% ============================================================
clear; clc; close all;

fprintf('=====================================================\n');
fprintf('        GENERIC RANGE TRADE STUDY\n');
fprintf('=====================================================\n\n');

loaded = false;
if exist('mission_data.mat', 'file')
    ans_load = input('Found "mission_data.mat" from a previous sizing run. Load it? (y/n): ', 's');
    if lower(ans_load) == 'y'
        load('mission_data.mat');
        loaded = true;
        fprintf('\nLoaded mission: %s\n', acType);
        fprintf('  A = %.3f, C = %.3f, K_vs = %.2f\n', A, C, K_vs);
        fprintf('  Crew + Payload = %.1f lb\n', Wfixed);
        fprintf('  Segments:\n');
        typeStr = {'fixed','cruise','loiter'};
        for i = 1:nSeg
            tag = '';
            if isRangeLeg(i), tag = '  <-- range-trade leg'; end
            fprintf('    %d) %-22s [%s]  Wi/W(i-1) = %.4f%s\n', i, segLabel{i}, ...
                typeStr{segType(i)}, frac(i), tag);
        end
    end
end

%% ---------------------------------------------------------
%  IF NOT LOADED: define everything manually (fallback path)
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

    histLabel = {'Warmup and takeoff';'Climb';'Descent';'Landing, taxi';'Land'};
    histFrac  = [0.970; 0.985; 0.990; 0.995; 0.995];

    fprintf('\nDEFINE MISSION PROFILE\n');
    nSeg = input('Enter number of mission segments: ');
    segType = zeros(nSeg,1); segLabel = cell(nSeg,1); frac = zeros(nSeg,1);
    segC = nan(nSeg,1); segV = nan(nSeg,1); segLD = nan(nSeg,1); segR = nan(nSeg,1);
    isRangeLeg = false(nSeg,1);

    for i = 1:nSeg
        fprintf('\n--- Segment %d ---\n', i);
        fprintf('  1) Fixed/known weight fraction\n  2) Cruise\n  3) Loiter\n');
        stype = input('  Select segment type: ');
        segType(i) = stype;
        switch stype
            case 1
                for k = 1:length(histLabel)
                    fprintf('    %d) %-22s  %.3f\n', k, histLabel{k}, histFrac(k));
                end
                fprintf('    %d) Custom\n', length(histLabel)+1);
                hsel = input('  Select: ');
                if hsel == length(histLabel)+1
                    segLabel{i} = input('  Segment name: ', 's');
                    frac(i) = input('  Wi/W(i-1): ');
                else
                    segLabel{i} = histLabel{hsel};
                    frac(i) = histFrac(hsel);
                end
            case 2
                segLabel{i} = 'Cruise';
                R = input('  Range R (ft): ');
                Ccr = input('  C (1/s): ');
                V = input('  V (ft/s): ');
                LD = input('  L/D: ');
                frac(i) = exp(-R*Ccr/(V*LD));
                segR(i)=R; segC(i)=Ccr; segV(i)=V; segLD(i)=LD;
                rl = input('  Range-trade leg? (y/n): ', 's');
                isRangeLeg(i) = lower(rl) == 'y';
            case 3
                segLabel{i} = 'Loiter';
                E = input('  E (s): ');
                Clt = input('  C (1/s): ');
                LD = input('  L/D: ');
                frac(i) = exp(-E*Clt/LD);
        end
    end

    fprintf('\n');
    Wcrew    = input('Enter crew weight (lb): ');
    Wpayload = input('Enter payload weight (lb): ');
    Wfixed   = Wcrew + Wpayload;
end

if ~any(isRangeLeg)
    fprintf('\nNo segment is currently marked as a range-trade leg.\n');
    for i = 1:nSeg
        if segType(i) == 2
            fprintf('  Segment %d: %s (R=%.0f ft, C=%.6f, V=%.1f, L/D=%.1f)\n', ...
                i, segLabel{i}, segR(i), segC(i), segV(i), segLD(i));
        end
    end
    idxSel = input('Enter segment number(s) to mark as range-trade legs, e.g. [3 5]: ');
    isRangeLeg(idxSel) = true;
end

trapped_reserve = 1.06;

%% ---------------------------------------------------------
%  DEFINE RANGE SWEEP
% ---------------------------------------------------------
fprintf('\n---------------------------------------------------\n');
fprintf('DEFINE RANGE SWEEP (each-way design range)\n');
fprintf('---------------------------------------------------\n');
fprintf('  1) Enter a list of ranges (e.g. 1000, 1500, 2000)\n');
fprintf('  2) Enter a linear sweep (start:step:end)\n');
rmode = input('  Select option: ');
unitSel = input('  Enter ranges in (1) nautical miles or (2) feet? [1/2]: ');
convFac = 6076.1;

if rmode == 1
    Rlist = input('  Enter range values as a vector, e.g. [1000 1500 2000]: ');
else
    r0 = input('  Start range: ');
    rs = input('  Step: ');
    rf = input('  End range: ');
    Rlist = r0:rs:rf;
end

if unitSel == 1
    Rlist_ft = Rlist * convFac;
else
    Rlist_ft = Rlist;
end

%% ---------------------------------------------------------
%  SWEEP - RESIZE AIRCRAFT FOR EACH RANGE
% ---------------------------------------------------------
nR = length(Rlist_ft);
W0_results   = zeros(nR,1);
WeW0_results = zeros(nR,1);
Wx_results   = zeros(nR,1);
Wf_results   = zeros(nR,1);

W0_guess0 = input('\nEnter initial W0 guess (lb) for the iteration: ');
tol = 1e-4; maxIter = 200;

fprintf('\n=====================================================\n');
fprintf('RANGE TRADE RESULTS\n');
fprintf('=====================================================\n');

for r = 1:nR
    fracLocal = frac;
    for i = 1:nSeg
        if segType(i) == 2 && isRangeLeg(i)
            fracLocal(i) = exp(-Rlist_ft(r) * segC(i) / (segV(i) * segLD(i)));
        end
    end

    Wx_W0 = prod(fracLocal);
    Wf_W0 = trapped_reserve * (1 - Wx_W0);

    W0_guess = W0_guess0;
    err = 1; iter = 0;
    fprintf('\n--- Range = %.0f (each way) ---\n', Rlist(r));
    fprintf('%-10s %-14s %-14s\n', 'Iter', 'W0 Guess', 'We/W0');
    while err > tol && iter < maxIter
        iter = iter + 1;
        WeW0 = A * W0_guess^C * K_vs;
        W0_new = Wfixed / (1 - Wf_W0 - WeW0);
        fprintf('%-10d %-14.1f %-14.4f\n', iter, W0_guess, WeW0);
        err = abs(W0_new - W0_guess) / W0_new;
        W0_guess = W0_new;
    end

    W0_results(r)   = W0_guess;
    WeW0_results(r) = A * W0_guess^C * K_vs;
    Wx_results(r)   = Wx_W0;
    Wf_results(r)   = Wf_W0;
end

%% ---------------------------------------------------------
%  SUMMARY TABLE
% ---------------------------------------------------------
fprintf('\n=====================================================\n');
fprintf('SUMMARY: RANGE TRADE\n');
fprintf('=====================================================\n');
fprintf('%-14s %-12s %-12s %-14s\n', 'Range', 'Wx/W0', 'Wf/W0', 'W0 (lb)');
for r = 1:nR
    fprintf('%-14.0f %-12.4f %-12.4f %-14.1f\n', Rlist(r), Wx_results(r), Wf_results(r), W0_results(r));
end

%% ---------------------------------------------------------
%  PLOT - TOGW vs RANGE  (like Fig 3.11)
% ---------------------------------------------------------
figure('Color','w');
plot(Rlist, W0_results/1000, '-o', 'LineWidth', 1.6, 'MarkerFaceColor','b');
grid on;
xlabel('Range - nm (each way)');
ylabel('TOGW, 1000 lb');
title('Range Trade');