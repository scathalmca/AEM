classdef AEMGUI_ < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        QcMaxLabel                      matlab.ui.control.Label
        QcMinLabel                      matlab.ui.control.Label
        QcMaxEditField                  matlab.ui.control.NumericEditField
        EndFreqMHzEditFieldLabel        matlab.ui.control.Label
        EndFreqMHzEditField             matlab.ui.control.NumericEditField
        NonEquidistantResonatorsButton  matlab.ui.control.Button
        NumberOfResonatorsEditField     matlab.ui.control.NumericEditField
        NumberOfResonatorsEditFieldLabel  matlab.ui.control.Label
        QcMinEditField                  matlab.ui.control.NumericEditField
        QcRangeEditFieldLabel           matlab.ui.control.Label
        StartFreqMHzLabel               matlab.ui.control.Label
        StartFreqMHzEditField           matlab.ui.control.NumericEditField
        ResultingResonatorsLabel        matlab.ui.control.Label
        StartingGeometryFileLabel       matlab.ui.control.Label
        FileSettingsLabel               matlab.ui.control.Label
        FilenameEditButton              matlab.ui.control.EditField
        FilenameButton                  matlab.ui.control.Button
        CenterPanel                     matlab.ui.container.Panel
        UIAxes                          matlab.ui.control.UIAxes
        RightPanel                      matlab.ui.container.Panel
        AEMLabel                        matlab.ui.control.Label
        AutomatedElectromagneticMKIDSimulationsLabel  matlab.ui.control.Label
        X2EditField                     matlab.ui.control.NumericEditField
        X2EditFieldLabel                matlab.ui.control.Label
        Y2EditField                     matlab.ui.control.NumericEditField
        Y2EditFieldLabel                matlab.ui.control.Label
        Y1EditField                     matlab.ui.control.NumericEditField
        Y1EditFieldLabel                matlab.ui.control.Label
        X1EditField                     matlab.ui.control.NumericEditField
        X1EditFieldLabel                matlab.ui.control.Label
        CoordinatesLabel                matlab.ui.control.Label
        GeometrySettingsLabel           matlab.ui.control.Label
        CouplingBarThicknessEditField   matlab.ui.control.NumericEditField
        CouplingBarThicknessEditFieldLabel  matlab.ui.control.Label
        FingerThicknessEditField        matlab.ui.control.NumericEditField
        FingerThicknessEditFieldLabel   matlab.ui.control.Label
        CapacitorSpacingEditField       matlab.ui.control.NumericEditField
        CapacitorSpacingEditFieldLabel  matlab.ui.control.Label
        StartAutomationButton           matlab.ui.control.Button
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
    end

    
    properties (Access = private)


        Filename;
        X1Coord;
        Y1Coord;
        X2Coord;
        Y2Coord;
        StartFreq;
        EndFreq;
        Num_Res;
        Spacing;
        Thickness;
        Barthickness;
        QcMax;
        QcMin;
        myApp;
        Manual;
        txtname;

        %User Path for file directory
        selectedPath = ''; % Description
    end

    methods (Access = private)

 


    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, Spacing)
            
        end

        % Button down function: CenterPanel
        function CenterPanelButtonDown(app, event)
       


        end

        % Callback function
        function DirectoryButtonPushed(app, event)
            dir_name= uigetdir();
            app.DirectoryEditField.Value = dir_name;
            figure(app.UIFigure);

        end

        % Button pushed function: FilenameButton
        function FilenameButtonPushed(app, event)
            filename= uigetfile('*.son');
            app.Filename =filename;
            app.FilenameEditButton.Value = filename;
            cla(app.UIAxes);
            figure(app.UIFigure);
            obj=SonnetProject(filename);
            theLevelNumber=0;

            if obj.isGeometryProject


                set(app.UIAxes,'Ydir','reverse')
                hold(app.UIAxes,"on")

                if nargin == 1
                    theLevelNumber=0;
                end

                % Loop for all the polygons in the file.
                % if they are on the proper level then we will plot them.
                % this iteration we will plot planar metals only.
                for iPlotCounter=1:length(obj.GeometryBlock.ArrayOfPolygons)

                    % if the polygon is on a different level then go to the next
                    % polygon in the array of polygons.
                    if obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.MetalizationLevelIndex ~= theLevelNumber || ...
                            strcmpi(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.Type,'')==0
                        continue;
                    end

                    % Draw the polygon
                    anArrayOfXValues = cell2mat(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.XCoordinateValues);
                    anArrayOfYValues = cell2mat(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.YCoordinateValues);
                    fill(app.UIAxes,anArrayOfXValues,anArrayOfYValues,[1 0 1]);

                end
                % Loop for all the polygons in the file.
                % if they are on the proper level then we will plot them.
                % this iteration we will plot dielectric bricks only.
                for iPlotCounter=1:length(obj.GeometryBlock.ArrayOfPolygons)

                    % if the polygon is on a different level then go to the next
                    % polygon in the array of polygons.
                    if obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.MetalizationLevelIndex ~= theLevelNumber || ...
                            strcmpi(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.Type,'BRI POLY')==0
                        continue;
                    end

                    % Draw the polygon
                    anArrayOfXValues = cell2mat(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.XCoordinateValues);
                    anArrayOfYValues = cell2mat(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.YCoordinateValues);
                    fill(app.UIAxes,anArrayOfXValues,anArrayOfYValues,[.4 .8 .8]);


                end
                % Loop for all the polygons in the file.
                % if they are on the proper level then we will plot them.
                % this iteration we will plot vias only.
                for iPlotCounter=1:length(obj.GeometryBlock.ArrayOfPolygons)

                    % if the polygon is on a different level then go to the next
                    % polygon in the array of polygons.
                    if obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.MetalizationLevelIndex ~= theLevelNumber || ...
                            strcmpi(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.Type,'VIA POLYGON')==0
                        continue;
                    end

                    % Draw the polygon
                    anArrayOfXValues = cell2mat(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.XCoordinateValues);
                    anArrayOfYValues = cell2mat(obj.GeometryBlock.ArrayOfPolygons{iPlotCounter}.YCoordinateValues);
                    fill(app.UIAxes,anArrayOfXValues,anArrayOfYValues,[1 .5 .2]);

                end
                % Loop for all the ports in the file.
                % if they are connected to a polygon on the proper level we will plot them
                % this iteration we will plot ports only.

                grid(app.UIAxes,"on")
                title(app.UIAxes, filename, FontSize=12);
                hold(app.UIAxes,"off")

                % draw the boundries for the box
                XboxLength=obj.GeometryBlock.SonnetBox.XWidthOfTheBox;
                YboxLength=obj.GeometryBlock.SonnetBox.YWidthOfTheBox;
                line(app.UIAxes,[0 XboxLength XboxLength 0 0],[0 0 YboxLength YboxLength 0]);
                line(app.UIAxes,[0 XboxLength XboxLength 0 0],[0 0 YboxLength YboxLength 0]);

                % find good major tick sizes
                aXCellSize=obj.GeometryBlock.xCellSize();
                anMajorXTick=0:aXCellSize:XboxLength;
                while length(anMajorXTick)>20
                    aXCellSize=aXCellSize*2;
                    anMajorXTick=0:aXCellSize:XboxLength;
                end

                aYCellSize=obj.GeometryBlock.yCellSize();
                anMajorYTick=0:aYCellSize:YboxLength;
                while length(anMajorYTick)>20
                    aYCellSize=aYCellSize*2;
                    anMajorYTick=0:aYCellSize:YboxLength;
                end

                % change the grid

                set(app.UIAxes,'XTick',anMajorXTick);
                set(app.UIAxes,'YTick',anMajorYTick);
                axis(app.UIAxes,[(0-.05*XboxLength) (XboxLength+.05*XboxLength) (0-.05*YboxLength) (YboxLength+.05*YboxLength)]);

            else
                error('This method is only available for Geometry projects');
            end

      

        end

        % Value changed function: FilenameEditButton
        function FilenameEditButtonValueChanged(app, event)
            filename = app.FilenameEditButton.Value;

            app.Filename =filename;
            
        end

        % Button pushed function: StartAutomationButton
        function StartAutomationButtonPushed(app, event)
            %Call previous buttons/fields
            %Call Automation function

            if app.Manual ==1

                fileID=fopen(app.txtname,'r');
                formatSpec='%f';
                A=fscanf(fileID,formatSpec);

                User_Frequencies = round(sort(A.'/1000,"descend"),4);

            else
            
                End = (app.EndFreq/1000);

                Start = (app.StartFreq/1000);

                if End < Start
                    [End,Start]=deal(Start,End);

                end

                User_Frequencies=round(linspace(End, Start, app.Num_Res),4);
            end



            if app.X1Coord > app.X2Coord

                [app.X1Coord,app.X2Coord]=deal(app.X2Coord,app.X1Coord);

            end

            if app.Y1Coord > app.Y2Coord

                [app.Y1Coord,app.Y2Coord]=deal(app.Y2Coord,app.Y1Coord);

            end

            

            Qvalues = [app.QcMin  (app.QcMax-app.QcMin)  0];
            

            AEM(app.X1Coord, app.Y1Coord, app.X2Coord, app.Y2Coord, app.Filename, User_Frequencies, Qvalues, app.Spacing, app.Thickness, app.Barthickness);
        end

        % Button pushed function: NonEquidistantResonatorsButton
        function NonEquidistantResonatorsButtonPushed(app, event)
            app.Manual =1;

            disp("Please Import .txt File Containing Resonant Frequencies...");

            txt =uigetfile('*.txt');
            app.txtname =txt;

        end

        % Value changed function: StartFreqMHzEditField
        function StartFreqMHzEditFieldValueChanged(app, event)
            app.Manual =0;

            app.StartFreq=app.StartFreqMHzEditField.Value;
           
            
        end

        % Value changed function: QcMaxEditField
        function QcMaxEditFieldValueChanged(app, event)

            app.QcMax=app.QcMaxEditField.Value;
            
        end

        % Value changed function: QcMinEditField
        function QcMinEditFieldValueChanged(app, event)

            app.QcMin =app.QcMinEditField.Value;
            
        end

        % Value changed function: EndFreqMHzEditField
        function EndFreqMHzEditFieldValueChanged(app, event)
            app.Manual =0;

            
            app.EndFreq = app.EndFreqMHzEditField.Value;

            
        end

        % Value changed function: NumberOfResonatorsEditField
        function NumberOfResonatorsEditFieldValueChanged(app, event)
            app.Manual =0;

            app.Num_Res=app.NumberOfResonatorsEditField.Value;

        end

        % Value changed function: X1EditField
        function X1EditFieldValueChanged(app, event)

            app.X1Coord = app.X1EditField.Value;

        end

        % Value changed function: Y1EditField
        function Y1EditFieldValueChanged(app, event)

            app.Y1Coord = app.Y1EditField.Value;

        end

        % Value changed function: Y2EditField
        function Y2EditFieldValueChanged(app, event)

            app.Y2Coord = app.Y2EditField.Value;

        end

        % Value changed function: X2EditField
        function X2EditFieldValueChanged(app, event)
            app.X2Coord = app.X2EditField.Value;



        end

        % Value changed function: CouplingBarThicknessEditField
        function CouplingBarThicknessEditFieldValueChanged(app, event)

            app.Barthickness= app.CouplingBarThicknessEditField.Value;


        end

        % Value changed function: FingerThicknessEditField
        function FingerThicknessEditFieldValueChanged(app, event)

            app.Thickness =app.FingerThicknessEditField.Value;
     
        end

        % Value changed function: CapacitorSpacingEditField
        function CapacitorSpacingEditFieldValueChanged(app, event)

            app.Spacing = app.CapacitorSpacingEditField.Value;
          
        end

        % Callback function
        function StopAutomationButtonPushed(app, event)
            delete(myApp)
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 3x1 grid
                app.GridLayout.RowHeight = {480, 480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 1;
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 3;
                app.RightPanel.Layout.Column = 1;
            elseif (currentFigureWidth > app.onePanelWidth && currentFigureWidth <= app.twoPanelWidth)
                % Change to a 2x2 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x', '1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = [1,2];
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 2;
            else
                % Change to a 1x3 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {212, '1x', 209};
                app.LeftPanel.Layout.Row = 1;
                app.LeftPanel.Layout.Column = 1;
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 2;
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 3;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 860 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {212, '1x', 209};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create FilenameButton
            app.FilenameButton = uibutton(app.LeftPanel, 'push');
            app.FilenameButton.ButtonPushedFcn = createCallbackFcn(app, @FilenameButtonPushed, true);
            app.FilenameButton.Position = [102 349 96 25];
            app.FilenameButton.Text = 'Filename';

            % Create FilenameEditButton
            app.FilenameEditButton = uieditfield(app.LeftPanel, 'text');
            app.FilenameEditButton.ValueChangedFcn = createCallbackFcn(app, @FilenameEditButtonValueChanged, true);
            app.FilenameEditButton.Position = [17 378 181 27];

            % Create FileSettingsLabel
            app.FileSettingsLabel = uilabel(app.LeftPanel);
            app.FileSettingsLabel.BackgroundColor = [0.8 0.8 0.8];
            app.FileSettingsLabel.HorizontalAlignment = 'center';
            app.FileSettingsLabel.FontWeight = 'bold';
            app.FileSettingsLabel.Position = [7 445 197 27];
            app.FileSettingsLabel.Text = 'File Settings';

            % Create StartingGeometryFileLabel
            app.StartingGeometryFileLabel = uilabel(app.LeftPanel);
            app.StartingGeometryFileLabel.HorizontalAlignment = 'center';
            app.StartingGeometryFileLabel.FontWeight = 'bold';
            app.StartingGeometryFileLabel.FontAngle = 'italic';
            app.StartingGeometryFileLabel.Position = [18 407 179 22];
            app.StartingGeometryFileLabel.Text = 'Starting Geometry File';

            % Create ResultingResonatorsLabel
            app.ResultingResonatorsLabel = uilabel(app.LeftPanel);
            app.ResultingResonatorsLabel.BackgroundColor = [0.8 0.8 0.8];
            app.ResultingResonatorsLabel.HorizontalAlignment = 'center';
            app.ResultingResonatorsLabel.FontWeight = 'bold';
            app.ResultingResonatorsLabel.Position = [7 302 197 27];
            app.ResultingResonatorsLabel.Text = ' Resulting Resonators';

            % Create StartFreqMHzEditField
            app.StartFreqMHzEditField = uieditfield(app.LeftPanel, 'numeric');
            app.StartFreqMHzEditField.ValueChangedFcn = createCallbackFcn(app, @StartFreqMHzEditFieldValueChanged, true);
            app.StartFreqMHzEditField.HorizontalAlignment = 'center';
            app.StartFreqMHzEditField.Position = [135 261 69 26];

            % Create StartFreqMHzLabel
            app.StartFreqMHzLabel = uilabel(app.LeftPanel);
            app.StartFreqMHzLabel.FontWeight = 'bold';
            app.StartFreqMHzLabel.Position = [8 263 95 22];
            app.StartFreqMHzLabel.Text = 'Start Freq(MHz)';

            % Create QcRangeEditFieldLabel
            app.QcRangeEditFieldLabel = uilabel(app.LeftPanel);
            app.QcRangeEditFieldLabel.BackgroundColor = [0.8 0.8 0.8];
            app.QcRangeEditFieldLabel.HorizontalAlignment = 'center';
            app.QcRangeEditFieldLabel.FontSize = 14;
            app.QcRangeEditFieldLabel.FontWeight = 'bold';
            app.QcRangeEditFieldLabel.Position = [8 122 196 22];
            app.QcRangeEditFieldLabel.Text = 'Qc Range';

            % Create QcMinEditField
            app.QcMinEditField = uieditfield(app.LeftPanel, 'numeric');
            app.QcMinEditField.ValueChangedFcn = createCallbackFcn(app, @QcMinEditFieldValueChanged, true);
            app.QcMinEditField.HorizontalAlignment = 'center';
            app.QcMinEditField.Position = [8 57 89 26];

            % Create NumberOfResonatorsEditFieldLabel
            app.NumberOfResonatorsEditFieldLabel = uilabel(app.LeftPanel);
            app.NumberOfResonatorsEditFieldLabel.FontSize = 11;
            app.NumberOfResonatorsEditFieldLabel.FontWeight = 'bold';
            app.NumberOfResonatorsEditFieldLabel.Position = [7 200 125 22];
            app.NumberOfResonatorsEditFieldLabel.Text = 'Number Of Resonators';

            % Create NumberOfResonatorsEditField
            app.NumberOfResonatorsEditField = uieditfield(app.LeftPanel, 'numeric');
            app.NumberOfResonatorsEditField.ValueChangedFcn = createCallbackFcn(app, @NumberOfResonatorsEditFieldValueChanged, true);
            app.NumberOfResonatorsEditField.HorizontalAlignment = 'center';
            app.NumberOfResonatorsEditField.Position = [134 198 70 26];

            % Create NonEquidistantResonatorsButton
            app.NonEquidistantResonatorsButton = uibutton(app.LeftPanel, 'push');
            app.NonEquidistantResonatorsButton.ButtonPushedFcn = createCallbackFcn(app, @NonEquidistantResonatorsButtonPushed, true);
            app.NonEquidistantResonatorsButton.BackgroundColor = [1 1 1];
            app.NonEquidistantResonatorsButton.FontWeight = 'bold';
            app.NonEquidistantResonatorsButton.Position = [19 161 177 24];
            app.NonEquidistantResonatorsButton.Text = 'Non-Equidistant Resonators';

            % Create EndFreqMHzEditField
            app.EndFreqMHzEditField = uieditfield(app.LeftPanel, 'numeric');
            app.EndFreqMHzEditField.ValueChangedFcn = createCallbackFcn(app, @EndFreqMHzEditFieldValueChanged, true);
            app.EndFreqMHzEditField.HorizontalAlignment = 'center';
            app.EndFreqMHzEditField.Position = [134 229 70 26];

            % Create EndFreqMHzEditFieldLabel
            app.EndFreqMHzEditFieldLabel = uilabel(app.LeftPanel);
            app.EndFreqMHzEditFieldLabel.FontWeight = 'bold';
            app.EndFreqMHzEditFieldLabel.Position = [7 231 95 22];
            app.EndFreqMHzEditFieldLabel.Text = 'End Freq(MHz)';

            % Create QcMaxEditField
            app.QcMaxEditField = uieditfield(app.LeftPanel, 'numeric');
            app.QcMaxEditField.ValueChangedFcn = createCallbackFcn(app, @QcMaxEditFieldValueChanged, true);
            app.QcMaxEditField.HorizontalAlignment = 'center';
            app.QcMaxEditField.Position = [114 57 90 26];

            % Create QcMinLabel
            app.QcMinLabel = uilabel(app.LeftPanel);
            app.QcMinLabel.BackgroundColor = [0.8314 0.8314 0.8314];
            app.QcMinLabel.HorizontalAlignment = 'center';
            app.QcMinLabel.FontWeight = 'bold';
            app.QcMinLabel.Position = [17 89 68 25];
            app.QcMinLabel.Text = 'Qc Min';

            % Create QcMaxLabel
            app.QcMaxLabel = uilabel(app.LeftPanel);
            app.QcMaxLabel.BackgroundColor = [0.8314 0.8314 0.8314];
            app.QcMaxLabel.HorizontalAlignment = 'center';
            app.QcMaxLabel.FontWeight = 'bold';
            app.QcMaxLabel.Position = [125 89 68 25];
            app.QcMaxLabel.Text = 'Qc Max';

            % Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.ButtonDownFcn = createCallbackFcn(app, @CenterPanelButtonDown, true);
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.CenterPanel);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [4 1 430 475];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create StartAutomationButton
            app.StartAutomationButton = uibutton(app.RightPanel, 'push');
            app.StartAutomationButton.ButtonPushedFcn = createCallbackFcn(app, @StartAutomationButtonPushed, true);
            app.StartAutomationButton.BackgroundColor = [1 1 1];
            app.StartAutomationButton.FontWeight = 'bold';
            app.StartAutomationButton.Position = [21 40 170 24];
            app.StartAutomationButton.Text = 'Start Automation';

            % Create CapacitorSpacingEditFieldLabel
            app.CapacitorSpacingEditFieldLabel = uilabel(app.RightPanel);
            app.CapacitorSpacingEditFieldLabel.HorizontalAlignment = 'right';
            app.CapacitorSpacingEditFieldLabel.FontWeight = 'bold';
            app.CapacitorSpacingEditFieldLabel.Position = [6 313 111 22];
            app.CapacitorSpacingEditFieldLabel.Text = 'Capacitor Spacing';

            % Create CapacitorSpacingEditField
            app.CapacitorSpacingEditField = uieditfield(app.RightPanel, 'numeric');
            app.CapacitorSpacingEditField.ValueChangedFcn = createCallbackFcn(app, @CapacitorSpacingEditFieldValueChanged, true);
            app.CapacitorSpacingEditField.HorizontalAlignment = 'center';
            app.CapacitorSpacingEditField.Position = [139 311 64 26];

            % Create FingerThicknessEditFieldLabel
            app.FingerThicknessEditFieldLabel = uilabel(app.RightPanel);
            app.FingerThicknessEditFieldLabel.HorizontalAlignment = 'center';
            app.FingerThicknessEditFieldLabel.FontWeight = 'bold';
            app.FingerThicknessEditFieldLabel.Position = [11 273 99 22];
            app.FingerThicknessEditFieldLabel.Text = 'Finger Thickness';

            % Create FingerThicknessEditField
            app.FingerThicknessEditField = uieditfield(app.RightPanel, 'numeric');
            app.FingerThicknessEditField.ValueChangedFcn = createCallbackFcn(app, @FingerThicknessEditFieldValueChanged, true);
            app.FingerThicknessEditField.HorizontalAlignment = 'center';
            app.FingerThicknessEditField.Position = [139 271 64 26];

            % Create CouplingBarThicknessEditFieldLabel
            app.CouplingBarThicknessEditFieldLabel = uilabel(app.RightPanel);
            app.CouplingBarThicknessEditFieldLabel.FontSize = 11;
            app.CouplingBarThicknessEditFieldLabel.FontWeight = 'bold';
            app.CouplingBarThicknessEditFieldLabel.Position = [11 233 132 22];
            app.CouplingBarThicknessEditFieldLabel.Text = 'Coupling Bar Thickness';

            % Create CouplingBarThicknessEditField
            app.CouplingBarThicknessEditField = uieditfield(app.RightPanel, 'numeric');
            app.CouplingBarThicknessEditField.ValueChangedFcn = createCallbackFcn(app, @CouplingBarThicknessEditFieldValueChanged, true);
            app.CouplingBarThicknessEditField.HorizontalAlignment = 'center';
            app.CouplingBarThicknessEditField.Position = [139 231 64 26];

            % Create GeometrySettingsLabel
            app.GeometrySettingsLabel = uilabel(app.RightPanel);
            app.GeometrySettingsLabel.BackgroundColor = [0.8 0.8 0.8];
            app.GeometrySettingsLabel.HorizontalAlignment = 'center';
            app.GeometrySettingsLabel.FontWeight = 'bold';
            app.GeometrySettingsLabel.Position = [7 445 197 27];
            app.GeometrySettingsLabel.Text = 'Geometry Settings';

            % Create CoordinatesLabel
            app.CoordinatesLabel = uilabel(app.RightPanel);
            app.CoordinatesLabel.HorizontalAlignment = 'center';
            app.CoordinatesLabel.FontSize = 10;
            app.CoordinatesLabel.FontWeight = 'bold';
            app.CoordinatesLabel.Position = [40 418 143 22];
            app.CoordinatesLabel.Text = 'Coordinates';

            % Create X1EditFieldLabel
            app.X1EditFieldLabel = uilabel(app.RightPanel);
            app.X1EditFieldLabel.FontWeight = 'bold';
            app.X1EditFieldLabel.Position = [21 400 25 22];
            app.X1EditFieldLabel.Text = 'X1';

            % Create X1EditField
            app.X1EditField = uieditfield(app.RightPanel, 'numeric');
            app.X1EditField.ValueChangedFcn = createCallbackFcn(app, @X1EditFieldValueChanged, true);
            app.X1EditField.Position = [50 400 48 18];

            % Create Y1EditFieldLabel
            app.Y1EditFieldLabel = uilabel(app.RightPanel);
            app.Y1EditFieldLabel.FontWeight = 'bold';
            app.Y1EditFieldLabel.Position = [118 398 25 22];
            app.Y1EditFieldLabel.Text = 'Y1';

            % Create Y1EditField
            app.Y1EditField = uieditfield(app.RightPanel, 'numeric');
            app.Y1EditField.ValueChangedFcn = createCallbackFcn(app, @Y1EditFieldValueChanged, true);
            app.Y1EditField.Position = [147 398 48 18];

            % Create Y2EditFieldLabel
            app.Y2EditFieldLabel = uilabel(app.RightPanel);
            app.Y2EditFieldLabel.FontWeight = 'bold';
            app.Y2EditFieldLabel.Position = [118 362 25 22];
            app.Y2EditFieldLabel.Text = 'Y2';

            % Create Y2EditField
            app.Y2EditField = uieditfield(app.RightPanel, 'numeric');
            app.Y2EditField.ValueChangedFcn = createCallbackFcn(app, @Y2EditFieldValueChanged, true);
            app.Y2EditField.Position = [146 362 48 18];

            % Create X2EditFieldLabel
            app.X2EditFieldLabel = uilabel(app.RightPanel);
            app.X2EditFieldLabel.FontWeight = 'bold';
            app.X2EditFieldLabel.Position = [21 364 25 22];
            app.X2EditFieldLabel.Text = 'X2';

            % Create X2EditField
            app.X2EditField = uieditfield(app.RightPanel, 'numeric');
            app.X2EditField.ValueChangedFcn = createCallbackFcn(app, @X2EditFieldValueChanged, true);
            app.X2EditField.Position = [50 364 48 18];

            % Create AutomatedElectromagneticMKIDSimulationsLabel
            app.AutomatedElectromagneticMKIDSimulationsLabel = uilabel(app.RightPanel);
            app.AutomatedElectromagneticMKIDSimulationsLabel.HorizontalAlignment = 'center';
            app.AutomatedElectromagneticMKIDSimulationsLabel.FontName = 'Bauhaus 93';
            app.AutomatedElectromagneticMKIDSimulationsLabel.FontSize = 22;
            app.AutomatedElectromagneticMKIDSimulationsLabel.FontWeight = 'bold';
            app.AutomatedElectromagneticMKIDSimulationsLabel.Position = [16 74 183 118];
            app.AutomatedElectromagneticMKIDSimulationsLabel.Text = {''; 'Automated'; 'Electromagnetic'; 'MKID Simulations'};

            % Create AEMLabel
            app.AEMLabel = uilabel(app.RightPanel);
            app.AEMLabel.HorizontalAlignment = 'center';
            app.AEMLabel.FontName = 'Bauhaus 93';
            app.AEMLabel.FontSize = 55;
            app.AEMLabel.FontColor = [1 0 0];
            app.AEMLabel.Position = [28 161 160 59];
            app.AEMLabel.Text = 'AEM';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AEMGUI_(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

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