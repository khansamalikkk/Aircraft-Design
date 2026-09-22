function adjust_WS_to_takeoff()
% =====================================================================
% ADJUST ALL W/S VALUES TO TAKEOFF CONDITIONS
% (Raymer Sec. 5.3, final consolidation step)
%
% Each constraint was computed at a different mission weight. This code
% converts every W/S to takeoff weight so they can be compared on the
% same basis:
%
%   (W/S)_takeoff = (W/S)_mission / (W_mission / W_takeoff)
%
% Then it identifies the BINDING constraint (smallest W/S_takeoff) that
% determines the minimum wing size.
%
% Generic - works for any aircraft. Defaults for jet transport.
% =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('   ADJUST ALL W/S VALUES TO TAKEOFF CONDITIONS\n');
    fprintf('   (Raymer Sec. 5.3 -- Final Consolidation)\n');
    fprintf('========================================================\n\n');

    %% ========== AIRCRAFT CLASS ==========
    fprintf('--- AIRCRAFT CLASS ---\n');
    fprintf('  jet_transport / mil_cargo_bomber / jet_fighter / jet_trainer\n');
    fprintf('  twin_turboprop / ga_single / ga_twin / sailplane\n');
    cls = get_str('Aircraft class', 'jet_transport');

    %% ========== DEFAULT MISSION WEIGHT RATIOS ==========
    % Raymer Table 3.2 typical values
    switch lower(cls)
        case {'jet_transport', 'mil_cargo_bomber', 'bomber', 'cargo'}
            Wr_climb  = 0.985;   % after takeoff climb
            Wr_cruise = 0.956;   % start of cruise
            Wr_loiter = 0.85;    % average loiter
            Wr_land   = 0.85;    % landing weight
            Wr_combat = 0.85;    % combat weight
        case {'jet_fighter', 'jet_fighter_dog'}
            Wr_climb  = 0.99;
            Wr_cruise = 0.94;
            Wr_loiter = 0.80;
            Wr_land   = 0.85;
            Wr_combat = 0.85;
        case {'twin_turboprop', 'ga_twin'}
            Wr_climb  = 0.99;
            Wr_cruise = 0.98;
            Wr_loiter = 0.90;
            Wr_land   = 1.00;
            Wr_combat = 0.90;
        case {'ga_single', 'homebuilt_metal', 'homebuilt_comp'}
            Wr_climb  = 0.99;
            Wr_cruise = 0.98;
            Wr_loiter = 0.90;
            Wr_land   = 1.00;
            Wr_combat = 1.00;
        case 'sailplane'
            Wr_climb  = 1.00;
            Wr_cruise = 0.98;
            Wr_loiter = 0.95;
            Wr_land   = 1.00;
            Wr_combat = 1.00;
        otherwise
            Wr_climb = 0.985; Wr_cruise = 0.956;
            Wr_loiter = 0.85; Wr_land = 0.85; Wr_combat = 0.85;
    end

    fprintf('\n--- DEFAULT MISSION WEIGHT RATIOS (Raymer Table 3.2) ---\n');
    fprintf('  W_climb  / W_to = %.3f\n', Wr_climb);
    fprintf('  W_cruise / W_to = %.3f\n', Wr_cruise);
    fprintf('  W_loiter / W_to = %.3f\n', Wr_loiter);
    fprintf('  W_land   / W_to = %.3f\n', Wr_land);
    fprintf('  W_combat / W_to = %.3f\n', Wr_combat);
    fprintf('  (Press Enter to accept each; type a new value to override.)\n');

    Wr_climb  = get_num('  W_climb  / W_to', Wr_climb);
    Wr_cruise = get_num('  W_cruise / W_to', Wr_cruise);
    Wr_loiter = get_num('  W_loiter / W_to', Wr_loiter);
    Wr_land   = get_num('  W_land   / W_to', Wr_land);
    Wr_combat = get_num('  W_combat / W_to', Wr_combat);

    %% ========== ENTER W/S VALUES FROM PREVIOUS TASKS ==========
    fprintf('\n========================================================\n');
    fprintf('   ENTER W/S VALUES FROM PREVIOUS TASKS\n');
    fprintf('   (as computed at each mission condition)\n');
    fprintf('========================================================\n');

    fprintf('\n--- Stall (Eq. 5.6) ---\n');
    WS_stall = get_num('  W/S at stall condition', 107.5);
    Wr_stall = get_num('  W/W_to at stall (usually 1.0)', 1.0);

    fprintf('\n--- Takeoff (Eq. 5.9) ---\n');
    WS_to = get_num('  W/S at takeoff condition', 166.3);
    Wr_to = get_num('  W/W_to at takeoff (usually 1.0)', 1.0);

    fprintf('\n--- Landing (Eq. 5.11) ---\n');
    fprintf('  NOTE: use the value BEFORE dividing by W_land/W_to\n');
    WS_land = get_num('  W/S at landing condition', 90.6);
    Wr_land_in = get_num('  W/W_to at landing', Wr_land);

    fprintf('\n--- Climb (Eq. 5.30) ---\n');
    fprintf('  Use the HIGH ROOT (practical value)\n');
    WS_climb = get_num('  W/S at climb condition', 603);
    Wr_climb_in = get_num('  W/W_to at climb', Wr_climb);

    fprintf('\n--- Cruise (Eq. 5.14) ---\n');
    fprintf('  Use the cruise-optimal W/S (not a hard constraint)\n');
    WS_cruise = get_num('  W/S at cruise condition', 81.3);
    Wr_cruise_in = get_num('  W/W_to at cruise', Wr_cruise);

    fprintf('\n--- Loiter (Eq. 5.15/5.16) ---\n');
    WS_loiter = get_num('  W/S at loiter condition', 135.7);
    Wr_loiter_in = get_num('  W/W_to at loiter', Wr_loiter);

    fprintf('\n--- Instantaneous Turn (Eq. 5.20) ---\n');
    WS_inst = get_num('  W/S at combat condition', 44.6);
    Wr_inst_in = get_num('  W/W_to at combat', Wr_combat);

    fprintf('\n--- Sustained Turn (Eq. 5.25, high root) ---\n');
    WS_sust = get_num('  W/S at combat condition', 77.6);
    Wr_sust_in = get_num('  W/W_to at combat', Wr_combat);

    %% ========== BUILD CONSTRAINT TABLE ==========
    names = {'Stall', 'Takeoff', 'Landing', 'Climb', ...
             'Cruise (opt)', 'Loiter (opt)', ...
             'Instant Turn', 'Sustained Turn'};

    WS_mission = [WS_stall, WS_to, WS_land, WS_climb, ...
                  WS_cruise, WS_loiter, WS_inst, WS_sust];

    Wr_mission = [Wr_stall, Wr_to, Wr_land_in, Wr_climb_in, ...
                  Wr_cruise_in, Wr_loiter_in, Wr_inst_in, Wr_sust_in];

    % Constraint classification
    % 'hard' = sizing constraint,  'opt' = optimization target
    kind_arr = {'hard', 'hard', 'hard', 'hard', ...
                'opt',  'opt',  'hard', 'hard'};

    % Adjust to takeoff conditions
    WS_to_list = WS_mission ./ Wr_mission;

    %% ========== PRINT TABLE ==========
    fprintf('\n========================================================\n');
    fprintf('      W/S ADJUSTED TO TAKEOFF CONDITIONS\n');
    fprintf('========================================================\n');
    fprintf('%-18s %13s %9s %15s %10s\n', ...
            'Constraint', 'W/S mission', 'W/W_to', 'W/S takeoff', 'Type');
    fprintf('%-18s %13s %9s %15s %10s\n', ...
            '------------------', '-------------', ...
            '---------', '---------------', '----------');
    for i = 1:numel(names)
        fprintf('%-18s %13.1f %9.3f %15.1f %10s\n', ...
                names{i}, WS_mission(i), Wr_mission(i), ...
                WS_to_list(i), kind_arr{i});
    end
    fprintf('--------------------------------------------------------\n');

    %% ========== IDENTIFY BINDING CONSTRAINT ==========
    hard_idx = find(strcmp(kind_arr, 'hard'));
    [min_WS, local_idx] = min(WS_to_list(hard_idx));
    binding_idx = hard_idx(local_idx);

    fprintf('\n>>> BINDING CONSTRAINT (tightest upper bound):\n');
    fprintf('    %s at W/S = %.1f lb/ft^2 (takeoff)\n', ...
            names{binding_idx}, min_WS);

    %% ========== FEASIBLE DESIGN WINDOW ==========
    fprintf('\n--- FEASIBLE DESIGN WINDOW ---\n');
    fprintf('  All hard constraints must be satisfied simultaneously:\n');
    fprintf('  W/S(takeoff) <= %.1f lb/ft^2\n', min_WS);
    fprintf('  => Minimum wing area S_min = W_to / %.1f\n', min_WS);

    W_to = get_num('  Enter your takeoff gross weight (lb)', 530000);
    S_min = W_to / min_WS;
    fprintf('\n  For W_to = %.0f lb:\n', W_to);
    fprintf('    S_min = %.0f ft^2\n', S_min);

    %% ========== OPTIMIZATION TARGETS ==========
    opt_idx = find(strcmp(kind_arr, 'opt'));
    if ~isempty(opt_idx)
        fprintf('\n--- OPTIMIZATION TARGETS (not hard limits) ---\n');
        for i = 1:numel(opt_idx)
            k = opt_idx(i);
            fprintf('  %-18s : W/S_takeoff = %.1f lb/ft^2\n', ...
                    names{k}, WS_to_list(k));
        end
        fprintf('  These are the W/S values for best efficiency.\n');
        fprintf('  You may deviate from them if hard constraints force it.\n');
    end

    %% ========== NOTE ==========
    fprintf('\n--- NOTE ---\n');
    fprintf('  * Stall, takeoff, landing, climb, and turn constraints\n');
    fprintf('    are all UPPER BOUNDS on W/S.\n');
    fprintf('  * Cruise and loiter are optimization targets, not limits.\n');
    fprintf('  * The design W/S must be <= the binding hard constraint.\n');
    fprintf('  * Choose a W/S at or slightly below this value for margin.\n');
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