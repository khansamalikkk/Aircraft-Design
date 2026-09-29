function [We_W0, We, coef] = empty_weight_fraction(ac_type, W0, A, T_W, W_S, Mmax, Kvs)
% empty_weight_fraction  Raymer Table 6.1 empty-weight fraction for jet aircraft
%
% Inputs:
%   ac_type : 'jet trainer', 'jet fighter',
%             'military cargo/bomber', or 'jet transport'
%   W0      : takeoff gross weight [lb]
%   A       : aspect ratio [-]
%   T_W     : thrust-to-weight ratio T_total/W0 [-]
%   W_S     : wing loading W0/S [lb/ft^2]
%   Mmax    : maximum Mach number [-]
%   Kvs     : variable-sweep constant
%             1.04 for variable sweep, 1.00 for fixed sweep
%
% Outputs:
%   We_W0   : empty-weight fraction We/W0
%   We      : empty weight [lb]
%   coef    : coefficients used [a b C1 C2 C3 C4 C5]

    if nargin < 7 || isempty(Kvs)
        Kvs = 1.00;
    end

    key = lower(strtrim(ac_type));
    key = strrep(key, ' ', '_');
    key = strrep(key, '/', '_');

    switch key
        case {'jet_trainer','jettrainer'}
            coef = [0.00, 4.28, -0.10, 0.10, 0.20, -0.24, 0.11];

        case {'jet_fighter','jetfighter'}
            coef = [-0.02, 2.16, -0.10, 0.20, 0.04, -0.10, 0.08];

        case {'military_cargo_bomber','military_cargo','bomber'}
            coef = [0.07, 1.71, -0.10, 0.10, 0.06, -0.10, 0.05];

        case {'jet_transport','jettransport'}
            coef = [0.32, 0.66, -0.13, 0.30, 0.06, -0.05, 0.05];

        otherwise
            error(['Unknown aircraft type. Use: jet trainer, jet fighter, ' ...
                   'military cargo/bomber, or jet transport.']);
    end

    a  = coef(1);
    b  = coef(2);
    C1 = coef(3);
    C2 = coef(4);
    C3 = coef(5);
    C4 = coef(6);
    C5 = coef(7);

    We_W0 = a + b * W0^C1 * A^C2 * T_W^C3 * W_S^C4 * Mmax^C5 * Kvs;
    We = We_W0 * W0;
end

