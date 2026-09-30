function [L, coef] = fuselage_length(ac_type, W0, units)
% fuselage_length  Raymer Table 6.3 statistical fuselage length.
%
% Inputs:
%   ac_type : aircraft category string (see switch below)
%   W0      : takeoff gross weight (lb if units='lb', kg if units='kg')
%   units   : 'lb' (default) or 'kg'
%
% Outputs:
%   L       : fuselage length (ft if units='lb', m if units='kg')
%   coef    : [a, C] actually used
%
% Note: Raymer Table 6.3 is Length = a * W0^C.

    if nargin < 3, units = 'lb'; end

    key = lower(strtrim(ac_type));
    key = strrep(key, ' ', '_');
    key = strrep(key, '/', '_');
    key = strrep(key, '-', '_');

    switch key
        case {'sailplane_unpowered','sailplane_unpowered '}
            coef = [0.86, 0.48];
        case {'sailplane_powered'}
            coef = [0.71, 0.48];
        case {'homebuilt_metal_wood','homebuilt_metal','homebuilt_wood'}
            coef = [3.68, 0.23];
        case {'homebuilt_composite'}
            coef = [3.50, 0.23];
        case {'general_aviation_single_engine','ga_single'}
            coef = [4.37, 0.23];
        case {'general_aviation_twin_engine','ga_twin'}
            coef = [0.86, 0.42];
        case {'agricultural_aircraft','agricultural'}
            coef = [4.04, 0.23];
        case {'twin_turboprop'}
            coef = [0.37, 0.51];
        case {'flying_boat'}
            coef = [1.05, 0.40];
        case {'jet_trainer'}
            coef = [0.79, 0.41];
        case {'jet_fighter'}
            coef = [0.93, 0.39];
        case {'military_cargo_bomber','military_cargo','bomber'}
            coef = [0.23, 0.50];
        case {'jet_transport'}
            coef = [0.67, 0.43];
        otherwise
            error('Unknown aircraft type for Table 6.3.');
    end

    % Convert to metric coefficients if requested
    if strcmpi(units,'kg')
        a_metric = containers.Map( ...
            {'sailplane_unpowered','sailplane_powered', ...
             'homebuilt_metal_wood','homebuilt_composite', ...
             'general_aviation_single_engine','general_aviation_twin_engine', ...
             'agricultural_aircraft','twin_turboprop','flying_boat', ...
             'jet_trainer','jet_fighter','military_cargo_bomber','jet_transport'}, ...
            {0.383, 0.316, 1.35, 1.28, 1.6, 0.366, 1.48, 0.169, ...
             0.439, 0.333, 0.389, 0.104, 0.287});
        if isKey(a_metric, key)
            coef(1) = a_metric(key);
        end
    end

    a = coef(1);
    C = coef(2);
    L = a * W0^C;
end