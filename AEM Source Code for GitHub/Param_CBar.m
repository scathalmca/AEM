function [Sweep_Matrix, box_dimensions] = Param_CBar(Sweep_Matrix,box_dimensions, Qvalues, LeftX, LeftY, x2, y2, spacing)
%  PARAM_CBAR 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function parameterises the coupling bar of the MKID in both
% thickness (y-direction) and length (x-direction). 
% This is done until it finds a geometry with suitable Qc factor set by the user. 
% The function will also call the Param_GND function if the coupling bar
% becomes too large in the y-direction (i.e. 1 block away from the ground
% plane between the MKID and the feedline)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initializing IDC finger coordinates & values from Sweep_Matrix
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
Project_Name = char(Sweep_Matrix{1, 4}(2,1));
% Quality Factor Values
% Q Factor of the MKID geometry
Q_Factor = Sweep_Matrix{1, 6}(2,1);
% User defined acceptable Qc range
user_Q = Qvalues(1);
Q_highbound = Qvalues(2);
Q_lowbound = Qvalues(3);
Project = SonnetProject(Project_Name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In order to call the Param_GND function, we need to input the coordinates
% of the box in the ground plane in which the MKID sits.
% Box dimensions
box_x1=box_dimensions(1);
box_y1=box_dimensions(2);
box_y2=box_dimensions(4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we can use the box coordinates to identify the other ground plane
% polygon coordinates that surround the MKID.
% These are used to determine maximum possible thickness of coupling bar.
% Left side GND Plane coordinates
LGP_xmean = mean([0  box_x1]);
LGP_ymean = mean([box_y1   box_y2]);
LGP_ycoords = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0).YCoordinateValues;
LGP_ycoords = cell2mat(LGP_ycoords);
LGP_ycoords= [LGP_ycoords(2)  LGP_ycoords(3)  LGP_ycoords(4)  LGP_ycoords(5)];
LGP_ycoords = round([min(LGP_ycoords)  min(LGP_ycoords)  max(LGP_ycoords)  max(LGP_ycoords)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bottom ground polygon coordinates that seperates the MKID and the feedline
BGP_ycoords=Project.findPolygonUsingPoint(1,LGP_ycoords(3)+1,0).YCoordinateValues;
BGP_ycoords = cell2mat(BGP_ycoords);
BGP_ycoords= [BGP_ycoords(2)  BGP_ycoords(3)  BGP_ycoords(4)  BGP_ycoords(5)];
BGP_ycoords = round([min(BGP_ycoords)  min(BGP_ycoords)  max(BGP_ycoords)  max(BGP_ycoords)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now identify the coordinates for the coupling bar polygon
Couple_Xcoord = (x2-spacing);
Couple_Ycoord = (y2+0.5);
CBar_Polygon=Project.findPolygonUsingPoint(Couple_Xcoord, Couple_Ycoord);
% Coupling Bar X coordinates
XCoords=CBar_Polygon.XCoordinateValues;
CBar_Xcoords = [XCoords{2}  XCoords{3}  XCoords{4}  XCoords{5}];
CBar_Xcoords =round([min(CBar_Xcoords)  max(CBar_Xcoords)  max(CBar_Xcoords)  min(CBar_Xcoords)]);
% Coupling Bar Y coordinates
YCoords=CBar_Polygon.YCoordinateValues;
CBar_Ycoords = [YCoords{2}  YCoords{3}  YCoords{4}  YCoords{5}];
CBar_Ycoords = round([min(CBar_Ycoords)  min(CBar_Ycoords)  max(CBar_Ycoords)  max(CBar_Ycoords)]);
% Calculate the current thickness (y-direction) of the coupling bar.
barthickness = round(CBar_Ycoords(3)-CBar_Ycoords(1));
% Need to fix
% Q range
Q_diff= round(((x2-5)-LeftX(2))/8);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    :Section 1:                     %%%%%%%%
%%%%%%%%                   Check If The                     %%%%%%%% 
%%%%%%%%                  Dimensions Can                    %%%%%%%% 
%%%%%%%%                 Be Parameterised                   %%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check barthickness is 1 block away from the ground plane seperating the
% MKID to the feedline or the current coupling bar polygon is only 1 block
% in thickness (y-direction).
% If this happens, we need to reset the thickness of the coupling bar to
% the original thickness and vary the thickness of the ground plane polygon
% seperating the MKID to the feedline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (CBar_Ycoords(3) <= CBar_Ycoords(1)+1) || (CBar_Ycoords(3) >= BGP_ycoords(1)-1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % First, reset the coupling bar to the original dimensions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Remove the current coupling bar polygon before placing a new one
    removex=round(mean([CBar_Xcoords(1) CBar_Xcoords(2)]));
    removey=round(mean([CBar_Ycoords(1) CBar_Ycoords(4)]));
    % Find the polygons DebugID
    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
    % Remove the polygon using the DebugID
    Project.deletePolygonUsingId(first_Polygon);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create coords for the new coupling bar polygon being placed
    CBar_Xcoords = [(LeftX(2)-spacing)   CBar_Xcoords(2)  CBar_Xcoords(2)  (LeftX(2)-spacing)];
    CBar_Ycoords = [CBar_Ycoords(1)    CBar_Ycoords(2)   CBar_Ycoords(1)+barthickness    CBar_Ycoords(2)+barthickness];
    % Place new polygon
    Project.addMetalPolygonEasy(0, CBar_Xcoords, CBar_Ycoords, 1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Now, we parameterise the bottom ground plane polygon.
    % Name the new structure
    str=append("Test_ResetGND",'.son');
    % Save the file as "String".son
    Project.saveAs(str);
    % Reset the Sweep_Matrix with new values
    % New Resonant Frequency
    Sweep_Matrix{1, 4}(1,1) = Resonance;
    % New .son Filename
    Sweep_Matrix{1, 4}(2,1) = str;
    % New Q Factor
    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
    % Call Param_GND to begin varying the ground plane polygon for a better
    % Q approximation
    [Sweep_Matrix, ~] = Param_GND(Sweep_Matrix, box_dimensions, Qvalues,(y2 + (spacing+barthickness)), 1, LeftX);
    
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    :Section 2:                     %%%%%%%%
%%%%%%%%                  Determining What                  %%%%%%%%
%%%%%%%%                    Coupling Bar                    %%%%%%%%
%%%%%%%%                 Operation To Perform               %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    :Operation 1:                   %%%%%%%%
%%%%%%%%                     Variation Of                   %%%%%%%%
%%%%%%%%                  Coupling Bar Length               %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the Qc Factor starts off too high, we must increase the length of the coupling
% bar.
% This variation has been shown in Sonnet to reduce Qc Factor. Please see:
% the Low Temperature Detectors 2023 Proceedings Paper 
% "Automation of MKID Simulations for Array Building With AEM (Automated
% Electromagnetic MKID simulations)"
% C.McAleer, et.al, https://doi.org/10.21203/rs.3.rs-3550856/v1
if Q_Factor >= (user_Q + Q_highbound)
    
    % Increase the length of the Coupling Bar (X-direction)
    for i= CBar_Xcoords(1)-Q_diff: -Q_diff : LeftX(1)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Remove the current coupling bar polygon before placing a new one
        removex=round(mean([CBar_Xcoords(1) CBar_Xcoords(2)]));
        removey=round(mean([CBar_Ycoords(1) CBar_Ycoords(4)]));
        % Find the polygons DebugID
        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
        % Remove the polygon using the DebugID
        Project.deletePolygonUsingId(first_Polygon);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % New Coupling Bar dimensions with increased length.
        CBar_Xcoords= [round(i)  CBar_Xcoords(2)  CBar_Xcoords(3)  round(i) ];
        % Place new polygon
        Project.addMetalPolygonEasy(0, CBar_Xcoords, CBar_Ycoords, 1);
        % Name the new structure
        str=append('Test',num2str(round(i)),'.son');
        % Save the file as "String".son
        Project.saveAs(str);
        % Set the upper and lower frequency sweep bounds.
        upper_bound = Resonance +0.2;
        lower_bound = Resonance-0.2;
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If the new Qc Factor lies within the user's designated Qc Factor
        % range, AEM performs another simulation with frequency sweep
        % centered around the resonant frequency of the MKID to produce
        % more accurate Qc values
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if Q_Factor <= user_Q + Q_highbound && Q_Factor >= user_Q - Q_lowbound
            % Stricter frequency sweep bounds centered around the resonant
            % frequency
            upper_bound = Resonance +0.05;
            lower_bound = Resonance -0.05;
            % Reinitalise the geometry
            Project = SonnetProject(str_son);
            % Simulate new project
            while true
                try
                    % Call Auto_Sim for simulation and analysis
                    [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
                    % There is no need to rename the file here
                    break
                catch ME
                    warning("Something Broke! Retrying...");
                    Project.cleanProject;
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Now determining if the Qc factor still lies within the user's
            % range after more accurate simulations
            if Q_Factor <= user_Q + Q_highbound && Q_Factor >= user_Q - Q_lowbound
                % The correct Qc has been found, return function
                
                % Reset Sweep_Matrix to correct values
                % Reset Resonant Frequency
                Sweep_Matrix{1, 4}(1,1) = Resonance;
                % Reset .son Filename
                Sweep_Matrix{1, 4}(2,1) = str_son;
                % Reset correct Qc Factor
                Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                return
            end
        end
        % If the Q Factor still is outside the user's range, reset
        % Sweep_Matrix values and call Param_CBar for recursion
        if Q_Factor < (user_Q - Q_lowbound)
            % Reset Sweep_Matrix values
            % New Resonant Frequency
            Sweep_Matrix{1, 4}(1,1) = Resonance;
            % New .son Filename
            Sweep_Matrix{1, 4}(2,1) = str_son;
            % New Qc Factor
            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
            % Perform recursion
            [Sweep_Matrix, box_dimensions] = Param_CBar(Sweep_Matrix,box_dimensions, Qvalues, LeftX, LeftY, x2, y2, spacing);
            return
        % If the Qc Factor is still too high, continue for loop to increase
        % the length of the coupling bar
       
        end
    end
%If Q Factor starts off being too low, decrease coupling bar length
elseif Q_Factor <= (user_Q - Q_lowbound)
    % Decrease the length of the Coupling Bar (X-direction)
    for i= CBar_Xcoords(1)+Q_diff: Q_diff : CBar_Xcoords(2)-5
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Remove the current coupling bar polygon before placing a new one
        removex=round(mean([CBar_Xcoords(1) CBar_Xcoords(2)]));
        removey=round(mean([CBar_Ycoords(1) CBar_Ycoords(4)]));
        % Find the polygons DebugID
        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
        % Remove the polygon using the DebugID
        Project.deletePolygonUsingId(first_Polygon);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % New Coupling Bar dimensions with decreased length.
        CBar_Xcoords= [round(i)  CBar_Xcoords(2)  CBar_Xcoords(3)  round(i) ];
        % Place new polygon
        Project.addMetalPolygonEasy(0, CBar_Xcoords, CBar_Ycoords, 1);
        % Name the new structure
        str=append('Test',num2str(round(i)),'.son');
        % Save the file as "String".son
        Project.saveAs(str);
        %Set the upper and lower frequency sweep bounds.
        upper_bound = Resonance+0.5;
        lower_bound = Resonance-0.2;
        % Reinitalise the geometry
        Project = SonnetProject(str_son);
        
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If the new Qc Factor lies within the user's designated Qc Factor
        % range, AEM performs another simulation with frequency sweep
        % centered around the resonant frequency of the MKID to produce
        % more accurate Qc values
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if Q_Factor <= (user_Q + Q_highbound) && Q_Factor >= (user_Q - Q_lowbound)
            % Stricter frequency sweep bounds centered around the resonant
            % frequency
            upper_bound = Resonance +0.05;
            lower_bound = Resonance -0.05;
            % Reinitalise the geometry
            Project = SonnetProject(str_son);
            % Simulate new project
            while true
                try
                    % Call Auto_Sim for simulation and analysis
                    [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
                    % There is no need to rename the file here
                    break
                catch ME
                    warning("Something Broke! Retrying...");
                    Project.cleanProject;
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Now determining if the Qc factor still lies within the user's
            % range after more accurate simulations
            if Q_Factor <= (user_Q + Q_highbound) && Q_Factor >= (user_Q - Q_lowbound)
                % The correct Qc has been found, return function
                
                % Reset Sweep_Matrix to correct values
                % Reset Resonant Frequency
                Sweep_Matrix{1, 4}(1,1) = Resonance;
                % Reset .son Filename
                Sweep_Matrix{1, 4}(2,1) = str_son;
                % Reset Qc Factor
                Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                return
            end
        end
        % If the Q Factor still is outside the user's range, reset
        % Sweep_Matrix values and call Param_CBar for recursion
        if Q_Factor > (user_Q + Q_highbound)
            % Reset Sweep_Matrix values
            % New Resonant Frequency
            Sweep_Matrix{1, 4}(1,1) = Resonance;
            % New .son Filename
            Sweep_Matrix{1, 4}(2,1) = str_son;
            % New Qc Factor
            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
            % Perform recursion
            [Sweep_Matrix, box_dimensions] = Param_CBar(Sweep_Matrix,box_dimensions, Qvalues, LeftX, LeftY, x2, y2, spacing);
            return
        end
        % If the Qc Factor is still too low, continue for loop to increase
        % the length of the coupling bar
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    :Operation 2:                   %%%%%%%%
%%%%%%%%                     Variation Of                   %%%%%%%%
%%%%%%%%                Coupling Bar Thickness              %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract current values from Sweep_Matrix
% Resonant Frequency
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
% .son Filename
str_son =char(Sweep_Matrix{1, 4}(2,1));
% Qc Factor
Q_Factor = Sweep_Matrix{1, 6}(2,1);
% Frequency sweep bounds centered around Resonance
upper_bound = Resonance +0.005;
lower_bound = Resonance -0.005;
% Decompile the project
Project = SonnetProject(str_son);
% Simulate new project with stricter bounds for accurate Qc Factor
while true
    try
        % Call Auto_Sim for simulation and analysis
        [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
        % There is no need to rename the file here
        break
    catch ME
        warning("Something Broke! Retrying...");
        Project.cleanProject;
    end
end
% If the Qc Factor lies between the user's range, return the function with
% corrected Sweep_Matrix values
if Q_Factor <= (user_Q + Q_highbound) && Q_Factor >= (user_Q - Q_lowbound)
    
    % Reset Sweep_Matrix
    % Reset Resonant Frequency
    Sweep_Matrix{1, 4}(1,1) = Resonance;
    % Reset .son Filename
    Sweep_Matrix{1, 4}(2,1) = str_son;
    % Reset Qc Factor
    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If Q_Factor can't be corrected via variation of coupling bar length alone,
% we now vary the thickness of the coupling bar and repeat with new
% thickness.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove the current coupling bar polygon before placing a new one
removex=round(mean([CBar_Xcoords(1) CBar_Xcoords(2)]));
removey=round(mean([CBar_Ycoords(1) CBar_Ycoords(4)]));
% Find the polygons DebugID
first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
% Remove the polygon using the DebugID
Project.deletePolygonUsingId(first_Polygon);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now must determine if the Qc Factor is still too low or too high after
% the full variation of the coupling bar length.
% 1) If the Q Factor is still too large, we increase the coupling bar
% thickness (Y-direction) (See proceedings above for more).
if Q_Factor > (user_Q + Q_highbound) && (CBar_Ycoords(3) ~= CBar_Ycoords(1)+1) && (CBar_Ycoords(3) < BGP_ycoords(1)-1)
    %disp("QFactor too large, increasing bar thickness...");
    
    % X-coordinates for a full length coupling bar
    CBar_Xcoords = [(LeftX(2)-spacing)   CBar_Xcoords(2)  CBar_Xcoords(2)  (LeftX(2)-spacing)];
    % Increase the thickness of the coupling bar by 1 block
    CBar_Ycoords = [CBar_Ycoords(1)    CBar_Ycoords(2)   (CBar_Ycoords(3)+1)  (CBar_Ycoords(4)+1)];
% 2) If the Q Factor is still too low, we decrease the coupling bar
% thickness (Y-direction).
elseif Q_Factor < (user_Q - Q_lowbound) && (CBar_Ycoords(3) ~= BGP_ycoords(1)-1)
    %disp("QFactor too low, decreasing bar thickness...");
    
    % X-coordinates for a full length coupling bar
    CBar_Xcoords = [(LeftX(2)-spacing)   CBar_Xcoords(2)  CBar_Xcoords(2)  (LeftX(2)-spacing)];
    % Increase the thickness of the coupling bar by 1 block
    CBar_Ycoords = [CBar_Ycoords(1)    CBar_Ycoords(2)   (CBar_Ycoords(3)-1)  (CBar_Ycoords(4)-1)];
    
% 3) If the thickness of the current coupling bar is 1 block or if the
% coupling bar thickness is 1 block away in distance from the bottom ground
% plane seperating the MKID from the feedline, we need to reset the
% thickness and vary the ground plane.
elseif (CBar_Ycoords(3) <= CBar_Ycoords(1)+1) || (CBar_Ycoords(3) >= BGP_ycoords(1)-1)
    % X-coordinates for a full length coupling bar
    CBar_Xcoords = [(LeftX(2)-spacing)   CBar_Xcoords(2)  CBar_Xcoords(2)  (LeftX(2)-spacing)];
    
    % Original Y-coordinates of coupling bar provided by the user 
    CBar_Ycoords = [CBar_Ycoords(1)    CBar_Ycoords(2)   CBar_Ycoords(1)+barthickness    CBar_Ycoords(2)+barthickness];
    % Place the new polygon
    Project.addMetalPolygonEasy(0, CBar_Xcoords, CBar_Ycoords, 1);
    % Name the new structure
    str=append("Test_ResetGND",'.son');
    % Save the file as "String".son
    Project.saveAs(str);
    % Reset Resonant Frequency
    Sweep_Matrix{1, 4}(1,1) = Resonance;
    % Reset .son Filename
    Sweep_Matrix{1, 4}(2,1) = str;
    % Reset new Qc Factor
    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
    % Call Param_GND to vary the bottom ground plane polygon
    [Sweep_Matrix, ~] = Param_GND(Sweep_Matrix, box_dimensions, Qvalues,(y2 + (spacing+barthickness)), 1, LeftX);
    
    return
end
% Place the polygon dictated by 1) or 2)
Project.addMetalPolygonEasy(0, CBar_Xcoords, CBar_Ycoords, 1);
% Name the new structure
str=append("Test_Thickness",'.son');
% Save the file as "String".son
Project.saveAs(str);
% Decompile the new geometry file
Project = SonnetProject(str);
% Set new frequency sweep bounds
upper_bound = Resonance+0.5;
lower_bound = Resonance-0.5;
% Simulate new project 
while true
    try
        % Call Auto_Sim for simulation and analysis
        [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
        % There is no need to rename the file here
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
% Reset Sweep_Matrix with new values
% New Resonant Frequency
Sweep_Matrix{1, 4}(1,1) = Resonance;
% New .son Filename
Sweep_Matrix{1, 4}(2,1) = str_son;
% New Qc Factor
Sweep_Matrix{1, 6}(2,1) = Q_Factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determining where the Qc now lies
% If the Qc now lies within the user's bounds, return function
if Q_Factor <= (user_Q + Q_highbound) && Q_Factor >= (user_Q - Q_lowbound)
    return
else
    % If the Qc is still not correct, perform recursion until correct Qc is
    % found.
    [Sweep_Matrix, box_dimensions] = Param_CBar(Sweep_Matrix,box_dimensions, Qvalues, LeftX, LeftY, x2, y2, spacing);
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end