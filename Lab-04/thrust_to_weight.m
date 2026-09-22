function thrust_to_weight()
% =====================================================================
% THRUST-TO-WEIGHT RATIO ANALYSIS  (Raymer, Section 5.2)
%
% Tasks performed:
%   1. Look up statistical T/W (Table 5.1 / 5.3, or hp/W Table 5.2 / 5.4)
%   2. Refine T/W based on max Mach number (Table 5.3 curve fit)
%   3. Get thrust lapse ratio T_cruise / T_takeoff (Fig. 5.1)
%   4. Compute T/W at climb (climb-rate requirement)
%   5. Compute T/W at takeoff from cruise matching (Eq. 5.3)
%   6. Pick the highest T/W for engine sizing
%
% Generic - works for any aircraft. Defaults are set for a 530,000 lb
% jet transport (Boeing 777-200 class).
% =====================================================================

clc;
fprintf('========================================================\n');
fprintf('   THRUST-TO-WEIGHT RATIO ANALYSIS (Raymer Sec. 5.2)\n');
fprintf('========================================================\n\n');

%% ========== AIRCRAFT CLASS PRESETS ==========
% Table 5.3 (jets):   T/W0 = a * Mmax^C
% Table 5.4 (props):  hp/W0 = a * Vmax^C   (Vmax in mph)
% 'lapse' = T_cruise/T_takeoff from Raymer Fig. 5.1
presets = struct( ...
    'jet_trainer',      struct('a',0.488,'C',0.728,'kind','jet', 'lapse',0.25), ...
    'jet_fighter_dog',  struct('a',0.648,'C',0.594,'kind','jet', 'lapse',0.55), ...
    'jet_fighter',      struct('a',0.514,'C',0.141,'kind','jet', 'lapse',0.45), ...
    'mil_cargo_bomber', struct('a',0.244,'C',0.341,'kind','jet', 'lapse',0.22), ...
    'jet_transport',    struct('a',0.267,'C',0.363,'kind','jet', 'lapse',0.22), ...
    'twin_turboprop',   struct('a',0.012,'C',0.50, 'kind','prop','lapse',0.70), ...
    'ga_single',        struct('a',0.024,'C',0.22, 'kind','prop','lapse',0.75), ...
    'ga_twin',          struct('a',0.034,'C',0.32, 'kind','prop','lapse',0.75), ...
    'agricultural',     struct('a',0.008,'C',0.50, 'kind','prop','lapse',0.75), ...
    'homebuilt_metal',  struct('a',0.005,'C',0.57, 'kind','prop','lapse',0.75), ...
    'homebuilt_comp',   struct('a',0.004,'C',0.57, 'kind','prop','lapse',0.75), ...
    'sailplane',        struct('a',0.043,'C',0.00, 'kind','prop','lapse',0.80), ...
    'flying_boat',      struct('a',0.029,'C',0.23, 'kind','prop','lapse',0.75));

class_names = fieldnames(presets);

%% ========== INPUTS ==========
fprintf('--- AIRCRAFT CLASS ---\n');
fprintf('Available classes:\n');
for i = 1:numel(class_names)
    fprintf('  %s\n', class_names{i});
end
cls = get_str('Aircraft class', 'jet_transport');
if ~isfield(presets, cls)
    fprintf('  Class "%s" not found. Using jet_transport.\n', cls);
    cls = 'jet_transport';
end
P = presets.(cls);

fprintf('\n--- DESIGN PARAMETERS ---\n');
Mmax    = get_num('Design max Mach Mmax', 0.84);
Mcruise = get_num('Cruise Mach', 0.84);
alt_cr  = get_num('Cruise altitude (ft)', 35000);
WS      = get_num('Wing loading W/S (lb/ft^2)', 120);   % Table 5.5
LDmax   = get_num('Max L/D', 18);
RC_fpm  = get_num('Climb rate requirement (ft/min)', 1500);
V_climb = get_num('Climb speed (ft/s)', 500);

% Thrust lapse (Fig. 5.1)
fprintf('\n--- THRUST LAPSE (Fig. 5.1) ---\n');
fprintf('  Typical values: 0.20-0.25  high-BPR turbofan\n');
fprintf('                  0.40-0.50  low-BPR turbofan\n');
fprintf('                  0.50-0.70  afterburning turbojet\n');
T_lapse = get_num('T_cruise / T_takeoff', P.lapse);

%% ========== 1. STATISTICAL T/W ==========
if strcmp(P.kind, 'jet')
    TW_stat = P.a * Mmax^P.C;
    fprintf('\n--- 1. STATISTICAL T/W  (Table 5.3) ---\n');
    fprintf('  T/W0 = %.4f * Mmax^%.4f\n', P.a, P.C);
    fprintf('  T/W0 = %.4f * (%.2f)^%.4f = %.4f\n', P.a, Mmax, P.C, TW_stat);
else
    Vmax_mph = get_num('Max speed Vmax (mph)', 200);
    hpW_stat = P.a * Vmax_mph^P.C;
    eta_p    = 0.8;
    TW_stat  = hpW_stat * 550 * eta_p / (Vmax_mph * 1.46667);
    fprintf('\n--- 1. STATISTICAL hp/W  (Table 5.4) ---\n');
    fprintf('  hp/W0 = %.4f * Vmax^%.4f = %.4f\n', P.a, P.C, hpW_stat);
    fprintf('  Equivalent T/W0 = %.4f\n', TW_stat);
end

%% ========== 2. CRUISE MATCHING ==========
if strcmp(P.kind, 'jet')
    LD_cruise = 0.866 * LDmax;   % Raymer: jet cruise = 86.6% of L/D max
else
    LD_cruise = LDmax;            % prop: cruise L/D = L/D max
end
TW_cruise = 1 / LD_cruise;

fprintf('\n--- 2. CRUISE MATCHING ---\n');
fprintf('  (L/D)max    = %.2f\n', LDmax);
fprintf('  (L/D)cruise = %.2f\n', LD_cruise);
fprintf('  T/W at cruise = 1/(L/D)cruise = %.4f\n', TW_cruise);

%% ========== 3. THRUST LAPSE -> TAKEOFF T/W FROM CRUISE ==========
Wcr_Wto = 0.956;   % Raymer: fuel burned during takeoff + climb
TW_to_cruiseMatch = TW_cruise * Wcr_Wto / T_lapse;

fprintf('\n--- 3. TAKEOFF T/W FROM CRUISE MATCHING (Eq. 5.3) ---\n');
fprintf('  W_cruise/W_takeoff = %.3f\n', Wcr_Wto);
fprintf('  T_cruise/T_takeoff = %.3f\n', T_lapse);
fprintf('  T/W_takeoff = %.4f\n', TW_to_cruiseMatch);

%% ========== 4. T/W FROM CLIMB REQUIREMENT ==========
% T/W = 1/(L/D) + RC/V     (small-angle climb)
LD_climb = 0.9 * LDmax;     % approximate climb L/D
RC_fps   = RC_fpm / 60;
TW_climb = 1/LD_climb + RC_fps/V_climb;

fprintf('\n--- 4. CLIMB T/W REQUIREMENT ---\n');
fprintf('  (L/D)climb = %.2f\n', LD_climb);
fprintf('  RC/V       = %.4f\n', RC_fps/V_climb);
fprintf('  T/W_climb  = %.4f\n', TW_climb);

%% ========== 5. T/W FROM TAKEOFF GROUND ROLL (optional) ==========
fprintf('\n--- 5. TAKEOFF GROUND ROLL (optional) ---\n');
d_to = get_num('Takeoff ground roll (ft, 0 to skip)', 0);
if d_to > 0
    CLmax = get_num('CLmax at takeoff', 2.0);
    rho0  = 0.0023769;
    g     = 32.174;
    TW_to_gr = 1.44 * WS / (rho0 * g * CLmax * d_to);
    fprintf('  T/W from ground roll = %.4f\n', TW_to_gr);
else
    TW_to_gr = 0;
    fprintf('  Skipped.\n');
end

%% ========== 6. PICK HIGHEST T/W ==========
candidates = [TW_stat, TW_to_cruiseMatch, TW_climb, TW_to_gr];
labels = {'Statistical (Table 5.3/5.4)', ...
          'Cruise matching -> takeoff', ...
          'Climb requirement', ...
          'Takeoff ground roll'};

fprintf('\n========================================================\n');
fprintf('                    T/W CANDIDATES\n');
fprintf('========================================================\n');
for i = 1:numel(candidates)
    if candidates(i) > 0
        fprintf('  %-40s %10.4f\n', labels{i}, candidates(i));
    end
end

[TW_max, idx] = max(candidates);
fprintf('\n>>> SELECTED T/W (highest) = %.4f\n', TW_max);
fprintf('>>> Driven by: %s\n', labels{idx});

if strcmp(P.kind, 'jet')
    fprintf('\nSea-level static takeoff T/W = %.3f\n', TW_max);
    fprintf('(Use this value to size engines at takeoff)\n');
else
    eta_p = 0.8;
    hpW_final = TW_max * V_climb / (550 * eta_p);
    fprintf('\nEquivalent hp/W = %.4f\n', hpW_final);
    fprintf('Power loading W/hp = %.2f\n', 1/hpW_final);
end

fprintf('\n========================================================\n');
fprintf('Note: After wing loading is finalized, recheck T/W\n');
fprintf('against all requirements (takeoff, climb, cruise, turn).\n');
fprintf('========================================================\n');
end

%% ========== HELPERS ==========
function val = get_num(prompt, default)
    str = input(sprintf('%s [%g]: ', prompt, default), 's');
    if isempty(str)
        val = default;
    else
        val = str2double(str);
        if isnan(val), val = default; end
    end
end

function str = get_str(prompt, default)
    str = input(sprintf('%s [%s]: ', prompt, default), 's');
    if isempty(str), str = default; end
    str = strtrim(str);
end