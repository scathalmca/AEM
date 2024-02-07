function [] = AEM(box_x1, box_y1, box_x2, box_y2, Filename, User_Frequencies, Qvalues, spacing, thickness, barthickness)
%  AEM Call function for running the automation software AEM.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%    Automated Electromagnetic MKID simulations   %%%%%
        %%%%%                        AEM                      %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize starting geometry provided by user
Project = SonnetProject(Filename);
% Time automation
tic 
% Display waitbar 
f = waitbar(0, 'AEM Warming Up...');
% Count the number of simulations performed by Sonnet
SimCounter("new"); 
% Store resonant frequencies, Qc and filename of finished MKID structures
EndResonators(0, 0, 0, "new");
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%                :SECTION 1:                 %%%%%%%%%%
            %%%%%       Determining the coordinates of       %%%%%%%%%%
            %%%%%           the starting geometry            %%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %%%%%%%%%%%%%%%%%%% Variable Explanations %%%%%%%%%%%%%%%%%%%%%%%%%
                    %---- box_x1, box_x2, box_y1, box_y2 ----%
    % These are the x and y coordinates of the
    % empty space in which the MKID structure is positioned in the ground plane. 
    % The only polygons that exist  within these coordinates are the MKID
    % resonant structure's polygons.
                              %---- Filename ----%
    % This is the .son filename of the Sonnet Geometry File imported into
    % AEM by the user. The filename is used with the SonnetProject()
    % function to decompile the geometry file in a Project within the Sonnet
    % Toolbox.
                            %---- User_Frequencies ----%
    % A list of the resonant frequencies the user is requesting from AEM.
                                %---- Qvalues ----%
    % The range of allowed coupling quality factors (Qc) provided by the user.
                                %---- spacing ----%
    % The number of "units" of spacing determined by the user between the
    % interdigitated fingers of the MKID. The spacing variable also
    % determines the maximum length of the fingers as the spacing is even
    % around the total finger.
                               %---- thickness ----%
    % The thickness of the interdigitated fingers determined by the user.
    % The "thickness" and "spacing" variables determine the maximum number
    % of possible capacitor fingers within the given IDC space.
                              %---- barthickness ----%
    % The initial thickness of the coupling capacitor bar that couples the
    % feedline to the MKID. This thickness is likely to change throughout the
    % automation, however choosing a good approximation of a thickness speeds
    % up the overall automation.
% Empty box coordinates in which MKID sits in (See Fig.)
box_dimensions = [box_x1  box_y1  box_x2  box_y2];
% Determine the coordinates of the left side of the capacitor
[LeftX, LeftY] = Find_LeftSideKID(Project, box_x1, box_x2, box_y1, box_y2);
% Determine the coordinates of the right side of the capacitor
[XCoords, RightY] = Find_RightSideKID(Project, box_x1, box_x2, box_y1, box_y2);
% Coordinates of the internal area of the capacitor
x1 = round(LeftX(2));
y1 = round(LeftY(1));
x2 = round(XCoords(1));
% y2 is set to the coordinate of the bottom of the coupling bar
y2 = round(RightY(3))+ (spacing+barthickness);
% Small section seperating coupling bar from IDC
side_x = round(XCoords(2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                  Store Variables                %%%%%      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Percentage error on resonant frequencies
Accuracy_Perc=[]; 
% Accuracy (abs(Chosen - Actual)) MHz
Accuracy_Freq=[];
% Close waitbar
close(f);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                    :SECTION 2:                  %%%%%
        %%%%%                  Finding Geometry               %%%%%
        %%%%%                    With Largest                 %%%%%     
        %%%%%                 Resonant Frequency              %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while true
    try
        % Call function to perform large binary search construction to
        % determine the possible resonant frequencies as well as the
        % structure that matches the user's largest frequency.
        [max_freq,min_freq, maxProjectName]=min_Structure(x1,y1,x2,y2,side_x, spacing,thickness,barthickness,Filename);
                               
        break
    catch ME
        warning("Max Frequency Failed. Retrying...");
        delete("maxFrequency.csv");
        delete("maxFrequency.son");
        [max_freq, min_freq, maxProjectName]=min_Structure(x1,y1,x2,y2,side_x, spacing,thickness,barthickness,Filename);
       
    end
end
% Perform check to see if the structure allows for the frequencies given by
% the user in the GUI
if min(User_Frequencies) < min_freq || max(User_Frequencies) > max_freq
    answer = questdlg("The user defined resonances do not lie within the maximum and minimum frequency for this particular geometry. Would you like to continue?") ;
    if answer == "Yes"
        %If user continues the automation after failing the check, reset
        %the list of user frequencies to possible resonances for the given 
        %geometry and begin automation.
        User_Frequencies = User_Frequencies(User_Frequencies>min_freq);
        User_Frequencies = User_Frequencies(User_Frequencies<max_freq);
        if numel(User_Frequencies)==0
            %If no MKIDs lie within the user's given range, cancel
            %automation
            warning("No Resonances Found! Change the Maximum and Minimum Frequencies!");
            return
        end
    else
        return
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                    :SECTION 3:                  %%%%%
        %%%%%                   Building MKIDs                %%%%%
        %%%%%                    With Accurate                %%%%%
        %%%%%                 Resonant Frequencies            %%%%%
        %%%%%                         &                       %%%%%
        %%%%%                      Qc Factors                 %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                    :Subsection 1:               %%%%%
        %%%%%                     Initial Large               %%%%%
        %%%%%                        Sweeps                   %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Finding first resonator geometry
%disp("Starting General Sweep...")
% Start new waitbar for user
f = waitbar(0, 'Building Resonators...');
% Call function to find the first "Guess" geometry that is closest to the
% first/highest user given frequency.
% This function produces the "Sweep_Matrix" used to contain coordinates,
% filenames, resonant frequencies and Q factor of the previous geometry
% throughout the automation.
[Sweep_Matrix]= Asym_BinarySearch(x1, y1, x2, y2, spacing, thickness, barthickness, max(User_Frequencies), maxProjectName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sonnet unfortunately can produce varying Q factors for differing
% frequency sweep ranges for the same MKID structures.
% As an attempt to rectify this problem and improve accuracy in Q factor,
% AEM performs additional simulations with Sonnet with frequency sweeps
% more precisely centered around the resonant frequency of the MKID.
while true
    try
        % Extract variables from Sweep_Matrix 
        % Resonant frequency
        Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
        
        % Initialize project as SonnetProject
        Project = SonnetProject(char(Sweep_Matrix{1, 4}(2,1)));
        
        % Simulate with tighter frequency sweep range with Auto_Sim
        [Resonance, Q_Factor] = Auto_Sim(Project, Resonance+0.01, Resonance-0.01);
        % Set new values extracted with Auto_Sim in Sweep_Matrix
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now check if the Qc Factor is within the user's range, if not perform a
% parameter sweep of the ground plane seperating the MKID and the feedline.
% This section needs fixing
Q_LowerRange = Qvalues(1)+round(Qvalues(3)*0.25);
Q_Factor = Sweep_Matrix{1, 6}(2,1);
if (Q_Factor > Q_LowerRange) || (Q_Factor < Qvalues(1)-Qvalues(3))
    disp("Starting Ground Sweep...")
    [Sweep_Matrix, box_dimensions] = Param_GND(Sweep_Matrix, box_dimensions, Qvalues, y2, 0, LeftX);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                    :Subsection 2:               %%%%%
        %%%%%                Accurate Construction            %%%%%
        %%%%%                     Of All MKIDs                %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finding All Other Resonators
for b = 1: numel(User_Frequencies)
    Sweep_Matrix{1, 6}(1,1) = User_Frequencies(b);
    % Call Find_Resonator
    % This is the main parameterising function that varies the MKID geometry and ground planes to find the correct structures. 
    [Sweep_Matrix] = Find_Resonator(Sweep_Matrix, box_dimensions, Qvalues, LeftX, LeftY, spacing, thickness, barthickness, x1,y1, x2 ,y2);
    % Extract new Resonant Frequency, Filename and Qc Factor from
    % Sweep_Matrix
    Resonance = str2double(cell2mat(Sweep_Matrix{1, 4}(1,1)));
    Filename = Sweep_Matrix{1, 4}(2,1);
    Q_Factor = Sweep_Matrix{1, 6}(2,1);
    % Show a resonator has been constructed successfully.
    disp("Resonator Found...Repeating...")
    % Append values to EndResonators for later.
    EndResonators(Resonance, Q_Factor, Filename, "add");
    % Calculate accuracy values of Resonant Frequency and append to list.
    Accuracy_Perc = [Accuracy_Perc  (100 - (abs((Resonance - User_Frequencies(b))/User_Frequencies(b))*100))];
    Accuracy_Freq = [Accuracy_Freq  (abs(User_Frequencies(b) - Resonance)*1000)];
    
    % If this is not the last resonator automated, close Sonnet.exe
    % This removes previous simulation data stored in Sonnet to avoid
    % crashes and speed up Sonnet's performance (slightly).
    if b~=numel(User_Frequencies)
        % Improves speed
        system('Taskkill/IM sonnet.exe');
    end
    % Show progress of iteration on progress bar
    waitbar(b/numel(User_Frequencies), f, sprintf('Progress: %d %%', floor((b/numel(User_Frequencies))*100)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%                    :SECTION 4:                  %%%%%
        %%%%%                   Printing Data                 %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write all data to a txt file
% Return all resonant frequencies, Q Factor and Filenames belonging to the
% finished MKIDs.
[all_Resonances, all_QFactors, all_Filenames] = EndResonators(0, 0, 0, "get");
% Return the total number of Sonnet simulations performed
[Counter] = SimCounter("get"); 
% Create .txt file.
txtfile=fopen("Resonator Data File.txt", "w+");
% Stop timer and calculate elapsed time
elapsedTime = toc;
% Calculate time in hours, minutes, and seconds
hours = num2str(floor(elapsedTime / 3600));
minutes = num2str(floor(mod(elapsedTime, 3600) / 60));
seconds = num2str(mod(elapsedTime, 60));
% Print the value to the file with a "|" separator
% Display runtime in format hours/minutes/seconds
fprintf(txtfile,'%s%s%s%s%s%s%s',"Runtime| ","Hours: ", hours,"  Minutes: ", minutes, "  Seconds: ",seconds);
fprintf(txtfile, "\n");
fprintf(txtfile,"%s%s", "Number of Simulations Performed: ", num2str(Counter));
fprintf(txtfile, "\n");
fprintf(txtfile,"%s%s", "Mean Accuracy(%) ", num2str(mean(Accuracy_Perc)));
fprintf(txtfile, "\n");
fprintf(txtfile,"%s%s", "Mean Accuracy(MHz) ", num2str((mean(Accuracy_Freq))));
fprintf(txtfile, "\n");
fprintf(txtfile, "\n");
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 6),"FileName", repmat('_', 1, 6));
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 6),"User Resonances(MHz)", repmat('_', 1, 6));
fprintf(txtfile, '%s%s', "|",repmat('_', 1, 6),"Resonances(MHz)", repmat('_', 1, 6));
fprintf(txtfile, '%s%s%s%s%s', "|",repmat('_', 1, 6),"Q-Factor", repmat('_', 1, 6), "|");
% Change directory and make new folder
mkdir FinishedMKIDs\
for i=1:numel(all_Resonances)
    %%%%%%%%%%%%%%%%%%%%
    % Printing data to .txt
    %%%%%%%%%%%%%%%%%%%%
    fprintf(txtfile, "\n");
    
    % Set resonant frequencies from GHz to MHz and round
    all_Resonances(i) = round(all_Resonances(i)*1e3, 2);
    
    % Round Qc Factors.
    all_QFactors(i)=round(all_QFactors(i));
    % Print values to .txtfile line by line.
    fprintf(txtfile, "%s%23s%33s%26s", all_Filenames(i), num2str(User_Frequencies(i)*1000), num2str(all_Resonances(i)), num2str(all_QFactors(i)));
    %%%%%%%%%%%%%%%%%%%%
    % Storing .son and .csv files
    %%%%%%%%%%%%%%%%%%%%
    % Move all finished MKID geometries and .csv data files to new folder.
    movefile(all_Filenames(i), "FinishedMKIDs\");
    str_csv=erase(all_Filenames(i),".son") + ".csv";
    movefile(str_csv, "FinishedMKIDs\")
end
% Close .txt file
fclose(txtfile);
% Change directory and make new folder
mkdir ExcessGeometries\
%Moving all excess geometries to seperate folder
movefile *GHz.son ExcessGeometries\
movefile *GHz.csv ExcessGeometries\
% Close existing waitbar.
close(f);
% Display the automation software has finished successfully.
disp("Resonators Successfully Simulated!");
end