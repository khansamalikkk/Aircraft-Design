function wing_loading_sustained_turn()
% =====================================================================
% WING LOADING FOR SUSTAINED TURN
% (Raymer Sec. 5.3, Eq. 5.21 - 5.26)
%
%   n_max = (T/W) * (L/D)                        Eq. 5.21
%   W/S = (q/n) * sqrt(pi*A*e*CD0)               Eq. 5.22 (best L/D)
%   W/S = [(T/W) +/- sqrt((T/W)^2 - 4n^2*CD0/(pi*A*e))]
%         / (2n^2/(q*pi*A*e))                     Eq. 5.25 (exact)
%   T/W >= 2n*sqrt(CD0/(pi*A*e))                 Eq. 5.26 (feasibility)
%
% Generic - works for any aircraft. Defaults set for a jet fighter.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   WING LOADING FOR SUSTAINED TURN (Raymer 5.21-5.26)\n');
    fprintf('========================================================\n\n');

    %% ========== USER INPUTS ==========
    fprintf('--- FLIGHT CONDITION ---\n');
    fprintf('  Typical sustained turn spec: 4-5 g at Mach 0.9, 30,000 ft\n');
    Mach    = get_num('Flight Mach', 0.90);
    alt_ft  = get_num('Flight altitude (ft)', 30000);

    fprintf('\n--- WING GEOMETRY ---\n');
    AR = get_num('Aspect ratio AR', 3.5);

    fprintf('\n--- AERODYNAMIC COEFFICIENTS ---\n');
    fprintf('  CD0 typical:  0.015-0.020 for fighters\n');
    CD0 = get_num('Zero-lift drag CD0', 0.018);

    fprintf('  Oswald efficiency e:\n');
    fprintf('    0.65-0.70 for fighters at combat CL\n');
    fprintf('    0.80 for transport/cruise\n');
    fprintf('    Note: Raymer warns e drops 30%%+ at high CL\n');
    e = get_num('Oswald efficiency e', 0.65);

    fprintf('\n--- COMBAT THRUST ---\n');
    fprintf('  T/W at combat conditions (T_sustained/W_combat)\n');
    TW_combat = get_num('Combat T/W', 0.70);

    fprintf('\n--- REQUIRED TURN ---\n');
    fprintf('  Enter either sustained load factor n OR turn rate\n');
    mode = get_str('Input mode (n / rate)', 'n');
    if strcmpi(mode, 'rate')
        rate_dps = get_num('Required sustained turn rate (deg/s)', 12);
        g = 32.174;
        a_sound = sqrt(1.4 * 1716.5 * isa_T(alt_ft, 518.67, 0.00356616));
        V_fps = Mach * a_sound;
        n_req = sqrt(1 + (deg2rad(rate_dps) * V_fps / g)^2);
        fprintf('  Converted: n_req = %.3f g\n', n_req);
    else
        n_req = get_num('Required sustained load factor n', 4.5);
    end

    fprintf('\n--- WEIGHT RATIO ---\n');
    Wc_Wto = get_num('Combat weight ratio W_combat/W_takeoff', 0.85);

    %% ========== ISA ATMOSPHERE ==========
    RHO0  = 0.0023769;
    T0    = 518.67;
    L     = 0.00356616;
    R     = 1716.5;
    GAMMA = 1.4;
    g     = 32.174;

    [rho, T, a_sound] = isa_atmosphere(alt_ft, RHO0, T0, L, R, GAMMA);

    %% ========== FLIGHT CONDITIONS ==========
    V_fps = Mach * a_sound;
    q     = 0.5 * rho * V_fps^2;

    %% ========== EQ. 5.26: MINIMUM T/W CHECK ==========
    TW_min = 2 * n_req * sqrt(CD0 / (pi * AR * e));
    fprintf('\n--- EQUATION 5.26: FEASIBILITY CHECK ---\n');
    fprintf('  Minimum T/W for n = %.2f : %.4f\n', n_req, TW_min);
    fprintf('  Available T/W            : %.4f\n', TW_combat);
    feasible = TW_combat >= TW_min;
    if feasible
        fprintf('  OK: turn is FEASIBLE at this T/W\n');
    else
        fprintf('  *** WARNING: T/W insufficient for this turn! ***\n');
        fprintf('  Increase T/W or reduce required n.\n');
    end

    %% ========== EQ. 5.22: W/S FOR BEST L/D AT LOAD FACTOR n ==========
    WS_bestLD = (q / n_req) * sqrt(pi * AR * e * CD0);

    %% ========== EQ. 5.25: W/S FOR EXACT ATTAINMENT OF n ==========
    TW_eff = TW_combat;
    discriminant = TW_eff^2 - 4 * n_req^2 * CD0 / (pi * AR * e);
    if discriminant < 0
        fprintf('\n--- EQUATION 5.25 ---\n');
        fprintf('  *** No real solution: discriminant < 0 ***\n');
        fprintf('  Required n cannot be sustained at this T/W.\n');
        WS_exact_lo = NaN;
        WS_exact_hi = NaN;
    else
        sqrt_disc = sqrt(discriminant);
        WS_exact_lo = (TW_eff - sqrt_disc) / (2 * n_req^2 / (q * pi * AR * e));
        WS_exact_hi = (TW_eff + sqrt_disc) / (2 * n_req^2 / (q * pi * AR * e));
    end

    %% ========== EQ. 5.21: MAX n FROM T/W AND L/D ==========
    % L/D at best-L/D condition
    LD_max = 0.5 * sqrt(pi * AR * e / CD0);
    n_max_from_TW = TW_combat * LD_max;

    %% ========== CONVERT TO TAKEOFF W/S ==========
    WS_bestLD_takeoff = WS_bestLD / Wc_Wto;
    if ~isnan(WS_exact_hi)
        WS_exact_hi_takeoff = WS_exact_hi / Wc_Wto;
        WS_exact_lo_takeoff = WS_exact_lo / Wc_Wto;
    end

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Flight Mach              : %.3f\n', Mach);
    fprintf('Flight altitude          : %.0f ft\n', alt_ft);
    fprintf('True airspeed V          : %.1f ft/s (%.1f kts)\n', ...
            V_fps, V_fps/1.68781);
    fprintf('Density rho              : %.8f slug/ft^3\n', rho);
    fprintf('Dynamic pressure q       : %.1f lb/ft^2\n', q);
    fprintf('--------------------------------------------------------\n');
    fprintf('Aspect ratio AR          : %.2f\n', AR);
    fprintf('CD0                      : %.4f\n', CD0);
    fprintf('Oswald efficiency e      : %.2f\n', e);
    fprintf('(L/D)max                 : %.2f\n', LD_max);
    fprintf('Combat T/W               : %.4f\n', TW_combat);
    fprintf('Required load factor n   : %.2f g\n', n_req);
    fprintf('--------------------------------------------------------\n');
    fprintf('EQUATION 5.22 (best L/D at n = %.1f):\n', n_req);
    fprintf('  Combat W/S             : %.1f lb/ft^2\n', WS_bestLD);
    fprintf('  Takeoff W/S            : %.1f lb/ft^2\n', WS_bestLD_takeoff);
    fprintf('--------------------------------------------------------\n');
    if ~isnan(WS_exact_hi)
        fprintf('EQUATION 5.25 (exact n = %.1f with T/W = %.2f):\n', ...
                n_req, TW_combat);
        fprintf('  Combat W/S (low)       : %.1f lb/ft^2\n', WS_exact_lo);
        fprintf('  Combat W/S (high)      : %.1f lb/ft^2\n', WS_exact_hi);
        fprintf('  Takeoff W/S (low)      : %.1f lb/ft^2\n', WS_exact_lo_takeoff);
        fprintf('  Takeoff W/S (high)     : %.1f lb/ft^2\n', WS_exact_hi_takeoff);
        fprintf('  (Both values give same n; the HIGH is the practical one)\n');
    end
    fprintf('--------------------------------------------------------\n');
    fprintf('EQUATION 5.21 (max n from T/W * L/D):\n');
    fprintf('  Max sustained n        : %.2f g\n', n_max_from_TW);
    fprintf('--------------------------------------------------------\n');

    %% ========== SENSITIVITY: W/S vs REQUIRED n ==========
    fprintf('\n--- SENSITIVITY: W/S vs REQUIRED LOAD FACTOR n ---\n');
    fprintf('%8s %14s %14s %14s\n', 'n', ...
            'W/S (5.22)', 'W/S (5.25 hi)', 'T/W min');
    fprintf('%8s %14s %14s %14s\n', '--------', ...
            '--------------', '--------------', '--------------');
    ns = [2 3 4 4.5 5 6 7 8 9];
    for i = 1:numel(ns)
        n_i = ns(i);
        WS_22 = (q / n_i) * sqrt(pi * AR * e * CD0);
        disc = TW_combat^2 - 4 * n_i^2 * CD0 / (pi * AR * e);
        if disc >= 0
            WS_25 = (TW_combat + sqrt(disc)) / ...
                    (2 * n_i^2 / (q * pi * AR * e));
        else
            WS_25 = NaN;
        end
        TW_min_i = 2 * n_i * sqrt(CD0 / (pi * AR * e));
        if isnan(WS_25)
            fprintf('%8.1f %14.1f %14s %14.4f\n', ...
                    n_i, WS_22, 'infeasible', TW_min_i);
        else
            fprintf('%8.1f %14.1f %14.1f %14.4f\n', ...
                    n_i, WS_22, WS_25, TW_min_i);
        end
    end

    %% ========== SENSITIVITY: W/S vs T/W ==========
    fprintf('\n--- SENSITIVITY: W/S vs COMBAT T/W (at n = %.1f) ---\n', n_req);
    fprintf('%8s %14s %14s %14s\n', 'T/W', ...
            'W/S (5.25 lo)', 'W/S (5.25 hi)', 'Feasible?');
    fprintf('%8s %14s %14s %14s\n', '--------', ...
            '--------------', '--------------', '--------------');
    TWs = [0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1];
    for i = 1:numel(TWs)
        TW_i = TWs(i);
        disc = TW_i^2 - 4 * n_req^2 * CD0 / (pi * AR * e);
        if disc >= 0
            lo_i = (TW_i - sqrt(disc)) / (2 * n_req^2 / (q * pi * AR * e));
            hi_i = (TW_i + sqrt(disc)) / (2 * n_req^2 / (q * pi * AR * e));
            fprintf('%8.2f %14.1f %14.1f %14s\n', TW_i, lo_i, hi_i, 'YES');
        else
            fprintf('%8.2f %14s %14s %14s\n', TW_i, '-', '-', 'NO');
        end
    end

    %% ========== COMPARISON TO INSTANTANEOUS TURN ==========
    fprintf('\n--- COMPARISON: SUSTAINED vs INSTANTANEOUS ---\n');
    fprintf('  Sustained n at this T/W     : %.2f g\n', n_max_from_TW);
    fprintf('  (Instantaneous n is limited by CLmax, typically 5-9 g)\n');
    fprintf('  Ratio sustained/instantaneous ~ %.2f\n', ...
            n_max_from_TW / max(n_req, 9));

    %% ========== NOTES ==========
    fprintf('\n--- NOTES ---\n');
    fprintf('  * Eq. 5.22 gives W/S for BEST L/D during turn — often\n');
    fprintf('    produces very low W/S (big wing). Practical value\n');
    fprintf('    is usually higher.\n');
    fprintf('  * Eq. 5.25 gives W/S that EXACTLY uses available thrust\n');
    fprintf('    to sustain n. This is the practical design value.\n');
    fprintf('  * Use HIGH root of Eq. 5.25 (bigger W/S = smaller wing).\n');
    fprintf('  * Raymer warns e drops 30%%+ at high CL — if W/S is\n');
    fprintf('    unrealistically low, e is probably too optimistic.\n');
    fprintf('  * T/W here is at COMBAT conditions. Convert to takeoff:\n');
    fprintf('    (T/W)_to = (T/W)_combat * (T_to/T_combat) * (W_combat/W_to)\n');
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

function T = isa_T(alt, T0, L)
    if alt <= 36089, T = T0 - L*alt; else, T = 389.97; end
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