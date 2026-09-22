function wing_loading_stall()
% =====================================================================
% WING LOADING FROM STALL SPEED  (Raymer, Section 5.3, Eq. 5.6)
%
%   W/S = 0.5 * rho * Vstall^2 * CLmax
%
% Generic - works for any aircraft. Defaults are for a jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   WING LOADING FROM STALL SPEED  (Raymer Eq. 5.6)\n');
    fprintf('========================================================\n\n');

    %% ========== AIRCRAFT CLASS AND CLmax PRESETS ==========
    % CLmax typical values from Raymer Section 5.3
    % (landing configuration, high-lift devices deployed)
    presets = struct( ...
        'sailplane',          struct('CLmax',1.5, 'WS_hist',6), ...
        'homebuilt',          struct('CLmax',1.8, 'WS_hist',11), ...
        'ga_single',          struct('CLmax',2.0, 'WS_hist',17), ...
        'ga_twin',            struct('CLmax',2.2, 'WS_hist',26), ...
        'twin_turboprop',     struct('CLmax',2.4, 'WS_hist',40), ...
        'jet_trainer',        struct('CLmax',2.0, 'WS_hist',50), ...
        'jet_fighter',        struct('CLmax',1.8, 'WS_hist',70), ...
        'jet_transport',      struct('CLmax',2.4, 'WS_hist',120), ...
        'mil_cargo_bomber',   struct('CLmax',2.4, 'WS_hist',120), ...
        'stol_transport',     struct('CLmax',3.0, 'WS_hist',60));

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

    fprintf('\n--- STALL SPEED INPUT ---\n');
    fprintf('  Enter either stall speed OR approach speed.\n');
    fprintf('  Approach speed = 1.3 * Vstall (civil) or 1.2 * Vstall (military).\n');
    input_mode = get_str('Enter (Vstall) or (Vapproach)', 'Vstall');

    if strcmpi(input_mode, 'Vapproach')
        V_app = get_num('Approach speed (knots)', 145);
        spec  = get_str('Specification (civil/military/carrier)', 'civil');
        if strcmpi(spec, 'military')
            factor = 1.2;
        elseif strcmpi(spec, 'carrier')
            factor = 1.15;
        else
            factor = 1.3;
        end
        V_stall_kts = V_app / factor;
        fprintf('  Vstall = Vapproach / %.2f = %.1f knots\n', factor, V_stall_kts);
    else
        V_stall_kts = get_num('Stall speed Vstall (knots)', 115);
    end

    fprintf('\n--- MAX LIFT COEFFICIENT ---\n');
    fprintf('  Typical values from Raymer Section 5.3:\n');
    fprintf('    Plain wing (no flaps)          : 1.2 - 1.5\n');
    fprintf('    Flaps on inner wing only       : 1.6 - 2.0\n');
    fprintf('    Transport with flaps and slats : 2.4\n');
    fprintf('    STOL with large flaps          : 3.0\n');
    CLmax = get_num('CLmax (landing configuration)', P.CLmax);

    fprintf('\n--- AIR DENSITY ---\n');
    fprintf('  1 = Sea-level standard (0.0023769 slug/ft^3)\n');
    fprintf('  2 = 5000 ft hot day   (0.00189   slug/ft^3)\n');
    fprintf('  3 = User-specified\n');
    rho_choice = get_num('Density option (1/2/3)', 1);
    switch rho_choice
        case 1
            rho = 0.0023769;
            rho_label = 'Sea-level standard';
        case 2
            rho = 0.00189;
            rho_label = '5000 ft hot day';
        case 3
            rho = get_num('Enter density (slug/ft^3)', 0.0023769);
            rho_label = 'User-specified';
        otherwise
            rho = 0.0023769;
            rho_label = 'Sea-level standard';
    end

    %% ========== CALCULATION ==========
    V_stall_fps = V_stall_kts * 1.68781;   % knots -> ft/s
    WS_stall    = 0.5 * rho * V_stall_fps^2 * CLmax;

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Aircraft class          : %s\n', cls);
    fprintf('Stall speed Vstall      : %.1f knots (%.1f ft/s)\n', ...
            V_stall_kts, V_stall_fps);
    fprintf('Max lift coefficient    : %.2f\n', CLmax);
    fprintf('Density (%s) : %.6f slug/ft^3\n', rho_label, rho);
    fprintf('--------------------------------------------------------\n');
    fprintf('Required wing loading W/S = %.1f lb/ft^2\n', WS_stall);
    fprintf('--------------------------------------------------------\n');
    fprintf('Historical W/S for class  : %.0f lb/ft^2\n', P.WS_hist);

    %% ========== FAR 23 STALL SPEED CHECK ==========
    fprintf('\n--- FAR 23 STALL SPEED CHECK ---\n');
    W = get_num('Aircraft takeoff weight (lb, 0 to skip)', 0);
    if W > 0 && W <= 12500
        if V_stall_kts <= 61
            fprintf('FAR 23: PASS (%.1f kts <= 61 kts)\n', V_stall_kts);
        else
            fprintf('FAR 23: FAIL (%.1f kts > 61 kts)\n', V_stall_kts);
        end
    elseif W > 12500
        fprintf('FAR 23 not applicable (W > 12,500 lb). FAR 25 applies.\n');
    else
        fprintf('Skipped.\n');
    end

    %% ========== NOTE ==========
    fprintf('\n--- NOTE ---\n');
    fprintf('  * This is the wing loading required ONLY to meet the stall\n');
    fprintf('    speed requirement. Other constraints (takeoff, landing,\n');
    fprintf('    climb, cruise) may drive W/S lower or higher.\n');
    fprintf('  * Select the lowest W/S from all constraints.\n');
    fprintf('  * If this value is unrealistically low, consider a better\n');
    fprintf('    high-lift system (larger CLmax) instead of a larger wing.\n');
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