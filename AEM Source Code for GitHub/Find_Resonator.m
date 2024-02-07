function [Sweep_Matrix] = Find_Resonator(Sweep_Matrix, box_dimensions, Qvalues, LeftX, LeftY, spacing, thickness, barthickness, x1,y1, x2 ,y2)
%  FIND_RESONATOR This is the main parameterisation function for AEM.
% 
% All parameterisation functions are called from Find_Resonator.
% 
% This function also check s each resonator matches the user's preference and 
% returns correct geometries.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Q factor range defined by user
% Needs to be fixed
user_Q = Qvalues(1);
Q_highbound = Qvalues(2);
Q_lowbound = Qvalues(3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import values from Sweep_Matrix
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
User_Frequency = Sweep_Matrix{1, 6}(1,1);
Q_Factor = Sweep_Matrix{1, 6}(2,1);
% If Qc Factor lies outside the user defined range, begin parameterising
% the coupling bar in both length and thickness
if Q_Factor < (user_Q - Q_lowbound) ||  Q_Factor > (user_Q + Q_highbound)
    
    % Tell user what is happening
    disp("Starting Coupling Bar Sweep...")
    % Call coupling bar parameterisation function
    [Sweep_Matrix, box_dimensions] = Param_CBar(Sweep_Matrix,box_dimensions, Qvalues, LeftX, LeftY, x2, (y2-barthickness), spacing);
end
% Since the coupling bar has been changed, the resonant frequency of the
% MKID has also shifted and now must be reset.
if Resonance ~= User_Frequency
    % Tell user what is happening
    disp("Starting More Sensitive Sweep...")
    
    % Call function for placing or removing larger sections of IDC fingers
    % and using the binary search method to solve for the closest geometry
    % to the wanted resonant frequency
    [Sweep_Matrix]=Two_WayParam(Sweep_Matrix, x1, x2, y1, (y2-barthickness), spacing, thickness);
    if Resonance ~= User_Frequency
        % Call function to find the geometry with the closest resonant frequency 
        [Sweep_Matrix]=Sense_Sweep(Sweep_Matrix);
    end
end
% Once again, the Q Factor will be changed, however not by much
% (assumption).
% As such, AEM will check the Qc Factor once again and perform recursion of
% the Find_Resonator function until the correct MKID is produced.
% Define variables with Sweep_Matrix
Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
% Reinitialize the project
Project = SonnetProject(char(Sweep_Matrix{1, 4}(2,1)));
% Rerun the simulation with stricter frequency sweep range to test for more
% accurate Qc factor.
[Resonance, Q_Factor] = Auto_Sim(Project, Resonance+0.01, Resonance-0.01);
% Reset Sweep_Matrix to current values
Sweep_Matrix{1, 4}(1,1) = Resonance;
Sweep_Matrix{1, 6}(2,1) = Q_Factor;
Sweep_Matrix{1, 4}(2,1) = Project.Filename;
% Check if Q factor lies in the correct range, if not, perform recursion
if Q_Factor < (user_Q - Q_lowbound) ||  Q_Factor > (user_Q + Q_highbound)
    
    % Tell user what is happening
    disp("Qc Factor does not lie within range...");
    disp("Performing recursion to find correct Qc Factors...")
    % Performing recursion
    [Sweep_Matrix] = Find_Resonator(Sweep_Matrix, box_dimensions, Qvalues, LeftX, LeftY,  spacing, thickness, barthickness, x1, y1, x2 ,y2);
end
% Accuracy for resonant frequency
% This value is chosen specifically for optical to Near IR MKIDs to avoid
% clashing between pixels in readout.
Accuracy = 0.001; %1MHz
if Resonance > (User_Frequency+Accuracy) || Resonance < (User_Frequency-Accuracy)
    % Perform 1 last check for resonant frequency
    [Sweep_Matrix, Value] = Res_Check(Sweep_Matrix, User_Frequency,x1,x2, y1 ,(y2-barthickness), spacing, thickness);
    
    % If Value = 0, the geometry does not produce the correct resonant
    % frequency and must be adjusted.
    % If Value = 1, the MKID has passed both resonant frequency and Qc
    % Factor checks.
    if Value==0
        % Geometry needs to be corrected.
        [Sweep_Matrix]=Sense_Sweep(Sweep_Matrix);
        % Checking for accurate Q Factor once again.
        while true
            try
                
                % Extracting values from Sweep_Matrix
                Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
                Project= SonnetProject(char(Sweep_Matrix{1, 4}(2,1)));
                
                % Call Auto_Sim to simulate more accurate S-Parameter
                % values
                [Resonance, Q_Factor] = Auto_Sim(Project, Resonance+0.01, Resonance-0.01);
                % Reset Sweep_Matrix values after simulation and analyses.
                Sweep_Matrix{1, 4}(1,1) = Resonance;
                Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                Sweep_Matrix{1, 4}(2,1) = Project.Filename;
                break
            catch ME
                warning("Something Failed. Retrying...");
                [Resonance, Q_Factor] = Auto_Sim(Project, Resonance+0.01, Resonance-0.01);
                Sweep_Matrix{1, 4}(1,1) = Resonance;
                Sweep_Matrix{1, 6}(2,1) = Q_Factor;
                Sweep_Matrix{1, 4}(2,1) = Project.Filename;
            end
        end
        
        % After fixing resonant frequency and performing more sensitive frequency sweeps,
        % check for Qc Factor once again.
        % Check if Q factor lies in the correct range, if not, perform recursion
        if Q_Factor < (user_Q - Q_lowbound) ||  Q_Factor > (user_Q + Q_highbound)
            % Tell user what is happening
            disp("Qc Factor does not lie within range...");
            disp("Performing recursion to find correct Qc Factors...")
            % Performing recursion
            [Sweep_Matrix] = Find_Resonator(Sweep_Matrix, box_dimensions, Qvalues, LeftX, LeftY,  spacing, thickness, barthickness, x1, y1, x2 ,y2);
        end
    end
%If Value == 1, resonator passed resonance and Q_Factor checks.
% Return function
end
end