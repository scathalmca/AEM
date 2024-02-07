function [Value] = Accuracy_Check(NewValue, OldValue, User_Frequency)
%  ACCURACY_CHECK 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is used with Sense_Sweep to determine which simulated MKID
% resonant frequency lies closer to the user's designed resonant frequency.
% The function takes in 2 frequencies (NewValue and OldValue) (or Resonance
% and prev_resonance) and determines which is closer to the user's
% resonance.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prev_resonance - User_Frequency
Old= abs(OldValue-User_Frequency);
% Resonance - User_Frequency
New = abs(NewValue-User_Frequency);
if New < Old
    % Continue forloop in Sense_Sweep
    Value = 0;
elseif New >= Old
    % Closest possible resonant frequency to User_Frequency has been found.
    Value = 1;
end