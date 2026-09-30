clear; clc;

%% --- Lengths from Task 6 ---
L_sized  = 177.5;   % ft, from W0 = 431,849 lb
L_ref    = 193.9;   % ft, from W0 = 530,000 lb
L_actual = 209.1;   % ft, actual 777-200

%% --- Cabin layout (3-4-3 economy, 777-200 class) ---
layout.n_seats       = 10;
layout.seat_width    = 17.5;   % in
layout.armrest_width = 2.0;    % in
layout.n_aisles      = 2;
layout.aisle_width   = 20.0;   % in
layout.sidewall      = 6.0;    % in per side

%% --- Compute D and FR ---
[D1, FR1, cabin_w, info] = fuselage_diameter(L_sized,  layout);
[~,  FR2]                = fuselage_diameter(L_ref,    layout);
[~,  FR3]                = fuselage_diameter(L_actual, layout);

%% --- Report ---
fprintf('=== Fuselage Diameter and Fineness Ratio (cabin-layout method) ===\n\n');
fprintf('Cabin width (internal)   = %.2f in = %.3f ft\n', info.cabin_w_in, cabin_w);
fprintf('Sidewall (per side)      = %.2f in\n', layout.sidewall);
fprintf('External diameter D      = %.3f ft (%.3f m)\n\n', D1, D1*0.3048);

fprintf('%-30s %10s %10s %8s\n','Case','L [ft]','D [ft]','FR');
fprintf('%-30s %10s %10s %8s\n','----','------','------','--');
fprintf('%-30s %10.1f %10.2f %8.2f\n','Refined sizing (431,849 lb)', L_sized,  D1, FR1);
fprintf('%-30s %10.1f %10.2f %8.2f\n','Reference MTOW (530,000 lb)', L_ref,    D1, FR2);
fprintf('%-30s %10.1f %10.2f %8.2f\n','Actual 777-200',             L_actual, D1, FR3);

fprintf('\n=== Comparison with actual 777-200 ===\n');
fprintf('D (estimated / actual)   = %.2f / 20.30 ft   (%+.2f%%)\n', ...
    D1, 100*(D1 - 20.30)/20.30);