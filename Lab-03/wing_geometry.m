function wing_geometry_generic()
    % =====================================================================
    % GENERIC WING GEOMETRY CALCULATOR
    % Based on Raymer, "Aircraft Design: A Conceptual Approach"
    %
    % Calculates all 16 wing parameters from:
    %   - Selected airfoil (root & tip thickness ratios)
    %   - Reference aircraft data (S, b, AR, sweep, taper, MTOW)
    %   - Your aircraft weight
    %   - Your design choices (twist, incidence, dihedral, etc.)
    %
    % Defaults are set for: NASA SC(2)-0714 airfoil, Boeing 777-200 reference,
    % and a 530,000 lb jet transport.
    % =====================================================================

    clc;
    fprintf('=====================================================\n');
    fprintf('   GENERIC WING GEOMETRY CALCULATOR (Raymer Method)\n');
    fprintf('=====================================================\n\n');

    %% ==================== INPUT SECTION ====================

    % ---------- Your Aircraft ----------
    fprintf('--- YOUR AIRCRAFT ---\n');
    W = get_input('Your aircraft weight (lb)', 530000);

    % ---------- Reference Aircraft ----------
    fprintf('\n--- REFERENCE AIRCRAFT DATA ---\n');
    ref_name = get_input_str('Reference aircraft name', 'Boeing 777-200');
    W_ref    = get_input('Reference MTOW (lb)', 545000);
    S_ref    = get_input('Reference wing area (ft^2)', 4605);
    b_ref    = get_input('Reference wing span (ft)', 199.9);
    AR_ref   = get_input('Reference aspect ratio', 8.68);
    sw_c4_ref= get_input('Reference quarter-chord sweep (deg)', 31.6);
    lam_ref  = get_input('Reference taper ratio', 0.30);

    % ---------- Selected Airfoil ----------
    fprintf('\n--- SELECTED AIRFOIL ---\n');
    airfoil_name = get_input_str('Airfoil name', 'NASA SC(2)-0714');
    tc_root = get_input('Root airfoil thickness ratio t/c (e.g. 0.139)', 0.139);
    tc_tip  = get_input('Tip airfoil thickness ratio t/c (e.g. 0.11)', 0.11);

    % ---------- Design Choices ----------
    fprintf('\n--- DESIGN CHOICES ---\n');
    lambda    = get_input('Taper ratio lambda = c_t/c_r', lam_ref);
    twist     = get_input('Washout (deg, negative for washout)', -4);
    incidence = get_input('Wing incidence (deg)', 3);
    dihedral  = get_input('Dihedral angle (deg)', 5);
    wing_loc  = get_input_str('Wing location (low/mid/high)', 'low');
    wing_cfg  = get_input_str('Wing config (cantilever/braced)', 'cantilever');
    wing_tip  = get_input_str('Wing tip type (raked/rounded/winglet)', 'raked');

    %% ==================== CALCULATIONS ====================

    % 1. Aspect Ratio
    AR = (b_ref^2)/S_ref;

    % 2. Wing Sweep
    sweep_c4 = sw_c4_ref;                          % quarter-chord sweep
    n = 0; m = 0.25;                               % LE and c/4
    sweep_LE = rad2deg(atan( tan(deg2rad(sweep_c4)) ...
        - (4/AR) * ((n - m) * (1 - lambda) / (1 + lambda)) ));

    % 3. Taper Ratio (already input as lambda)

    % 4. Wing Area (scaled by weight ratio)
    S = S_ref * (W / W_ref);

    % 5. Wing Span
    b = sqrt(AR * S);

    % 6. Twist (already input)

    % 7. Root Chord
    c_r = 2 * S / (b * (1 + lambda));

    % 8. Tip Chord
    c_t = lambda * c_r;

    % 9. Mean Aerodynamic Chord
    MAC = (2/3) * c_r * (1 + lambda + lambda^2) / (1 + lambda);

    % 10. MAC Location (spanwise from centerline)
    y_MAC = (b/6) * (1 + 2*lambda) / (1 + lambda);

    % 11. Wing Twist (same as 6)

    % 12. Wing Incidence (already input)

    % 13. Dihedral Angle (already input)

    % 14-16. Wing location, config, tip type (already input)

    % ---------- Additional: physical thickness from airfoil ----------
    t_root_ft = tc_root * c_r;   % root airfoil thickness, ft
    t_tip_ft  = tc_tip  * c_t;   % tip airfoil thickness, ft
    t_root_in = t_root_ft * 12;  % inches
    t_tip_in  = t_tip_ft  * 12;  % inches

    % ---------- Wing planform volume (rough estimate) ----------
    % Approximate internal volume for fuel (trapezoidal wing box)
    % Using average thickness and 50% chord box
    t_avg = 0.5 * (t_root_ft + t_tip_ft);
    box_chord = 0.5 * (c_r + c_t) / 2;
    V_wing = 0.5 * (b/2) * (c_r + c_t) * t_avg * 0.5;  % rough ft^3

    %% ==================== OUTPUT SECTION ====================

    fprintf('\n=====================================================\n');
    fprintf('              WING GEOMETRY RESULTS\n');
    fprintf('=====================================================\n');
    fprintf('Reference aircraft : %s\n', ref_name);
    fprintf('Airfoil selected   : %s\n', airfoil_name);
    fprintf('-----------------------------------------------------\n');

    fprintf('%-38s %12s\n', 'Parameter', 'Value');
    fprintf('%-38s %12s\n', '--------------------------------------', '------------');
    fprintf('%-38s %12.2f\n',   '1.  Aspect Ratio (AR)', AR);
    fprintf('%-38s %12.2f\n',   '2a. Quarter-chord sweep (deg)', sweep_c4);
    fprintf('%-38s %12.2f\n',   '2b. Leading-edge sweep (deg)', sweep_LE);
    fprintf('%-38s %12.3f\n',   '3.  Taper ratio (lambda)', lambda);
    fprintf('%-38s %12.1f\n',   '4.  Wing area S (ft^2)', S);
    fprintf('%-38s %12.2f\n',   '5.  Wing span b (ft)', b);
    fprintf('%-38s %12.1f\n',   '6.  Twist / washout (deg)', twist);
    fprintf('%-38s %12.3f\n',   '7.  Root chord c_r (ft)', c_r);
    fprintf('%-38s %12.3f\n',   '8.  Tip chord c_t (ft)', c_t);
    fprintf('%-38s %12.3f\n',   '9.  Mean aerodynamic chord MAC (ft)', MAC);
    fprintf('%-38s %12.3f\n',   '10. MAC spanwise location (ft)', y_MAC);
    fprintf('%-38s %12.1f\n',   '11. Wing twist (deg)', twist);
    fprintf('%-38s %12.1f\n',   '12. Wing incidence (deg)', incidence);
    fprintf('%-38s %12.1f\n',   '13. Dihedral angle (deg)', dihedral);
    fprintf('%-38s %12s\n',     '14. Wing vertical location', wing_loc);
    fprintf('%-38s %12s\n',     '15. Wing configuration', wing_cfg);
    fprintf('%-38s %12s\n',     '16. Wing tips', wing_tip);

    fprintf('\n--- AIRFOIL THICKNESS DETAILS ---\n');
    fprintf('%-38s %12.4f\n', 'Root t/c', tc_root);
    fprintf('%-38s %12.4f\n', 'Tip t/c', tc_tip);
    fprintf('%-38s %12.3f ft (%6.2f in)\n', 'Root thickness', t_root_ft, t_root_in);
    fprintf('%-38s %12.3f ft (%6.2f in)\n', 'Tip thickness',  t_tip_ft,  t_tip_in);
    fprintf('%-38s %12.3f ft^3\n', 'Approx. wing-box volume', V_wing);

    fprintf('\n-----------------------------------------------------\n');
    fprintf('Notes:\n');
    fprintf('  * Sweep, AR, and t/c are consistent with the reference aircraft\n');
    fprintf('    and the selected airfoil family.\n');
    fprintf('  * Wing area scaled by weight ratio W / W_ref = %.3f\n', W/W_ref);
    fprintf('  * MAC location measured from aircraft centerline.\n');
    fprintf('  * Refine with CFD/XFOIL at cruise Mach and Re before final layout.\n');
    fprintf('-----------------------------------------------------\n');
end

%% ==================== HELPER FUNCTIONS ====================

function val = get_input(prompt, default)
    str = input(sprintf('%s [%g]: ', prompt, default), 's');
    if isempty(str)
        val = default;
    else
        val = str2double(str);
        if isnan(val), val = default; end
    end
end

function str = get_input_str(prompt, default)
    str = input(sprintf('%s [%s]: ', prompt, default), 's');
    if isempty(str), str = default; end
end