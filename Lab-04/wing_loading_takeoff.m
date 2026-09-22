function wing_loading_takeoff()
% =====================================================================
% WING LOADING FROM TAKEOFF DISTANCE  (Raymer Sec. 5.3, Eq. 5.9)
%
%   W/S = TOP * sigma * CL_TO * (T/W)
%
% TOP is read from digitized Fig. 5.4 (takeoff distance vs takeoff
% parameter) for the given distance and constraint type.
%
% Generic - works for any aircraft. Defaults set for jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   WING LOADING FROM TAKEOFF DISTANCE (Raymer Eq. 5.9)\n');
    fprintf('========================================================\n\n');

    %% ========== USER INPUTS ==========
    fprintf('--- TAKEOFF REQUIREMENT ---\n');
    fprintf('  Constraint types (Fig. 5.4):\n');
    fprintf('    1 = Ground roll only\n');
    fprintf('    2 = FAR 25 balanced field length (35 ft obstacle)\n');
    fprintf('    3 = Military balanced field length (50 ft obstacle)\n');
    fprintf('    4 = Takeoff over 50 ft obstacle (AEO)\n');
    constraint = get_num('Constraint type (1-4)', 2);

    if constraint == 2
        n_engines = get_num('Number of jet engines (2/3/4)', 2);
    else
        n_engines = 0;
    end

    takeoff_dist = get_num('Required takeoff distance (ft)', 8500);
    fprintf('  Enter T/W (from previous analysis)\n');
    TW = get_num('Thrust-to-weight ratio T/W', 0.28);
    fprintf('  Enter takeoff lift coefficient CL_TO = CLmax_TO / 1.21\n');
    CL_TO = get_num('CL_TO', 1.98);
    fprintf('  Density ratio sigma = rho / rho0 (1.0 at sea level)\n');
    sigma = get_num('Density ratio sigma', 1.0);

    fprintf('\n--- AIRCRAFT CLASS (for historical reference) ---\n');
    cls = get_str('Class name', 'jet_transport');
    WS_hist = get_historical_WS(cls);

    %% ========== SOLVE FOR TOP FROM FIG. 5.4 ==========
    % Distance is in ft, converted to 10^3 ft
    L_kft = takeoff_dist / 1000;

    % Digitized linear fits:  L_kft = m * TOP + b
    % from Raymer Fig. 5.4
    switch constraint
        case 1   % Ground roll (jet)
            m = 0.0100;  b = -0.10;
            label = 'Ground roll (jet)';
        case 2   % FAR 25 balanced field length, 35 ft obstacle
            if n_engines == 2
                m = 0.0290; b = -0.20;
                label = 'FAR 25 BFL, 2 engines (35 ft)';
            elseif n_engines == 3
                m = 0.0250; b = -0.20;
                label = 'FAR 25 BFL, 3 engines (35 ft)';
            elseif n_engines == 4
                m = 0.0210; b = -0.20;
                label = 'FAR 25 BFL, 4 engines (35 ft)';
            else
                m = 0.0290; b = -0.20;
                label = 'FAR 25 BFL (default 2 engines)';
            end
        case 3   % MIL BFL, 50 ft obstacle (approx 5% more than FAR 35 ft)
            if n_engines == 2
                m = 0.0290 * 0.95; b = -0.20;
            elseif n_engines == 3
                m = 0.0250 * 0.95; b = -0.20;
            elseif n_engines == 4
                m = 0.0210 * 0.95; b = -0.20;
            else
                m = 0.0290 * 0.95; b = -0.20;
            end
            label = sprintf('MIL BFL, %d engines (50 ft)', max(n_engines,2));
        case 4   % Over 50 ft obstacle (all engines operating)
            m = 0.0150; b = -0.30;
            label = 'Over 50 ft obstacle (AEO)';
        otherwise
            m = 0.0290; b = -0.20;
            label = 'FAR 25 BFL (default)';
    end

    TOP = (L_kft - b) / m;

    if TOP <= 0
        fprintf('\n*** ERROR: Required distance too short to reverse-solve ***\n');
        fprintf('    Check digitized fit or try a longer distance.\n');
        return;
    end

    %% ========== COMPUTE W/S ==========
    WS_takeoff = TOP * sigma * CL_TO * TW;

    %% ========== OUTPUT ==========
    fprintf('\n========================================================\n');
    fprintf('                RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Constraint type          : %s\n', label);
    fprintf('Required takeoff distance: %.0f ft (%.2f kft)\n', ...
            takeoff_dist, L_kft);
    fprintf('T/W                      : %.4f\n', TW);
    fprintf('CL_TO (takeoff)          : %.3f\n', CL_TO);
    fprintf('Density ratio sigma      : %.3f\n', sigma);
    fprintf('--------------------------------------------------------\n');
    fprintf('Takeoff Parameter (TOP)  : %.1f\n', TOP);
    fprintf('Required W/S             : %.1f lb/ft^2\n', WS_takeoff);
    fprintf('--------------------------------------------------------\n');
    fprintf('Historical W/S for %s : %.0f lb/ft^2\n', cls, WS_hist);

    %% ========== BACK-CHECK: actual takeoff distance with this W/S ==========
    TOP_check = WS_takeoff / (sigma * CL_TO * TW);
    L_check = m * TOP_check + b;
    fprintf('\n--- BACK-CHECK ---\n');
    fprintf('Recomputed TOP from W/S        : %.1f\n', TOP_check);
    fprintf('Recomputed takeoff distance    : %.0f ft\n', L_check * 1000);

    %% ========== NOTES ==========
    fprintf('\n--- NOTES ---\n');
    fprintf('  * Fig. 5.4 curves are digitized as linear fits — valid over\n');
    fprintf('    the range TOP ? 50 to 500 (dist ? 2,000 to 12,000 ft).\n');
    fprintf('  * For final design, replace with the actual curve or use\n');
    fprintf('    the detailed takeoff integration (Ch. 17).\n');
    fprintf('  * CL_TO = CLmax_TO / 1.21 (takeoff at 1.1 * Vstall).\n');
    fprintf('  * Typical CLmax_TO = 0.8 * CLmax_landing.\n');
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

function WS = get_historical_WS(cls)
    switch lower(cls)
        case 'sailplane',       WS = 6;
        case 'homebuilt',       WS = 11;
        case 'ga_single',       WS = 17;
        case 'ga_twin',         WS = 26;
        case 'twin_turboprop',  WS = 40;
        case 'jet_trainer',     WS = 50;
        case 'jet_fighter',     WS = 70;
        case 'jet_transport',   WS = 120;
        case 'mil_cargo_bomber',WS = 120;
        otherwise,              WS = 100;
    end
end