% Mission Profile Specification for Boeing 777-200 Class
% Aircraft Design Lab

clear; clc;

%% --- Mission Parameters ---
Range_nmi   = 5240;          % Design range [nmi]
Range_ft    = Range_nmi * 6076.12;  % Convert to feet

Cruise_Alt  = 35000;         % Cruise altitude [ft]
Cruise_Mach = 0.84;          % Cruise Mach number

% Standard atmosphere at cruise altitude
[~, a_cruise, ~, ~] = atmosisa(Cruise_Alt * 0.3048);  % a in m/s
V_cruise    = Cruise_Mach * a_cruise * 3.28084;       % Cruise speed [ft/s]

SFC_cruise  = 0.55;          % Specific fuel consumption [1/hr]
LD_cruise   = 17.5;          % Cruise lift-to-drag ratio

Loiter_Time = 0.5;           % Loiter time [hr]
SFC_loiter  = 0.55;          % SFC during loiter [1/hr]
LD_loiter   = 15.0;          % Loiter L/D

%% --- Mission Segment Weight Fractions ---
% 1. Start, Warm-up & Taxi
WF_taxi = 0.970;

% 2. Takeoff & Acceleration (included in taxi fraction)

% 3. Climb
WF_climb = 0.985;

% 4. Cruise (Breguet Range Equation)
WF_cruise = exp(-Range_ft * SFC_cruise / (V_cruise * LD_cruise));

% 5. Descent
WF_descent = 0.985;

% 6. Loiter / Reserves
WF_loiter = exp(-Loiter_Time * SFC_loiter / LD_loiter);

% 7. Landing, Taxi & Shutdown (included in descent fraction)

%% --- Total Mission Weight Fraction ---
WF_total = WF_taxi * WF_climb * WF_cruise * WF_descent * WF_loiter;

%% --- Display Results ---
fprintf('=== Mission Profile Results ===\n');
fprintf('Design Range: %.0f nmi (%.0f ft)\n', Range_nmi, Range_ft);
fprintf('Cruise Altitude: %.0f ft\n', Cruise_Alt);
fprintf('Cruise Mach: %.2f\n', Cruise_Mach);
fprintf('Cruise Speed: %.0f ft/s\n', V_cruise);
fprintf('\n--- Segment Weight Fractions ---\n');
fprintf('Taxi:      %.4f\n', WF_taxi);
fprintf('Climb:     %.4f\n', WF_climb);
fprintf('Cruise:    %.4f\n', WF_cruise);
fprintf('Descent:   %.4f\n', WF_descent);
fprintf('Loiter:    %.4f\n', WF_loiter);
fprintf('\n--- Total Mission Weight Fraction ---\n');
fprintf('W_final / W_initial = %.4f\n', WF_total);
fprintf('Mission Fuel Fraction (1 - WF_total) = %.4f\n', 1 - WF_total);