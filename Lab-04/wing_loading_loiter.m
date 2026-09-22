function wing_loading_loiter()
% =====================================================================
% WING LOADING FOR LOITER ENDURANCE
% (Raymer Sec. 5.3, Eq. 5.15 and 5.16)
%
%   Jet  loiter: W/S = q * sqrt(pi * A * e * CD0)
%   Prop loiter: W/S = q * sqrt(3 * pi * A * e * CD0)
%
% The loiter W/S is then divided by W_loiter/W_takeoff (typically 0.85)
% to convert back to takeoff wing loading.
%
% Generic - works for any aircraft. Defaults set for jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   WING LOADING FOR LOITER  (Raymer Eq. 5.15 / 5.16)\n');
    fprintf('========================================================\n\n');

    %% ========== USER INPUTS ==========
    fprintf('--- AIRCRAFT TYPE ---\n');
    kind = get_str('Engine type (jet/prop)', 'jet');

    fprintf('\n--- WING GEOMETRY (from previous step) ---\n');
    AR = get_num('Aspect ratio AR', 8.68);

    fprintf('\n--- AERODYNAMIC COEFFICIENTS ---\n');
    fprintf('  CD0 typical values:\n');
    fprintf('    0.015 = jet aircraft (clean)\n');
    fprintf('    0.020 = clean propeller aircraft\n');
    fprintf('    0.030 = dirty, fixed-gear propeller\n');
    if strcmpi(kind, 'jet')
        CD0_default = 0.015;
    else
        CD0_default = 0.020;
    end
    CD0 = get_num('Zero-lift drag coefficient CD0', CD0_default);

    fprintf('  Oswald efficiency factor e:\n');
    fprintf('    0.6 = fighter\n');
    fprintf('    0.8 = other aircraft\n');
    e = get_num('Oswald efficiency factor e', 0.80);

    fprintf('\n--- LOITER CONDITION ---\n');
    fprintf('  Typical loiter velocities (Raymer):\n');
    fprintf('    150-200 kts for turboprops and jets\n');
    fprintf('     80-120 kts for piston-props\n');
    fprintf('  Typical loiter altitude: 30,000-40,000 ft (jet)\n');
    fprintf('  For piston-prop: turbocharger limit altitude\n');
    fprintf('  For non-turbocharged: sea level\n');

    alt_ft = get_num('Loiter altitude (ft)', 30000);
    if strcmpi(kind, 'jet')
        V_loiter_kts = get_num('Loiter speed (knots)', 180);
    else
        V_loiter_kts = get_num('Loiter speed (knots)', 120);
    end

    fprintf('\n--- WEIGHT RATIO ---\n');
    fprintf('  W_loiter / W_takeoff is typically about 0.85\n');
    Wl_Wto = get_num('Loiter weight ratio W_loiter/W_takeoff', 0.85);

    %% ========== ISA ATMOSPHERE ==========
    RHO0  = 0.0023769;
    T0    = 518.67;
    L     = 0.00356616;
    R     = 1716.5;
    GAMMA = 1.4;

    [rho, T, a_sound] = isa_atmosphere(alt_ft, RHO0, T0, L, R, GAMMA);

    %% ========== SPEED AND DYNAMIC PRESSURE ==========
    V_fps = V_loiter_kts * 1.68781;
    mach  = V_fps / a_sound;
    q     = 0.5 * rho * V_fps^2;

    %% ========== COMPUTE W/S ==========
    if strcmpi(kind, 'jet')
        WS_loiter = q * sqrt(pi * AR * e * CD0);
        mode_str = 'Jet loiter (max L/D)';
        formula_str = 'W/S = q * sqrt(pi * A * e * CD0)';
        comment = 'Jet: max endurance at best L/D (parasite = induced)';
    else
        WS_loiter = q * sqrt(3 * pi * AR * e * CD0);
        mode_str = 'Prop loiter (min power required)';
        formula_str = 'W/S = q * sqrt(3 * pi * A * e * CD0)';
        comment = 'Prop: min power when induced = 3x parasite drag';
    end

    % Convert to takeoff wing loading
    WS_takeoff = WS_loiter / Wl_Wto;

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Aircraft type            : %s\n', mode_str);
    fprintf('Formula                  : %s\n', formula_str);
    fprintf('Physics                  : %s\n', comment);
    fprintf('--------------------------------------------------------\n');
    fprintf('Aspect ratio AR          : %.2f\n', AR);
    fprintf('CD0                      : %.4f\n', CD0);
    fprintf('Oswald efficiency e      : %.2f\n', e);
    fprintf('Loiter altitude          : %.0f ft\n', alt_ft);
    fprintf('Loiter speed             : %.1f kts (Mach %.3f, %.1f ft/s)\n', ...
            V_loiter_kts, mach, V_fps);
    fprintf('Density rho              : %.8f slug/ft^3\n', rho);
    fprintf('Dynamic pressure q       : %.1f lb/ft^2\n', q);
    fprintf('--------------------------------------------------------\n');
    fprintf('Loiter W/S (average)     : %.1f lb/ft^2\n', WS_loiter);
    fprintf('W_loiter/W_takeoff       : %.3f\n', Wl_Wto);
    fprintf('Takeoff W/S              : %.1f lb/ft^2\n', WS_takeoff);
    fprintf('--------------------------------------------------------\n');

    %% ========== SENSITIVITY: W/S vs LOITER SPEED ==========
    fprintf('\n--- SENSITIVITY: W/S vs LOITER SPEED ---\n');
    fprintf('%10s %14s %14s %14s\n', 'V (kts)', 'q (lb/ft^2)', ...
            'W/S loiter', 'W/S takeoff');
    fprintf('%10s %14s %14s %14s\n', '--------', '--------------', ...
            '--------------', '--------------');
    speeds = [100, 120, 150, 180, 200, 220];
    for i = 1:numel(speeds)
        V_i = speeds(i) * 1.68781;
        q_i = 0.5 * rho * V_i^2;
        if strcmpi(kind, 'jet')
            WS_i = q_i * sqrt(pi * AR * e * CD0);
        else
            WS_i = q_i * sqrt(3 * pi * AR * e * CD0);
        end
        fprintf('%10.0f %14.1f %14.1f %14.1f\n', ...
                speeds(i), q_i, WS_i, WS_i / Wl_Wto);
    end

    %% ========== SENSITIVITY: W/S vs LOITER ALTITUDE ==========
    fprintf('\n--- SENSITIVITY: W/S vs LOITER ALTITUDE ---\n');
    fprintf('  (fixed loiter speed = %.0f kts)\n', V_loiter_kts);
    fprintf('%10s %14s %14s %14s\n', 'Alt (ft)', 'rho', ...
            'W/S loiter', 'W/S takeoff');
    fprintf('%10s %14s %14s %14s\n', '--------', '--------------', ...
            '--------------', '--------------');
    alts = [10000, 20000, 30000, 35000, 40000];
    for i = 1:numel(alts)
        [rho_i, ~, ~] = isa_atmosphere(alts(i), RHO0, T0, L, R, GAMMA);
        q_i = 0.5 * rho_i * V_fps^2;
        if strcmpi(kind, 'jet')
            WS_i = q_i * sqrt(pi * AR * e * CD0);
        else
            WS_i = q_i * sqrt(3 * pi * AR * e * CD0);
        end
        fprintf('%10.0f %14.8f %14.1f %14.1f\n', ...
                alts(i), rho_i, WS_i, WS_i / Wl_Wto);
    end

    %% ========== NOTES ==========
    fprintf('\n--- NOTES ---\n');
    fprintf('  * Loiter = endurance, not range. Optimize for time on\n');
    fprintf('    station, not distance covered.\n');
    fprintf('  * Most aircraft are NOT optimized for loiter — they use\n');
    fprintf('    the cruise W/S and treat loiter as a fallout.\n');
    fprintf('  * Use loiter W/S only if the mission has substantial\n');
    fprintf('    loiter requirement (ASW, AWACS, ISR platforms).\n');
    fprintf('  * For typical 20-min loiter before landing, use cruise\n');
    fprintf('    W/S instead.\n');
    fprintf('  * The W/S here is the AVERAGE loiter W/S. Convert to\n');
    fprintf('    takeoff W/S by dividing by W_loiter/W_takeoff.\n');
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