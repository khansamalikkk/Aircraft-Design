% HT_sizing_driver.m  -- fixed
clear; clc;

%% --- Wing/fuselage data from previous tasks ---
cases = struct( ...
  'name',  {'Refined',   'RefMTOW',  'Actual777'}, ...
  'W0',    {431849,       530000,     530000}, ...
  'S_w',   {3752.2,       4605.0,     4605.0}, ...
  'MAC_w', {23.87,        26.45,      26.45}, ...
  'L_fus', {177.5,        193.9,      209.1} );

%% --- HT design parameters ---
c_HT         = 1.00;
A_HT         = 4.00;
lambda_HT    = 0.35;
sweep_HT     = 30.0;    % degrees
sweep_ref_HT = 'c4';    % anchor at quarter-chord
mount        = 'wing';  % L_HT = 0.50 * L_fus

%% --- Report header ---
fprintf('=== HORIZONTAL TAIL SIZING (Raymer Volume-Coefficient Method) ===\n');
fprintf('c_HT = %.2f, A_HT = %.2f, lambda_HT = %.2f, sweep(%s) = %.1f deg\n', ...
    c_HT, A_HT, lambda_HT, sweep_ref_HT, sweep_HT);
fprintf('Tail arm L_HT = 0.50 * L_fus (wing-mounted engines)\n\n');

fprintf('%-14s %10s %10s %10s %10s %10s %10s\n', ...
    'Case','L_fus[ft]','L_HT[ft]','S_HT[ft^2]','b_HT[ft]','cr_HT[ft]','ct_HT[ft]');
fprintf('%-14s %10s %10s %10s %10s %10s %10s\n', ...
    '----','---------','---------','---------','--------','--------','--------');

T_ref = [];
for k = 1:numel(cases)
    c = cases(k);
    T = tail_geometry(c.S_w, c.MAC_w, c.L_fus, c_HT, A_HT, lambda_HT, ...
                      sweep_HT, sweep_ref_HT, 'HT', mount);

    fprintf('%-14s %10.1f %10.2f %10.1f %10.2f %10.2f %10.2f\n', ...
        c.name, c.L_fus, T.L_T, T.S_T, T.b_T, T.cr_T, T.ct_T);

    if strcmp(c.name,'RefMTOW')
        T_ref = T;
    end
end

%% --- Detailed report for the reference case ---
fprintf('\n--- Detailed HT geometry (RefMTOW case) ---\n');
fprintf('S_HT          = %7.2f ft^2\n',  T_ref.S_T);
fprintf('Span b_HT     = %7.2f ft\n',    T_ref.b_T);
fprintf('Root chord    = %7.2f ft\n',    T_ref.cr_T);
fprintf('Tip chord     = %7.2f ft\n',    T_ref.ct_T);
fprintf('MAC_HT        = %7.2f ft\n',    T_ref.MAC_T);
fprintf('Sweep LE      = %7.2f deg\n',   T_ref.sweep.LE);
fprintf('Sweep c/4     = %7.2f deg\n',   T_ref.sweep.c4);
fprintf('Sweep TE      = %7.2f deg\n',   T_ref.sweep.TE);
fprintf('Aspect ratio check   = %7.3f\n', T_ref.b_T^2 / T_ref.S_T);
fprintf('Taper ratio check    = %7.3f\n', T_ref.ct_T / T_ref.cr_T);

%% --- Comparison with actual 777-200 ---
fprintf('\n=== COMPARISON WITH ACTUAL 777-200 ===\n');
S_HT_actual = 1241;
b_HT_actual = 70.67;
fprintf('Actual S_HT   = %7.1f ft^2\n', S_HT_actual);
fprintf('Actual b_HT   = %7.2f ft\n',   b_HT_actual);
fprintf('Raymer S_HT   = %7.1f ft^2   (%+6.1f%%)\n', ...
    T_ref.S_T, 100*(T_ref.S_T-S_HT_actual)/S_HT_actual);
fprintf('Raymer b_HT   = %7.2f ft   (%+6.1f%%)\n', ...
    T_ref.b_T, 100*(T_ref.b_T-b_HT_actual)/b_HT_actual);