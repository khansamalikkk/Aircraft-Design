% Boeing 777-200 class reference aircraft
W0 = 530000;              % lb, given takeoff gross weight

span = 199 + 11/12;       % ft, Boeing 777-200 wingspan
S = 4605;                 % ft^2, wing area
A = span^2 / S;           % aspect ratio

T_total = 2 * 77000;      % lb, two 77,000 lbf engines
T_W = T_total / W0;       % takeoff thrust-to-weight ratio
W_S = W0 / S;             % wing loading, lb/ft^2

Mmax = 0.89;              % max Mach number
% If your lab uses cruise Mach instead, use Mmax = 0.84;

Kvs = 1.00;               % fixed sweep wing

[We_W0, We] = empty_weight_fraction('jet transport', W0, A, T_W, W_S, Mmax, Kvs);

fprintf('Aspect ratio A       = %.3f\n', A);
fprintf('Thrust/Weight T/W0   = %.4f\n', T_W);
fprintf('Wing loading W0/S    = %.2f lb/ft^2\n', W_S);
fprintf('Empty weight fraction We/W0 = %.4f\n', We_W0);
fprintf('Empty weight We      = %.0f lb\n', We);