function W = wing_geometry(W0, W_S, A, lambda, sweep_c4_deg, sweep_ref)
% wing_geometry  Raymer trapezoidal wing planform layout.
%
% Inputs:
%   W0          : takeoff gross weight [lb]
%   W_S         : wing loading W0/S [lb/ft^2]
%   A           : aspect ratio [-]
%   lambda      : taper ratio ct/cr [-]
%   sweep_c4_deg: quarter-chord sweep [deg]
%   sweep_ref   : (optional) reference point: 'c4' (default), 'LE', or 'TE'
%
% Outputs (struct W):
%   S, b, cr, ct, MAC, y_MAC
%   sweep.LE, sweep.c4, sweep.TE  [deg]
%   sweep.half                    [deg] (50% chord)
%   coords  : 4x2 matrix [x,y] of wing planform corners (ft)
%             rows = root LE, tip LE, tip TE, root TE

    if nargin < 6, sweep_ref = 'c4'; end

    % --- 1. Wing reference area ---
    S = W0 / W_S;

    % --- 2. Span ---
    b = sqrt(A * S);

    % --- 3. Root and tip chord ---
    cr = 2*S / (b * (1 + lambda));
    ct = lambda * cr;

    % --- 4. Mean aerodynamic chord ---
    MAC = (2/3) * cr * (1 + lambda + lambda^2) / (1 + lambda);

    % --- 5. Spanwise location of MAC ---
    y_MAC = (b/6) * (1 + 2*lambda) / (1 + lambda);

    % --- 6. Sweep relations ---
    % tan(L_n) = tan(L_c4) + (0.25 - n)*2*(cr - ct)/b
    k = 2 * (cr - ct) / b;
    switch upper(sweep_ref)
        case 'C4'
            tc4 = tand(sweep_c4_deg);
        case 'LE'
            tc4 = tand(sweep_c4_deg) - 0.5*k;
        case 'TE'
            tc4 = tand(sweep_c4_deg) + 1.5*k;
        otherwise
            error('sweep_ref must be ''c4'', ''LE'', or ''TE''.');
    end
    sweep.c4   = atand(tc4);
    sweep.LE   = atand(tc4 + 0.5*k);
    sweep.TE   = atand(tc4 - 1.5*k);
    sweep.half = atand(tc4 + (0.25-0.5)*k);   % n = 0.5

    % --- 7. Planform corner coordinates (half-wing, y from centerline) ---
    %    x measured from root LE (aft positive)
    x_root_LE = 0;
    x_tip_LE  = (b/2) * tand(sweep.LE);
    coords = [ x_root_LE,            0;         % root LE
               x_tip_LE,             b/2;       % tip LE
               x_tip_LE + ct,        b/2;       % tip TE
               x_root_LE + cr,       0     ];   % root TE

    % --- Pack results ---
    W.S      = S;
    W.b      = b;
    W.cr     = cr;
    W.ct     = ct;
    W.lambda = lambda;
    W.A      = A;
    W.MAC    = MAC;
    W.y_MAC  = y_MAC;
    W.sweep  = sweep;
    W.coords = coords;
    W.W0     = W0;
    W.W_S    = W_S;
end