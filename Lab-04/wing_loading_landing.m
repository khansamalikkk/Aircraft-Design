function wing_loading_landing()
% =====================================================================
% WING LOADING FROM LANDING DISTANCE  (Raymer Sec. 5.3, Eq. 5.11)
%
%   S_land = 80 * (W/S)_land / (sigma * CLmax_land) + Sa
%
%   Modifications:
%     - Thrust reversers / reversible props: x0.66 on ground term
%     - FAR 25: x1.67 on total landing distance (safety margin)
%
% Generic - works for any aircraft. Defaults set for jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('  WING LOADING FROM LANDING DISTANCE (Raymer Eq. 5.11)\n');
    fprintf('========================================================\n\n');

    %% ========== USER INPUTS ==========
    fprintf('--- LANDING REQUIREMENT ---\n');
    fprintf('  Landing distance definition:\n');
    fprintf('    1 = FAR 23 (50 ft obstacle, no safety factor)\n');
    fprintf('    2 = FAR 25 (50 ft obstacle, x1.67 safety factor)\n');
    fprintf('    3 = Military / RFP (usually like FAR 23)\n');
    spec = get_num('Specification type (1-3)', 2);

    S_land_req = get_num('Required landing distance (ft)', 5000);

    fprintf('\n--- LANDING WEIGHT ---\n');
    fprintf('  Typical landing weight ratio W_land/W_to:\n');
    fprintf('    1.00 = prop aircraft, jet trainers (land at TOGW)\n');
    fprintf('    0.85 = most jet aircraft\n');
    fprintf('    0.80 = long-range transports\n');
    Wland_Wto = get_num('Landing weight ratio W_land/W_to', 0.85);

    fprintf('\n--- AERODYNAMIC PARAMETERS ---\n');
    CLmax_land = get_num('CLmax at landing (flaps full)', 2.4);
    fprintf('  Density ratio sigma = rho/rho0 (1.0 at sea level)\n');
    sigma = get_num('Density ratio sigma', 1.0);

    fprintf('\n--- OPTIONS ---\n');
    rev = get_str('Thrust reversers installed? (y/n)', 'y');
    has_rev = strcmpi(rev, 'y');

    %% ========== Sa FROM RAYMER EQ. 5.11 ==========
    fprintf('\n--- OBSTACLE CLEARANCE DISTANCE Sa ---\n');
    fprintf('  1000 ft = airliner-type, 3-deg glideslope\n');
    fprintf('   600 ft = general aviation, power-off approach\n');
    fprintf('   450 ft = STOL, 7-deg glideslope\n');
    Sa = get_num('Sa (ft)', 1000);

    %% ========== CALCULATION ==========
    % Undo FAR 25 safety factor to get actual calculated landing distance
    if spec == 2
        S_land_calc = S_land_req / 1.67;
    else
        S_land_calc = S_land_req;
    end

    % Ground-roll term available for absorbing kinetic energy
    S_ground_available = S_land_calc - Sa;

    if S_ground_available <= 0
        fprintf('\n*** ERROR: Required distance is too short ***\n');
        fprintf('    S_land - Sa = %.0f ft is negative.\n', S_ground_available);
        return;
    end

    % Coefficient on ground term (thrust reversers reduce it)
    if has_rev
        k_rev = 0.66;
    else
        k_rev = 1.0;
    end

    % Solve for (W/S)_landing
    % S_ground = k_rev * 80 * (W/S)_land / (sigma * CLmax)
    WS_land = S_ground_available * sigma * CLmax_land / (k_rev * 80);

    % Convert to takeoff wing loading
    WS_takeoff = WS_land / Wland_Wto;

    %% ========== BACK-CHECK ==========
    S_ground_check = k_rev * 80 * WS_land / (sigma * CLmax_land);
    S_land_check   = S_ground_check + Sa;
    if spec == 2
        S_land_check_FAR25 = S_land_check * 1.67;
    else
        S_land_check_FAR25 = S_land_check;
    end

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    if spec == 1
        fprintf('Specification            : FAR 23\n');
    elseif spec == 2
        fprintf('Specification            : FAR 25 (x1.67 safety)\n');
    else
        fprintf('Specification            : Military / RFP\n');
    end
    fprintf('Required landing distance: %.0f ft\n', S_land_req);
    fprintf('Computed landing distance: %.0f ft\n', S_land_calc);
    fprintf('Obstacle clearance Sa    : %.0f ft\n', Sa);
    fprintf('Available ground roll    : %.0f ft\n', S_ground_available);
    fprintf('Thrust reversers         : %s (k = %.2f)\n', rev, k_rev);
    fprintf('CLmax at landing         : %.2f\n', CLmax_land);
    fprintf('Density ratio sigma      : %.3f\n', sigma);
    fprintf('W_land/W_takeoff         : %.3f\n', Wland_Wto);
    fprintf('--------------------------------------------------------\n');
    fprintf('(W/S)_landing            : %.1f lb/ft^2\n', WS_land);
    fprintf('(W/S)_takeoff            : %.1f lb/ft^2\n', WS_takeoff);
    fprintf('--------------------------------------------------------\n');

    %% ========== BACK-CHECK OUTPUT ==========
    fprintf('\n--- BACK-CHECK ---\n');
    fprintf('Ground roll from W/S     : %.0f ft\n', S_ground_check);
    fprintf('Total landing distance   : %.0f ft\n', S_land_check);
    if spec == 2
        fprintf('FAR 25 field length      : %.0f ft\n', S_land_check_FAR25);
    end

    %% ========== QUICK REFERENCE ==========
    fprintf('\n--- APPROXIMATE SPEEDS ---\n');
    fprintf('  (assuming landing at sea level, W_land = %.2f W_to)\n', Wland_Wto);
    W_to = get_num('Takeoff weight (lb)', 530000);
    W_land = W_to * Wland_Wto;
    rho0 = 0.0023769;
    V_stall_fps = sqrt(2 * W_land / (rho0 * sigma * get_wing_area(W_to, WS_takeoff) * CLmax_land));
    V_stall_kts = V_stall_fps / 1.68781;
    if spec == 1
        factor = 1.3;
    elseif spec == 3
        factor = 1.2;
    else
        factor = 1.3;
    end
    V_app_kts = factor * V_stall_kts;
    fprintf('  Vstall (landing)  : %.1f kts\n', V_stall_kts);
    fprintf('  Vapproach         : %.1f kts (%.2f x Vstall)\n', V_app_kts, factor);

    %% ========== NOTES ==========
    fprintf('\n--- NOTES ---\n');
    fprintf('  * Eq. 5.11 constant 80 is typical for transports.\n');
    fprintf('  * FAR 25 landing field length adds x1.67 safety margin.\n');
    fprintf('  * Thrust reversers reduce ground term by x0.66.\n');
    fprintf('  * W/S_landing must be divided by Wland/Wto to get\n');
    fprintf('    the takeoff wing loading used in design.\n');
    fprintf('  * Select the SMALLEST W/S from all constraints.\n');
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

function S = get_wing_area(W_to, WS_to)
    S = W_to / WS_to;
end