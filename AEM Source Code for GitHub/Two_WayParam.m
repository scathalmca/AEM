function [Sweep_Matrix] = Two_WayParam(Sweep_Matrix, x1,x2,y1,y2, spacing, thickness)
%  TWO_WAYPARAM Function designed to decide whether to remove or build more capacitor area 
% to the MKID depending on resonant frequency. This is done by removing(or adding) 
% whole IDC fingers at a time to find the approximate geometry for the desired 
% resonance, then performing a binary search until the resonant frequency lies 
% within 10 um of capacitor.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is used AFTER an appropriate Qc value is found
% It is used to reset the resonant frequency of the MKID after Qc
% parameterisation.
% The function decides whether to add more or remove capacitor fingers 
% in order to achieve a close approximation of the user's resonant
% frequency.
% Two_WayParam performs the binary search parameterisation until the user's
% resonant frequency lies within a 10 block capacitor finger span.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initializing IDC finger coordinates & values from Sweep_Matrix
x1_co=Sweep_Matrix{1, 1}(1,1);
x2_co = Sweep_Matrix{1, 2}(1,1);
y1_co = Sweep_Matrix{1, 1}(1,2);
y2_co = Sweep_Matrix{1, 1}(2,2);
% Initialise other variables from Sweep_Matrix
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
Project_Name = char(Sweep_Matrix{1, 4}(2,1));
User_Frequency = Sweep_Matrix{1, 6}(1,1);
Project = SonnetProject(Project_Name);
prev_resonance = Resonance;
prev_filename = Project_Name;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the total length (y direction) of the IDC capacitor area.
y_total=(y2-y2_co);
% Calculate how many capacitor fingers have already been placed.
forloop_start=floor(y_total/(spacing+thickness))+1;
% Calculate the maximum number of allowed IDC fingers.
forloop_end=NumCap(y1,y2,spacing,thickness)+1;
% Calculate the full length of a single finger.
Length=x2-x1-spacing;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    Building Capacitor              %%%%%%%%
%%%%%%%%                        Fingers                     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the current resonant frequency is higher than the desired user
% frequency, add more capacitor fingers.
% This section begins with removing the capacitor finger closest to the
% inductor of the MKID, then placing a full length finger in its place.
% If this new geometry is still below the user's resonant frequency, begin
% adding 1/2 sections of capacitor fingers. 
% If the MKID does have a resonance below User_Frequency, the code calls
% Guess_Sim to shorten/lengthen the capacitor finger such that the user's
% resonant frequency lies within a 10 block length of IDC.
if User_Frequency < Resonance
    % From current IDC finger to last possible finger.
    for i=forloop_start : 1 : forloop_end
        
        % If starting from the first(current) finger, we must remove it
        % first before placing a new polygon
        if i==forloop_start
            % Remove none whole finger
            removex=round(mean([x1_co x2_co]));
            removey=round(mean([y1_co y2_co]));
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Determine whether the polygon is connected to the left or the
            % right side of the IDC capacitor.
            s=(-1)^i; 
            if s==1 % Start on right side
                
                % Full length of finger connected on the right side
                X_Array= [(x1+spacing)  x2   x2  (x1+spacing)];
            elseif s==-1 % Start on left side
                % Full length of finger connected on the left side
                X_Array= [x1  (x2-spacing)   (x2-spacing)  x1];
            end
            
            % Y coordinates of the polygon
            Y_Array = [y1_co  y1_co   y2_co  y2_co];
            % Place new full length finger polygon
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            %Name the new structure temporarily.
            str="Test_Forwards.son";
            %Save the file as "String".son
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
            % Test to see if the resonant frequency is still below the user
            % frequency
            if Resonance <= User_Frequency
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                s=(-1)^forloop_start; % Even = Right, Odd = Left
                if s==-1 % Finger connected on left side of MKID
                    % Reset coordinates in Sweep_Matrix to new geometry
                    % New x1 coordinate
                    Sweep_Matrix{1, 1}(1,1) = x1; 
                    % New x2 coordinate
                    Sweep_Matrix{1, 2}(1,1) = x1+2;
                    % New x3 coordinate
                    Sweep_Matrix{1, 3}(1,1) = x2;
                    % New Resonant Frequency
                    Sweep_Matrix{1, 4}(1,1) = Resonance;
                    % New .son Filename
                    Sweep_Matrix{1, 4}(2,1) = str_son;
                    % New Qc Factor
                    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                    % New previous resonant frequency
                    Sweep_Matrix{1, 5}(1,1) = prev_resonance;
                    % New previous filename
                    Sweep_Matrix{1, 5}(2,1) = prev_filename;
                    % After placing new capacitor finger, check if the user
                    % resonant frequency lies within 10 blocks of
                    % capacitor.
                    % If the finger is not within 10 blocks, call Guess_Sim
                    % to perform binary search to bring the MKID geometry
                    % atleast 10 blocks away from the user's resonant
                    % frequency
                    if (x2 -(x1+2)) >10 && Resonance ~= User_Frequency
                        while true
                            try
                                % Call Guess_Sim to perform binary sweep to
                                % bring the MKID 10 blocks within the user
                                % frequency
                                [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                % Import new x2 and x3 from Sweep_Matrix (As we
                                % are connected to the left side of the
                                % MKID and already know x1
                                x2_co =Sweep_Matrix{1, 2}(1,1);
                                x3_co = Sweep_Matrix{1, 3}(1,1);
                                % Extract resonant frequency from
                                % Sweep_Matrix
                                Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                % Test if the user resonant frequency now exists
                                % within less than 10 capacitor blocks.
                                new_polygon_length = x3_co-x2_co;
                                if new_polygon_length <=10 || Resonance == User_Frequency
                                    break
                                end
                            end
                        end
                    end
                    return
                elseif s==1 % Finger connected on right side of MKID
                    % Reset coordinates in Sweep_Matrix to new geometry
                    % New x1 coordinate
                    Sweep_Matrix{1, 1}(1,1) = x2-2;
                    % New x2 coordinate
                    Sweep_Matrix{1, 2}(1,1) = x2;
                    % New x3 coordinate
                    Sweep_Matrix{1, 3}(1,1) = x1;
                    % New Resonant Frequency
                    Sweep_Matrix{1, 4}(1,1) = Resonance;
                    % New .son Filename
                    Sweep_Matrix{1, 4}(2,1) = str_son;
                    % New Qc Factor
                    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                    % New previous resonant frequency
                    Sweep_Matrix{1, 5}(1,1) = prev_resonance;
                    % New previous filename
                    Sweep_Matrix{1, 5}(2,1) = prev_filename;
                    % After placing new capacitor finger, check if the user
                    % resonant frequency lies within 10 blocks of
                    % capacitor.
                    % If the finger is not within 10 blocks, call Guess_Sim
                    % to perform binary search to bring the MKID geometry
                    % atleast 10 blocks away from the user's resonant
                    % frequency
                    if ((x2-2)-x1) >10 && Resonance ~= User_Frequency
                        while true
                            try
                                % Call Guess_Sim to perform binary sweep to
                                % bring the MKID 10 blocks within the user
                                % frequency
                                [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                % Import new x1 and x3 from Sweep_Matrix (As we
                                % are connected to the right side of the
                                % MKID and already know x2
                                x1_co=Sweep_Matrix{1, 1}(1,1);
                                x3_co = Sweep_Matrix{1, 3}(1,1);
                                % Extract resonant frequency from
                                % Sweep_Matrix
                                Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                % Test if the user resonant frequency now exists
                                % within less than 10 capacitor blocks.
                                new_polygon_length = x1_co-x3_co;
                                if new_polygon_length <=10 || Resonance == User_Frequency
                                    break
                                end
                            end
                        end
                    end
                    return
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            % If the user frequency still is lower than the resonant
            % frequency, continue the loop placing capacitor fingers.
            % Reset values for next iteration in loop
            prev_resonance = Resonance;
            prev_filename = str_son;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % If the finger is not the initial non-whole capacitor finger
        else
            
            % Reset y coordinates after every loop
            y1_co = y2 - i*(spacing+thickness);
            y2_co = y1_co + thickness;
            s=(-1)^i; % Clock to go from left side to right side of capacitor
            % Odd  = Left, Even = Right
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if s==-1 % Finger connected on left side of MKID
                % Reset x2 every loop 
                prev_x2 = x1+round(Length/4);
                % Place 1/4 sections of capacitor.
                for b=Length/4 : Length/4 : Length
                    
                    % New X coordinate array
                    X_Array = [x1   x1+round(b)   x1+round(b)  x1];
                    Y_Array = [y1_co  y1_co  y2_co  y2_co];
                    % Place new polygon
                    Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
                    % Name the new structure
                    str=append("Test", num2str(i),"_", num2str(round(b)),".son");
                    % Save the file as "String".son
                    Project.saveAs(str);
                    % Set new upper and lower frequency sweep bounds
                    upper_bound = Resonance +0.2;
                    lower_bound = Resonance-0.2;
                    % Decompile new Sonnet Project
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
                    % Test to see if the resonant frequency is still below the user
                    % frequency
                    if Resonance <= User_Frequency
                        
                        % We must be careful with coordinates when working
                        % with a previous polygon with differing y coords.
                        % I.e. starting with a new polygon with new y
                        % coordiantes.
                        if b == Length/4
                            % Reset all coordinates in Sweep_Matrix
                            % New x1 coordinate
                            Sweep_Matrix{1, 1}(1,1) = x1;
                            
                            % New x2 coordinate
                            Sweep_Matrix{1, 2}(1,1) = x1+2;
                            % New x3 coordinate
                            Sweep_Matrix{1, 3}(1,1) = X_Array(2);
                            % New y1 coordinate
                            Sweep_Matrix{1, 1}(1,2) = Y_Array(1);
                            % New y2 coordinate
                            Sweep_Matrix{1, 1}(2,2) = Y_Array(3);
                            % New Resonant Frequency
                            Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                            % New .son Filename
                            Sweep_Matrix{1, 4}(2,1) = str_son;
                            % New Qc Factor 
                            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                            % New previous resonance
                            Sweep_Matrix{1, 5}(1,1) = Resonance;
                            % New previous filename
                            Sweep_Matrix{1, 5}(2,1) = str_son;
                            % After placing new capacitor finger, check if the user
                            % resonant frequency lies within 10 blocks of
                            % capacitor.
                            % If the finger is not within 10 blocks, call Guess_Sim
                            % to perform binary search to bring the MKID geometry
                            % atleast 10 blocks away from the user's resonant
                            % frequency
                            if (X_Array(2)-(x1+2)) >10 && Resonance ~= User_Frequency
                                while true
                                    try
                                        % Call Guess_Sim to perform binary sweep to
                                        % bring the MKID 10 blocks within the user
                                        % frequency
                                        [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                        % Import new x2 and x3 from Sweep_Matrix (As we
                                        % are connected to the left side of the
                                        % MKID and already know x1
                                        x2_co =Sweep_Matrix{1, 2}(1,1);
                                        x3_co = Sweep_Matrix{1, 3}(1,1);
                                        
                                        % Extract resonant frequency from
                                        % Sweep_Matrix
                                        Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                        % Test if the user resonant frequency now exists
                                        % within less than 10 capacitor blocks.
                                        new_polygon_length = x3_co-x2_co;
                                        if new_polygon_length <=10 || Resonance == User_Frequency
                                            break
                                        end
                                    end
                                end
                            end
                        % Else if the polygon does not start with new y-
                        % coordinates.
                        else
                            % Reset all coordinates in Sweep_Matrix
                            
                            % New x1 coordinate
                            Sweep_Matrix{1, 1}(1,1) = x1;
                            % New x2 coordinate
                            Sweep_Matrix{1, 2}(1,1) = prev_x2;
                            % New x3 coordinate
                            Sweep_Matrix{1, 3}(1,1) = X_Array(2);
                            % New y1 coordinate
                            Sweep_Matrix{1, 1}(1,2) = Y_Array(1);
                            % New y2 coordinate
                            Sweep_Matrix{1, 1}(2,2) = Y_Array(3);
                            % New Resonant Frequency
                            Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                            % New .son Filename
                            Sweep_Matrix{1, 4}(2,1) = str_son;
                            % New Qc Factor
                            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                            % New previous resonant frequency
                            Sweep_Matrix{1, 5}(1,1) = Resonance;
                            % New filename
                            Sweep_Matrix{1, 5}(2,1) = str_son;
                            % After placing new capacitor finger, check if the user
                            % resonant frequency lies within 10 blocks of
                            % capacitor.
                            % If the finger is not within 10 blocks, call Guess_Sim
                            % to perform binary search to bring the MKID geometry
                            % atleast 10 blocks away from the user's resonant
                            % frequency
                            if (X_Array(2)-prev_x2) >10 && Resonance ~= User_Frequency
                                while true
                                    try
                                        % Call Guess_Sim to perform binary sweep to
                                        % bring the MKID 10 blocks within the user
                                        % frequency
                                        [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                        % Import new x2 and x3 from Sweep_Matrix (As we
                                        % are connected to the left side of the
                                        % MKID and already know x1
                                        x2_co=Sweep_Matrix{1, 2}(1,1);
                                        x3_co = Sweep_Matrix{1, 3}(1,1);
                                        % Extract resonant frequency from
                                        % Sweep_Matrix
                                        Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                        % Test if the user resonant frequency now exists
                                        % within less than 10 capacitor blocks.
                                        new_polygon_length = x3_co-x2_co;
                                        if new_polygon_length <=10 || Resonance == User_Frequency
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        return
                    end
                    % If the polygon does not contain the user resonant
                    % frequency and is not the full length of capacitor
                    % finger, we remove the section before building on a
                    % new polygon
                    if b~=Length
                        removex=round(mean([x1 X_Array(2)]));
                        removey=round(mean([y1_co y2_co]));
                        % Find the polygons DebugID
                        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                        % Remove the polygon using the DebugID
                        Project.deletePolygonUsingId(first_Polygon);
                    end
                    % Reset new values every loop
                    % Previous x2 coordinate
                    prev_x2 = X_Array(2);
                    % Previous filename
                    prev_filename = str_son;
                    % Previous resonnat frequency
                    prev_resonance = Resonance;
                end
    
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            elseif s==1 % Finger connected on right side of MKID
                % Reset x1 every loop 
                prev_x1 = (x2-round(Length/4));
                % Place 1/4 sections of capacitor.
                for b=Length/4 : Length/4 : Length
                    % New X coordinate array
                    X_Array= [(x2-round(b))  x2  x2  (x2-round(b))];
                    Y_Array = [y1_co  y1_co  y2_co  y2_co];
                    % Place new polygon
                    Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
                    % Name the new structure
                    str=append("Test", num2str(i),"_", num2str(b),".son");
                    % Save the file as "String".son
                    Project.saveAs(str);
                    % Set new upper and lower frequency sweep bounds
                    upper_bound = Resonance +0.2;
                    lower_bound = Resonance-0.2;
                    % Decompile new Sonnet Project
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
                    % Test to see if the resonant frequency is still below the user
                    % frequency
                    if Resonance <= User_Frequency
                        % We must be careful with coordinates when working
                        % with a previous polygon with differing y coords.
                        % I.e. starting with a new polygon with new y
                        % coordiantes.
                        if b == Length/4
                            % Reset all coordinates in Sweep_Matrix
                            % New x1 coordinate
                            Sweep_Matrix{1, 1}(1,1) = x2-2;
                            % New x2 coordinate
                            Sweep_Matrix{1, 2}(1,1) = x2;
                            % New x3 coordinate
                            Sweep_Matrix{1, 3}(1,1) = X_Array(1);
                            % New y1 coordinate
                            Sweep_Matrix{1, 1}(1,2) = Y_Array(1);
                            % New y2 coordinate
                            Sweep_Matrix{1, 1}(2,2) = Y_Array(3);
                            % New Resonant Frequency
                            Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                            % New .son Filename
                            Sweep_Matrix{1, 4}(2,1) = str_son;
                            % New Qc Factor
                            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                            % New previous resonance
                            Sweep_Matrix{1, 5}(1,1) = Resonance;
                            % New previous filename
                            Sweep_Matrix{1, 5}(2,1) = str_son;
                            % After placing new capacitor finger, check if the user
                            % resonant frequency lies within 10 blocks of
                            % capacitor.
                            % If the finger is not within 10 blocks, call Guess_Sim
                            % to perform binary search to bring the MKID geometry
                            % atleast 10 blocks away from the user's resonant
                            % frequency
                            if ((x2-2)-X_Array(1)) >10 && Resonance ~= User_Frequency
                                while true
                                    try
                                        % Call Guess_Sim to perform binary sweep to
                                        % bring the MKID 10 blocks within the user
                                        % frequency
                                        [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                        % Import new x1 and x3 from Sweep_Matrix (As we
                                        % are connected to the right side of the
                                        % MKID and already know x2
                                        x1_co =Sweep_Matrix{1, 1}(1,1);
                                        x3_co = Sweep_Matrix{1, 3}(1,1);
                                        % Extract resonant frequency from
                                        % Sweep_Matrix
                                        Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                        % Test if the user resonant frequency now exists
                                        % within less than 10 capacitor blocks.
                                        new_polygon_length = x1_co-x3_co;
                                        if new_polygon_length <=10 || Resonance == User_Frequency
                                            break
                                        end
                                    end
                                end
                            end
                        % Else if the polygon does not start with new y-
                        % coordinates.
                        else
                            % Reset all coordinates in Sweep_Matrix
                            
                            % New x1 coordinate
                            Sweep_Matrix{1, 1}(1,1) = prev_x1;
                            % New x2 coordinate
                            Sweep_Matrix{1, 2}(1,1) = x2;
                            % New x3 coordinate
                            Sweep_Matrix{1, 3}(1,1) = X_Array(1);
                            % New y1 coordinate
                            Sweep_Matrix{1, 1}(1,2) = Y_Array(1);
                            % New y2 coordinate
                            Sweep_Matrix{1, 1}(2,2) = Y_Array(3);
                            % New Resonant Frequency
                            Sweep_Matrix{1, 4}(1,1) = prev_resonance;
                            % New .son Filename
                            Sweep_Matrix{1, 4}(2,1) =str_son;
                            % New Qc Factor
                            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                            % New previous resonance
                            Sweep_Matrix{1, 5}(1,1) = Resonance;
                            % New filename
                            Sweep_Matrix{1, 5}(2,1) = str_son;
                            % After placing new capacitor finger, check if the user
                            % resonant frequency lies within 10 blocks of
                            % capacitor.
                            % If the finger is not within 10 blocks, call Guess_Sim
                            % to perform binary search to bring the MKID geometry
                            % atleast 10 blocks away from the user's resonant
                            % frequency
                            if (prev_x1-X_Array(1)) >10 && Resonance ~= User_Frequency
                                while true
                                    try
                                        % Call Guess_Sim to perform binary sweep to
                                        % bring the MKID 10 blocks within the user
                                        % frequency
                                        [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                        % Import new x1 and x3 from Sweep_Matrix (As we
                                        % are connected to the right side of the
                                        % MKID and already know x2
                                        x1_co=Sweep_Matrix{1, 1}(1,1);
                                        x3_co = Sweep_Matrix{1, 3}(1,1);
                                        % Extract resonant frequency from
                                        % Sweep_Matrix
                                        Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                        % Test if the user resonant frequency now exists
                                        % within less than 10 capacitor blocks.
                                        new_polygon_length = x1_co-x3_co;
                                        if new_polygon_length <=10 || Resonance == User_Frequency
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        return
                    end
                    % If the polygon does not contain the user resonant
                    % frequency and is not the full length of capacitor
                    % finger, we remove the section before building on a
                    % new polygon
                    if b~=Length
                        removex=round(mean([X_Array(1) X_Array(2)]));
                        removey=round(mean([y1_co y2_co]));
                        % Find the polygons DebugID
                        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                        % Remove the polygon using the DebugID
                        Project.deletePolygonUsingId(first_Polygon);
                    end
                    % Reset new values every loop
                    % Previous x1 coordinate
                    prev_x1 = X_Array(1);
                    % Previous .son filename
                    prev_filename = str_son;
                    % Previous resonant frequency
                    prev_resonance = Resonance;
                end
            end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    Removing Capacitor              %%%%%%%%
%%%%%%%%                        Fingers                     %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif User_Frequency > Resonance 
    % Starting from the finger closest to the inductor, remove capacitor
    % fingers until 3 are left (approximation).
    for i=forloop_start : -1 : 3
        if i==forloop_start
            % Remove none whole finger
            removex=round(mean([x1_co x2_co]));
            removey=round(mean([y1_co y2_co]));
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Determine whether the polygon is connected to the left or the
            % right side of the IDC capacitor.
            s=(-1)^i;
            if s==1 % Start on right side
                % Full length of finger connected on the right side
                X_Array= [(x2-2)  x2_co   x2_co  (x2-2)];
            elseif s==-1 % Start on left side
                % Full length of finger connected on the left side
                X_Array= [x1  (x1_co+2)   (x1_co+2)  x1];
            end
            Y_Array = [y1_co  y1_co   y2_co  y2_co];
            % Y coordinates of the polygon
            Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
            % Name the new structure
            str="Test_Backwards.son";
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
            % Test to see if the resonant frequency is still above the user
            % frequency
            if Resonance >= User_Frequency
                s=(-1)^forloop_start; % Even = Right, Odd = Left
                if s==-1 % Finger connected on left side of MKID
                    % Reset coordinates in Sweep_Matrix to new geometry
                    % New x1 coordinate
                    Sweep_Matrix{1, 1}(1,1) = x1;
                    % New x2 coordinate
                    Sweep_Matrix{1, 2}(1,1) = x1+2;
                    % New x3 coordinate
                    Sweep_Matrix{1, 3}(1,1) = x2;
                    % New Resonant Frequency
                    Sweep_Matrix{1, 4}(1,1) = Resonance;
                    % New .son Filename
                    Sweep_Matrix{1, 4}(2,1) = str_son;
                    % New Qc Factor
                    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                    % After placing new capacitor finger, check if the user
                    % resonant frequency lies within 10 blocks of
                    % capacitor.
                    % If the finger is not within 10 blocks, call Guess_Sim
                    % to perform binary search to bring the MKID geometry
                    % atleast 10 blocks away from the user's resonant
                    % frequency
                    if (x2 -(x1+2)) >10 && Resonance ~= User_Frequency
                        while true
                            try
                                % Call Guess_Sim to perform binary sweep to
                                % bring the MKID 10 blocks within the user
                                % frequency
                                [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                % Import new x2 and x3 from Sweep_Matrix (As we
                                % are connected to the left side of the
                                % MKID and already know x1
                                x2_co =Sweep_Matrix{1, 2}(1,1);
                                x3_co = Sweep_Matrix{1, 3}(1,1);
                                % Extract resonant frequency from
                                % Sweep_Matrix
                                Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                % Test if the user resonant frequency now exists
                                % within less than 10 capacitor blocks.
                                new_polygon_length = x3_co-x2_co;
                                if new_polygon_length <=10 || Resonance == User_Frequency
                                    break
                                end
                            end
                        end
                    end
                    return
                elseif s==1 % Finger connected on right side of MKID
                    % Reset coordinates in Sweep_Matrix to new geometry
                    % New x1 coordinate
                    Sweep_Matrix{1, 1}(1,1) = x2-2;
                    % New x2 coordinate
                    Sweep_Matrix{1, 2}(1,1) = x2;
                    % New x3 coordinate
                    Sweep_Matrix{1, 3}(1,1) = x1;
                    % New Resonant Frequency
                    Sweep_Matrix{1, 4}(1,1) = Resonance;
                    % New .son Filename
                    Sweep_Matrix{1, 4}(2,1) = str_son;
                    % New Qc Factor
                    Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                    % New previous resonance
                    Sweep_Matrix{1, 5}(1,1) = prev_resonance;
                    % New .son filename
                    Sweep_Matrix{1, 5}(2,1) = prev_filename;
                    % After placing new capacitor finger, check if the user
                    % resonant frequency lies within 10 blocks of
                    % capacitor.
                    % If the finger is not within 10 blocks, call Guess_Sim
                    % to perform binary search to bring the MKID geometry
                    % atleast 10 blocks away from the user's resonant
                    % frequency
                    if ((x2-2)-x1) >10 && Resonance ~= User_Frequency
                        while true
                            try
                                % Call Guess_Sim to perform binary sweep to
                                % bring the MKID 10 blocks within the user
                                % frequency
                                [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                % Import new x1 and x3 from Sweep_Matrix (As we
                                % are connected to the right side of the
                                % MKID and already know x2
                                x1_co=Sweep_Matrix{1, 1}(1,1);
                                x3_co = Sweep_Matrix{1, 3}(1,1);
                                % Extract resonant frequency from
                                % Sweep_Matrix
                                Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                % Test if the user resonant frequency now exists
                                % within less than 10 capacitor blocks.
                                new_polygon_length = x1_co-x3_co;
                                if new_polygon_length <=10 || Resonance == User_Frequency
                                    break
                                end
                            end
                        end
                    end
                    return
                end
            end
            % Loop back and remove another section of capacitor finger
            % since the user resonant frequency is still above the MKID
            % resonant frequency
            % Reset values
            % New previous resonant frequency
            prev_resonance = Resonance;
            
            % New previous .son filename
            prev_filename = str_son;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Remove the current capacitor finger polygon closest to the inductor
            removex=round(mean([X_Array(1) X_Array(2)]));
            removey=round(mean([y1_co y2_co]));
            % Find the polygons DebugID
            first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
            % Remove the polygon using the DebugID
            Project.deletePolygonUsingId(first_Polygon);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If the finger is not the initial non-whole capacitor finger
        else
            % Reset y coordinates after every loop
            y1_co = y2 - i*(spacing+thickness);
            y2_co = y1_co + thickness;
            s=(-1)^i;  % Clock to go from left side to right side of capacitor
            % Odd  = Right, Even = Left
            if s==1  % If clock=1, start on right side of capacitor
                % Constant x2 coordinate for finger connected to the right
                % side of the capacitor
                x2_co = x2;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if i~=forloop_start-1
                    % Delete small piece from left side from previous
                    % iteration
                    removex=x1+1;
                    % Fix Y values
                    removey=round(mean([y1_co-(spacing+thickness) y2_co-(spacing+thickness)]));
                    % Find the polygons DebugID
                    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                    % Remove the polygon using the DebugID
                    Project.deletePolygonUsingId(first_Polygon);
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Reset X Array
                X_Array= [x1_co  x2_co   x2_co  x1_co];
                % Removing 1/4 sections of capacitor.
                for b=Length/4: Length/4 :Length
                    if b==Length/4
                        prev_x1 = x1+spacing;
                    end
                    % Mean of x and y coordinates of polygon to find the
                    % center of the polygon (used for DebugID)
                    removex=round(mean([X_Array(1) x2_co]));
                    removey=round(mean([y1_co y2_co]));
                    % Find the polygons DebugID
                    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                    % Remove the polygon using the DebugID
                    Project.deletePolygonUsingId(first_Polygon);
                    % New polygon x coordinates
                    X_Array= [(x1+b)  x2_co   x2_co  (x1+b)];
                    % New polygon y coordinates
                    Y_Array = [y1_co  y1_co   y2_co  y2_co];
                    % Place new polygon
                    Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
                    %Name the new structure
                    str=append("Test", num2str(i),"_",num2str(b), ".son");
                    %Save the file as "String".son
                    Project.saveAs(str);
                    % Set new frequency sweep bounds
                    upper_bound = Resonance+0.2;
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
                    % Test to see if the resonant frequency is still above the user
                    % frequency
                    if Resonance >= User_Frequency
                        % Reset all coordinates in Sweep_Matrix
                        % New x1 coordinate
                        Sweep_Matrix{1, 1}(1,1) = X_Array(1); 
                        % New x2 coordinate
                        Sweep_Matrix{1, 2}(1,1) = X_Array(2); 
                        % New x3 coordinate
                        Sweep_Matrix{1, 3}(1,1) = prev_x1; 
                        % New y1 coordinate
                        Sweep_Matrix{1, 1}(1,2) = Y_Array(1);
                        % New y2 coordinate
                        Sweep_Matrix{1, 1}(2,2) = Y_Array(3);
                        % New Resonant Frequency
                        Sweep_Matrix{1, 4}(1,1) = Resonance;
                        % New .son Filename
                        Sweep_Matrix{1, 4}(2,1) = str_son;
                        % New Qc Factor
                        Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                        % New previous resonance
                        Sweep_Matrix{1, 5}(1,1) = prev_resonance;
                        % New previous filename
                        Sweep_Matrix{1, 5}(2,1) = prev_filename;
      
                        % After placing new capacitor finger, check if the user
                        % resonant frequency lies within 10 blocks of
                        % capacitor.
                        % If the finger is not within 10 blocks, call Guess_Sim
                        % to perform binary search to bring the MKID geometry
                        % atleast 10 blocks away from the user's resonant
                        % frequency
                        if (X_Array(1)-prev_x1) >10 && Resonance ~= User_Frequency
                            while true
                                try
                                    % Call Guess_Sim to perform binary sweep to
                                    % bring the MKID 10 blocks within the user
                                    % frequency
                                    [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                    % Import new x1 and x3 from Sweep_Matrix (As we
                                    % are connected to the right side of the
                                    % MKID and already know x2
                                    x1_co =Sweep_Matrix{1, 1}(1,1);
                                    x3_co = Sweep_Matrix{1, 3}(1,1);
                                    % Extract resonant frequency from
                                    % Sweep_Matrix
                                    Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                    % Test if the user resonant frequency now exists
                                    % within less than 10 capacitor blocks.
                                    new_polygon_length = x1_co-x3_co;
                                    if new_polygon_length <=10 || Resonance == User_Frequency
                                        break
                                    end
                                end
                            end
                        end
                        return
                    end
                    % Loop back and remove another section of capacitor finger
                    % since the user resonant frequency is still above the MKID
                    % resonant frequency
                    % Reset values
                    % New previous x1 coordinate
                    prev_x1 = X_Array(1);
                    % New previous .son filename
                    prev_filename = str_son;
                    % New previous resonant frequency
                    prev_resonance = Resonance;
                end
            elseif s==-1 % If clock=-1, start on left side of capacitor
                % Constant x1 coordinate for finger connected to left side
                % of capacitor
                x1_co = x1;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if i~=forloop_start-1
                    % Delete small piece from right side from previous
                    % iteration
                    removex=x2-1;
                    % Fix Y values
                    removey=round(mean([y1_co-(spacing+thickness) y2_co-(spacing+thickness)]));
                    % Find the polygons DebugID
                    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                    % Remove the polygon using the DebugID
                    Project.deletePolygonUsingId(first_Polygon);
                end
                % New polygon x coordinates
                X_Array= [x1_co  x2_co   x2_co  x1_co];
                % Removing 1/4 sections of capacitor.
                for b=x2-round(((x2-spacing)-x1)/4): -round(((x2-spacing)-x1)/4) : x1
                    if b==x2-round(((x2-spacing)-x1)/4)
                        prev_x2 = x2-spacing;
                    end
                    % Mean of x and y coordinates of polygon to find the
                    % center of the polygon (used for DebugID)
                    removex=round(mean([x1_co X_Array(2)]));
                    removey=round(mean([y1_co y2_co]));
                    % Find the polygons DebugID
                    first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
                    % Remove the polygon using the DebugID
                    Project.deletePolygonUsingId(first_Polygon);
                    % X coordinates for 1/4 section of capacitor
                    X_Array= [x1_co  b  b  x1_co];
                    if b == x1
                        X_Array= [x1_co  (b+2)  (b+2)  x1_co];
                    end
                    Y_Array = [y1_co  y1_co   y2_co  y2_co];
                    % Place new polygon
                    Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
                    %Name the new structure
                    str=append("Test", num2str(i),"_",num2str(b), ".son");
                    %Save the file as "String".son
                    Project.saveAs(str);
                    % Set new frequency sweep bounds
                    upper_bound = Resonance+0.2;
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
                    % Test to see if the resonant frequency is still above the user
                    % frequency
                    if Resonance >= User_Frequency
                        
                        % Reset all coordinates in Sweep_Matrix
                        % New x1 coordinate
                        Sweep_Matrix{1, 1}(1,1) = x1; 
                        % New x2 coordinate
                        Sweep_Matrix{1, 2}(1,1) = X_Array(2); 
                        % New x3 coordinate
                        Sweep_Matrix{1, 3}(1,1) = prev_x2; 
                        % New y1 coordinate
                        Sweep_Matrix{1, 1}(1,2) = Y_Array(1);
                        % New y2 coordinate
                        Sweep_Matrix{1, 1}(2,2) = Y_Array(3);
                        % New Resonant Frequency
                        Sweep_Matrix{1, 4}(1,1) = Resonance;
                        % New .son Filename
                        Sweep_Matrix{1, 4}(2,1) = str_son;
                        % New Qc Factor
                        Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                        % New previous resonance
                        Sweep_Matrix{1, 5}(1,1) = prev_resonance;
                        % New previous filename
                        Sweep_Matrix{1, 5}(2,1) = prev_filename;
                        
                        % After placing new capacitor finger, check if the user
                        % resonant frequency lies within 10 blocks of
                        % capacitor.
                        % If the finger is not within 10 blocks, call Guess_Sim
                        % to perform binary search to bring the MKID geometry
                        % atleast 10 blocks away from the user's resonant
                        % frequency
                        if (prev_x2 - X_Array(2)) >10 && Resonance ~= User_Frequency
                            while true
                                try
                                    % Call Guess_Sim to perform binary sweep to
                                    % bring the MKID 10 blocks within the user
                                    % frequency
                                    [Sweep_Matrix] = Guess_Sim(Sweep_Matrix);
                                    % Import new x2 and x3 from Sweep_Matrix (As we
                                    % are connected to the keft side of the
                                    % MKID and already know x1
                                    x2_co=Sweep_Matrix{1, 2}(1,1);
                                    x3_co = Sweep_Matrix{1, 3}(1,1);
                                    % Extract resonant frequency from
                                    % Sweep_Matrix
                                    Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                                    % Test if the user resonant frequency now exists
                                    % within less than 10 capacitor blocks.
                                    new_polygon_length = x3_co-x2_co;
                                    if new_polygon_length <=10 || Resonance == User_Frequency
                                        break
                                    end
                                end
                            end
                        end
                        return
                    end
                    % Loop back and remove another section of capacitor finger
                    % since the user resonant frequency is still above the MKID
                    % resonant frequency
                    % Reset values
                    % New previous x2 coordinate
                    prev_x2 = X_Array(2);
                    % New previous .son filename
                    prev_filename = str_son;
                    % New previous resonance
                    prev_resonance = Resonance;
                end
            end
        end
    end
end