function [Sweep_Matrix, box_dimensions] = Param_GND(Sweep_Matrix, box_dimensions, Qvalues, MKID_y2,  Reset_Code, LeftX)
%  PARAM_GND 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function parameterises the bottom ground plane polygon that
% seperates the MKID from the feedline in order to achieve a correct Qc
% value that is within the user's Qc Factor range.
% This function should only be used when the coupling bar can not be
% parameterised anymore in order to achieve a correct Qc value.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Importing values from each row of Sweep_Matrix
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
Project_Name = char(Sweep_Matrix{1, 4}(2,1));
Q_Factor = Sweep_Matrix{1, 6}(2,1);
% Decompile geometry file
Project = SonnetProject(Project_Name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Qc Factor values, need to fix this section
user_Q = Qvalues(1);
Q_highbound = Qvalues(2);
Q_lowbound = Qvalues(3);
Q_UpperRange = mean([user_Q  (user_Q+Q_highbound)]);
CloseQ1 = abs(Q_Factor - (user_Q + Q_highbound));
if Reset_Code == 1
    Q_LowerRange = (user_Q  - Q_lowbound);
elseif Reset_Code ==0
    Q_LowerRange = round(mean([user_Q  Q_UpperRange]));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% As we are varying the ground plane polygon that contains the ports for
% ground, we must locate the coordinates at which the ports exist to
% replace them.
% Store coordinates in list
port_coord=[];
for i =1:numel(Project.GeometryBlock.ArrayOfPorts)
    port_coord = [port_coord  Project.GeometryBlock.ArrayOfPorts{1,i}.XCoordinate];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In order to call the Param_GND function, we need to input the coordinates
% of the box in the ground plane in which the MKID sits.
% Box dimensions
box_x1coord=box_dimensions(1);
box_y1coord=box_dimensions(2);
box_x2coord=box_dimensions(3);
box_y2coord=box_dimensions(4);
box_width = (box_x2coord - box_x1coord);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We must now identify the coordinates for the ground plane polygons at the
% edges of the simulation as we must also change their dimensions if we
% change the bottom ground plane polygon.
% Side GND Plane coords
% Left GND Plane
% Finding the Left GND Plane Y Coordinates
LGP_xmean = mean([0  box_x1coord]);
LGP_ymean = mean([box_y1coord   box_y2coord]);
LGP_ycoords = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0).YCoordinateValues;
LGP_ycoords = cell2mat(LGP_ycoords);
LGP_ycoords= [LGP_ycoords(2)  LGP_ycoords(3)  LGP_ycoords(4)  LGP_ycoords(5)];
LGP_ycoords = round([min(LGP_ycoords)  min(LGP_ycoords)  max(LGP_ycoords)  max(LGP_ycoords)]);
% Finding the Left GND Plane X Coordinates
LGP_x1coord=0;
LGP_y1coord=box_y1coord;
LGP_x2coord=box_x1coord;
LGP_y2coord=box_y2coord;
LGP_xcoords = [LGP_x1coord    LGP_x2coord   LGP_x2coord   LGP_x1coord];
% Right GND Plane
% Finding the Right GND Plane Coordinates
RGP_x2coord=round(max(port_coord));
RGP_y2coord=LGP_y2coord;
RGP_x1coord=LGP_x2coord+box_width;
RGP_y1coord=LGP_y1coord;
RGP_xcoords = [RGP_x1coord    RGP_x2coord   RGP_x2coord   RGP_x1coord];
RGP_ycoords = [RGP_y1coord  RGP_y1coord   RGP_y2coord   RGP_y2coord];
% Bottom GND Plane
% Finding the Coordinates for the bottom ground plane that seperates the
% MKID from the Feedline
BGP_xcoords=Project.findPolygonUsingPoint(1,LGP_ycoords(3)+1,0).XCoordinateValues;
BGP_ycoords=Project.findPolygonUsingPoint(1,LGP_ycoords(3)+1,0).YCoordinateValues;
BGP_xcoords = cell2mat(BGP_xcoords);
BGP_ycoords = cell2mat(BGP_ycoords);
BGP_xcoords= [BGP_xcoords(2)  BGP_xcoords(3)  BGP_xcoords(4)  BGP_xcoords(5)];
BGP_ycoords= [BGP_ycoords(2)  BGP_ycoords(3)  BGP_ycoords(4)  BGP_ycoords(5)];
BGP_xcoords = round([ 0  max(BGP_xcoords)   max(BGP_xcoords)   0]);
BGP_ycoords = round([min(BGP_ycoords)  min(BGP_ycoords)  max(BGP_ycoords)  max(BGP_ycoords)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%                    :Section 1:                     %%%%%%%%
%%%%%%%%                   Resetting GND                    %%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If Reset_Code==1, we must reset the ground plane to be as close to the
% coupling bar as possible (i.e. 1 block away). This allows for a broader
% range of parameterisation options
if Reset_Code == 1
    
    % Place GND as close to reset coupling bar as possible
    % Bottom Ground Plane
    mean_xcoord = mean([BGP_xcoords(1) BGP_xcoords(2)]);
    mean_ycoord = mean([BGP_ycoords(2) BGP_ycoords(3)]);
    % Find the polygons DebugID
    Debug_ID= Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0);
    % Remove the polygon using the DebugID
    Project.deletePolygonUsingIndex(Debug_ID);
    % Set the maximum thickness of the Bottom GND Plane
    maxBGP_ycoords = round([(MKID_y2+1)  (MKID_y2+1)   BGP_ycoords(3)  BGP_ycoords(4)]); 
    % Place the new GND Plane polygon 
    Project.addMetalPolygonEasy(0,BGP_xcoords, maxBGP_ycoords,1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Now we must place ports to this new polygon to define it as a ground
    % plane
    mean_ycoord = mean([maxBGP_ycoords(2) maxBGP_ycoords(3)]);
    % Find the new polygons DebugID
    Debug_ID=Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0).DebugId;
    % Add new grounding ports to the left and right side of the polygon
    Right_Port=Project.addPortStandard(Debug_ID, 2, 50, 0, 0, 0, -1);
    Left_Port=Project.addPortStandard(Debug_ID, 4, 50, 0, 0, 0, -1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % As we have now changed the shape of the bottom ground plane, we must
    % also change the dimensions of the left and right ground plane
    % polygons.
    % Left Side GND 
    LGP_xmean = mean([LGP_x1coord  LGP_x2coord]);
    LGP_ymean = mean([LGP_y1coord  LGP_y2coord]);
    LGP_index = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0);
    % Delete the old plane
    Project.deletePolygonUsingIndex(LGP_index);
    LGP_ycoords = [LGP_y1coord  LGP_y1coord   maxBGP_ycoords(1)   maxBGP_ycoords(1)];
    % Add the new Left Side Ground Plane
    Project.addMetalPolygonEasy(0,LGP_xcoords, LGP_ycoords,1);
    % New Left Side Ground Plane Coordinates
    LGP_y2coord = LGP_ycoords(3);
    % Right Side GND
    RGP_xmean = mean([RGP_x1coord  RGP_x2coord]);
    RGP_ymean = mean([RGP_y1coord  RGP_y2coord]);
    RGP_index = Project.findPolygonUsingPoint(RGP_xmean, RGP_ymean, 0);
    % Delete the old plane
    Project.deletePolygonUsingIndex(RGP_index);
    RGP_ycoords = [RGP_y1coord  RGP_y1coord   maxBGP_ycoords(1)   maxBGP_ycoords(1)];
    % Add the new Right Side Ground Plane
    Project.addMetalPolygonEasy(0,RGP_xcoords, RGP_ycoords,1);
    % New Right Side Ground Plane Coordinates
    RGP_y2coord = RGP_ycoords(3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Name the new structure
    str=append('TestGND_max.son');
    % Save the file as "String".son
    Project.saveAs(str);
    % Since file was renamed, decompile new file as SonnetProject
    Project=SonnetProject(str);
    % Set the upper and lower frequency sweep bounds.
    upper_bound = Resonance +0.05;
    lower_bound = Resonance -0.05;
    % Simulate new project
    while true
        try
            % Call Auto_Sim for simulation and analysis
            [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
            % Rename .csv and .son as the resonant frequency
            old_son_file=str;
            str_son=num2str(maxResonance)+"GHz.son";
            str_csv_old=erase(str, ".son")+".csv";
            str_csv_new=num2str(maxResonance)+"GHz.csv";
            Project.saveAs(str_son);
            movefile(str_csv_old, str_csv_new);
            delete(old_son_file);
            break
        catch ME
            warning("Something Broke! Retrying...");
            Project.cleanProject;
        end
    end
    % New Bottom Ground Plane Coordinates
    BGP_ycoords = maxBGP_ycoords;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate which side of the Qc Factor user range the new Qc Factor is
    % closer to
    CloseQ2 = abs(maxQ_Factor - (user_Q - Q_lowbound));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the Reset_Code=-0,  Change the Bottom Ground Plane to the minimum
% thickness (1 block)
else
    % Bottom Ground Plane Coordinates 
    mean_xcoord = mean([BGP_xcoords(1) BGP_xcoords(2)]);
    mean_ycoord = mean([BGP_ycoords(2) BGP_ycoords(3)]);
    % Find the polygons DebugID
    Debug_ID= Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0);
    % Delete the old plane
    Project.deletePolygonUsingIndex(Debug_ID);
    % Minimum Ground Plane Coordinates
    minBGP_ycoords = round([(BGP_ycoords(3)-1)  (BGP_ycoords(4)-1)   BGP_ycoords(3)  BGP_ycoords(4)]); 
    % Add new ground plane polygon
    Project.addMetalPolygonEasy(0,BGP_xcoords, minBGP_ycoords,1);
    mean_ycoord = mean([minBGP_ycoords(2) minBGP_ycoords(3)]);
    % Find the new polygons DebugID
    Debug_ID=Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0).DebugId;
    % Add new grounding ports to the left and right side of the polygon
    Right_Port=Project.addPortStandard(Debug_ID, 2, 50, 0, 0, 0, -1);
    Left_Port=Project.addPortStandard(Debug_ID, 4, 50, 0, 0, 0, -1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % As we have now changed the shape of the bottom ground plane, we must
    % also change the dimensions of the left and right ground plane
    % polygons.
    % Left Side GND 
    LGP_xmean = mean([LGP_x1coord  LGP_x2coord]);
    LGP_ymean = mean([LGP_y1coord  LGP_y2coord]);
    LGP_index = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0);
    % Delete the old plane
    Project.deletePolygonUsingIndex(LGP_index);
    LGP_ycoords = [LGP_y1coord  LGP_y1coord   minBGP_ycoords(1)   minBGP_ycoords(1)];
    % Add the new Righ Side Ground Plane
    Project.addMetalPolygonEasy(0,LGP_xcoords, LGP_ycoords,1);
    % New Left Side Ground Plane Coordinates
    LGP_y2coord = LGP_ycoords(3);
    % Right Side GND
    RGP_xmean = mean([RGP_x1coord  RGP_x2coord]);
    RGP_ymean = mean([RGP_y1coord  RGP_y2coord]);
    RGP_index = Project.findPolygonUsingPoint(RGP_xmean, RGP_ymean, 0);
    % Delete the old plane
    Project.deletePolygonUsingIndex(RGP_index);
    RGP_ycoords = [RGP_y1coord  RGP_y1coord   minBGP_ycoords(1)   minBGP_ycoords(1)];
    % Add the new Right Side Ground Plane
    Project.addMetalPolygonEasy(0,RGP_xcoords, RGP_ycoords,1);
    RGP_y2coord = RGP_ycoords(3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Name the new structure
    str=append('TestGNDmin.son');
    % Save the file as "String".son
    Project.saveAs(str);
    % Since file was renamed, decompile new file as SonnetProject
    Project=SonnetProject(str);
    % Set the upper and lower frequency sweep bounds.
    upper_bound = Resonance +0.05;
    lower_bound = Resonance -0.05;
    % Simulate new project
    while true
        try
            % Call Auto_Sim for simulation and analysis
            [Resonance, Q_Factor, ~]=Auto_Sim(Project, upper_bound, lower_bound);
            % Rename .csv and .son as the resonant frequency
            old_son_file=str;
            str_son=num2str(minResonance)+"GHz.son";
            str_csv_old=erase(str, ".son")+".csv";
            str_csv_new=num2str(minResonance)+"GHz.csv";
            Project.saveAs(str_son);
            movefile(str_csv_old, str_csv_new);
            delete(old_son_file);
            break
        catch ME
            warning("Something Broke! Retrying...");
            Project.cleanProject;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate which side of the Qc Factor user range the new Qc Factor is
    % closer to
    CloseQ2 = abs(minQ_Factor - (user_Q - Q_lowbound));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If Qc is too high
if CloseQ1 < CloseQ2 || Reset_Code ==1
    Project = SonnetProject(Project_Name);
    if (Q_Factor > user_Q + Q_highbound)
        for i = BGP_ycoords(1)+1 : 1 : BGP_ycoords(4)-1
            mean_xcoord = mean([BGP_xcoords(1) BGP_xcoords(2)]);
            mean_ycoord = mean([BGP_ycoords(2) BGP_ycoords(3)]);
            Debug_ID= Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0);
            Project.deletePolygonUsingIndex(Debug_ID);
            BGP_ycoords = [i  i   BGP_ycoords(3)  BGP_ycoords(4)]; %Param
            Project.addMetalPolygonEasy(0,BGP_xcoords, BGP_ycoords,1);
            mean_ycoord = mean([BGP_ycoords(2) BGP_ycoords(3)]);
            Debug_ID=Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0).DebugId;
            Right_Port=Project.addPortStandard(Debug_ID, 2, 50, 0, 0, 0, -1);
            Left_Port=Project.addPortStandard(Debug_ID, 4, 50, 0, 0, 0, -1);
            %Fixing side plane coords
            %Left Side
            LGP_xmean = mean([LGP_x1coord  LGP_x2coord]);
            LGP_ymean = mean([LGP_y1coord  LGP_y2coord]);
            LGP_index = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0);
            Project.deletePolygonUsingIndex(LGP_index);
            LGP_ycoords = [LGP_y1coord  LGP_y1coord   BGP_ycoords(1)   BGP_ycoords(1)];
            Project.addMetalPolygonEasy(0,LGP_xcoords, LGP_ycoords,1);
            LGP_y2coord = LGP_ycoords(3);
            %Right Side
            RGP_xmean = mean([RGP_x1coord  RGP_x2coord]);
            RGP_ymean = mean([RGP_y1coord  RGP_y2coord]);
            RGP_index = Project.findPolygonUsingPoint(RGP_xmean, RGP_ymean, 0);
            Project.deletePolygonUsingIndex(RGP_index);
            RGP_ycoords = [RGP_y1coord  RGP_y1coord   BGP_ycoords(1)   BGP_ycoords(1)];
            Project.addMetalPolygonEasy(0,RGP_xcoords, RGP_ycoords,1);
            RGP_y2coord = RGP_ycoords(3);
            %Name the new structure
            str=append('TestGND',num2str(round(i)),'.son');
            %Save the file as "String".son
            Project.saveAs(str);
            Project=SonnetProject(str);
            upper_bound = Resonance +0.05;
            lower_bound = Resonance -0.05;
            while true
                try
                    [Resonance, Q_Factor, Warning]=Auto_Sim(Project, upper_bound, lower_bound);
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
            if (Q_Factor <= user_Q+Q_highbound) && (Q_Factor >= Q_LowerRange)
                box_dimensions = [box_x1coord  box_y1coord  box_x2coord  i];
                Sweep_Matrix{1, 4}(1,1) = Resonance;
                Sweep_Matrix{1, 4}(2,1) = str_son;
                Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                return
            end
            %If Q is too low
        end
    elseif (Q_Factor < user_Q - Q_lowbound)
        for i = BGP_ycoords(2)-1 : -1 : MKID_y2+1
            mean_xcoord = mean([BGP_xcoords(1) BGP_xcoords(2)]);
            mean_ycoord = mean([BGP_ycoords(2) BGP_ycoords(3)]);
            Debug_ID= Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0);
            Project.deletePolygonUsingIndex(Debug_ID);
            BGP_ycoords = [i  i   BGP_ycoords(3)  BGP_ycoords(4)]; %Param
            Project.addMetalPolygonEasy(0,BGP_xcoords, BGP_ycoords,1);
            mean_ycoord = mean([BGP_ycoords(2) BGP_ycoords(3)]);
            Debug_ID=Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0).DebugId;
            Right_Port=Project.addPortStandard(Debug_ID, 2, 50, 0, 0, 0, -1);
            Left_Port=Project.addPortStandard(Debug_ID, 4, 50, 0, 0, 0, -1);
            %Fixing side plane coords
            %Left Side
            LGP_xmean = mean([LGP_x1coord  LGP_x2coord]);
            LGP_ymean = mean([LGP_y1coord  LGP_y2coord]);
            LGP_index = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0);
            Project.deletePolygonUsingIndex(LGP_index);
            LGP_ycoords = [LGP_y1coord  LGP_y1coord   BGP_ycoords(1)   BGP_ycoords(1)];
            Project.addMetalPolygonEasy(0,LGP_xcoords, LGP_ycoords,1);
            LGP_y2coord = LGP_ycoords(3);
            %Right Side
            RGP_xmean = mean([RGP_x1coord  RGP_x2coord]);
            RGP_ymean = mean([RGP_y1coord  RGP_y2coord]);
            RGP_index = Project.findPolygonUsingPoint(RGP_xmean, RGP_ymean, 0);
            Project.deletePolygonUsingIndex(RGP_index);
            RGP_ycoords = [RGP_y1coord  RGP_y1coord   BGP_ycoords(1)   BGP_ycoords(1)];
            Project.addMetalPolygonEasy(0,RGP_xcoords, RGP_ycoords,1);
            RGP_y2coord = RGP_ycoords(3);
            %Name the new structure
            str=append('TestGND',num2str(round(i)),'.son');
            %Save the file as "String".son
            Project.saveAs(str);
            Project=SonnetProject(str);
            upper_bound = Resonance +0.005;
            lower_bound = Resonance -0.005;
            while true
                try
                    [Resonance, Q_Factor, Warning]=Auto_Sim(Project, upper_bound, lower_bound);
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
            if (Q_Factor <= user_Q+Q_highbound) && (Q_Factor >= Q_LowerRange)
                box_dimensions = [box_x1coord  box_y1coord  box_x2coord  i];
                Sweep_Matrix{1, 4}(1,1) = Resonance;
                Sweep_Matrix{1, 4}(2,1) = str_son;
                Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                return
            end
        end
    end
    disp("no Q found")
    %Perform recursion after parametersing Side Planes
    %[Sweep_Matrix, box_dimensions] = Param_SidePlane(Sweep_Matrix,box_dimensions, Qvalues,LeftX);
elseif CloseQ1 > CloseQ2 
    disp("Start at small GND plane")
    Check_Q = [Q_Factor];
    for i = minBGP_ycoords(2)-1 : -1 : MKID_y2+1
        mean_xcoord = mean([BGP_xcoords(1) BGP_xcoords(2)]);
        mean_ycoord = mean([minBGP_ycoords(2) minBGP_ycoords(3)]);
        Debug_ID= Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0);
        Project.deletePolygonUsingIndex(Debug_ID);
        minBGP_ycoords = [i  i   minBGP_ycoords(3)  minBGP_ycoords(4)]; %Param
        Project.addMetalPolygonEasy(0,BGP_xcoords, minBGP_ycoords,1);
        mean_ycoord = mean([minBGP_ycoords(2) minBGP_ycoords(3)]);
        Debug_ID=Project.findPolygonUsingPoint(mean_xcoord, mean_ycoord, 0).DebugId;
        Right_Port=Project.addPortStandard(Debug_ID, 2, 50, 0, 0, 0, -1);
        Left_Port=Project.addPortStandard(Debug_ID, 4, 50, 0, 0, 0, -1);
        %Fixing side plane coords
        %Left Side
        LGP_xmean = mean([LGP_x1coord  LGP_x2coord]);
        LGP_ymean = mean([LGP_y1coord  LGP_y2coord]);
        LGP_index = Project.findPolygonUsingPoint(LGP_xmean, LGP_ymean, 0);
        Project.deletePolygonUsingIndex(LGP_index);
        LGP_ycoords = [LGP_y1coord  LGP_y1coord   minBGP_ycoords(1)   minBGP_ycoords(1)];
        Project.addMetalPolygonEasy(0,LGP_xcoords, LGP_ycoords,1);
        LGP_y2coord = LGP_ycoords(3);
        %Right Side
        RGP_xmean = mean([RGP_x1coord  RGP_x2coord]);
        RGP_ymean = mean([RGP_y1coord  RGP_y2coord]);
        RGP_index = Project.findPolygonUsingPoint(RGP_xmean, RGP_ymean, 0);
        Project.deletePolygonUsingIndex(RGP_index);
        RGP_ycoords = [RGP_y1coord  RGP_y1coord   minBGP_ycoords(1)   minBGP_ycoords(1)];
        Project.addMetalPolygonEasy(0,RGP_xcoords, RGP_ycoords,1);
        RGP_y2coord = RGP_ycoords(3);
        %Name the new structure
        str=append('TestGND',num2str(round(i)),'.son');
        %Save the file as "String".son
        Project.saveAs(str);
        Project=SonnetProject(str);
        upper_bound = Resonance +0.005;
        lower_bound = Resonance -0.005;
        while true
            try
                [Resonance, Q_Factor, Warning]=Auto_Sim(Project, upper_bound, lower_bound);
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
        Sweep_Matrix{1, 4}(1,1) = Resonance;
        Sweep_Matrix{1, 4}(2,1) = str_son;
        Sweep_Matrix{1, 6}(2,1) = Q_Factor;
        if (Q_Factor <= user_Q+Q_highbound) && (Q_Factor >= Q_LowerRange)
            box_dimensions = [box_x1coord  box_y1coord  box_x2coord  i];
            Sweep_Matrix{1, 4}(1,1) = Resonance;
            Sweep_Matrix{1, 4}(2,1) = str_son;
            Sweep_Matrix{1, 6}(2,1) = Q_Factor;
            return
        end
        Check_Q = [Check_Q  Q_Factor];
        if numel(Check_Q) >5 && Q_Factor > (user_Q + Q_highbound) && numel(Check_Q) < 6
            %Perform check
            if mean(diff(Check_Q)) >0
                disp("Q is Increasing")
                return
            elseif mean(diff(Check_Q))<0
                %Continue Parameterisation
                disp("Q is Decreasing")
            end
        end
    end
end
end