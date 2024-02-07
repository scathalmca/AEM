function [max_Resonance,min_Resonance, maxProjectName] = min_Structure(x1coord,y1coord,x2coord,y2coord,side_x, spacing, thickness, barthickness,ProjectName)
%  MIN_STRUCTURE Constructs the minimum structure for a LEKID (i.e. a lumped inductor and capacitor).
% 
% The script will then build interdigitated capcaitor fingers to find the resonant 
% structure that has a resonant frequency close to the maximum resonant frequency 
% given by the user.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If files with the names below already exist, delete them to avoid reading
% from the wrong project files.
if exist("maxFrequency.son") 
    delete("maxFrequency.son");
elseif exist("maxFrequency.csv")
    delete("maxFrequency.csv");
elseif exist("minFrequency.son")
    delete("minFrequency.son");
elseif exist("minFrequency.csv")
    delete("minFrequency.csv");
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decompile the starting geometry
Project = SonnetProject(ProjectName);
% Delete all existing File-Output and Frequency Sweeps to clean file.
delFileOutput(Project);
delFreqSweeps(Project);
% Set the upper and lower frequency sweep bounds to a very broad range for 
% initial simulations to test for beginning resonant frequency. 
% i.e. 1-10GHz
lower_bound=1;
upper_bound = 10;
% Calculate the maximum number of possible interdigitated fingers given the
% capacitor area, spacing between fingers & thickness of fingers.
max_NumFingers=NumCap(y1coord,y2coord-(spacing+barthickness),spacing,thickness)-1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                  Finding the minimum            %%%%%
        %%%%%                   Resonant Frequency            %%%%%     
        %%%%%                        First                    %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fill the capacitor area with IDC fingers to find the lowest possible
% resonant frequency.
for i= 0 : 1 : max_NumFingers
    s=(-1)^i; % Move construction from left to right side of capacitor 
    
    % Reset y coordinates each iteration to place new fingers moving
    % downwards.
    y2_co = y2coord -(spacing+barthickness)-i*(thickness+spacing);
    y1_co = y2_co - thickness;
    if s==-1
        % Build finger connecting to the right side of capacitor.
        % X coordinates of new polygon
        X_Array = [(x1coord+spacing)   x2coord  x2coord  (x1coord+spacing)];
        
        % Y coordinates of new polygon
        Y_Array = [y1_co   y1_co  y2_co  y2_co];
        % Place polygon with new coordinates
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
    else
        % Build finger connecting to the left side of capacitor.
        % X coordinates of new polygon
        X_Array = [x1coord   (x2coord-spacing)  (x2coord-spacing)  x1coord];
        % Y coordinates of new polygon
        Y_Array = [y1_co   y1_co  y2_co  y2_co];
        % Place polygon with new coordinates
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
    end
end
% Place full-length capacitor coupling bar 
PlaceCoupleBar(x1coord,y2coord,side_x, spacing, barthickness, Project);
% There is a small area missing between the coupling bar and the IDC of the
% MKID, thus we need to connect them with a small polygon.
% Placing small piece between coupling bar and right side polygon of MKID
% Array of coordinates for small connecting polygon
ArrayXValues=[x2coord  side_x   side_x   x2coord];
ArrayYValues=[y2coord-barthickness   y2coord-barthickness   y2coord-(spacing+barthickness)   y2coord-(spacing+barthickness)];
Project.addMetalPolygonEasy(0,ArrayXValues,ArrayYValues,1);
% Rename the new geometry file.
str_min = "minFrequency.son";
Project.saveAs(str_min);
% After renaming a .son file, must re-decompile into MATLAB everytime.
Project_min = SonnetProject(str_min);
% Waitbar for user
f = waitbar(0, 'Checking Minimum Resonant Frequency...');
% Simulate and analyse data with Auto_Sim
while true
    try
        [min_Resonance, minQ_Factor, Warning]=Auto_Sim(Project_min, upper_bound, lower_bound);
        % Rename .son and .csv files to resonant frequency and delete old
        % files.
        old_son_file=str_min;
        str_son=num2str(min_Resonance)+"GHz.son";
        str_csv_old=erase(str_min, ".son")+".csv";
        str_csv_new=num2str(min_Resonance)+"GHz.csv";
        Project.saveAs(str_son);
        movefile(str_csv_old, str_csv_new);
        delete(old_son_file);
        break
    catch ME
        warning("Something Broke! Retrying...");
        Project.cleanProject;
    end
end
% Close the waitbar for minimum resonant frequency
close(f);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                  Finding the maximum            %%%%%
        %%%%%                   Resonant Frequency            %%%%%     
        %%%%%                        First                    %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Decompile the original starting geometry
Project = SonnetProject(ProjectName);
% Place 2 IDC fingers in starting geoemtry
for i=0:1:1
    s=(-1)^i; % Move construction from left to right side of capacitor
    % Reset y coordinates each iteration to place new fingers moving
    % downwards.
    y2_co = y2coord -(spacing+barthickness)-i*(thickness+spacing);
    y1_co = y2_co - thickness;
    if s==-1
        % Build finger connecting to the right side of capacitor.
        % X coordinates of new polygon
        X_Array = [(x1coord+spacing)   x2coord  x2coord  (x1coord+spacing)];
        % Y coordinates of new polygon
        Y_Array = [y1_co   y1_co  y2_co  y2_co];
        % Place new polygon
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
    else
        % Build finger connecting to the left side of capacitor.
        X_Array = [x1coord   (x2coord-spacing)  (x2coord-spacing)  x1coord];
        % Y coordinates of new polygon
        Y_Array = [y1_co   y1_co  y2_co  y2_co];
        % Place new polygon
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
    end
end
% Place 1/4 capacitor coupling bar 
% This length is just from experience as to the minimum length of coupling
% bar at such low capacitance before causing an increase in errors in data.
PlaceCoupleBar(x2coord-(spacing+round(x2coord/4)),y2coord,side_x, spacing, barthickness, Project);
% There is a small area missing between the coupling bar and the IDC of the
% MKID, thus we need to connect them with a small polygon.
% Placing small piece between coupling bar and right side polygon of MKID
% Array of coordinates for small connecting polygon
ArrayXValues=[x2coord  side_x   side_x   x2coord];
ArrayYValues=[y2coord-barthickness   y2coord-barthickness   y2coord-(spacing+barthickness)   y2coord-(spacing+barthickness)];
Project.addMetalPolygonEasy(0,ArrayXValues,ArrayYValues,1);
% Rename the new geometry file.
str_max="maxFrequency.son";
Project.saveAs(str_max);
% After renaming a .son file, must re-decompile into MATLAB everytime.
Project=SonnetProject(str_max);
% New frequency sweep bounds from the previous minimum resonant frequency
% to a larger frequency (i.e. 20GHz).
lower_bound=min_Resonance;
upper_bound = 20;
% Waitbar for user
f = waitbar(0, 'Checking Maximum Resonant Frequency...');
% Simulate and analyse data with Auto_Sim
while true
    try
        [max_Resonance, maxQ_Factor, Warning]=Auto_Sim(Project, upper_bound, lower_bound);
        % Rename .son and .csv files to resonant frequency and delete old
        % files.
        old_son_file=str_max;
        str_son=num2str(max_Resonance)+"GHz.son";
        str_csv_old=erase(str_max, ".son")+".csv";
        str_csv_new=num2str(max_Resonance)+"GHz.csv";
        Project.saveAs(str_son);
        movefile(str_csv_old, str_csv_new);
        delete(old_son_file);
        break
    catch ME
        warning("Something Broke! Retrying...");
        Project.cleanProject;
    end
end
% Close waitbar
close(f);
% Return the maximum resonant frequency structures .son filename
maxProjectName=str_son;
% Kill exisiting cmd windows
system('Taskkill/IM cmd.exe');
end