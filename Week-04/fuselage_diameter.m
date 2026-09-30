function [D_ext, FR, cabin_w, info] = fuselage_diameter(L, layout, W0)
% fuselage_diameter  Estimate external fuselage diameter and fineness ratio.
%
% Method 1 (cabin layout) is used if 'layout' is provided.
% Method 2 (statistical) is used as a fallback / cross-check if W0 is given.
%
% Inputs:
%   L      : fuselage length [ft]
%   layout : struct with fields (all inches):
%              .n_seats        number of seats abreast
%              .seat_width     seat width
%              .armrest_width  armrest width
%              .n_aisles       number of aisles (1 or 2)
%              .aisle_width    aisle width
%              .sidewall       sidewall thickness (one side)
%            Pass [] to skip Method 1.
%   W0     : takeoff gross weight [lb] (optional, for Method 2)
%
% Outputs:
%   D_ext    : external fuselage diameter [ft]
%   FR       : fineness ratio L/D
%   cabin_w  : internal cabin width [ft]
%   info     : breakdown struct

    info = struct();

    % ---------- Method 1: cabin layout ----------
    if nargin >= 2 && ~isempty(layout)
        cabin_w_in = layout.n_seats * layout.seat_width ...
                   + (layout.n_seats - 1) * layout.armrest_width ...
                   + layout.n_aisles * layout.aisle_width;

        cabin_w = cabin_w_in / 12;                       % ft
        D_ext   = cabin_w + 2 * layout.sidewall / 12;    % ft

        info.method     = 'cabin layout';
        info.cabin_w_in = cabin_w_in;
        info.layout     = layout;
    else
        % ---------- Method 2: statistical ----------
        if nargin < 3 || isempty(W0)
            error('Provide either a layout struct or W0 for statistical estimate.');
        end
        D_ext   = 0.090 * W0^0.45;
        cabin_w = D_ext - 1.0;                           % assume 1 ft total wall
        info.method = 'statistical';
    end

    FR = L / D_ext;
    info.D_ext = D_ext;
    info.FR    = FR;
end