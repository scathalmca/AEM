function [Resonance, Qual_Fac, Warning] = Auto_Sim(Project, upperbound, lowerbound)
%  AUTO_SIM Auto_Sim sets the project settings of a given Sonnet Project file.
% 
% The function will monitor the progress of the simulation via the .csv file 
% output from Sonnet.
% 
% Auto_Sim will continuely monitor the .csv file and detect crashes, errors 
% in data and stalls in Sonnet.
% Add to the simulation counter
SimCounter("sim"); 
% Check is a .csv file already exists with the same project filename and
% remove.
csv_name=erase(Project.Filename(), ".son") + ".csv";
if exist(csv_name)
    delete(csv_name);
end
% Clean the project file.
% This function sometimes breaks the automation software, not sure why.
Project.cleanProject;
% Delete all existing File-Output and Frequency Sweeps/
delFileOutput(Project);
delFreqSweeps(Project);
% Add the given frequency sweep range with 2,000 points.
Project.addAbsEntryFrequencySweep(lowerbound, upperbound, 2000);
% Add a file output to the project folder with the starting geometry file
% name.csv
Project.addFileOutput("CSV","D","Y","$BASENAME.csv","NC","Y","S","MA","R",50);
% Simulate the project.
Project.simulate();
% Cast the largest frequency point (upperbound) as a double.
% This value will later let us determine if the simulation is finished or
% if an error has occurred.
endFrequency = round(cast(upperbound, "double"), 4);
% Initilize m, n and i for while loops
m = 0; 
i=0;
n=0;
% This while statement allows us to check if Sonnet has created a .csv file
% for the simulated geometry file before continuing the programme.
while m == 0
    
    %If .csv exists, break while statement
    if exist(csv_name)
        m = m+1;
    else
        %File does not yet exist, so loop back
    end
end
% Once the .csv file exists,
% Kill any cmd display windows
system('Taskkill/IM cmd.exe');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The below while statement allows us to check if Sonnet has finished it's
% analyse by continuing analysing the .csv file until we satisfy two
% conditions:
% 1) The last frequency in the file is equal to the last frequency (upperbound)
% 2) The last frequency is NOT the minimum |S21| value.
% In the case of condition (2), if no resonant frequency is detected by
% Sonnet, then the upperbound in the sweep will correspond to the
% minimum |s21| value.
% Therefore, we want to detect resonances by avoiding this condition, even
% if Sonnet decides to simulate the circuit at the upperbound before finishing the
% entire data set.
while n == 0
    % Slows down reading of the matrix so Sonnet can catch up
    pause(0.1)
    
    while true
        try
            % Read in .csv matrix
            T=readmatrix(csv_name);
            % Cast the first column, last value as a double
            Frequency = cast(T(end,1), "double");
            
            break
        catch ME
            warning("Trouble reading csv file. Retrying...");
            
            % Pause again for the programme to catch up.
            pause(1);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This section monitors the last time the .csv file has been
    % editted/accessed.
    % This is important as it detects when Sonnet has crashed and no longer
    % produces data.
    %Determine the file location
    folderpath = fileparts(which(csv_name)) + "\"+csv_name;
    files = dir(folderpath);
    date_number=files.datenum;
    % Get the time the file was last accessed
    Modified_time = (minute(date_number)*60 + second(date_number));
    % Get the current time on PC
    Current_time = (minute(now)*60)+second(now);
    % Check the time
    check_time =  (Current_time- Modified_time)/60;
    % If the file hasn't been accessed within the past 2 minutes, AEM will
    % classify this as a "crash" of Sonnet and perform the simulation once
    % again.
    if check_time >=2
        % Tell user what is happening
        disp("Sonnet appears to have crashed!");
        disp("Performing the simulation again...")
        % Typically, changing the frequency sweep range will rectify issues
        % with crashing Sonnet project files.
        upperbound = ceil(upperbound);
        lowerbound = floor(lowerbound);
        % Perform recursion
        [Resonance, Qual_Fac, Warning]=Auto_Sim(Project, upperbound, lowerbound);
        return
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This section checks if the data file has been successful finished and
    % all data has been produced.
    
    if ismembertol(endFrequency,Frequency, 1e-7) == 1 && numel(T)>=2000
        
        while true
            try
                
                % Try extracting resonant frequency from data file
                [Resonance, Qual_Fac, Warning, upperbound, lowerbound] = Auto_Extract(csv_name);
                break
            catch ME
                warning("Extraction of Data failed. Retrying...");
                [Resonance, Qual_Fac, Warning]=Auto_Sim(Project, upperbound+0.1, lowerbound-0.1);
                break
            end
        end
    
        % If the resonant frequency is equal to last frequency in sweep,
        % loop back again.
        if Resonance == endFrequency
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % This section is seperated for ease of reading.
            % Here, we check if the .csv contains any inaccurate data.
            if Warning~= 0
                % Tell user what is happening
                disp("The .csv file contains inaccurate data...");
                disp("Re-simulating data...")
                % Perform recursion
                [Resonance, Qual_Fac, Warning]=Auto_Sim(Project, upperbound, lowerbound);
                % Back from recursion
                return
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
            % This section is designed to search for a particular error
            % file produced by Sonnet when the simulation fails.
            % This file has no extension and comes in the form :"SON" and a
            % random string of numbers (i.e. SON19481)
            % This error file is always produced when a simulation is
            % finished, but promptly deleted is the simulation is
            % successful.
            % To detect a crash, AEM will detect the exist of the SON error
            % file and if that file exists for long enough (usually a few
            % seconds), classify this as a crash from Sonnet.
            % Find the file path
            folderpath = fileparts(which(Project.Filename));
            files = dir(folderpath);
            subFolderNames = {files(1:end).name};
            Sonnet_Crash_Array=contains(subFolderNames, "SON");
            Sonnet_Crash=any(contains(subFolderNames, "SON"));
            
            % Check if the SON file exists
            if Sonnet_Crash==1
                % Basic timer
                i=i+1;
                if Sonnet_Crash==1 &&  i>=200
                    index=find(Sonnet_Crash_Array==1);
                    
                    % Delete the SON file
                    delete(char(subFolderNames(index)));
                    % Clean the project
                    Project.cleanProject;
                    
                    % Tell user what is happening
                    disp("Sonnet appears to have crashed!");
                    disp("Performing the simulation again...")
                    % Resimulate data with new frequency sweep ranges.
                    [Resonance, Qual_Fac, Warning]=Auto_Sim(Project, upperbound+0.1, lowerbound-0.1);
                    
                end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
        % End of the Resonance == endFrequency if statement
        % If the resonant frequency does not equal the upperbound,
        % break the while loop and extract the correct resonant frequency
        else
            % Break the while n==0 statement
            n = n+1;
            
        end
        
    end
    
end
% Check if data produced from simulation is correct once again
if Warning~= 0
    % Tell user what is happening
    disp("The .csv file contains inaccurate data...");
    disp("Re-simulating data...")
    % Perform recursion
    [Resonance, Qual_Fac, Warning]=Auto_Sim(Project, upperbound, lowerbound);
    % Back from recursion
    return
end
% Display values to keep track during automation
disp("---Current Simulation---")
disp(['Filename: ', Project.Filename()]);
disp(['Resonant Frequency: ', num2str(round(Resonance,3)), 'GHz']);
disp(['Qc Factor: ', num2str(round(Qual_Fac))]);
% Kill exisiting cmd windows
system('Taskkill/IM cmd.exe');
end