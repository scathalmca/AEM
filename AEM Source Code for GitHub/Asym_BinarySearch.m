function [Sweep_Matrix] = Asym_BinarySearch(x1coord,y1coord,x2coord,y2coord,spacing, thickness, barthickness,User_Frequency, ProjectName)
%  ASYM_BINARYSEARCH Function to place "half-interval" sections of interdigitated capacitor fingers 
% within the MKID IDC.
% 
% The automation will continue constructing and simulating each interval structure 
% until the User_Frequency given by 
% 
% the user lies between two intervals (i.e. f_current <= User_Frequency <= f_previous).
% 
% The coordinates of the finger polygons, resonant frequencies, Q factor & filenames 
% are then appended to the Sweep_Matrix and returned.
Project=SonnetProject(ProjectName);
% Extract Resonant Frequency and Qc Factor from already existing .csv data
% file.
[Resonance, Q_Factor]=Auto_Extract(erase(ProjectName, ".son") + ".csv");
% Clean project from any already existing file outputs or frequency sweeps.
delFileOutput(Project);
delFreqSweeps(Project);
% Length of a single IDC finger.
Length = x2coord-x1coord-spacing;
% Calculate the maximum number of possible interdigitated fingers given the
% capacitor area, spacing between fingers & thickness of fingers.
max_NumFingers=NumCap(y1coord,y2coord-(thickness),spacing,thickness);
% Initialize previous resonance value
prev_resonance=Resonance;
% Initialize previous filename
prev_filename = ProjectName;
% Set y2 to be equal to the bottom of the first IDC finger (not Coupling Bar)
y2coord = y2coord - (spacing+thickness+barthickness);
Sweep_Matrix = [];
% Begin iteration through all capacitor fingers
for i=2:1:max_NumFingers
    s=(-1)^i; % Clock to go from left side to right side of capacitor
    % Reset y1 and y2 coordinates every iteration
    y1_co = y2coord - i*(spacing+thickness);
    y2_co = y1_co + thickness;
    if s==1  % If clock=1, start on Left side of interdigitated capacitor.
        
        % Begin iteration through a single capacitor finger length
        for b=Length/2:Length/2:Length
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If placing a full length finger, remove the previous half
            % length finger.
            if b~= Length/2
                % Half finger x coordinates
                removex=round(mean([x1coord x1coord+round(Length/2)]));
                % Half finger y coordinates
                removey=round(mean([y1_co  y2_co]));
                
                % Find the DebugID of the polygon we want to remove
                Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                % Delete that polygon using its DebugID
                Project.deletePolygonUsingId(Polygon);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X coordinate of the polygon being placed.
            X_Array = [x1coord   x1coord+round(b)  x1coord+round(b)  x1coord];
            % Y coordinate of the polygon being placed.
            Y_Array = [y1_co  y1_co  y2_co  y2_co];
            
            % Place polygon.
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str=append("Test", num2str(i),"_", num2str(round(b)),".son");
            % Save the file as "String".son
            Project.saveAs(str);
            % Set upper and lower frequency sweep bounds .
            % Since we are adding capacitance in large sections, the lower
            % bound is set to the previous resonant frequency -1.
            upper_bound = Resonance;
            lower_bound = Resonance-1;
            % Reinitialize the project.
            Project = SonnetProject(str);
            % Simulate and analyse data with Auto_Sim
            while true
                try
                    [Resonance, Q_Factor, Warning]=Auto_Sim(Project, upper_bound, lower_bound);
                    % Rename .son and .csv files to resonant frequency and delete old
                    % files.
                    old_son_file=str;
                    str_son=num2str(Resonance)+"GHz.son";
                    str_csv_old=erase(str, ".son")+".csv";
                    str_csv_new=num2str(Resonance)+"GHz.csv";
                    Project.saveAs(str_son);
                    movefile(str_csv_old, str_csv_new);
                    delete(old_son_file);
                    break
                catch ME
                    warning("Something Broke! Retrying...");
                    Project.cleanProject;
                end
            end
            % If the current structure produces a resonant frequency that
            % satisfies the inequality: (f_current<=User_Frequency<=f_previous),
            % produce the Sweep_Matrix and return.
            if (prev_resonance >= User_Frequency) && (Resonance<= User_Frequency)
                
                % Create Sweep_Matrix with variables
                Sweep_Matrix = Matrix_Maker(User_Frequency, X_Array, prev_X_Array, Y_Array, Resonance, str_son, Q_Factor, prev_resonance, prev_filename);
                return
            end
            
            % If the resonant frequency does not satisfy the condition,
            % reset values as new "previous" values and continue placing
            % new polygons.
            %Previous X coordinate array.
            prev_X_Array=X_Array;
            % Previous filename
            prev_filename = str_son;
            % Previous Resonant Frequency
            prev_resonance = Resonance;
        end
    elseif s==-1 % If clock=-1, begin on Right side of interdigitated capacitor.
        % Begin iteration through a single capacitor finger length
        for b=Length/2:Length/2:Length
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If placing a full length finger, remove the previous half
            % length finger.
            if b~= Length/2
                % Half finger x coordinates
                removex=round(mean([x2coord-round(Length/2) x2coord]));
                % Half finger y coordinates
                removey=round(mean([y1_co  y2_co]));
                % Find the DebugID of the polygon we want to remove
                Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                % Delete that polygon using its DebugID
                Project.deletePolygonUsingId(Polygon);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X coordinate of the polygon being placed.
            X_Array = [(x2coord-round(b))   x2coord  x2coord  (x2coord-round(b))];
            % Y coordinate of the polygon being placed.
            Y_Array = [y1_co  y1_co  y2_co  y2_co];
            % Place polygon.
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str=append("Test", num2str(i),"_", num2str(round(b)),".son");
            % Save the file as "String".son
            Project.saveAs(str);
            % Set upper and lower frequency sweep bounds .
            % Since we are adding capacitance in large sections, the lower
            % bound is set to the previous resonant frequency -1.
            upper_bound = Resonance;
            lower_bound = Resonance-1;
            % Reinitialize the project.
            Project = SonnetProject(str);
            % Simulate and analyse data with Auto_Sim
            while true
                try
                    [Resonance, Q_Factor, Warning]=Auto_Sim(Project, upper_bound, lower_bound);
                    % Rename .son and .csv files to resonant frequency and delete old
                    % files.
                    old_son_file=str;
                    str_son=num2str(Resonance)+"GHz.son";
                    str_csv_old=erase(str, ".son")+".csv";
                    str_csv_new=num2str(Resonance)+"GHz.csv";
                    Project.saveAs(str_son);
                    movefile(str_csv_old, str_csv_new);
                    delete(old_son_file);
                    break
                catch ME
                    warning("Something Broke! Retrying...");
                    Project.cleanProject;
                end
            end
            % If the current structure produces a resonant frequency that
            % satisfies the inequality: (f_current<=User_Frequency<=f_previous),
            % produce the Sweep_Matrix and return.
            if (prev_resonance >= User_Frequency) && (Resonance<= User_Frequency)
                % Create Sweep_Matrix with variables
                Sweep_Matrix = Matrix_Maker(User_Frequency, X_Array, prev_X_Array, Y_Array, Resonance, str_son, Q_Factor, prev_resonance, prev_filename);
                return
            end
            % If the resonant frequency does not satisfy the condition,
            % reset values as new "previous" values and continue placing
            % new polygons.
            %Previous X coordinate array.
            prev_X_Array=X_Array;
            % Previous filename
            prev_filename = str_son;
            % Previous Resonant Frequency
            prev_resonance = Resonance;
            
        end
        
    end
end
end