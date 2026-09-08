%  GENERIC AIRCRAFT SIZING CALCULATION (ASW - Raymer Method)
%  Based on: Table 3.1 (Empty Weight Fraction) +
%            Box 3.1 (Mission Segment Weight Fractions)
%
%  Works for ANY aircraft type / ANY mission profile the user
%  defines interactively.
clear; clc; close all;

fprintf('   AIRCRAFT CONCEPTUAL SIZING - GENERIC ASW CODE\n');

%  STEP 1: SELECT AIRCRAFT TYPE  --> gives A, C  (Table 3.1)
%  We/W0 = A * W0^C * K_vs

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
    acType = 'Custom';
else
    A = A_tab(sel);
    C = C_tab(sel);
    acType = names{sel};
end

vs = input('Variable sweep wing? (y/n): ', 's');
if lower(vs) == 'y'
    K_vs = 1.04;
else
    K_vs = 1.00;
end

fprintf('\nSelected: %s   |   A = %.3f, C = %.3f, K_vs = %.2f\n\n', acType, A, C, K_vs);

%  STEP 2: DEFINE MISSION PROFILE
%  Build the mission segment-by-segment. Each segment reduces
%  weight from W(i-1) to W(i). Supported types:
%    1) Fixed historical fraction (warmup/takeoff, climb, land, etc.)
%    2) Cruise segment      -> Breguet range equation
%    3) Loiter segment      -> Breguet endurance equation

fprintf('---------------------------------------------------\n');
fprintf('DEFINE MISSION PROFILE\n');
fprintf('---------------------------------------------------\n');
nSeg = input('Enter number of mission segments (e.g. 7 for a typical ASW mission): ');

frac = zeros(nSeg,1);   % Wi/W(i-1) for each segment
segLabel = cell(nSeg,1);

% Historical mission segment weight fractions (Raymer Table 2.2)
% These are typical statistical values used for phases that are NOT
% cruise or loiter (i.e. where the Breguet equations don't apply).
histLabel = { ...
    'Warmup and takeoff'; ...
    'Climb'; ...
    'Descent'; ...
    'Landing, taxi'; ...
    'Land'};
histFrac  = [0.970; 0.985; 0.990; 0.995; 0.995];

for i = 1:nSeg
    fprintf('\n--- Segment %d ---\n', i);
    fprintf('  1) Fixed/known weight fraction (historical table or custom)\n');
    fprintf('  2) Cruise (Breguet range equation)\n');
    fprintf('  3) Loiter (Breguet endurance equation)\n');
    stype = input('  Select segment type: ');

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
                frac(i) = input('  Enter weight fraction Wi/W(i-1): ');
            else
                segLabel{i} = histLabel{hsel};
                frac(i) = histFrac(hsel);
                fprintf('  --> Using Wi/W(i-1) = %.3f for %s\n', frac(i), segLabel{i});
            end

        case 2
            segLabel{i} = 'Cruise';
            R  = input('  Range R (ft)                     [or nm*6076.1 to convert]: ');
            Ccr = input('  Specific fuel consumption C (1/s)  : ');
            V  = input('  Velocity V (ft/s)                 : ');
            LD = input('  Lift-to-drag ratio L/D             : ');
            frac(i) = exp(-R*Ccr/(V*LD));
            fprintf('  --> Computed Wi/W(i-1) = %.4f\n', frac(i));

        case 3
            segLabel{i} = 'Loiter';
            E  = input('  Endurance time E (s)               : ');
            Clt = input('  Specific fuel consumption C (1/s)  : ');
            LD = input('  Lift-to-drag ratio L/D             : ');
            frac(i) = exp(-E*Clt/LD);
            fprintf('  --> Computed Wi/W(i-1) = %.4f\n', frac(i));

        otherwise
            error('Invalid segment type selected.');
    end
end


%  STEP 3: MISSION WEIGHT FRACTION & FUEL FRACTION

Wx_W0 = prod(frac);                 % Wx/W0 = product of all segment fractions
trapped_reserve = 1.06;             % 6% allowance for reserve + trapped fuel (Raymer default)
Wf_W0 = trapped_reserve * (1 - Wx_W0);

fprintf('\n---------------------------------------------------\n');
fprintf('MISSION SUMMARY\n');
fprintf('---------------------------------------------------\n');
for i = 1:nSeg
    fprintf('  Segment %d (%s): Wi/W(i-1) = %.4f\n', i, segLabel{i}, frac(i));
end
fprintf('  Wx/W0 (final/initial)   = %.4f\n', Wx_W0);
fprintf('  Wf/W0 (fuel fraction)   = %.4f   [includes %.0f%% reserve/trapped fuel]\n', ...
        Wf_W0, (trapped_reserve-1)*100);

%  STEP 4: CREW + PAYLOAD
% ---------------------------------------------------------
fprintf('\n---------------------------------------------------\n');
Wcrew    = input('Enter crew weight (lb): ');
Wpayload = input('Enter payload weight (lb): ');
Wfixed   = Wcrew + Wpayload;

%  STEP 5: ITERATIVE SOLUTION FOR W0
%  W0 = Wfixed / (1 - Wf/W0 - We/W0)
%  We/W0 = A * W0^C * K_vs   (depends on W0 itself -> iterate)

fprintf('\n---------------------------------------------------\n');
W0_guess = input('Enter initial W0 guess (lb): ');
tol      = 1e-4;      % convergence tolerance
maxIter  = 100;
err      = 1;
iter     = 0;

fprintf('\n%-10s %-14s %-14s\n', 'Iter', 'W0 Guess', 'We/W0');
fprintf('%-10s %-14s %-14s\n', '----', '--------', '-----');

results = [];
while err > tol && iter < maxIter
    iter = iter + 1;
    WeW0 = A * W0_guess^C * K_vs;
    W0_new = Wfixed / (1 - Wf_W0 - WeW0);

    fprintf('%-10d %-14.1f %-14.4f\n', iter, W0_guess, WeW0);
    results = [results; iter, W0_guess, WeW0, W0_new]; %#ok<AGROW>

    err = abs(W0_new - W0_guess) / W0_new;
    W0_guess = W0_new;
end

%  STEP 6: FINAL RESULTS

We_W0_final = A * W0_guess^C * K_vs;
We_final    = We_W0_final * W0_guess;
Wf_final    = Wf_W0 * W0_guess;

fprintf('\n=====================================================\n');
fprintf('CONVERGED RESULTS (after %d iterations)\n', iter);
fprintf('=====================================================\n');
fprintf('  Takeoff gross weight   W0       = %.1f lb\n', W0_guess);
fprintf('  Empty weight fraction  We/W0    = %.4f\n', We_W0_final);
fprintf('  Empty weight           We       = %.1f lb\n', We_final);
fprintf('  Fuel weight            Wf       = %.1f lb\n', Wf_final);
fprintf('  Crew + Payload weight           = %.1f lb\n', Wfixed);
fprintf('=====================================================\n\n');

%  STEP 7: PLOT CONVERGENCE (W0 guess vs iteration)

figure('Color','w');
plot(results(:,1), results(:,2), '-o', 'LineWidth', 1.5, 'MarkerFaceColor','b');
grid on;
xlabel('Iteration');
ylabel('W_0 (lb)');
title('Convergence of Takeoff Gross Weight (W_0)');