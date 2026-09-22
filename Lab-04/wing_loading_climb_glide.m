function wing_loading_climb_glide()
% =====================================================================
% WING LOADING FOR CLIMB AND GLIDE
% (Raymer Sec. 5.3, Eq. 5.27 - 5.33)
%
%   G = (T - D)/W                                Eq. 5.27
%   T/W = D/W + G                                Eq. 5.28
%   D/W = q*CD0/(W/S) + (W/S)/(q*pi*A*e)         Eq. 5.29
%   W/S = [(T/W)-G ± sqrt(((T/W)-G)^2 - 4*CD0/(pi*A*e))]
%         / (2/(q*pi*A*e))                       Eq. 5.30
%   T/W >= G + 2*sqrt(CD0/(pi*A*e))              Eq. 5.31
%
% Glide: set T/W = 0, use negative G.
%
% Generic - works for any aircraft. Defaults set for jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   WING LOADING FOR CLIMB / GLIDE (Raymer 5.27-5.33)\n');
    fprintf('========================================================\n\n');

    %% ========== AIRCRAFT CLASS ==========
    kind = get_str('Engine type (jet/prop)', 'jet');

    %% ========== WING GEOMETRY ==========
    fprintf('\n--- WING GEOMETRY ---\n');
    AR = get_num('Aspect ratio AR', 8.68);

    %% ========== FLIGHT CONDITION ==========
    fprintf('\n--- FLIGHT CONDITION ---\n');
    fprintf('  Climb requirements (FAR 25 examples):\n');
    fprintf('    2.4%% gradient = FAR 25.121(b) 2nd segment, 2-eng OEI\n');
    fprintf('    2.1%% gradient = FAR 25.121(d) approach, 2-eng OEI\n');
    fprintf('    3.2%% gradient = FAR 25.119 landing climb, AEO\n');
    fprintf('    1.2%% gradient = FAR 25.121(d) final, 2-eng OEI\n');
    fprintf('    5.0%% gradient = typical military\n');
    alt_ft = get_num('Climb altitude (ft)', 15000);
    V_kts  = get_num('Climb speed (knots)', 250);

    %% ========== AERODYNAMIC COEFFICIENTS ==========
    fprintf('\n--- AERODYNAMIC COEFFICIENTS ---\n');
    fprintf('  CD0 base (clean)          : ~0.015-0.020\n');
    fprintf('  Takeoff flaps  : +0.02 on CD0, -5%% on e\n');
    fprintf('  Landing flaps  : +0.07 on CD0, -10%% on e\n');
    fprintf('  Gear down      : +0.02 on CD0\n');
    CD0 = get_num('CD0 for this climb condition', 0.020);
    fprintf('  Oswald efficiency e (clean ~0.80, takeoff ~0.75, landing ~0.70)\n');
    e = get_num('Oswald efficiency e', 0.75);

    %% ========== THRUST-TO-WEIGHT ==========
    fprintf('\n--- THRUST-TO-WEIGHT ---\n');
    fprintf('  Enter T/W at THIS flight condition (climb thrust / climb weight)\n');
    fprintf('  Typical: 0.20-0.30 for transport, 0.50-0.80 for fighter\n');
    TW_climb = get_num('Climb T/W', 0.25);

    %% ========== CLIMB GRADIENT ==========
    fprintf('\n--- CLIMB GRADIENT ---\n');
    fprintf('  Enter G = (climb rate)/(forward velocity)\n');
    fprintf('  Common values:\n');
    fprintf('    0.024 = FAR 25 2nd segment (2-eng OEI)\n');
    fprintf('    0.032 = FAR 25 landing climb (AEO)\n');
    fprintf('    0.050 = military climb\n');
    G = get_num('Climb gradient G', 0.024);

    %% ========== ISA ATMOSPHERE ==========
    RHO0  = 0.0023769;
    T0    = 518.67;
    L     = 0.00356616;
    R     = 1716.5;
    GAMMA = 1.4;

    [rho, T, a_sound] = isa_atmosphere(alt_ft, RHO0, T0, L, R, GAMMA);
    V_fps = V_kts * 1.68781;
    mach  = V_fps / a_sound;
    q     = 0.5 * rho * V_fps^2;
    RC_fpm = G * V_fps * 60;   % climb rate implied by gradient

    %% ========== EQ. 5.31: FEASIBILITY CHECK ==========
    K = TW_climb - G;
    TW_min = G + 2 * sqrt(CD0 / (pi * AR * e));
    fprintf('\n--- EQ. 5.31: FEASIBILITY CHECK ---\n');
    fprintf('  K = (T/W) - G           = %.4f\n', K);
    fprintf('  Minimum T/W for G=%.3f : %.4f\n', G, TW_min);
    fprintf('  Available T/W           = %.4f\n', TW_climb);
    if TW_climb < TW_min
        fprintf('  *** WARNING: T/W insufficient for this climb! ***\n');
        feasible = false;
    else
        fprintf('  OK: climb is FEASIBLE.\n');
        feasible = true;
    end

    %% ========== EQ. 5.30: W/S FOR CLIMB ==========
    fprintf('\n--- EQ. 5.30: WING LOADING FOR CLIMB ---\n');
    disc = K^2 - 4 * CD0 / (pi * AR * e);
    if disc < 0
        fprintf('  *** No real solution: discriminant < 0 ***\n');
        WS_lo = NaN; WS_hi = NaN;
    else
        denom = 2 / (q * pi * AR * e);
        WS_lo = (K - sqrt(disc)) / denom;
        WS_hi = (K + sqrt(disc)) / denom;
    end

    %% ========== GLIDE (T/W = 0, negative G) ==========
    fprintf('\n--- GLIDE ANALYSIS (T/W = 0) ---\n');
    glide_angle_deg = get_num('Glide angle (deg, positive = descending)', 5);
    G_glide = -sind(glide_angle_deg);   % negative G means descending

    K_glide = 0 - G_glide;   % T/W - G = 0 - (-sin) = sin
    disc_g = K_glide^2 - 4 * CD0 / (pi * AR * e);
    if disc_g < 0
        WS_glide_lo = NaN; WS_glide_hi = NaN;
    else
        denom_g = 2 / (q * pi * AR * e);
        WS_glide_lo = (K_glide - sqrt(disc_g)) / denom_g;
        WS_glide_hi = (K_glide + sqrt(disc_g)) / denom_g;
    end
    % Sink rate at this glide angle
    V_sink_fps = V_fps * sind(glide_angle_deg);
    V_sink_fpm = V_sink_fps * 60;

    %% ========== MAX CEILING ==========
    fprintf('\n--- MAX CEILING ---\n');
    fprintf('  Set G = 0 for level flight at ceiling, or small G\n');
    fprintf('  for residual climb rate (e.g., 100 ft/min).\n');
    RC_ceiling_fpm = get_num('Residual climb rate at ceiling (ft/min)', 100);
    G_ceiling = (RC_ceiling_fpm / 60) / V_fps;

    fprintf('  Enter T/W at ceiling altitude (typically 0.02-0.10)\n');
    TW_ceiling = get_num('T/W at ceiling', 0.05);

    K_c = TW_ceiling - G_ceiling;
    disc_c = K_c^2 - 4 * CD0 / (pi * AR * e);
    if disc_c < 0
        WS_ceiling_lo = NaN; WS_ceiling_hi = NaN;
    else
        denom_c = 2 / (q * pi * AR * e);
        WS_ceiling_lo = (K_c - sqrt(disc_c)) / denom_c;
        WS_ceiling_hi = (K_c + sqrt(disc_c)) / denom_c;
    end

    %% ========== HIGH-ALTITUDE CRUISE (Eq 5.32, 5.33) ==========
    fprintf('\n--- HIGH-ALTITUDE CRUISE (Eq. 5.32 / 5.33) ---\n');
    WS_minpower = q * sqrt(pi * AR * e * CD0);
    fprintf('  Eq. 5.32 W/S for min power    : %.1f lb/ft^2\n', WS_minpower);
    CL_design = get_num('Design CL for high-alt cruise', 0.5);
    WS_CL = q * CL_design;
    fprintf('  Eq. 5.33 W/S for CL = %.2f     : %.1f lb/ft^2\n', CL_design, WS_CL);

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Climb altitude           : %.0f ft\n', alt_ft);
    fprintf('Climb speed              : %.0f kts (Mach %.3f, %.1f ft/s)\n', ...
            V_kts, mach, V_fps);
    fprintf('Density rho              : %.8f slug/ft^3\n', rho);
    fprintf('Dynamic pressure q       : %.1f lb/ft^2\n', q);
    fprintf('Gradient G               : %.4f (%.2f%%)\n', G, G*100);
    fprintf('Implied climb rate       : %.0f ft/min\n', RC_fpm);
    fprintf('CD0                      : %.4f\n', CD0);
    fprintf('Oswald e                 : %.2f\n', e);
    fprintf('Climb T/W                : %.4f\n', TW_climb);
    fprintf('--------------------------------------------------------\n');
    fprintf('Feasibility (Eq. 5.31)   : %s\n', ternary(feasible,'PASS','FAIL'));
    fprintf('--------------------------------------------------------\n');
    if ~isnan(WS_hi)
        fprintf('CLIMB W/S (Eq. 5.30):\n');
        fprintf('  Low root  (huge wing)  : %.1f lb/ft^2\n', WS_lo);
        fprintf('  High root (practical)  : %.1f lb/ft^2\n', WS_hi);
    end
    fprintf('--------------------------------------------------------\n');
    if ~isnan(WS_glide_hi)
        fprintf('GLIDE W/S at %.1f deg (T/W = 0):\n', glide_angle_deg);
        fprintf('  Low root               : %.1f lb/ft^2\n', WS_glide_lo);
        fprintf('  High root              : %.1f lb/ft^2\n', WS_glide_hi);
        fprintf('  Sink rate at this angle: %.0f ft/min\n', V_sink_fpm);
    end
    fprintf('--------------------------------------------------------\n');
    if ~isnan(WS_ceiling_hi)
        fprintf('CEILING W/S (G = %.4f, T/W = %.2f):\n', G_ceiling, TW_ceiling);
        fprintf('  Low root               : %.1f lb/ft^2\n', WS_ceiling_lo);
        fprintf('  High root              : %.1f lb/ft^2\n', WS_ceiling_hi);
    end
    fprintf('--------------------------------------------------------\n');
    fprintf('HIGH-ALTITUDE CRUISE:\n');
    fprintf('  Min power W/S (Eq 5.32): %.1f lb/ft^2\n', WS_minpower);
    fprintf('  W/S for CL=%.2f (Eq 5.33): %.1f lb/ft^2\n', CL_design, WS_CL);

    %% ========== SENSITIVITY: W/S vs CLIMB GRADIENT ==========
    fprintf('\n--- SENSITIVITY: W/S (high root) vs CLIMB GRADIENT ---\n');
    fprintf('%10s %14s %14s %14s\n', 'G', 'G (%)', ...
            'W/S hi', 'RC (fpm)');
    fprintf('%10s %14s %14s %14s\n', '--------', ...
            '--------------', '--------------', '--------------');
    Gs = [0.010, 0.020, 0.024, 0.030, 0.050, 0.070, 0.100];
    for i = 1:numel(Gs)
        G_i = Gs(i);
        K_i = TW_climb - G_i;
        d_i = K_i^2 - 4*CD0/(pi*AR*e);
        if d_i >= 0
            WS_i = (K_i + sqrt(d_i)) / (2/(q*pi*AR*e));
            rc_i = G_i * V_fps * 60;
            fprintf('%10.3f %14.1f %14.1f %14.0f\n', ...
                    G_i, G_i*100, WS_i, rc_i);
        else
            fprintf('%10.3f %14.1f %14s %14.0f\n', ...
                    G_i, G_i*100, 'infeasible', G_i*V_fps*60);
        end
    end

    %% ========== SENSITIVITY: W/S vs CLIMB T/W ==========
    fprintf('\n--- SENSITIVITY: W/S (high root) vs CLIMB T/W (G = %.3f) ---\n', G);
    fprintf('%10s %14s %14s %14s\n', 'T/W', ...
            'K = T/W - G', 'W/S hi', 'Feasible?');
    fprintf('%10s %14s %14s %14s\n', '--------', ...
            '--------------', '--------------', '--------------');
    TWs = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50];
    for i = 1:numel(TWs)
        TW_i = TWs(i);
        K_i = TW_i - G;
        d_i = K_i^2 - 4*CD0/(pi*AR*e);
        if d_i >= 0
            WS_i = (K_i + sqrt(d_i)) / (2/(q*pi*AR*e));
            fprintf('%10.2f %14.4f %14.1f %14s\n', TW_i, K_i, WS_i, 'YES');
        else
            fprintf('%10.2f %14.4f %14s %14s\n', TW_i, K_i, '-', 'NO');
        end
    end

    %% ========== NOTES ==========
    fprintf('\n--- NOTES ---\n');
    fprintf('  * Eq. 5.30 is Eq. 5.25 with n=1 and T/W -> (T/W - G).\n');
    fprintf('  * For one-engine-out, reduce T/W by (n-1)/n.\n');
    fprintf('  * Use HIGH root of Eq. 5.30 — smaller wing, practical.\n');
    fprintf('  * Convert to takeoff W/S via W_land/W_takeoff or W_climb/W_takeoff.\n');
    fprintf('  * Glide: T/W = 0, G negative. High root may be unrealistically\n');
    fprintf('    large — glide is usually not a sizing constraint.\n');
    fprintf('  * Ceiling: set G ~ 0 (or small residual), T/W at altitude.\n');
    fprintf('  * Eq. 5.31 says T/W must exceed G — no matter how clean.\n');
    fprintf('  * Flap/gear effects on CD0 (Raymer):\n');
    fprintf('      Takeoff flaps: +0.02 on CD0, -5%% on e\n');
    fprintf('      Landing flaps: +0.07 on CD0, -10%% on e\n');
    fprintf('      Gear down    : +0.02 on CD0\n');
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

function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
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