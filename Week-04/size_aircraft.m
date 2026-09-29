function results = size_aircraft(cfg)
% size_aircraft  Raymer refined sizing: iterate to find takeoff gross weight.
%
% Inputs (cfg struct):
%   cfg.Wcrew        : crew weight [lb]
%   cfg.Wpayload     : payload weight [lb]
%   cfg.Range_nmi    : design range [nmi]
%   cfg.Cruise_Alt   : cruise altitude [ft]
%   cfg.Cruise_Mach  : cruise Mach number [-]
%   cfg.SFC_cruise   : cruise SFC [1/hr]
%   cfg.LD_cruise    : cruise L/D [-]
%   cfg.Loiter_hr    : loiter time [hr]
%   cfg.SFC_loiter   : loiter SFC [1/hr]
%   cfg.LD_loiter    : loiter L/D [-]
%   cfg.A            : aspect ratio [-]
%   cfg.T_W          : thrust-to-weight ratio [-]
%   cfg.W_S          : wing loading [lb/ft^2]
%   cfg.Mmax         : maximum Mach number [-]
%   cfg.Kvs          : variable sweep constant [-]
%   cfg.ac_type      : aircraft type for empty-weight equation
%   cfg.W0_guess     : (optional) initial guess [lb]
%   cfg.tol          : (optional) convergence tolerance [lb], default 1
%   cfg.max_iter     : (optional) max iterations, default 100
%   cfg.verbose      : (optional) display iterations, default true
%   cfg.payload_drop : (optional) payload dropped mid-mission [lb]
%   cfg.drop_segment : (optional) index of drop segment
%
% Outputs (results struct):
%   results.W0       : converged takeoff gross weight [lb]
%   results.We       : empty weight [lb]
%   results.Wf       : total fuel weight [lb]
%   results.We_W0    : empty weight fraction [-]
%   results.Wf_W0    : fuel weight fraction [-]
%   results.iter     : number of iterations
%   results.history  : iteration history [iter, W0_guess, W0_calc, We/W0]

    % --- Defaults ---
    if ~isfield(cfg,'tol'),        cfg.tol = 1;        end
    if ~isfield(cfg,'max_iter'),   cfg.max_iter = 100; end
    if ~isfield(cfg,'verbose'),    cfg.verbose = true; end
    if ~isfield(cfg,'payload_drop'), cfg.payload_drop = 0; end
    if ~isfield(cfg,'WF_taxi'),    cfg.WF_taxi = 0.970; end
    if ~isfield(cfg,'WF_climb'),   cfg.WF_climb = 0.985; end
    if ~isfield(cfg,'WF_descent'), cfg.WF_descent = 0.985; end
    if ~isfield(cfg,'W0_guess')
        cfg.W0_guess = 3 * (cfg.Wcrew + cfg.Wpayload);
    end

    % --- Cruise speed from ISA ---
    [~, a, ~, ~] = atmosisa(cfg.Cruise_Alt * 0.3048);
    V_cruise = cfg.Cruise_Mach * a * 3.28084;
    Range_ft = cfg.Range_nmi * 6076.12;

    % --- Segment weight fractions (independent of W0) ---
    WF_cruise = exp(-Range_ft * cfg.SFC_cruise / (V_cruise * cfg.LD_cruise));
    WF_loiter = exp(-cfg.Loiter_hr * cfg.SFC_loiter / (cfg.LD_loiter));

    names = {'Start/Taxi','Climb','Cruise','Descent/Land/Taxi','Loiter'};
    WFs   = [cfg.WF_taxi, cfg.WF_climb, WF_cruise, cfg.WF_descent, WF_loiter];
    drops = zeros(1,5);
    if cfg.payload_drop > 0 && isfield(cfg,'drop_segment')
        drops(cfg.drop_segment) = cfg.payload_drop;
    end
    segments = struct('name', names, 'WF', num2cell(WFs), 'drop', num2cell(drops));

    % --- Iteration ---
    W0 = cfg.W0_guess;
    history = zeros(cfg.max_iter, 4);
    iter = 0;

    for iter = 1:cfg.max_iter
        % Fuel burned for this W0 guess
        [Wf_total, ~, ~, ~, ~] = mission_fuel(W0, segments);

        % Empty-weight fraction at this W0 guess
        [We_W0, ~] = empty_weight_fraction(cfg.ac_type, W0, cfg.A, ...
            cfg.T_W, cfg.W_S, cfg.Mmax, cfg.Kvs);

        % Sizing equation solved for W0
        W0_calc = (cfg.Wcrew + cfg.Wpayload + Wf_total) / (1 - We_W0);

        history(iter,:) = [iter, W0, W0_calc, We_W0];

        if cfg.verbose
            fprintf('Iter %3d: W0_guess = %10.1f, W0_calc = %10.1f, We/W0 = %.4f\n', ...
                iter, W0, W0_calc, We_W0);
        end

        if abs(W0_calc - W0) < cfg.tol
            break;
        end

        % 75% move toward calculated value (Raymer's recommendation)
        W0 = 0.25 * W0 + 0.75 * W0_calc;
    end

    % --- Final values at converged W0 ---
    [Wf_total, Wf_mission, Wfinal, Wseg, dfuel] = mission_fuel(W0_calc, segments);
    [We_W0, We] = empty_weight_fraction(cfg.ac_type, W0_calc, cfg.A, ...
        cfg.T_W, cfg.W_S, cfg.Mmax, cfg.Kvs);

    results.W0       = W0_calc;
    results.We       = We;
    results.Wf       = Wf_total;
    results.We_W0    = We_W0;
    results.Wf_W0    = Wf_total / W0_calc;
    results.iter     = iter;
    results.history  = history(1:iter,:);
    results.segments = segments;
    results.Wf_mission = Wf_mission;
    results.Wfinal   = Wfinal;
    results.Wseg     = Wseg;
    results.dfuel    = dfuel;
end