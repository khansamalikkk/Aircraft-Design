function [Wf_total, Wf_mission, Wfinal, Wseg, dfuel] = mission_fuel(W0, segments)
% mission_fuel  Compute fuel weight from a detailed mission profile.
%
% Inputs:
%   W0        : takeoff gross weight [lb]
%   segments  : struct array with fields:
%                 .name  : segment name (string)
%                 .WF    : weight fraction W_i/W_{i-1} for the segment
%                 .drop  : payload dropped during segment [lb] (0 if none)
%
% Outputs:
%   Wf_total    : total aircraft fuel (with 5% reserve + 1% trapped) [lb]
%   Wf_mission  : mission fuel burned [lb]
%   Wfinal      : weight at end of last segment [lb]
%   Wseg        : weight at start of each segment [lb]
%   dfuel       : fuel burned in each segment [lb]

    n = numel(segments);
    Wseg  = zeros(1, n);   % weight at start of each segment
    dfuel = zeros(1, n);   % fuel burned in each segment

    W = W0;                % current aircraft weight
    for i = 1:n
        Wseg(i) = W;

        % Fuel burned during this segment (Eq. 6.5)
        dfuel(i) = W * (1 - segments(i).WF);

        % Weight at end of segment
        W = W * segments(i).WF;

        % Any payload drop (weight removed instantly, no fuel)
        if isfield(segments,'drop') && ~isempty(segments(i).drop) ...
                && segments(i).drop ~= 0
            W = W - segments(i).drop;
        end
    end

    Wf_mission = sum(dfuel);          % Eq. 6.6
    Wf_total   = 1.06 * Wf_mission;   % Eq. 6.7
    Wfinal     = W;
end