clear; clc;

%% --- Takeoff gross weight ---
W0 = 530000;             % lb

%% --- Cruise / loiter parameters ---
Range_nmi   = 5240;                       % design range [nmi]
Range_ft    = Range_nmi * 6076.12;        % [ft]

Cruise_Alt  = 35000;                      % [ft]
Cruise_Mach = 0.84;

% Speed of sound at altitude (ISA)
[~, a_cruise, ~, ~] = atmosisa(Cruise_Alt * 0.3048);   % m/s
V_cruise    = Cruise_Mach * a_cruise * 3.28084;        % ft/s

SFC_cruise  = 0.55;        % [1/hr]
LD_cruise   = 17.5;

Loiter_hr   = 0.5;         % 30 min reserve loiter
SFC_loiter  = 0.55;
LD_loiter   = 15.0;

%% --- Segment weight fractions ---
WF_taxi    = 0.970;   % start, warm-up, taxi-out
WF_climb   = 0.985;   % climb
WF_cruise  = exp(-Range_ft * SFC_cruise / (V_cruise * LD_cruise));
WF_descent = 0.985;   % descent, approach, land, taxi-in
WF_loiter  = exp(-Loiter_hr * SFC_loiter / LD_loiter);

%% --- Build mission profile ---
segments = struct( ...
    'name', {'Start/Taxi', 'Climb', 'Cruise', 'Descent/Land/Taxi', 'Loiter'}, ...
    'WF',   {WF_taxi, WF_climb, WF_cruise, WF_descent, WF_loiter}, ...
    'drop', {0, 0, 0, 0, 0} );

%% --- Compute fuel ---
[Wf_total, Wf_mission, Wfinal, Wseg, dfuel] = mission_fuel(W0, segments);

%% --- Print results ---
fprintf('=== Mission Fuel Calculation (Boeing 777-200 class) ===\n');
fprintf('Takeoff gross weight W0            = %10.0f lb\n', W0);
fprintf('Cruise speed                       = %10.1f ft/s\n', V_cruise);
fprintf('Cruise segment weight fraction     = %10.4f\n', WF_cruise);
fprintf('Loiter segment weight fraction     = %10.4f\n', WF_loiter);
fprintf('\n--- Segment breakdown ---\n');
fprintf('%-22s %10s %12s %12s\n','Segment','Start W','Fuel burned','End W');
W = W0;
for i = 1:numel(segments)
    Wend = W * segments(i).WF - segments(i).drop;
    fprintf('%-22s %10.0f %12.0f %12.0f\n', ...
        segments(i).name, W, dfuel(i), Wend);
    W = Wend;
end

fprintf('\n--- Totals ---\n');
fprintf('Mission fuel burned  Wf_mission   = %10.0f lb\n', Wf_mission);
fprintf('Total aircraft fuel  Wf (1.06x)   = %10.0f lb\n', Wf_total);
fprintf('Weight at end of mission          = %10.0f lb\n', Wfinal);
fprintf('Mission fuel fraction  Wf/W0      = %10.4f\n', Wf_total/W0);