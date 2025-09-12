classdef GUI_for_simulink_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        ElevationEditField        matlab.ui.control.NumericEditField
        ElevationEditFieldLabel   matlab.ui.control.Label
        AzimuthEditField          matlab.ui.control.NumericEditField
        AzimuthEditFieldLabel     matlab.ui.control.Label
        SimulationProgress        simulink.ui.control.SimulationProgress
        SimulationControls        simulink.ui.control.SimulationControls
        PlanetNameEditField       matlab.ui.control.EditField
        PlanetNameEditFieldLabel  matlab.ui.control.Label
        LoadButton                matlab.ui.control.Button
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)
        value; % Description
        data;
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            clc

global Azimuth Elevation t_vec azimuth_vec elevation_vec

app.PlanetNameEditField.Enable;
planet = app.data;
[x,y,z,JD] = getPlanetCoords(planet);% getplanetcoords is a user defind function
[RA,Dec]=computeAngles(x,y,z);%computeangles is a user defined function.

m = mobiledev; % Connect to MATLAB Mobile

pause(5); % Give time for GPS to update
latitude = m.Latitude;
longitude = m.Longitude;
alt = m.Altitude;
% Define the observer's longitude and latitude


T = (JD - 2451545.0) / 36525; % Time in Julian centuries from J2000
GMST = mod(280.46061837 + 360.98564736629 * (JD - 2451545) + T^2 * 0.000387933 - T^3 / 38710000, 360);

 %Calculate LST (Local Sidereal Time) based on longitude
LST = GMST + longitude; % Convert degrees to hours (since Earth rotates 15 degrees per hour)
LST = mod(LST, 360); % Ensure LST is within 0-24 hours

% Convert LST from hours to degrees
LST_deg = LST; % LST in degrees

% Calculate Hour Angle (H) in degrees
H = LST_deg - RA;
H = mod(H + 180, 360) - 180; % Ensure the hour angle is within [-180, 180] degrees

% Convert RA, Dec, Latitude to radians
RA_rad = deg2rad(RA);
Dec_rad = deg2rad(Dec);
lat_rad = deg2rad(latitude);
H_rad = deg2rad(H);

% Calculate Altitude and Azimuth
Elevation = asind(sin(Dec_rad) * sin(lat_rad) + cos(Dec_rad) * cos(lat_rad) * cos(H_rad));
Azimuth = atan2d(-cos(Dec_rad) * sin(H_rad), sin(Dec_rad) - sin(deg2rad(Elevation)) * sin(lat_rad));
app.ElevationEditField.Value = Elevation;
app.AzimuthEditField.Value = Azimuth;


% Ensure azimuth is in the range [0, 360]
if Azimuth < 0
    Azimuth = Azimuth + 360;
end
if isempty(t_vec)
    t_vec = 0; % Start time at 0
    azimuth_vec = Azimuth;
    elevation_vec = Elevation;
else
    t_vec = [t_vec; t_vec(end) + 1]; % Increment time
    azimuth_vec = [azimuth_vec; Azimuth];
    elevation_vec = [elevation_vec; Elevation];
end

% Create separate timeseries objects
Azimuth_ts = timeseries(azimuth_vec, t_vec);
Elevation_ts = timeseries(elevation_vec, t_vec);

% Assign to base workspace for Simulink
assignin('base', 'Azimuth_ts', Azimuth_ts);
assignin('base', 'Elevation_ts', Elevation_ts);


        end

        % Value changed function: PlanetNameEditField
        function PlanetNameEditFieldValueChanged(app, event)
           app.data= app.PlanetNameEditField.Value;
           
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [41 392 114 37];
            app.LoadButton.Text = 'Load';

            % Create PlanetNameEditFieldLabel
            app.PlanetNameEditFieldLabel = uilabel(app.UIFigure);
            app.PlanetNameEditFieldLabel.HorizontalAlignment = 'right';
            app.PlanetNameEditFieldLabel.Position = [171 399 74 22];
            app.PlanetNameEditFieldLabel.Text = 'Planet Name';

            % Create PlanetNameEditField
            app.PlanetNameEditField = uieditfield(app.UIFigure, 'text');
            app.PlanetNameEditField.ValueChangedFcn = createCallbackFcn(app, @PlanetNameEditFieldValueChanged, true);
            app.PlanetNameEditField.Position = [260 399 133 22];

            % Create SimulationControls
            app.SimulationControls = uisimcontrols(app.UIFigure);
            app.SimulationControls.Simulation = app.Simulation;
            app.SimulationControls.Position = [41 305 161 54];

            % Create SimulationProgress
            app.SimulationProgress = uisimprogress(app.UIFigure);
            app.SimulationProgress.Simulation = app.Simulation;
            app.SimulationProgress.Position = [392 16 219 59];

            % Create AzimuthEditFieldLabel
            app.AzimuthEditFieldLabel = uilabel(app.UIFigure);
            app.AzimuthEditFieldLabel.HorizontalAlignment = 'right';
            app.AzimuthEditFieldLabel.Position = [435 321 48 22];
            app.AzimuthEditFieldLabel.Text = 'Azimuth';

            % Create AzimuthEditField
            app.AzimuthEditField = uieditfield(app.UIFigure, 'numeric');
            app.AzimuthEditField.Position = [498 321 89 22];

            % Create ElevationEditFieldLabel
            app.ElevationEditFieldLabel = uilabel(app.UIFigure);
            app.ElevationEditFieldLabel.HorizontalAlignment = 'right';
            app.ElevationEditFieldLabel.Position = [425 284 54 22];
            app.ElevationEditFieldLabel.Text = 'Elevation';

            % Create ElevationEditField
            app.ElevationEditField = uieditfield(app.UIFigure, 'numeric');
            app.ElevationEditField.Position = [494 284 93 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI_for_simulink_exported

            % Associate the Simulink Model
            app.Simulation = simulation('CAD_simulation');

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end