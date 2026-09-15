function wing_chords()
    % Raymer conceptual design: wing root chord, tip chord,
    % mean geometric chord, and mean aerodynamic chord (MAC)
    %
    % Uses trapezoidal wing assumption.
    %
    % Inputs:
    %   S      = wing planform area, ft^2
    %   b      = wing span, ft
    %   lambda = taper ratio = c_t / c_r
    %
    % For your previous case:
    %   W = 530000 lb
    %   W/S = 120 lb/ft^2  -> S = 4416.7 ft^2
    %   Reference aircraft: Boeing 777-200
    %   b ~ 199.9 ft
    %   lambda ~ 0.30 (typical for jet transport)

    % -------- User inputs --------
    S = input('Wing planform area S (ft^2) [e.g. 4416.7]: ');
    b = input('Wing span b (ft) [e.g. 199.9]: ');
    lambda = input('Taper ratio lambda = c_t/c_r [e.g. 0.30]: ');

    % -------- Chord calculations --------
    c_r = 2 * S / (b * (1 + lambda));          % root chord, ft
    c_t = lambda * c_r;                        % tip chord, ft
    c_mean_geo = S / b;                        % mean geometric chord, ft
    c_MAC = (2/3) * c_r * (1 + lambda + lambda^2) / (1 + lambda);  % MAC, ft

    % -------- Output --------
    fprintf('\n--- Wing Chord Results ---\n');
    fprintf('Wing area S                 = %.1f ft^2\n', S);
    fprintf('Wing span b                 = %.1f ft\n', b);
    fprintf('Taper ratio lambda          = %.3f\n', lambda);
    fprintf('Root chord c_r              = %.2f ft\n', c_r);
    fprintf('Tip chord c_t               = %.2f ft\n', c_t);
    fprintf('Mean geometric chord S/b    = %.2f ft\n', c_mean_geo);
    fprintf('Mean aerodynamic chord MAC  = %.2f ft\n', c_MAC);
end