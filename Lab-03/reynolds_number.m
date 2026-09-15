function reynolds_number()
    % Raymer conceptual design: Reynolds number at 3 altitudes
    %
    % Re = (rho * V * c) / mu
    %
    % Uses:
    %   mach   = cruise Mach (from previous analysis)
    %   c_MAC  = mean aerodynamic chord, ft (from previous analysis)
    %   alt    = 3 altitudes, ft (user input)
    %
    % For your case:
    %   mach  = 0.84
    %   c_MAC = 24.22 ft
    %   altitudes = [30000, 35000, 40000] ft

    % ISA constants
    RHO0  = 0.0023769;   % slug/ft^3
    T0    = 518.67;      % Rankine
    L     = 0.00356616;  % R/ft
    R     = 1716.5;      % ft*lb/(slug*R)
    GAMMA = 1.4;
    G     = 32.174;
    MU0   = 3.737e-7;    % slug/(ft*s), sea-level viscosity
    T_REF = 518.67;      % Rankine, Sutherland reference
    SUTH  = 198.72;      % Rankine, Sutherland constant

    % -------- User inputs --------
    mach  = input('Cruise Mach [e.g. 0.84]: ');
    c_MAC = input('Mean aerodynamic chord MAC (ft) [e.g. 24.22]: ');

    fprintf('\nEnter 3 altitudes (ft):\n');
    alt1 = input('  Altitude 1 [e.g. 30000]: ');
    alt2 = input('  Altitude 2 [e.g. 35000]: ');
    alt3 = input('  Altitude 3 [e.g. 40000]: ');
    alts = [alt1, alt2, alt3];

    % -------- Loop over altitudes --------
    fprintf('\n--- Reynolds Number Results ---\n');
    fprintf('Cruise Mach          = %.2f\n', mach);
    fprintf('MAC                  = %.2f ft\n\n', c_MAC);
    fprintf('%10s %12s %12s %12s %14s\n', ...
            'Alt (ft)', 'rho', 'T (R)', 'V (ft/s)', 'Re');
    fprintf('%10s %12s %12s %12s %14s\n', ...
            '--------', '----------', '----------', '----------', '-------------');

    for i = 1:3
        alt_ft = alts(i);

        T   = isa_temperature(alt_ft, T0, L);
        rho = isa_density(alt_ft, RHO0, T0, L, R, G);
        mu  = sutherland_mu(T, MU0, T_REF, SUTH);
        V   = mach_to_ft_s(mach, alt_ft, T0, L, R, GAMMA);
        Re  = (rho * V * c_MAC) / mu;

        fprintf('%10.0f %12.8f %12.2f %12.2f %14.3e\n', ...
                alt_ft, rho, T, V, Re);
    end
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

function mu = sutherland_mu(T, MU0, T_REF, SUTH)
    % Sutherland's law for dynamic viscosity
    mu = MU0 * (T / T_REF)^1.5 * (T_REF + SUTH) / (T + SUTH);
end

function V = mach_to_ft_s(mach, alt_ft, T0, L, R, GAMMA)
    T = isa_temperature(alt_ft, T0, L);
    a = sqrt(GAMMA * R * T);
    V = mach * a;
end