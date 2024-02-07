function [] = delFreqSweeps(Project)
%  DELFREQSWEEPS Function for removing all current frequency sweeps within a Sonnet Project 
% File.
% Check if the project already contains frequency sweep settings.
if isempty(Project(1).FrequencyBlock.ArrayOfSweepSets) ==1
    % If empty, return function
    return
else
    % Set ArrayOfSweepSets to an empty list.
    Project(1).FrequencyBlock.ArrayOfSweepSets = [];
    
    % Save Project.
    Project.save();
end
end