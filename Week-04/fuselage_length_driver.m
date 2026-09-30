% fuselage_length_driver.m
clear; clc;

% --- Two candidate takeoff weights ---
W0_sized    = 431849;    % lb, from refined sizing (Task 4)
W0_ref      = 530000;    % lb, reference MTOW

% --- Raymer Table 6.3, jet transport ---
[L_sized, coef] = fuselage_length('jet transport', W0_sized, 'lb');
[L_ref,   ~   ] = fuselage_length('jet transport', W0_ref,   'lb');

% --- Actual aircraft ---
L_actual_ft = 209 + 1/12;   % 209 ft 1 in

fprintf('=== Raymer Table 6.3  Fuselage Length (jet transport) ===\n');
fprintf('Coefficients: a = %.2f ft, C = %.2f\n\n', coef(1), coef(2));

fprintf('%-28s %12s %14s\n','Case','W0 [lb]','Length [ft]');
fprintf('%-28s %12s %14s\n','----','-------','-----------');
fprintf('%-28s %12.0f %14.1f\n','Refined sizing W0',   W0_sized, L_sized);
fprintf('%-28s %12.0f %14.1f\n','Reference MTOW',      W0_ref,   L_ref);
fprintf('%-28s %12s %14.1f\n','Actual 777-200',       '530000', L_actual_ft);

fprintf('\n=== Error vs Actual ===\n');
fprintf('Refined sizing case: %+6.2f%%\n', 100*(L_sized  - L_actual_ft)/L_actual_ft);
fprintf('Reference MTOW case: %+6.2f%%\n', 100*(L_ref    - L_actual_ft)/L_actual_ft);