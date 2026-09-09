%  GENERIC RANGE TRADE STUDY  (Raymer Box 3.2 / Fig 3.11)
%
%  Re-sizes the aircraft (solves for W0) for several different
%  design ranges, keeping payload/crew and all other mission
%  segments fixed, so you can see how TOGW grows with range.
%
%  Works for ANY aircraft type and ANY mission profile - you
%  define the mission once, then mark which cruise segment(s)
%  are tied to the "range" being traded.

clear; clc; close all;

fprintf('=====================================================\n');
fprintf('        GENERIC RANGE TRADE STUDY\n');
fprintf('=====================================================\n\n');

%  STEP 1: AIRCRAFT TYPE -> EMPTY WEIGHT COEFFICIENTS (Table 3.1)

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

%  STEP 2: DEFINE BASELINE MISSION PROFILE
%  For each segment, mark whether it's the "range trade" cruise
%  leg (its range will be overwritten during the sweep) or fixed.

histLabel = {'Warmup and takeoff';'Climb';'Descent';'Landing, taxi';'Land'};
histFrac  = [0.970; 0.985; 0.990; 0.995; 0.995];

fprintf('\n---------------------------------------------------\n');
fprintf('DEFINE MISSION PROFILE\n');
fprintf('---------------------------------------------------\n');
nSeg = input('Enter number of mission segments: ');

segType   = zeros(nSeg,1);   % 1=fixed, 2=cruise, 3=loiter
segLabel  = cell(nSeg,1);
segFrac   = zeros(nSeg,1);   % used directly for fixed & loiter segments
segC      = zeros(nSeg,1);   % sfc for cruise segments
segV      = zeros(nSeg,1);   % velocity for cruise segments
segLD     = zeros(nSeg,1);   % L/D for cruise segments
isRangeLeg = false(nSeg,1);  % true if this cruise leg is tied to the swept range

for i = 1:nSeg
    fprintf('\n--- Segment %d ---\n', i);
    fprintf('  1) Fixed/known weight fraction (historical table or custom)\n');
    fprintf('  2) Cruise (Breguet range equation)\n');
    fprintf('  3) Loiter (Breguet endurance equation)\n');
    stype = input('  Select segment type: ');
    segType(i) = stype;

    switch stype
        case 1
            fprintf('\n  Historical mission segment weight fractions (Table 2.2):\n');
            for k = 1:length(histLabel)
                fprintf('    %d) %-22s  Wi/W(i-1) = %.3f\n', k, histLabel{k}, histFrac(k));
            end
            fprintf('    %d) Custom (enter your own name and value)\n', length(histLabel)+1);
            hsel = input('  Select option: ');
            if hsel == length(histLabel)+1
                segLabel{i} = input('  Segment name: ', 's');
                segFrac(i)  = input('  Enter weight fraction Wi/W(i-1): ');
            else
                segLabel{i} = histLabel{hsel};
                segFrac(i)  = histFrac(hsel);
            end

        case 2
            segLabel{i} = 'Cruise';
            rl = input('  Is this cruise leg tied to the RANGE being traded? (y/n): ', 's');
            isRangeLeg(i) = lower(rl) == 'y';
            if ~isRangeLeg(i)
                Rfixed = input('  Enter this leg''s (fixed) range R (ft): ');
                segFrac(i) = NaN;   % placeholder, computed below once C,V,L/D known
                segC(i)  = 0; segV(i) = 0; segLD(i) = 0; %#ok<NASGU>
            end
            segC(i)  = input('  Specific fuel consumption C (1/s): ');
            segV(i)  = input('  Velocity V (ft/s): ');
            segLD(i) = input('  Lift-to-drag ratio L/D: ');
            if ~isRangeLeg(i)
                segFrac(i) = exp(-Rfixed*segC(i)/(segV(i)*segLD(i)));
            end

        case 3
            segLabel{i} = 'Loiter';
            E  = input('  Endurance time E (s): ');
            Cl = input('  Specific fuel consumption C (1/s): ');
            LD = input('  Lift-to-drag ratio L/D: ');
            segFrac(i) = exp(-E*Cl/LD);

        otherwise
            error('Invalid segment type.');
    end
end

if ~any(isRangeLeg)
    error('No cruise segment was marked as the range-trade leg. Re-run and mark at least one.');
end

%  STEP 3: CREW + PAYLOAD (held constant across the trade)

fprintf('\n---------------------------------------------------\n');
Wcrew    = input('Enter crew weight (lb): ');
Wpayload = input('Enter payload weight (lb): ');
Wfixed   = Wcrew + Wpayload;

trapped_reserve = 1.06;   % 6% reserve/trapped fuel allowance

%  STEP 4: DEFINE RANGE SWEEP

fprintf('\n---------------------------------------------------\n');
fprintf('DEFINE RANGE SWEEP (each-way design range)\n');
fprintf('---------------------------------------------------\n');
fprintf('  1) Enter a list of ranges (e.g. 1000, 1500, 2000)\n');
fprintf('  2) Enter a linear sweep (start:step:end)\n');
rmode = input('  Select option: ');

unitSel = input('  Enter ranges in (1) nautical miles or (2) feet? [1/2]: ');
convFac = 6076.1;   % ft per nm

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

%  STEP 5: SWEEP - RESIZE AIRCRAFT FOR EACH RANGE

nR = length(Rlist_ft);
W0_results  = zeros(nR,1);
WeW0_results = zeros(nR,1);
Wx_results  = zeros(nR,1);
Wf_results  = zeros(nR,1);

W0_guess0 = input('\nEnter initial W0 guess (lb) for the iteration: ');
tol = 1e-4; maxIter = 200;

fprintf('\n=====================================================\n');
fprintf('RANGE TRADE RESULTS\n');
fprintf('=====================================================\n');

for r = 1:nR
    frac = segFrac;   % start from baseline fractions
    for i = 1:nSeg
        if segType(i) == 2 && isRangeLeg(i)
            frac(i) = exp(-Rlist_ft(r) * segC(i) / (segV(i) * segLD(i)));
        end
    end

    Wx_W0 = prod(frac);
    Wf_W0 = trapped_reserve * (1 - Wx_W0);

    % --- iterate for W0 ---
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

%  STEP 6: SUMMARY TABLE

fprintf('\n=====================================================\n');
fprintf('SUMMARY: RANGE TRADE\n');
fprintf('=====================================================\n');
fprintf('%-14s %-12s %-12s %-14s\n', 'Range', 'Wx/W0', 'Wf/W0', 'W0 (lb)');
for r = 1:nR
    fprintf('%-14.0f %-12.4f %-12.4f %-14.1f\n', Rlist(r), Wx_results(r), Wf_results(r), W0_results(r));
end

%  STEP 7: PLOT - TOGW vs RANGE  (like Fig 3.11)

figure('Color','w');
plot(Rlist, W0_results/1000, '-o', 'LineWidth', 1.6, 'MarkerFaceColor','b');
grid on;
xlabel('Range - nm (each way)');
ylabel('TOGW, 1000 lb');
title('Range Trade');