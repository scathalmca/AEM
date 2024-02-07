function [Sweep_Matrix] = Sense_Sweep(Sweep_Matrix)
%  SENSE_SWEEP Performs sensitivity sweep between two given co-ordinates 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is used AFTER Guess_Sim.mlx and places 1 block capacitor
% fingers from x1-x3(Right)/x2-x3(Left) to find the MKID with the closest possible 
% resonant frequency to the user's designed resonant frequency.
% Sense_Sweep (or Sensitive Sweep) places 1 block increments and thus is it
% important to call this function when the distance between x1-x3/x2-x3 is
% small (i.e. in the case of AEM, 10 blocks).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Importing values from each row of Sweep_Matrix
y1_co =Sweep_Matrix{1, 1}(1,2);
y2_co = Sweep_Matrix{1, 1}(2,2);
x1_co = Sweep_Matrix{1, 1}(1,1);
x2_co = Sweep_Matrix{1, 2}(1,1);
x3_co = Sweep_Matrix{1, 3}(1,1);
% Import resonant frequencies from Sweep_Matrix
% Current MKID Resonant Frequency 
f1 = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
% Previous MKID Resonant Frequency
f2 = str2double(cell2mat(Sweep_Matrix{1, 5}(1,1)));
% Assigning values
Resonance = f1;
Project_Name = char(Sweep_Matrix{1, 4}(2,1));
User_Frequency = Sweep_Matrix{1, 6}(1,1);
Q_Factor = Sweep_Matrix{1, 6}(2,1);
prev_resonance = Resonance;
prev_Q = Q_Factor;
prev_son = char(Sweep_Matrix{1, 4}(2,1));
prev_x2 = x2_co;
prev_x1 = x1_co;
% Decompile geometry
Project = SonnetProject(Project_Name);
% To avoid any illegal frequency sweeps where f2>f1
% This just avoids mishaps occurring in the code
if f2 > f1
    [f2 , f1] = deal(f1,f2);
end
% Here, determine whether the user's resonant frequency lies closer to f1
% or f2.
% This will let AEM know whether the build starting from e.g. x1 (for finger
% connected to right side) or decrease from x3
near_f1 =abs(User_Frequency-f1);
near_f2 = abs(User_Frequency -f2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    Building Capacitor              %%%%%%%%
%%%%%%%%                        Fingers                     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First, using the coordinates from Sweep_Matrix, we can determine whether
% the capacitor finger is connected to the left or right side of the
% capacitor.
if x3_co > x1_co % Starting on the left side of the capacitor
    
    % Iterate through blocks from x2_co to x3_co
    for b = x2_co+1 : 1 : x3_co
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Next, we determine if we should start from x2_co or x3_co, we
        % chose whatever is closer to the user's resonant frequency.
        % This reduces the overall amount of simulations needed to be
        % performed.
        % If the user's resonance is closer to x3_co, start from x3_co
        % I.e Build Backwards.
        if near_f2 < near_f1
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Determine what x coordinates of the polygon that needs to be
            % removed in current iteration of for loop.
            if b == (x2_co +1)
                removex=mean([x1_co  x2_co]);
            else
                removex=mean([x1_co ((x2_co-b)+x3_co) ]);
            end
            % Y coordinates of polygon to be deleted.
            removey = mean([y1_co y2_co]);
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            % X array of the new polygon being placed.
            X_Array= [x1_co  ((x2_co-b)+x3_co)  ((x2_co-b)+x3_co) x1_co];
            % Y array of the new polygon being placed.
            Y_Array = [y1_co  y1_co   y2_co  y2_co];
            % Place the new polygon.
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str=append('Test',num2str(round(b)),'.son');
            % Save the file as "String".son
            Project.saveAs(str);
            % Set the upper and lower frequency sweep bounds.
            upper_bound = Resonance+0.05;
            lower_bound = Resonance-0.05;
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
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Now we check if the current resonant frequency (Resonance) is
            % closer to the user's resonance than the previous resonance
            % (prev_resonance). 
            % We call Accuracy_Check to check which is closer.
            % If Value = 1, we found the closest possible resonant
            % frequency to the user's resonance.
            % Call Accuracy_Check
            [Value] = Accuracy_Check(Resonance, prev_resonance, User_Frequency);
            % The previous resonant frequency is the closest to the user's
            % frequency, so return the Sweep_Matrix with the previous MKID
            % specifications
            if Value == 1
                % New x2
                Sweep_Matrix{1, 2}(1,1) = prev_x2;
                % New Resonant Frequency
                Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                % New Qc Factor
                Sweep_Matrix{1, 6}(2,1) = prev_Q;
                % New .son Filename
                Sweep_Matrix{1, 4}(2,1) = prev_son;
                return
            end
            % If Resonance is closer to the user's resonant frequency,
            % continue looping and placing capacitor finger blocks until
            % prev_resonance is closer to user's resonance.
            % Reset previous values for forloop.
            prev_resonance = Resonance;
            prev_Q = Q_Factor;
            prev_son = str_son;
            prev_x2 = x2_co;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Else, if x2_co is closer to the user's resonant frequency, place
        % capacitor finger blocks starting from x2_co
        elseif (near_f1 < near_f2) || (near_f1 == near_f2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X coordinates of polygon to be deleted.
            removex=round(mean([x1_co b]));
            % Y coordinates of polygon to be deleted.
            removey=round(mean([y1_co y2_co]));
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X array of the new polygon being placed.
            X_Array= [x1_co  b   b  x1_co];
            % Y array of the new polygon being placed.
            Y_Array = [y1_co  y1_co   y2_co  y2_co];
            % Place new polygon.
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str=append('Test',num2str(round(b)),'.son');
            % Save the file as "String".son
            Project.saveAs(str);
            % Set the upper and lower frequency sweep bounds.
            upper_bound = Resonance+0.05;
            lower_bound = Resonance-0.05;
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
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Now we check if the current resonant frequency (Resonance) is
            % closer to the user's resonance than the previous resonance
            % (prev_resonance). 
            % We call Accuracy_Check to check which is closer.
            % If Value = 1, we found the closest possible resonant
            % frequency to the user's resonance.
            % Call Accuracy_Check
            [Value] = Accuracy_Check(Resonance, prev_resonance, User_Frequency);
            if Value == 1
                % New x2
                Sweep_Matrix{1, 2}(1,1) = prev_x2;
                % New Resonant Frequency
                Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                % New Qc Factor
                Sweep_Matrix{1, 6}(2,1) = prev_Q;
                % New .son Filename
                Sweep_Matrix{1, 4}(2,1) = prev_son;
                return
            end
            % If Resonance is closer to the user's resonant frequency,
            % continue looping and placing capacitor finger blocks until
            % prev_resonance is closer to user's resonance.
            % Reset previous values for forloop.
            prev_resonance = Resonance;
            prev_Q = Q_Factor;
            prev_son = str_son;
            prev_x2 = b;
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Starting on the right side of the capacitor
elseif x3_co < x1_co
    % Iterate through blocks from x1_co to x3_co
    for b=x1_co-1 : -1 : x3_co
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Next, we determine if we should start from x1_co or x3_co, we
        % chose whatever is closer to the user's resonant frequency.
        % This reduces the overall amount of simulations needed to be
        % performed.
        % If the user's resonance is closer to x3_co, start from x3_co
        % I.e Build Backwards.
        if near_f2 < near_f1
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Determine what x coordinates of the polygon that needs to be
            % removed in current iteration of for loop.
            if b == (x1_co - 1)
                removex=mean([x1_co  x2_co]);
            else
                removex=mean([( (x1_co-b)+x3_co)  x2_co]);
            end
            % Y coordinates of polygon to be deleted.
            removey = mean([y1_co y2_co]);
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X array of the new polygon being placed.
            X_Array= [(x1_co-b)+x3_co  x2_co  x2_co  (x1_co-b)+x3_co];
            % Y array of the new polygon being placed.
            Y_Array = [y1_co  y1_co   y2_co  y2_co];
            % Place new polygon.
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str=append('Test',num2str(round(b)),'.son');
            % Save the file as "String".son
            Project.saveAs(str);
            % Set the upper and lower frequency sweep bounds.
            upper_bound = Resonance+0.05;
            lower_bound = Resonance-0.05;
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
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Now we check if the current resonant frequency (Resonance) is
            % closer to the user's resonance than the previous resonance
            % (prev_resonance). 
            % We call Accuracy_Check to check which is closer.
            % If Value = 1, we found the closest possible resonant
            % frequency to the user's resonance.
            % Call Accuracy_Check
            [Value] = Accuracy_Check(Resonance, prev_resonance, User_Frequency);
            if Value == 1
                % New x1
                Sweep_Matrix{1, 1}(1,1) = prev_x1; 
                % New Resonant Frequency
                Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                % New Qc Factor
                Sweep_Matrix{1, 6}(2,1) = prev_Q;
                % New .son Filename
                Sweep_Matrix{1, 4}(2,1) = prev_son;
                return
            end
            % If Resonance is closer to the user's resonant frequency,
            % continue looping and placing capacitor finger blocks until
            % prev_resonance is closer to user's resonance.
            % Reset previous values for forloop.
            prev_resonance = Resonance;
            prev_Q = Q_Factor;
            prev_son = str_son;
            prev_x1 = (x1_co-b)+x3_co;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Else, if x1_co is closer to the user's resonant frequency, place
        % capacitor finger blocks starting from x1_co
        elseif (near_f1 < near_f2) || (near_f1 == near_f2)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X coordinates of polygon to be deleted.
            removex=round(mean([x2_co b]));
            % Y coordinates of polygon to be deleted.
            removey=round(mean([y1_co y2_co]));
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % X array of the new polygon being placed.
            X_Array= [b  x2_co  x2_co  b];
            % Y array of the new polygon being placed.
            Y_Array = [y1_co  y1_co   y2_co  y2_co];
            % Place new polygon.
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str=append('Test',num2str(round(b)),'.son');
            % Save the file as "String".son
            Project.saveAs(str);
            % Set the upper and lower frequency sweep bounds.
            upper_bound = Resonance+0.05;
            lower_bound = Resonance-0.05;
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
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Now we check if the current resonant frequency (Resonance) is
            % closer to the user's resonance than the previous resonance
            % (prev_resonance). 
            % We call Accuracy_Check to check which is closer.
            % If Value = 1, we found the closest possible resonant
            % frequency to the user's resonance.
            % Call Accuracy_Check
            [Value] = Accuracy_Check(Resonance, prev_resonance, User_Frequency);
            if Value == 1
                % New x1
                Sweep_Matrix{1, 1}(1,1) = prev_x1; 
                % New Resonant Frequency
                Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                % New Qc Factor
                Sweep_Matrix{1, 6}(2,1) = prev_Q;
                % New .son Filename
                Sweep_Matrix{1, 4}(2,1) = prev_son;
                return
            end
            % If Resonance is closer to the user's resonant frequency,
            % continue looping and placing capacitor finger blocks until
            % prev_resonance is closer to user's resonance.
            % Reset previous values for forloop.
            prev_resonance = Resonance;
            prev_Q = Q_Factor;
            prev_son = str_son;
            prev_x1 = b;
        end
    end
end
end