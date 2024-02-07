function [Sweep_Matrix] = Guess_Sim(Sweep_Matrix)
%  GUESS_SIM 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes in coordinates of two MKID geometries that satisfy
% the condition:  f1 <= User_Frequency <= f2.
% When this condition is satisfied, a geometry exists with a capacitor
% finger length (closest to the inductor) between f1 and f2.
% Guess_Sim places a polygon of half the length of (x1 and x3 - Right) or (x2 and x3 - Left)
% For further description, please see the GitHub repository for AEM.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initializing IDC finger coordinates & values from Sweep_Matrix
x1_co=Sweep_Matrix{1, 1}(1,1);
x2_co = Sweep_Matrix{1, 2}(1,1);
x3_co = Sweep_Matrix{1, 3}(1,1);
y1_co = Sweep_Matrix{1, 1}(1,2);
y2_co = Sweep_Matrix{1, 1}(2,2);
% Initialise other variables from Sweep_Matrix
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
Project_Name = char(Sweep_Matrix{1, 4}(2,1));
User_Frequency = Sweep_Matrix{1, 6}(1,1);
Q_Factor = Sweep_Matrix{1, 6}(2,1);
Project = SonnetProject(Project_Name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    Building Capacitor              %%%%%%%%
%%%%%%%%                        Fingers                     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% After importing coordinates from Sweep_Matrix, we can deduce whether the
% capacitor finger closest to the inductor is connected to either the left
% or right side of the capacitor with the x coordinates.
% Finger starting from the left side
if x3_co > x1_co
    
    % Remove capacitor finger polygon closest to the inductor.
    removex=round(mean([x1_co x2_co]));
    removey=round(mean([y1_co y2_co]));
    % Find the polygons DebugID
    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
    % Remove the polygon using the DebugID
    Project.deletePolygonUsingId(first_Polygon);
    % Since User_Frequency lies between MKID geometries with resonances f1
    % and f2 and the capacitor finger closest to the inductor is connected
    % to the left side of the MKID, place a capacitor finger with length
    % x1_co to mean(x2_co and x3_co)
    x2_co = round((x2_co + x3_co)/2);
    % New X coordinate Array
    X_Array= [x1_co  x2_co   x2_co  x1_co];
    % Y coordinate
    Y_Array = [y1_co  y1_co   y2_co  y2_co];
    % Place new polygon
    Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
    % Name the new structure
    str=append("TestG", num2str(x2_co), ".son");
    % Save the file as "String".son
    Project.saveAs(str);
    % Set the upper and lower frequency sweep bounds.
    % Since we are adding capacitance, the new resonant frequency will be
    % below the previous resonance
    upper_bound = Resonance;
    lower_bound = Resonance-1;
    % Since file was renamed, decompile new file as SonnetProject
    Project = SonnetProject(str);
    % Simulate new project
    while true
        try
            % Call Auto_Sim for simulation and analysis
            [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
            % Rename .csv and .son as the resonant frequency
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
    % Here, we determine what values to change in the Sweep_Matrix to
    % return to the previous function.
    % If the user's resonant frequency is above the current resonance, we
    % have missed the target resonance and thus return x3_co as the new x2
    % coordinate.
    if User_Frequency > Resonance
        
        % Set x3_co as x2_co 
        Sweep_Matrix{1, 3}(1,1) = x2_co;
        % Set f2 as the current resonant frequency
        Sweep_Matrix{1, 5}(1,1) = Resonance;
        % Add f2 filename as the current geometry filename.
        Sweep_Matrix{1, 5}(2,1) = str_son;
    % Otherwise, the User_Frequency still lies between x2_co and x3_co and
    % thus x2_co is set to the current x2_co coordinate in Sweep_Matrix
    else
        % Set f1 as the current resonant frequency
        Sweep_Matrix{1, 4}(1,1) = Resonance;
        % Set Qc Factor
        Sweep_Matrix{1, 6}(2,1) = Q_Factor;
        % Set f1 filename as the current geometry filename.
        Sweep_Matrix{1, 4}(2,1) = str_son;
        % Reset x2_co to the new x2_co
        Sweep_Matrix{1, 2}(1,1) = x2_co;
    end
% Finger starting from the right side
elseif x3_co < x1_co
    
    % Remove capacitor finger polygon closest to the inductor.
    removex=round(mean([x1_co x2_co]));
    removey=round(mean([y1_co y2_co]));
    % Find the polygons DebugID
    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
    % Remove the polygon using the DebugID
    Project.deletePolygonUsingId(first_Polygon);
    % Since User_Frequency lies between MKID geometries with resonances f1
    % and f2 and the capacitor finger closest to the inductor is connected
    % to the right side of the MKID, place a capacitor finger with length
    % x2_co to mean(x1_co and x3_co)
    x1_co = round((x1_co + x3_co)/2);
    % New X coordinate Array
    X_Array= [x1_co  x2_co   x2_co  x1_co];
    
    % Y coordinate
    Y_Array = [y1_co  y1_co   y2_co  y2_co];
    % Place new polygon
    Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
    % Name the new structure
    str=append("TestG", num2str(x1_co), ".son");
    % Save the file as "String".son
    Project.saveAs(str);
    % Set the upper and lower frequency sweep bounds.
    % Since we are adding capacitance, the new resonant frequency will be
    % below the previous resonance
    upper_bound = Resonance;
    lower_bound = Resonance-1;
    % Since file was renamed, decompile new file as SonnetProject
    Project = SonnetProject(str);
    % Simulate new project
    while true
        try
            % Call Auto_Sim for simulation and analysis
            [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
            % Rename .csv and .son as the resonant frequency
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
    % Here, we determine what values to change in the Sweep_Matrix to
    % return to the previous function.
    % If the user's resonant frequency is above the current resonance, we
    % have missed the target resonance and thus return x3_co as the new x2
    % coordinate.
    if User_Frequency > Resonance
        % Set x3_co as x1_co 
        Sweep_Matrix{1, 3}(1,1) = x1_co;
        % Set f2 as the current resonant frequency
        Sweep_Matrix{1, 5}(1,1) = Resonance;
        % Add f2 filename as the current geometry filename.
        Sweep_Matrix{1, 5}(2,1) = str_son;
    else
        % Set f1 as the current resonant frequency
        Sweep_Matrix{1, 4}(1,1) = Resonance;
        % Set Qc Factor
        Sweep_Matrix{1, 6}(2,1) = Q_Factor;
        % Set f1 filename as the current geometry filename.
        Sweep_Matrix{1, 4}(2,1) = str_son;
        % Reset x1_co to the new x1_co
        Sweep_Matrix{1, 1}(1,1) = x1_co;
    end
% Return to previous function with new Sweep_Matrix
end