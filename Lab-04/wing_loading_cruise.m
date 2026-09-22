function wing_loading_cruise()
% =====================================================================
% WING LOADING FOR CRUISE RANGE OPTIMIZATION
% (Raymer Sec. 5.3, Eq. 5.13 and 5.14)
%
%   Prop:  W/S = q * sqrt(pi * A * e * CD0)
%   Jet:   W/S = q * sqrt(pi * A * e * CD0 / 3)
%
% where q = 0.5 * rho * V^2 at cruise conditions.
%
% Generic - works for any aircraft. Defaults set for jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   WING LOADING FOR CRUISE  (Raymer Eq. 5.13 / 5.14)\n');
    fprintf('========================================================\n\n');

    %% ========== USER INPUTS ==========
    fprintf('--- AIRCRAFT TYPE ---\n');
    kind = get_str('Engine type (jet/prop)', 'jet');

    fprintf('\n--- WING GEOMETRY (from previous step) ---\n');
    AR = get_num('Aspect ratio AR', 8.68);

    fprintf('\n--- AERODYNAMIC COEFFICIENTS ---\n');
    fprintf('  CD0 typical values (Raymer):\n');
    fprintf('    0.015 = jet aircraft (clean)\n');
    fprintf('    0.020 = clean propeller aircraft\n');
    fprintf('    0.030 = dirty, fixed-gear propeller\n');
    if strcmpi(kind, 'jet')
        CD0_default = 0.015;
    else
        CD0_default = 0.020;
    end
    CD0 = get_num('Zero-lift drag coefficient CD0', CD0_default);

    fprintf('  Oswald efficiency factor e (Raymer):\n');
    fprintf('    0.6 = fighter\n');
    fprintf('    0.8 = other aircraft\n');
    if strcmpi(kind, 'jet')
        e_default = 0.80;
    else
        e_default = 0.80;
    end
    e = get_num('Oswald efficiency factor e', e_default);

    fprintf('\n--- CRUISE CONDITION ---\n');
    alt_ft = get_num('Cruise altitude (ft)', 35000);
    if strcmpi(kind, 'jet')
        mach = get_num('Cruise Mach', 0.84);
    else
        V_kts = get_num('Cruise speed (knots)', 250);
    end

    %% ========== ISA ATMOSPHERE ==========
    RHO0  = 0.0023769;
    T0    = 518.67;
    L     = 0.00356616;
    R     = 1716.5;
    GAMMA = 1.4;

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

    a_sound = sqrt(GAMMA * R * T);

    %% ========== COMPUTE DYNAMIC PRESSURE ==========
    if strcmpi(kind, 'jet')
        V_fps = mach * a_sound;
        V_kts_out = V_fps / 1.68781;
        speed_str = sprintf('Mach %.3f (%.1f kts, %.1f ft/s)', ...
                            mach, V_kts_out, V_fps);
    else
        V_fps = V_kts * 1.68781;
        mach = V_fps / a_sound;
        speed_str = sprintf('%.1f kts (Mach %.3f, %.1f ft/s)', ...
                            V_kts, mach, V_fps);
    end

    q = 0.5 * rho * V_fps^2;

    %% ========== COMPUTE W/S ==========
    if strcmpi(kind, 'jet')
        WS_cruise = q * sqrt(pi * AR * e * CD0 / 3);
        mode_str = 'Jet (max range, cruise-climb)';
        formula_str = 'W/S = q * sqrt(pi * A * e * CD0 / 3)';
    else
        WS_cruise = q * sqrt(pi * AR * e * CD0);
        mode_str = 'Prop (max range)';
        formula_str = 'W/S = q * sqrt(pi * A * e * CD0)';
    end

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Aircraft type            : %s\n', mode_str);
    fprintf('Formula                  : %s\n', formula_str);
    fprintf('--------------------------------------------------------\n');
    fprintf('Aspect ratio AR          : %.2f\n', AR);
    fprintf('CD0                      : %.4f\n', CD0);
    fprintf('Oswald efficiency e      : %.2f\n', e);
    fprintf('Cruise altitude          : %.0f ft\n', alt_ft);
    fprintf('Cruise speed             : %s\n', speed_str);
    fprintf('Density rho              : %.8f slug/ft^3\n', rho);
    fprintf('Dynamic pressure q       : %.1f lb/ft^2\n', q);
    fprintf('--------------------------------------------------------\n');
    fprintf('Cruise W/S               : %.1f lb/ft^2\n', WS_cruise);
    fprintf('--------------------------------------------------------\n');

    %% ========== INTERPRETATION ==========
    fprintf('\n--- INTERPRETATION ---\n');
    if strcmpi(kind, 'jet')
        fprintf('  For a jet, max range occurs when parasite drag = 3x\n');
        fprintf('  induced drag. Flying at this W/S maximizes cruise\n');
        fprintf('  efficiency at the chosen altitude and Mach.\n');
    else
        fprintf('  For a propeller aircraft, max range occurs at best L/D,\n');
        fprintf('  where parasite drag = induced drag.\n');
    end
    fprintf('  As fuel burns and weight drops, the aircraft should\n');
    fprintf('  cruise-climb to lower density to maintain this W/S.\n');

    %% ========== SENSITIVITY TABLE ==========
    fprintf('\n--- SENSITIVITY: W/S vs CRUISE ALTITUDE ---\n');
    alts = [25000, 30000, 35000, 40000, 45000];
    fprintf('%10s %14s %14s\n', 'Alt (ft)', 'rho', 'W/S (lb/ft^2)');
    fprintf('%10s %14s %14s\n', '--------', '--------------', '--------------');
    for i = 1:numel(alts)
        rho_i = isa_rho(alts(i), RHO0, T0, L, R);
        V_i   = mach * sqrt(GAMMA * R * isa_T(alts(i), T0, L));
        q_i   = 0.5 * rho_i * V_i^2;
        if strcmpi(kind, 'jet')
            WS_i = q_i * sqrt(pi * AR * e * CD0 / 3);
        else
            WS_i = q_i * sqrt(pi * AR * e * CD0);
        end
        fprintf('%10.0f %14.8f %14.1f\n', alts(i), rho_i, WS_i);
    end

    %% ========== COMPARISON TO OTHER CONSTRAINTS ==========
    fprintf('\n--- NOTE ---\n');
    fprintf('  This W/S is the OPTIMUM for cruise range. Actual\n');
    fprintf('  design W/S must also satisfy stall, takeoff, landing,\n');
    fprintf('  and climb constraints. Select the MINIMUM of all.\n');
    fprintf('  In practice, cruise-optimal W/S is usually HIGHER\n');
    fprintf('  than the stall/landing constraints.\n');
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

function rho = isa_rho(alt, RHO0, T0, L, R)
    if alt <= 36089
        theta = isa_T(alt, T0, L) / T0;
        rho = RHO0 * theta^4.2561;
    else
        theta = 389.97 / T0;
        delta_trop = theta^5.2561;
        H = R * 389.97 / 32.174;
        delta = delta_trop * exp(-(alt - 36089) / H);
        rho = RHO0 * delta / theta;
    end
end