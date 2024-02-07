function [Resonance, Qual_Fac, Warning, upperbound, lowerbound] = Auto_Extract(filename)
%  AUTO_EXTRACT Extracts Resonant Frequency from .csv file.
% 
% Auto_Extract also checks if the data from the .csv is logical.
% 
% If not, the function will return the "Warning" variable as 1.
% Read in all the data as a matrix
T=readmatrix(filename);
% Read in the Frequency values column
Frequency = T(1:end,1);
% Read just the S21 mag values
S21= T(1:end, 6);
% Initialize Qual_Fac and Warning as 0
% Qual_Fac is initialized as a value to return in case of errors.
Qual_Fac=0;
Warning = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%                      Checking Data                   %%%%%%%%%
%%%%%%%%%                        for errors                    %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%                        :Check 1:                     %%%%%%%%%
%%%%%%%%%                       Existance of                   %%%%%%%%%
%%%%%%%%%                        a resonant                    %%%%%%%%%
%%%%%%%%%                           dip                        %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First, determine the local minima of the S21 magnitude.
% As we expect a single resonant "dip" in |S21|, the local minima
% should also be the global minima.
TF_min = islocalmin(S21);
local_minima=S21(TF_min);
% Now we can apply simple logic to test for the existance of a resonant
% frequency
% I.e. No minima exists = No resonant frequency
% We must apply another condition as a minima will occur at the lasts
% frequency if the resonant frequency is outside the sweep range.
% Hence, we make sure that if a minima exists, it does not equal the
% upperbound frequency
if (isempty(local_minima)==1 && isempty(S21(local_minima == min(S21)))~=1)  || (isempty(S21(local_minima == min(S21)))==1 && isempty(local_minima)~=1)  ||  (isempty(S21(local_minima == min(S21)))==1 && isempty(local_minima)==1)
    
    % Tell user what is happening
    disp("No resonances detected. Repeating frequency sweep."); 
    
    % Increase the frequency sweep range
    upperbound = round(cast(T(end,1), "double") +0.5, 4);
    lowerbound = round(cast(T(1,1), "double") -0.5, 4);
    % Set the Resonance as the previous upperbound so as to continue the
    % while loop in Auto_Sim
    Resonance = T(end,1);
    
    % Return function with a warning =1 (failed checks)
    Warning = 1;
    if isempty(local_minima)~=1
        disp("Not Min S21 with  minima");
        index1 = find(S21 == local_minima(1));
        index2 = find(S21 == local_minima(end));
        % Increase the frequency sweep range
        upperbound =round(cast(Frequency(index2), "double") +0.1, 4);
        lowerbound =round(cast(Frequency(index1), "double") -0.1, 4);
        
    end
    % If the range has been set below 1 GHz,
    % increase the upperbound range.
    % This avoids illegal frequency sweeps of <0
    if (upperbound<=1) || (lowerbound<=1)
        upperbound = round(cast(T(end,1), "double")+1, 4);
        lowerbound = round(cast(T(1,1), "double"), 4);
    end
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%                        :Check 2:                     %%%%%%%%%
%%%%%%%%%                       Non-physical                   %%%%%%%%%
%%%%%%%%%                        Parameters                    %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Once we have verified the existance of a resonant frequency
% We now must scan for non-physical data.
% Unfortunately, Sonnet can produce errors in the S-parameter data points.
% Some of these errors include |S21| > 1, a sudden drop in |S21| at the end
% of the data set, etc
% Check if S21 contains values above 1
if numel(S21(S21 > 1))~=0
    
    % Tell user what is happening
    disp("|S21| is above 1! Correcting non-physical data in Sonnet by repeating simulation...");
    % Return the minimum of S21 as the resonant frequency
    index = find(S21 == min(S21));
    Resonance=Frequency(index);
    
    A=[Frequency(end), Resonance];
    B=[Frequency(1),Resonance];
    upperbound = round(mean(A), 4);
    lowerbound = round(mean(B), 4);
    % Return warning to Auto_Sim
    Warning = 2;
end  
%{
% Check if a resonant dip exists again
% This is in case any data has passed Check 1 by accident.
if S21(end,1) == min(S21) && isempty(local_minima)~=1
    disp("No resonant frequency exists! Resetting bounds...");
    % Recursion
    Auto_Extract(filename);
    
end
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%                      Determining                     %%%%%%%%% 
%%%%%%%%%                          Qc                          %%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if S21(end, 1)~= min(S21) && isempty(local_minima)~=1 && numel(S21(S21 > 1))==0
    index = find(S21 == min(S21));
    
    % Resonant frequency is the minimum of |S21| 
    Resonance=Frequency(index);
    
    % No warning returned
    Warning=0;
    % Return bounds 
    upperbound =round(cast(Frequency(end), "double"), 4);
    lowerbound =round(cast(Frequency(1), "double"), 4);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculating Qc factor
    % Qc is calculated using the FWHM method
    % As Qi goes to infinity in Sonnet, Qc = Q total.
    
    % FWHM is calculated by finding the x intercepts of the resonant dip
    % when shifted down by half the total length (y direction) of the
    % resonant dip.
    
    % Resonant frequency/ minimum of S21
    minimum_db=min(S21);
    
    % Half the length of the resonant dip.
    HM=(max(S21)+minimum_db)/2;
    % Finding the first x-intercept
    [xInt1]=intersections(Frequency(1:index), S21(1:index)-HM, Frequency(1:index), zeros(1,numel(S21(1:index))));
    % Finding the second x-intercept
    [xInt2]=intersections(Frequency(index:numel(Frequency)), S21(index:numel(S21))-HM, Frequency(index:numel(Frequency)), zeros(1,numel(S21(index:numel(S21)))));
    % The number of elements in xInt1 and xInt2 must be equal 
    if numel(xInt1)>numel(xInt2)
        diff=numel(xInt1)-numel(xInt2);
        xInt1(1:diff)=[];
    end
    if numel(xInt1)<numel(xInt2)
        diff=numel(xInt2)-numel(xInt1);
        xInt2(numel(xInt2)-diff:end)=[];
    end
    % FWHM
    x=xInt2-xInt1;
    % Qc = resonance/FWHM
    Qual_Fac=Frequency(index)/x;
end
end