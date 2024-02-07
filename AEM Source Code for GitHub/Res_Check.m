function [Sweep_Matrix, Value] = Res_Check(Sweep_Matrix, User_Frequency,x1,x2,y1,y2, spacing, thickness)
%  RES_CHECK Brief summary of this function.
% 
% Detailed explanation of this function.
y1_co = Sweep_Matrix{1, 1}(1,2);
y2_co = Sweep_Matrix{1, 1}(2,2);
x1_co=Sweep_Matrix{1, 1}(1,1);
x2_co = Sweep_Matrix{1, 2}(1,1);
x3_co = Sweep_Matrix{1, 3}(1,1);
prev_resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
Resonance = prev_resonance;
Project_Name = char(Sweep_Matrix{1, 4}(2,1));
Project = SonnetProject(Project_Name);
 %%%%%%%%%%%%%%%%%%%%%%%%
 %Starting Right Side 
 %Checking if Resonance is higher than User_Frequency
if prev_resonance >= User_Frequency
    %Check if too much capacitor removed
    if x1_co > x3_co %Finger starting on Right Side
        if x1_co == (x2_co-2)
            %Coords are too small to parameterised further
            Value = 1;
            return
        end
        removex=round(mean([x1_co x2_co]));
        removey=round(mean([y1_co y2_co]));
        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
        Project.deletePolygonUsingId(first_Polygon);
        X_Array = [(x1_co-1)  x2_co  x2_co (x1_co-1)];
        Y_Array = [y1_co y1_co  y2_co  y2_co];
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
        %Name the new structure
        str=append("Test_Check.son");
        %Save the file as "String".son
        Project.saveAs(str);
        upper_bound = Resonance +0.05;
        lower_bound = Resonance-0.05;
        Project = SonnetProject(str);
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
        [Value] = Accuracy_Check(Resonance, prev_resonance , User_Frequency);
        if Value ==1 %Geometry is correct
            disp("Geometry is Correct");
            return
        elseif Value ==0 % Resonance is not as close as possible, repeat param for resonance
            %Reset coords
            
            [Sweep_Matrix] = Two_WayParam(Sweep_Matrix, x1,x2,y1,y2, spacing, thickness);
            
            return
        end
 %%%%%%%%%%%%%%%%%%%%%%%%
 %Starting Left Side 
 %Checking if Resonance is higher than User_Frequency
    elseif x3_co > x1_co %Finger starting on Left Side
        if x1_co == (x2_co-2)
            %Coords are too small to parameterised further
            Value = 1;
            return
        end
        removex=round(mean([x1_co x2_co]));
        removey=round(mean([y1_co y2_co]));
        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
        Project.deletePolygonUsingId(first_Polygon);
        X_Array = [x1_co  (x2_co+1)  (x2_co+1) x1_co];
        Y_Array = [y1_co y1_co  y2_co  y2_co];
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
        %Name the new structure
        str=append("Test_Check.son");
        %Save the file as "String".son
        Project.saveAs(str);
        upper_bound = Resonance +0.05;
        lower_bound = Resonance-0.05;
        Project = SonnetProject(str);
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
        [Value] = Accuracy_Check(Resonance, prev_resonance , User_Frequency);
        if Value ==1 %Geometry is correct
            disp("Geometry is Correct");
            return
        elseif Value ==0 % Resonance is not as close as possible, repeat param for resonance
            %Reset coords
            [Sweep_Matrix] = Two_WayParam(Sweep_Matrix, x1,x2,y1,y2, spacing, thickness);
            return
        end
        
            
    end
    
    
    
    
    
    
 %%%%%%%%%%%%%%%%%%%%%%%%
 %Starting Right Side 
 %Checking if Resonance is lower than User_Frequency
elseif prev_resonance < User_Frequency
    %Check if too much capacitor added
    if x1_co > x3_co %Finger starting on Right Side
        if x1_co == (x2_co-2)
            %Coords are too small to parameterised further
            Value = 1;
            return
        end
        removex=round(mean([x1_co x2_co]));
        removey=round(mean([y1_co y2_co]));
        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
        Project.deletePolygonUsingId(first_Polygon);
        X_Array = [(x1_co+1)  x2_co  x2_co (x1_co+1)];
        Y_Array = [y1_co y1_co  y2_co  y2_co];
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
        %Name the new structure
        str=append("Test_Check.son");
        %Save the file as "String".son
        Project.saveAs(str);
        upper_bound = Resonance +0.05;
        lower_bound = Resonance-0.05;
        Project = SonnetProject(str);
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
        [Value] = Accuracy_Check(Resonance, prev_resonance , User_Frequency);
        if Value ==1 %Geometry is correct
            disp("Geometry is Correct");
            return
        elseif Value ==0 % Resonance is not as close as possible, repeat param for resonance
            %Reset coords
            [Sweep_Matrix] = Two_WayParam(Sweep_Matrix, x1,x2,y1,y2, spacing, thickness);
            
            return
        end
 %%%%%%%%%%%%%%%%%%%%%%%%
 %Starting Left Side 
 %Checking if Resonance is lower than User_Frequency
    elseif x3_co > x1_co %Finger starting on Left Side
        if x1_co == (x2_co-2)
            %Coords are too small to parameterised further
            Value = 1;
            return
        end
        removex=round(mean([x1_co x2_co]));
        removey=round(mean([y1_co y2_co]));
        first_Polygon=Project.findPolygonUsingPoint(removex, removey).DebugId;
        Project.deletePolygonUsingId(first_Polygon);
        X_Array = [x1_co  (x2_co-1)  (x2_co-1) x1_co];
        Y_Array = [y1_co y1_co  y2_co  y2_co];
        Project.addMetalPolygonEasy(0, X_Array ,Y_Array, 1);
        %Name the new structure
        str=append("Test_Check.son");
        %Save the file as "String".son
        Project.saveAs(str);
        upper_bound = Resonance +0.05;
        lower_bound = Resonance-0.05;
        Project = SonnetProject(str);
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
        [Value] = Accuracy_Check(Resonance, prev_resonance , User_Frequency);
        if Value ==1 %Geometry is correct
            disp("Geometry is Correct");
            return
        elseif Value ==0 % Resonance is not as close as possible, repeat param for resonance
            %Reset coords
            [Sweep_Matrix] = Two_WayParam(Sweep_Matrix, x1,x2,y1,y2, spacing, thickness);
            
            return
        end
    end
end
end