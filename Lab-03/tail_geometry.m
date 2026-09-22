function tail_geometry_generic()
    % =====================================================================
    % GENERIC TAIL GEOMETRY CALCULATOR
    % Based on Raymer, "Aircraft Design: A Conceptual Approach", Ch. 6
    %
    % Method: Tail Volume Coefficient
    %   S_h = V_h * S_w * MAC_w / L_h
    %   S_v = V_v * S_w * b_w   / L_v
    %
    % Works for ANY aircraft. Defaults are set for a 530,000 lb jet
    % transport (Boeing 777-200 class), but every value can be overridden.
    %
    % Call once and answer prompts, OR call as:
    %   tail_geometry_generic('W',530000,'class','jet_transport')
    % =====================================================================

    clc;
    fprintf('========================================================\n');
    fprintf('        GENERIC TAIL GEOMETRY CALCULATOR (Raymer)\n');
    fprintf('========================================================\n\n');

    %% ==================== AIRCRAFT CLASS PRESETS ====================
    % Historical tail volume coefficients and planform ratios by class.
    % Source: Raymer Tables 6.4, 6.5, and Fig. 6.14-6.16
    presets = struct( ...
        'sailplane',        struct('Vh',0.50,'Vv',0.020,'ARh',4.0,'ARv',1.2, ...
                                   'lh_frac',0.50,'lv_frac',0.45, ...
                                   'lam_h',0.70,'lam_v',0.60,'sw_h',5, 'sw_v',25), ...
        'homebuilt',        struct('Vh',0.50,'Vv',0.030,'ARh',4.0,'ARv',1.3, ...
                                   'lh_frac',0.50,'lv_frac',0.45, ...
                                   'lam_h',0.70,'lam_v',0.60,'sw_h',5, 'sw_v',25), ...
        'ga_single',        struct('Vh',0.70,'Vv',0.040,'ARh',4.0,'ARv',1.3, ...
                                   'lh_frac',0.50,'lv_frac',0.45, ...
                                   'lam_h',0.70,'lam_v',0.60,'sw_h',5, 'sw_v',30), ...
        'ga_twin',          struct('Vh',0.80,'Vv',0.050,'ARh',4.5,'ARv',1.3, ...
                                   'lh_frac',0.50,'lv_frac',0.45, ...
                                   'lam_h',0.70,'lam_v',0.60,'sw_h',5, 'sw_v',30), ...
        'twin_turboprop',   struct('Vh',0.90,'Vv',0.060,'ARh',5.0,'ARv',1.4, ...
                                   'lh_frac',0.50,'lv_frac',0.45, ...
                                   'lam_h',0.70,'lam_v',0.60,'sw_h',10,'sw_v',35), ...
        'jet_trainer',      struct('Vh',0.70,'Vv',0.060,'ARh',4.0,'ARv',1.4, ...
                                   'lh_frac',0.50,'lv_frac',0.45, ...
                                   'lam_h',0.70,'lam_v',0.60,'sw_h',20,'sw_v',35), ...
        'jet_fighter',      struct('Vh',0.40,'Vv',0.030,'ARh',3.0,'ARv',1.2, ...
                                   'lh_frac',0.45,'lv_frac',0.40, ...
                                   'lam_h',0.50,'lam_v',0.50,'sw_h',30,'sw_v',40), ...
        'jet_transport',    struct('Vh',0.90,'Vv',0.050,'ARh',5.5,'ARv',1.4, ...
                                   'lh_frac',0.46,'lv_frac',0.42, ...
                                   'lam_h',0.75,'lam_v',0.55,'sw_h',12,'sw_v',32), ...
        'bomber',           struct('Vh',0.80,'Vv',0.050,'ARh',4.5,'ARv',1.4, ...
                                   'lh_frac',0.46,'lv_frac',0.42, ...
                                   'lam_h',0.70,'lam_v',0.55,'sw_h',15,'sw_v',32), ...
        'cargo',            struct('Vh',0.90,'Vv',0.050,'ARh',5.5,'ARv',1.4, ...
                                   'lh_frac',0.46,'lv_frac',0.42, ...
                                   'lam_h',0.75,'lam_v',0.55,'sw_h',12,'sw_v',32));

    class_names = fieldnames(presets);

    %% ==================== WING INPUTS (from previous step) ====================
    fprintf('--- WING DATA (from previous step) ---\n');
    S_w        = get_num('Wing area S_w (ft^2)', 4478.3);
    b_w        = get_num('Wing span b_w (ft)', 197.13);
    MAC_w      = get_num('Wing MAC (ft)', 24.903);
    fus_length = get_num('Fuselage length (ft)', 209.1);

    %% ==================== AIRCRAFT CLASS ====================
    fprintf('\n--- AIRCRAFT CLASS ---\n');
    fprintf('Available: %s\n', strjoin(class_names', ', '));
    cls = get_str('Aircraft class', 'jet_transport');
    if ~isfield(presets, cls)
        fprintf('  Class "%s" not found. Using jet_transport defaults.\n', cls);
        cls = 'jet_transport';
    end
    P = presets.(cls);

    %% ==================== TAIL SIZING INPUTS ====================
    fprintf('\n--- TAIL SIZING (press Enter for class defaults) ---\n');
    V_h = get_num('Horizontal tail volume coeff V_h', P.Vh);
    V_v = get_num('Vertical tail volume coeff V_v',   P.Vv);

    L_h = get_num('Horizontal tail arm L_h (ft)', P.lh_frac * fus_length);
    L_v = get_num('Vertical tail arm L_v (ft)',   P.lv_frac * fus_length);

    %% ==================== HORIZONTAL TAIL PLANFORM ====================
    fprintf('\n--- HORIZONTAL TAIL PLANFORM ---\n');
    AR_h     = get_num('Aspect ratio AR_h', P.ARh);
    lambda_h = get_num('Taper ratio lambda_h', P.lam_h);
    sweep_h  = get_num('Quarter-chord sweep (deg)', P.sw_h);
    dihed_h  = get_num('Dihedral (deg)', 5);
    tc_h     = get_num('Airfoil t/c (symmetric NACA 00xx)', 0.10);

    %% ==================== VERTICAL TAIL PLANFORM ====================
    fprintf('\n--- VERTICAL TAIL PLANFORM ---\n');
    AR_v     = get_num('Aspect ratio AR_v', P.ARv);
    lambda_v = get_num('Taper ratio lambda_v', P.lam_v);
    sweep_v  = get_num('Quarter-chord sweep (deg)', P.sw_v);
    tc_v     = get_num('Airfoil t/c (symmetric NACA 00xx)', 0.10);

    %% ==================== HORIZONTAL TAIL CALCULATIONS ====================
    S_h     = V_h * S_w * MAC_w / L_h;
    b_h     = sqrt(AR_h * S_h);
    c_r_h   = 2 * S_h / (b_h * (1 + lambda_h));
    c_t_h   = lambda_h * c_r_h;
    MAC_h   = (2/3) * c_r_h * (1 + lambda_h + lambda_h^2) / (1 + lambda_h);
    y_MAC_h = (b_h/6) * (1 + 2*lambda_h) / (1 + lambda_h);
    t_root_h = tc_h * c_r_h;
    t_tip_h  = tc_h * c_t_h;
    area_ratio_h = S_h / S_w;

    %% ==================== VERTICAL TAIL CALCULATIONS ====================
    S_v     = V_v * S_w * b_w / L_v;
    b_v     = sqrt(AR_v * S_v);
    c_r_v   = 2 * S_v / (b_v * (1 + lambda_v));
    c_t_v   = lambda_v * c_r_v;
    MAC_v   = (2/3) * c_r_v * (1 + lambda_v + lambda_v^2) / (1 + lambda_v);
    y_MAC_v = (b_v/6) * (1 + 2*lambda_v) / (1 + lambda_v);
    t_root_v = tc_v * c_r_v;
    t_tip_v  = tc_v * c_t_v;
    area_ratio_v = S_v / S_w;

    %% ==================== OUTPUT ====================
    fprintf('\n========================================================\n');
    fprintf('              TAIL GEOMETRY RESULTS\n');
    fprintf('========================================================\n');
    fprintf('Aircraft class : %s\n', cls);
    fprintf('Wing ref       : S_w = %.1f ft^2, b_w = %.2f ft, MAC_w = %.3f ft\n', ...
            S_w, b_w, MAC_w);
    fprintf('Fuselage length: %.1f ft\n', fus_length);

    fprintf('\n--- HORIZONTAL TAIL ---\n');
    fprintf('%-34s %12.4f\n', 'Volume coefficient V_h',       V_h);
    fprintf('%-34s %12.2f ft\n', 'Moment arm L_h',           L_h);
    fprintf('%-34s %12.1f ft^2\n', 'Surface area S_h',       S_h);
    fprintf('%-34s %12.4f\n', 'Area ratio S_h/S_w',          area_ratio_h);
    fprintf('%-34s %12.2f\n', 'Aspect ratio AR_h',           AR_h);
    fprintf('%-34s %12.2f ft\n', 'Span b_h',                 b_h);
    fprintf('%-34s %12.3f\n', 'Taper ratio lambda_h',        lambda_h);
    fprintf('%-34s %12.3f ft\n', 'Root chord c_r_h',          c_r_h);
    fprintf('%-34s %12.3f ft\n', 'Tip chord c_t_h',           c_t_h);
    fprintf('%-34s %12.3f ft\n', 'MAC_h',                     MAC_h);
    fprintf('%-34s %12.3f ft\n', 'MAC location y_MAC_h',      y_MAC_h);
    fprintf('%-34s %12.2f deg\n', 'Quarter-chord sweep',      sweep_h);
    fprintf('%-34s %12.2f deg\n', 'Dihedral',                 dihed_h);
    fprintf('%-34s %12.4f\n', 'Airfoil t/c',                  tc_h);
    fprintf('%-34s %12.3f ft (%.2f in)\n', 'Root thickness',  t_root_h, t_root_h*12);
    fprintf('%-34s %12.3f ft (%.2f in)\n', 'Tip thickness',   t_tip_h,  t_tip_h*12);

    fprintf('\n--- VERTICAL TAIL ---\n');
    fprintf('%-34s %12.4f\n', 'Volume coefficient V_v',       V_v);
    fprintf('%-34s %12.2f ft\n', 'Moment arm L_v',           L_v);
    fprintf('%-34s %12.1f ft^2\n', 'Surface area S_v',       S_v);
    fprintf('%-34s %12.4f\n', 'Area ratio S_v/S_w',          area_ratio_v);
    fprintf('%-34s %12.2f\n', 'Aspect ratio AR_v',           AR_v);
    fprintf('%-34s %12.2f ft\n', 'Span b_v',                 b_v);
    fprintf('%-34s %12.3f\n', 'Taper ratio lambda_v',        lambda_v);
    fprintf('%-34s %12.3f ft\n', 'Root chord c_r_v',          c_r_v);
    fprintf('%-34s %12.3f ft\n', 'Tip chord c_t_v',           c_t_v);
    fprintf('%-34s %12.3f ft\n', 'MAC_v',                     MAC_v);
    fprintf('%-34s %12.3f ft\n', 'MAC location y_MAC_v',      y_MAC_v);
    fprintf('%-34s %12.2f deg\n', 'Quarter-chord sweep',      sweep_v);
    fprintf('%-34s %12.4f\n', 'Airfoil t/c',                  tc_v);
    fprintf('%-34s %12.3f ft (%.2f in)\n', 'Root thickness',  t_root_v, t_root_v*12);
    fprintf('%-34s %12.3f ft (%.2f in)\n', 'Tip thickness',   t_tip_v,  t_tip_v*12);

    fprintf('\n--- SHARED ---\n');
    fprintf('%-34s %12s\n', 'Tail airfoil', 'Symmetric NACA 00xx');
    fprintf('%-34s %12s\n', 'Horizontal tail incidence', '0 deg (adjustable)');

    fprintf('\n========================================================\n');
    fprintf('Note: Refine moment arms once fuselage layout and CG\n');
    fprintf('      envelope are established. Re-run with updated\n');
    fprintf('      L_h and L_v for accurate sizing.\n');
    fprintf('========================================================\n');
end

%% ==================== HELPER FUNCTIONS ====================
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