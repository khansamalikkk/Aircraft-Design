function design_lift_coefficient()
    % Raymer conceptual design:
    % CL = W / (q*S) = (W/S) / q
    %
    % User inputs:
    %   W        = aircraft weight, lb
    %   category = aircraft category (from Table 5.5)
    %   alt_ft   = cruise altitude, ft
    %   mach     = cruise Mach number
    %
    % For now, use cruise altitude and Mach from the reference aircraft
    % whose weight is closest to yours.
    %
    % Example for W = 530000 lb:
    %   Reference aircraft: Boeing 777-200 (MTOW ~ 545000 lb)
    %   Cruise altitude ~ 35000 ft
    %   Cruise Mach     ~ 0.84

    % ISA constants
    RHO0  = 0.0023769;   % slug/ft^3, sea level density
    T0    = 518.67;      % Rankine, sea level temperature
    L     = 0.00356616;  % R/ft, lapse rate
    R     = 1716.5;      % ft*lb/(slug*R)
    GAMMA = 1.4;
    G     = 32.174;

    % -------- User inputs --------
    W = input('Aircraft weight (lb): ');
    category = input(['Category (sailplane/homebuilt/ga_single/ga_twin/' ...
                      'twin_turboprop/jet_trainer/jet_fighter/jet_transport): '], 's');
    category = lower(strtrim(category));

    alt_ft = input('Cruise altitude (ft) [reference aircraft]: ');
    mach   = input('Cruise Mach [reference aircraft]: ');

    % -------- Table 5.5 Wing loading values (lb/ft^2) --------
    switch category
        case 'sailplane'
            ws = 6;
        case 'homebuilt'
            ws = 11;
        case 'ga_single'
            ws = 17;
        case 'ga_twin'
            ws = 26;
        case 'twin_turboprop'
            ws = 40;
        case 'jet_trainer'
            ws = 50;
        case 'jet_fighter'
            ws = 70;
        case 'jet_transport'
            ws = 120;
        otherwise
            fprintf('Category not found. Enter W/S manually.\n');
            ws = input('Wing loading W/S (lb/ft^2): ');
    end

    % -------- Wing area from assumed wing loading --------
    S = W / ws;   % ft^2

    % -------- Flight conditions --------
    rho = isa_density(alt_ft, RHO0, T0, L, R, G);
    V   = mach_to_ft_s(mach, alt_ft, T0, L, R, GAMMA);
    q   = 0.5 * rho * V^2;

    % -------- Design lift coefficient --------
    CL = W / (q * S);

    % -------- Output --------
    fprintf('\n--- Results ---\n');
    fprintf('Weight W              = %.0f lb\n', W);
    fprintf('Category              = %s\n', category);
    fprintf('Assumed W/S           = %.1f lb/ft^2\n', ws);
    fprintf('Estimated wing area S = %.1f ft^2\n', S);
    fprintf('Cruise Mach           = %.2f\n', mach);
    fprintf('Cruise altitude       = %.0f ft\n', alt_ft);
    fprintf('Density rho           = %.8f slug/ft^3\n', rho);
    fprintf('True airspeed V       = %.1f ft/s = %.1f kts\n', V, V/1.68781);
    fprintf('Dynamic pressure q    = %.1f lb/ft^2\n', q);
    fprintf('Design lift coeff CL  = %.3f\n', CL);
end

function T = isa_temperature(alt_ft, T0, L)
    if alt_ft <= 36089
        T = T0 - L * alt_ft;
    else
        T = 389.97;
    end
end

function rho = isa_density(alt_ft, RHO0, T0, L, R, G)
    if alt_ft <= 36089
        T = isa_temperature(alt_ft, T0, L);
        theta = T / T0;
        rho = RHO0 * theta^4.2561;
    else
        T = 389.97;
        theta = T / T0;
        delta_trop = theta^5.2561;
        H = R * T / G;
        delta = delta_trop * exp(-(alt_ft - 36089) / H);
        rho = RHO0 * delta / theta;
    end
end

function V = mach_to_ft_s(mach, alt_ft, T0, L, R, GAMMA)
    T = isa_temperature(alt_ft, T0, L);
    a = sqrt(GAMMA * R * T);
    V = mach * a;
end