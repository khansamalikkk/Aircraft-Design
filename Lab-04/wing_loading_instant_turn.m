function wing_loading_instant_turn()
% =====================================================================
% WING LOADING FOR INSTANTANEOUS TURN
% (Raymer Sec. 5.3, Eq. 5.17 - 5.20)
%
%   n = sqrt(1 + (omega * V / g)^2)        Eq. 5.19
%   W/S = q * CLmax_combat / n             Eq. 5.20
%
% The resulting W/S is at combat conditions. Convert to takeoff W/S
% by dividing by W_combat/W_takeoff (typically 0.85 for fighters).
%
% Generic - works for any aircraft. Defaults set for a jet fighter.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('  WING LOADING FOR INSTANTANEOUS TURN (Raymer 5.17-5.20)\n');
    fprintf('========================================================\n\n');

    %% ========== USER INPUTS ==========
    fprintf('--- TURN REQUIREMENT ---\n');
    fprintf('  Typical fighter instantaneous turn rates:\n');
    fprintf('    15-20 deg/s  for 4th-gen fighters (F-16, F-15)\n');
    fprintf('    20-30 deg/s  for 5th-gen fighters (F-22, F-35)\n');
    fprintf('    10-15 deg/s  for older fighters (F-4, MiG-21)\n');
    turn_rate_dps = get_num('Required turn rate (deg/s)', 18);

    fprintf('\n--- FLIGHT CONDITION ---\n');
    fprintf('  Corner speed is typically 300-350 kts IAS for fighters.\n');
    V_kts = get_num('Flight speed (knots)', 350);
    alt_ft = get_num('Combat altitude (ft)', 15000);

    fprintf('\n--- COMBAT LIFT COEFFICIENT ---\n');
    fprintf('  Raymer combat CLmax values:\n');
    fprintf('    0.6-0.8  simple trailing-edge flap only\n');
    fprintf('    1.0-1.5  complex LE + TE flap system\n');
    CLmax_combat = get_num('CLmax at combat', 1.0);

    fprintf('\n--- STRUCTURAL LIMIT ---\n');
    fprintf('  Operational g-limit:\n');
    fprintf('    7.33  classic fighter design limit\n');
    fprintf('    8-9   newer fighters\n');
    n_limit = get_num('Structural g-limit n_max', 9.0);

    fprintf('\n--- WEIGHT RATIO ---\n');
    fprintf('  W_combat / W_takeoff is typically ~0.85 for fighters\n');
    fprintf('  (combat weight = takeoff weight minus drop tanks\n');
    fprintf('   minus 50%% internal fuel)\n');
    Wc_Wto = get_num('Combat weight ratio W_combat/W_takeoff', 0.85);

    %% ========== ISA ATMOSPHERE ==========
    RHO0  = 0.0023769;
    T0    = 518.67;
    L     = 0.00356616;
    R     = 1716.5;
    GAMMA = 1.4;
    g     = 32.174;

    [rho, T, a_sound] = isa_atmosphere(alt_ft, RHO0, T0, L, R, GAMMA);

    %% ========== SPEED AND DYNAMIC PRESSURE ==========
    V_fps = V_kts * 1.68781;
    mach  = V_fps / a_sound;
    q     = 0.5 * rho * V_fps^2;

    %% ========== EQ. 5.19: LOAD FACTOR ==========
    omega_rad = deg2rad(turn_rate_dps);           % rad/s
    n_required = sqrt(1 + (omega_rad * V_fps / g)^2);

    %% ========== CHECK STRUCTURAL LIMIT ==========
    fprintf('\n--- STRUCTURAL CHECK ---\n');
    fprintf('  Load factor required      : %.2f g\n', n_required);
    fprintf('  Structural limit          : %.2f g\n', n_limit);
    if n_required > n_limit
        fprintf('  *** WARNING: Required n exceeds structural limit! ***\n');
        fprintf('  Either reduce turn rate, reduce speed, or\n');
        fprintf('  increase structural g-limit (heavier wing).\n');
        n_use = n_limit;
        fprintf('  Using n = %.2f for W/S calculation.\n', n_use);
    else
        fprintf('  OK: within structural limit.\n');
        n_use = n_required;
    end

    %% ========== EQ. 5.20: WING LOADING ==========
    WS_combat  = q * CLmax_combat / n_use;
    WS_takeoff = WS_combat / Wc_Wto;

    %% ========== BACK-CHECK ==========
    CL_needed = n_use * WS_combat / q;
    omega_check = rad2deg( g * sqrt(n_use^2 - 1) / V_fps );
    turn_radius = V_fps^2 / (g * sqrt(n_use^2 - 1));

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Required turn rate       : %.1f deg/s\n', turn_rate_dps);
    fprintf('Flight speed             : %.0f kts (Mach %.3f, %.1f ft/s)\n', ...
            V_kts, mach, V_fps);
    fprintf('Combat altitude          : %.0f ft\n', alt_ft);
    fprintf('Density rho              : %.8f slug/ft^3\n', rho);
    fprintf('Dynamic pressure q       : %.1f lb/ft^2\n', q);
    fprintf('--------------------------------------------------------\n');
    fprintf('Load factor n_required   : %.2f g\n', n_required);
    fprintf('Load factor n_used       : %.2f g\n', n_use);
    fprintf('CLmax at combat          : %.2f\n', CLmax_combat);
    fprintf('--------------------------------------------------------\n');
    fprintf('Combat W/S               : %.1f lb/ft^2\n', WS_combat);
    fprintf('W_combat/W_takeoff       : %.3f\n', Wc_Wto);
    fprintf('Takeoff W/S              : %.1f lb/ft^2\n', WS_takeoff);
    fprintf('--------------------------------------------------------\n');

    %% ========== EXTRA PERFORMANCE INFO ==========
    fprintf('\n--- TURN PERFORMANCE AT THIS CONDITION ---\n');
    fprintf('  Turn rate achieved       : %.2f deg/s\n', omega_check);
    fprintf('  Turn radius              : %.0f ft (%.2f nm)\n', ...
            turn_radius, turn_radius/6076);
    fprintf('  CL used                  : %.3f\n', CL_needed);
    fprintf('  Time for 360-deg turn    : %.1f s\n', 360/omega_check);

    %% ========== SENSITIVITY: W/S vs TURN RATE ==========
    fprintf('\n--- SENSITIVITY: W/S vs TURN RATE ---\n');
    fprintf('%10s %12s %14s %14s\n', 'rate (d/s)', 'n', ...
            'W/S combat', 'W/S takeoff');
    fprintf('%10s %12s %14s %14s\n', '----------', '----------', ...
            '--------------', '--------------');
    rates = [5 10 15 18 20 25 30];
    for i = 1:numel(rates)
        w_i = deg2rad(rates(i));
        n_i = sqrt(1 + (w_i * V_fps / g)^2);
        if n_i > n_limit, n_i = n_limit; end
        WS_i = q * CLmax_combat / n_i;
        fprintf('%10.0f %12.2f %14.1f %14.1f\n', ...
                rates(i), n_i, WS_i, WS_i / Wc_Wto);
    end

    %% ========== SENSITIVITY: W/S vs SPEED ==========
    fprintf('\n--- SENSITIVITY: W/S vs SPEED (rate = %.0f deg/s) ---\n', ...
            turn_rate_dps);
    fprintf('%10s %12s %14s %14s\n', 'V (kts)', 'q', ...
            'W/S combat', 'W/S takeoff');
    fprintf('%10s %12s %14s %14s\n', '----------', '----------', ...
            '--------------', '--------------');
    speeds = [200 250 300 350 400 450 500];
    for i = 1:numel(speeds)
        V_i = speeds(i) * 1.68781;
        q_i = 0.5 * rho * V_i^2;
        n_i = sqrt(1 + (omega_rad * V_i / g)^2);
        if n_i > n_limit, n_i = n_limit; end
        WS_i = q_i * CLmax_combat / n_i;
        fprintf('%10.0f %12.1f %14.1f %14.1f\n', ...
                speeds(i), q_i, WS_i, WS_i / Wc_Wto);
    end

    %% ========== CORNER SPEED ==========
    fprintf('\n--- CORNER SPEED ---\n');
    V_corner_fps = sqrt(2 * n_limit * (WS_combat) / (rho * CLmax_combat));
    V_corner_kts = V_corner_fps / 1.68781;
    fprintf('  V_corner (at W/S = %.1f) : %.0f kts\n', ...
            WS_combat, V_corner_kts);
    fprintf('  Max turn rate at corner  : %.1f deg/s\n', ...
            rad2deg(g * sqrt(n_limit^2 - 1) / V_corner_fps));

    %% ========== NOTES ==========
    fprintf('\n--- NOTES ---\n');
    fprintf('  * Instantaneous turn ignores thrust limits — the\n');
    fprintf('    aircraft slows down or descends during the turn.\n');
    fprintf('  * Corner speed = speed where CLmax and n_max coincide;\n');
    fprintf('    gives the highest instantaneous turn rate.\n');
    fprintf('  * For sustained turn, T/W must also be checked.\n');
    fprintf('  * W/S here is the MAXIMUM allowed for the required turn.\n');
    fprintf('    A smaller W/S (bigger wing) turns even better.\n');
    fprintf('  * Convert to takeoff W/S via W_combat/W_takeoff = %.2f.\n', ...
            Wc_Wto);
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

function [rho, T, a] = isa_atmosphere(alt_ft, RHO0, T0, L, R, GAMMA)
    if alt_ft <= 36089
        T = T0 - L * alt_ft;
        theta = T / T0;
        rho = RHO0 * theta^4.2561;
    else
        T = 389.97;
        theta = T / T0;
        delta_trop = theta^5.2561;
        H = R * T / 32.174;
        delta = delta_trop * exp(-(alt_ft - 36089) / H);
        rho = RHO0 * delta / theta;
    end
    a = sqrt(GAMMA * R * T);
end