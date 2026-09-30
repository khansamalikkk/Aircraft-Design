function T = tail_geometry(S_w, MAC_w, L_fus, c_T, A_T, lambda_T, sweep_val_deg, ...
                           sweep_ref, tail_type, mount_type, L_fus_frac)
% sweep_ref : 'LE', 'c4', 'TE', or numeric chord fraction n (0=LE, 1=TE)

    if nargin < 9
        error('tail_geometry: too few inputs.');
    end

    % --- Tail arm ---
    if nargin >= 11 && ~isempty(L_fus_frac)
        frac = L_fus_frac;
    elseif isnumeric(mount_type)
        frac = mount_type;
    else
        switch lower(mount_type)
            case 'wing',      frac = 0.50;
            case 'nose',      frac = 0.60;
            case 'aft',       frac = 0.475;
            case 'sailplane', frac = 0.65;
            otherwise, error('Unknown mount_type.');
        end
    end
    L_T = frac * L_fus;

    % --- Tail area ---
    S_T = c_T * MAC_w * S_w / L_T;

    % --- Planform ---
    b_T  = sqrt(A_T * S_T);
    cr_T = 2*S_T / (b_T * (1 + lambda_T));
    ct_T = lambda_T * cr_T;
    MAC_T = (2/3) * cr_T * (1 + lambda_T + lambda_T^2) / (1 + lambda_T);
    k = 2 * (cr_T - ct_T) / b_T;

    % --- Sweep relations ---
    if isnumeric(sweep_ref)
        n_ref = sweep_ref;
    else
        switch upper(sweep_ref)
            case 'LE', n_ref = 0.0;
            case 'C4', n_ref = 0.25;
            case 'TE', n_ref = 1.0;
            otherwise, error('sweep_ref must be ''LE'',''c4'',''TE'' or numeric.');
        end
    end
    % tan(L_n) = tan(L_ref) + (n_ref - n)*k
    tan_ref = tand(sweep_val_deg);
    sweep.LE = atand(tan_ref + (n_ref - 0.0)*k);
    sweep.c4 = atand(tan_ref + (n_ref - 0.25)*k);
    sweep.TE = atand(tan_ref + (n_ref - 1.0)*k);
    sweep.ref_deg = sweep_val_deg;
    sweep.ref_name = sweep_ref;

    % --- Corner coordinates ---
    x_tip_LE = (b_T/2) * tand(sweep.LE);
    coords = [ 0,                 0;
               x_tip_LE,          b_T/2;
               x_tip_LE + ct_T,   b_T/2;
               cr_T,              0 ];

    % --- Pack ---
    T.S_T = S_T;  T.b_T = b_T;  T.cr_T = cr_T;  T.ct_T = ct_T;
    T.MAC_T = MAC_T;  T.L_T = L_T;  T.c_T = c_T;
    T.A_T = A_T;  T.lambda_T = lambda_T;  T.sweep = sweep;
    T.coords = coords;  T.tail_type = tail_type;
end