% run_sizing_777.m  -- CORRECTED driver for size_aircraft.m
clear; clc;

%% --- Reference aircraft: Boeing 777-200 class ---
span    = 199 + 11/12;      % ft
S       = 4605;             % ft^2
A       = span^2 / S;

W0_ref  = 530000;           % lb
T_total = 2 * 77000;        % lb
T_W     = T_total / W0_ref;
W_S     = W0_ref / S;
Mmax    = 0.89;
Kvs     = 1.00;

%% --- Crew & payload ---
Wcrew    = 2 * 205;                 % lb
n_pax    = 305;
Wpayload = n_pax * (175 + 50);      % lb

%% --- Mission profile (UNITS EXPLICIT) ---
cfg.Wcrew        = Wcrew;
cfg.Wpayload     = Wpayload;
cfg.Range_nmi    = 5240;

cfg.Cruise_Alt   = 35000;           % ft
cfg.Cruise_Mach  = 0.84;

%  SFC input in 1/hr (typical turbofan), convert to 1/s inside
cfg.SFC_cruise_hr = 0.55;           % 1/hr
cfg.LD_cruise     = 17.5;

cfg.Loiter_hr     = 0.5;            % hr
cfg.SFC_loiter_hr = 0.55;           % 1/hr
cfg.LD_loiter     = 15.0;

% ---- UNIT CONVERSION ----
cfg.SFC_cruise = cfg.SFC_cruise_hr / 3600;   % <<< THE FIX (1/hr -> 1/s)
cfg.SFC_loiter = cfg.SFC_loiter_hr / 3600;   % <<< THE FIX

%% --- Geometry / aero for Table 6.1 empty-weight eq ---
cfg.A      = A;
cfg.T_W    = T_W;
cfg.W_S    = W_S;
cfg.Mmax   = Mmax;
cfg.Kvs    = Kvs;
cfg.ac_type = 'jet transport';
cfg.W0_guess = 500000;
cfg.verbose  = true;

%% --- Run sizing ---
results = size_aircraft(cfg);

%% --- Report ---
fprintf('\n=== SIZING RESULTS (Boeing 777-200 class) ===\n');
fprintf('Converged W0     = %10.0f lb\n', results.W0);
fprintf('Empty weight We  = %10.0f lb\n', results.We);
fprintf('Total fuel Wf    = %10.0f lb\n', results.Wf);
fprintf('We/W0            = %10.4f\n', results.We_W0);
fprintf('Wf/W0            = %10.4f\n', results.Wf_W0);
fprintf('Iterations       = %10d\n', results.iter);

fprintf('\n=== COMPARISON ===\n');
fprintf('Reference W0     = %10.0f lb\n', W0_ref);
fprintf('Calculated W0    = %10.0f lb\n', results.W0);
fprintf('Difference       = %10.0f lb (%.2f%%)\n', ...
    results.W0 - W0_ref, 100*(results.W0 - W0_ref)/W0_ref);