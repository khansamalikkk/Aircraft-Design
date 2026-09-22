function thrust_to_weight_analysis()
% =====================================================================
% THRUST-TO-WEIGHT RATIO ANALYSIS & FAR/MIL COMPLIANCE CHECK
% (Raymer, Section 5.2 & 5.5)
%
% This script calculates the T/W ratio and then checks the design
% against FAR 25 and MIL-C-5011A takeoff and landing requirements.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   THRUST-TO-WEIGHT RATIO & FAR/MIL COMPLIANCE CHECK\n');
    fprintf('========================================================\n\n');

    %% ========== AIRCRAFT CLASS PRESETS ==========
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
    WS      = get_num('Wing loading W/S (lb/ft^2)', 120);
    LDmax   = get_num('Max L/D', 18);
    RC_fpm  = get_num('Climb rate requirement (ft/min)', 1500);
    V_climb = get_num('Climb speed (ft/s)', 500);
    
    % Additional inputs for compliance check
    W = get_num('Takeoff gross weight (lb)', 530000);
    S_w = get_num('Wing area S (ft^2)', 4478.3);
    CLmax_TO = get_num('CLmax at takeoff', 2.4);
    CLmax_Land = get_num('CLmax at landing', 2.8);
    available_runway = get_num('Available runway length (ft)', 10000);

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
        LD_cruise = 0.866 * LDmax;
    else
        LD_cruise = LDmax;
    end
    TW_cruise = 1 / LD_cruise;

    fprintf('\n--- 2. CRUISE MATCHING ---\n');
    fprintf('  (L/D)max    = %.2f\n', LDmax);
    fprintf('  (L/D)cruise = %.2f\n', LD_cruise);
    fprintf('  T/W at cruise = 1/(L/D)cruise = %.4f\n', TW_cruise);

    %% ========== 3. THRUST LAPSE -> TAKEOFF T/W FROM CRUISE ==========
    Wcr_Wto = 0.956;
    TW_to_cruiseMatch = TW_cruise * Wcr_Wto / T_lapse;

    fprintf('\n--- 3. TAKEOFF T/W FROM CRUISE MATCHING (Eq. 5.3) ---\n');
    fprintf('  W_cruise/W_takeoff = %.3f\n', Wcr_Wto);
    fprintf('  T_cruise/T_takeoff = %.3f\n', T_lapse);
    fprintf('  T/W_takeoff = %.4f\n', TW_to_cruiseMatch);

    %% ========== 4. T/W FROM CLIMB REQUIREMENT ==========
    LD_climb = 0.9 * LDmax;
    RC_fps   = RC_fpm / 60;
    TW_climb = 1/LD_climb + RC_fps/V_climb;

    fprintf('\n--- 4. CLIMB T/W REQUIREMENT ---\n');
    fprintf('  (L/D)climb = %.2f\n', LD_climb);
    fprintf('  RC/V       = %.4f\n', RC_fps/V_climb);
    fprintf('  T/W_climb  = %.4f\n', TW_climb);

    %% ========== 5. PICK HIGHEST T/W ==========
    candidates = [TW_stat, TW_to_cruiseMatch, TW_climb];
    labels = {'Statistical (Table 5.3/5.4)', ...
              'Cruise matching -> takeoff', ...
              'Climb requirement'};

    fprintf('\n========================================================\n');
    fprintf('                    T/W CANDIDATES\n');
    fprintf('========================================================\n');
    for i = 1:numel(candidates)
        fprintf('  %-40s %10.4f\n', labels{i}, candidates(i));
    end

    [TW_max, idx] = max(candidates);
    fprintf('\n>>> SELECTED T/W (highest) = %.4f\n', TW_max);
    fprintf('>>> Driven by: %s\n', labels{idx});

    %% ========== 6. FAR / MIL COMPLIANCE CHECK ==========
    check_far_mil_compliance(W, S_w, WS, CLmax_TO, CLmax_Land, TW_max, ...
                             available_runway, cls);

    fprintf('\n========================================================\n');
    fprintf('Note: This is a simplified conceptual-level check.\n');
    fprintf('      Detailed performance analysis is required for\n');
    fprintf('      final certification.\n');
    fprintf('========================================================\n');
end

%% ========== FAR/MIL COMPLIANCE CHECK FUNCTION ==========
function check_far_mil_compliance(W, S_w, WS, CLmax_TO, CLmax_Land, TW, ...
                                  available_runway, aircraft_class)
% Checks takeoff and landing distances against FAR 25 and MIL-C-5011A
%
% Inputs:
%   W                - Takeoff gross weight (lb)
%   S_w              - Wing area (ft^2)
%   WS               - Wing loading (lb/ft^2)
%   CLmax_TO         - Max lift coefficient at takeoff
%   CLmax_Land       - Max lift coefficient at landing
%   TW               - Thrust-to-weight ratio (selected)
%   available_runway - Available runway length (ft)
%   aircraft_class   - String identifying aircraft class

    fprintf('\n========================================================\n');
    fprintf('         FAR 25 / MIL-C-5011A COMPLIANCE CHECK\n');
    fprintf('========================================================\n');

    % --- Constants ---
    rho0 = 0.0023769;   % slug/ft^3, sea level density
    g    = 32.174;      % ft/s^2
    mu   = 0.025;       % Rolling friction coefficient (Raymer)

    % --- Aircraft classification ---
    is_transport = any(strcmpi(aircraft_class, ...
        {'jet_transport', 'mil_cargo_bomber', 'bomber', 'cargo'}));
    is_fighter = any(strcmpi(aircraft_class, ...
        {'jet_fighter', 'jet_fighter_dog'}));
    is_ga = any(strcmpi(aircraft_class, ...
        {'ga_single', 'ga_twin', 'homebuilt_metal', 'homebuilt_comp'}));

    % Number of engines (simplified)
    if is_transport || strcmpi(aircraft_class, 'mil_cargo_bomber')
        n_engines = 2;
    elseif is_fighter
        n_engines = 1;   % Simplified for single-engine fighter
    else
        n_engines = 1;
    end

    %% --- TAKEOFF DISTANCE CALCULATION ---
    fprintf('\n--- TAKEOFF PERFORMANCE ---\n');

    % Takeoff speed (approximate)
    V_to = sqrt(2 * W / (rho0 * S_w * CLmax_TO));   % ft/s
    V_to_kts = V_to * 0.5925;                        % knots

    fprintf('  Takeoff speed V_TO          = %.1f ft/s (%.1f kts)\n', V_to, V_to_kts);
    fprintf('  CLmax at takeoff            = %.2f\n', CLmax_TO);

    % Ground roll distance (Raymer Eq. 5.9 simplified)
    % S_g = 1.44 * (W/S) / (rho0 * g * CLmax_TO * T/W)
    S_g = 1.44 * WS / (rho0 * g * CLmax_TO * TW);

    % Air distance to clear 35 ft obstacle
    % Simplified: assume average climb gradient during air phase
    % Using Raymer's approximation: S_a = 35 / tan(gamma_climb)
    % For transport, typical gamma_climb ~ 0.03 (3%)
    if is_transport
        gamma_climb = 0.03;
    elseif is_fighter
        gamma_climb = 0.08;
    else
        gamma_climb = 0.05;
    end
    S_a_35 = 35 / gamma_climb;      % distance to 35 ft
    S_a_50 = 50 / gamma_climb;      % distance to 50 ft

    % Total takeoff distance (AEO)
    S_to_35_AEO = S_g + S_a_35;
    S_to_50_AEO = S_g + S_a_50;

    % Balanced field length (simplified)
    % BFL ? 1.15 * S_to_35_AEO (conservative for 2-engine aircraft)
    % Raymer: for 2-engine, BFL is decisive
    if n_engines == 2
        BFL = 1.15 * S_to_35_AEO;
    else
        BFL = S_to_35_AEO;  % For 4-engine, TOD*1.15 is decisive
    end

    % FAR 25 TOFL
    TOFL_FAR25 = max(1.15 * S_to_35_AEO, BFL);

    % MIL-C-5011A takeoff distance (50 ft obstacle, AEO)
    TOFL_MIL = S_to_50_AEO;

    fprintf('\n  Ground roll S_g             = %.0f ft\n', S_g);
    fprintf('  Air distance to 35 ft       = %.0f ft\n', S_a_35);
    fprintf('  Air distance to 50 ft       = %.0f ft\n', S_a_50);
    fprintf('  Takeoff dist to 35 ft (AEO) = %.0f ft\n', S_to_35_AEO);
    fprintf('  Balanced field length BFL   = %.0f ft\n', BFL);
    fprintf('  FAR 25 TOFL                 = %.0f ft\n', TOFL_FAR25);
    fprintf('  MIL-C-5011A TOFL            = %.0f ft\n', TOFL_MIL);

    %% --- LANDING DISTANCE CALCULATION ---
    fprintf('\n--- LANDING PERFORMANCE ---\n');

    % Landing speed (V_REF = 1.3 * V_stall_land)
    V_stall_land = sqrt(2 * W / (rho0 * S_w * CLmax_Land));  % ft/s
    V_REF = 1.3 * V_stall_land;                               % ft/s
    V_REF_kts = V_REF * 0.5925;                               % knots

    fprintf('  Stall speed (landing)       = %.1f ft/s (%.1f kts)\n', ...
            V_stall_land, V_stall_land * 0.5925);
    fprintf('  Approach speed V_REF        = %.1f ft/s (%.1f kts)\n', ...
            V_REF, V_REF_kts);
    fprintf('  CLmax at landing            = %.2f\n', CLmax_Land);

    % Approach distance from 50 ft obstacle
    % Simplified: approach gradient ~ 3 degrees (typical for transports)
    approach_angle = 3 * pi/180;   % radians
    S_approach = 50 / tan(approach_angle);

    % Flare distance (simplified)
    S_flare = 1000;   % ft, typical for transport

    % Ground roll (braking) - simplified energy method
    % S_brake = V_REF^2 / (2 * a_avg)
    % a_avg = mu * g (assuming lift is zero after touchdown)
    mu_brake = 0.4;   % Dry runway braking coefficient (conservative)
    a_avg = mu_brake * g;
    S_brake = V_REF^2 / (2 * a_avg);

    % Total landing distance from 50 ft
    S_land_50 = S_approach + S_flare + S_brake;

    % FAR 25 landing field length (LFL = S_land / 0.6)
    LFL_FAR25 = S_land_50 / 0.6;

    % MIL-C-5011A landing distance (no 0.6 factor)
    LFL_MIL = S_land_50;

    fprintf('\n  Approach distance           = %.0f ft\n', S_approach);
    fprintf('  Flare distance              = %.0f ft\n', S_flare);
    fprintf('  Braking distance            = %.0f ft\n', S_brake);
    fprintf('  Landing dist from 50 ft     = %.0f ft\n', S_land_50);
    fprintf('  FAR 25 LFL                  = %.0f ft\n', LFL_FAR25);
    fprintf('  MIL-C-5011A LFL             = %.0f ft\n', LFL_MIL);

    %% --- COMPLIANCE CHECK ---
    fprintf('\n========================================================\n');
    fprintf('              COMPLIANCE RESULTS\n');
    fprintf('========================================================\n');
    fprintf('  Available runway length     = %.0f ft\n\n', available_runway);

    % Check FAR 25
    fprintf('  --- FAR 25 ---\n');
    if TOFL_FAR25 <= available_runway
        fprintf('  Takeoff: PASS (%.0f ft <= %.0f ft)\n', TOFL_FAR25, available_runway);
    else
        fprintf('  Takeoff: FAIL (%.0f ft > %.0f ft) - SHORT BY %.0f ft\n', ...
                TOFL_FAR25, available_runway, TOFL_FAR25 - available_runway);
    end

    if LFL_FAR25 <= available_runway
        fprintf('  Landing: PASS (%.0f ft <= %.0f ft)\n', LFL_FAR25, available_runway);
    else
        fprintf('  Landing: FAIL (%.0f ft > %.0f ft) - SHORT BY %.0f ft\n', ...
                LFL_FAR25, available_runway, LFL_FAR25 - available_runway);
    end

    % Check MIL-C-5011A
    fprintf('\n  --- MIL-C-5011A ---\n');
    if TOFL_MIL <= available_runway
        fprintf('  Takeoff: PASS (%.0f ft <= %.0f ft)\n', TOFL_MIL, available_runway);
    else
        fprintf('  Takeoff: FAIL (%.0f ft > %.0f ft) - SHORT BY %.0f ft\n', ...
                TOFL_MIL, available_runway, TOFL_MIL - available_runway);
    end

    if LFL_MIL <= available_runway
        fprintf('  Landing: PASS (%.0f ft <= %.0f ft)\n', LFL_MIL, available_runway);
    else
        fprintf('  Landing: FAIL (%.0f ft > %.0f ft) - SHORT BY %.0f ft\n', ...
                LFL_MIL, available_runway, LFL_MIL - available_runway);
    end

    %% --- ADDITIONAL NOTES ---
    fprintf('\n--- NOTES ---\n');
    if is_transport
        fprintf('  * FAR 25 takeoff uses 35 ft obstacle, landing uses 50 ft.\n');
        fprintf('  * Landing field length divided by 0.6 for FAR 25.\n');
    elseif is_fighter
        fprintf('  * Fighter aircraft may use different military standards.\n');
        fprintf('  * Consult MIL-C-5011A or specific procurement requirements.\n');
    elseif is_ga
        fprintf('  * FAR 23 (not FAR 25) applies to general aviation aircraft.\n');
        fprintf('  * FAR 23 uses 50 ft obstacle for both takeoff and landing.\n');
    end
    fprintf('  * This is a conceptual-level estimate. Detailed analysis\n');
    fprintf('    with actual engine data and flight test results is required.\n');
end

%% ========== HELPER FUNCTIONS ==========
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