function airfoil_thickness()
    % Raymer Airfoil Thickness Ratio estimation
    % Based on historical trend (Fig. 4.14)
    % Uses design Mach number (maximum) from previous analysis.
    
    % Ask user for design Mach number (from previous step, e.g., cruise Mach)
    mach = input('Enter design Mach number (from previous code, e.g., cruise Mach): ');
    
    % Historical trend data points (Mach, t/c)
    % Approximated from Raymer Fig. 4.14
    mach_data = [0.0, 0.5, 0.8, 0.95,1, 1.5, 2.0, 3.0, 4.0];
    tc_data   = [0.156, 0.148, 0.14, 0.137,0.057, 0.047, 0.04, 0.037, 0.038];
    
    % Interpolate to get t/c for given Mach
    tc = interp1(mach_data, tc_data, mach, 'linear', 'extrap');
    
    % Check if supercritical airfoil is desired
    supercrit = input('Use supercritical airfoil? (y/n): ', 's');
    if strcmpi(supercrit, 'y')
        tc = tc * 1.1;
        fprintf('Supercritical airfoil selected: t/c increased by 10%%.\n');
    end
    
    % Output
    fprintf('\n--- Airfoil Thickness Ratio ---\n');
    fprintf('Design Mach number       = %.2f\n', mach);
    fprintf('Historical trend t/c     = %.3f (%.1f%%)\n', tc, tc*100);
    
    % Note on root and tip thickness variation
    fprintf('\nNote: For subsonic aircraft, root airfoil can be 20-60%% thicker than tip.\n');
    fprintf('For example, if tip t/c = %.3f, root t/c could be between %.3f and %.3f.\n', ...
            tc, tc*1.2, tc*1.6);
end