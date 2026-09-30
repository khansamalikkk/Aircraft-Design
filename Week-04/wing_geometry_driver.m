% wing_geometry_driver.m
clear; clc;

%% --- Shared design parameters (from Tasks 4-7) ---
W_S_ref = 530000 / 4605;   % reference wing loading = 115.09 lb/ft^2
A       = 8.679;           % aspect ratio
lambda  = 0.20;            % taper ratio (typical transport 0.15-0.25)
sweep_c4 = 31.6;           % quarter-chord sweep [deg] (777-200)

%% --- Case 1: refined sizing W0 ---
W0_refined = 431849;
W1 = wing_geometry(W0_refined, W_S_ref, A, lambda, sweep_c4, 'c4');

%% --- Case 2: reference MTOW ---
W0_reference = 530000;
W2 = wing_geometry(W0_reference, W_S_ref, A, lambda, sweep_c4, 'c4');

%% --- Case 3: actual 777-200 ---
S_actual   = 4605;
b_actual   = 199.917;      % 199 ft 11 in
cr_actual  = 2*S_actual/(b_actual*(1+lambda));
W3 = wing_geometry(530000, 530000/S_actual, A, lambda, sweep_c4, 'c4');

%% --- Report ---
fprintf('=== WING PLANFORM GEOMETRY ===\n');
fprintf('Inputs: A = %.3f, lambda = %.2f, sweep(c/4) = %.1f deg, W/S = %.2f lb/ft^2\n\n', ...
    A, lambda, sweep_c4, W_S_ref);

fprintf('%-30s %12s %12s %12s\n','Quantity','Refined','RefMTOW','Actual777');
fprintf('%-30s %12s %12s %12s\n','--------','-------','-------','---------');
fprintf('%-30s %12.1f %12.1f %12.1f\n','W0 [lb]',           W1.W0,   W2.W0,   W3.W0);
fprintf('%-30s %12.1f %12.1f %12.1f\n','Wing area S [ft^2]',W1.S,    W2.S,    W3.S);
fprintf('%-30s %12.2f %12.2f %12.2f\n','Span b [ft]',       W1.b,    W2.b,    W3.b);
fprintf('%-30s %12.2f %12.2f %12.2f\n','Root chord cr [ft]',W1.cr,   W2.cr,   W3.cr);
fprintf('%-30s %12.2f %12.2f %12.2f\n','Tip chord ct [ft]', W1.ct,   W2.ct,   W3.ct);
fprintf('%-30s %12.2f %12.2f %12.2f\n','MAC [ft]',          W1.MAC,  W2.MAC,  W3.MAC);
fprintf('%-30s %12.2f %12.2f %12.2f\n','y_MAC [ft]',        W1.y_MAC,W2.y_MAC,W3.y_MAC);
fprintf('%-30s %12.2f %12.2f %12.2f\n','Sweep LE [deg]',    W1.sweep.LE, W2.sweep.LE, W3.sweep.LE);
fprintf('%-30s %12.2f %12.2f %12.2f\n','Sweep c/4 [deg]',   W1.sweep.c4, W2.sweep.c4, W3.sweep.c4);
fprintf('%-30s %12.2f %12.2f %12.2f\n','Sweep TE [deg]',    W1.sweep.TE, W2.sweep.TE, W3.sweep.TE);

fprintf('\n--- Half-wing corner coordinates (x from root LE, y from CL) ---\n');
fprintf('%-16s %12s %12s\n','Corner','x [ft]','y [ft]');
lbl = {'Root LE','Tip LE','Tip TE','Root TE'};
for i = 1:4
    fprintf('%-16s %12.2f %12.2f\n', lbl{i}, W1.coords(i,1), W1.coords(i,2));
end

%% --- Quick planform plot (half wing) ---
figure('Color','w'); hold on; axis equal; grid on;
plot(W1.coords(:,1), W1.coords(:,2), '-k','LineWidth',1.5);
plot(W1.coords(:,1), -W1.coords(:,2), '-k','LineWidth',1.5);
plot([W1.coords(1,1) W1.coords(4,1)],[0 0],'k-');
xlabel('x [ft] (aft from root LE)'); ylabel('y [ft] (from centerline)');
title(sprintf('Wing Planform: S=%.0f ft^2, b=%.1f ft, MAC=%.2f ft', W1.S, W1.b, W1.MAC));