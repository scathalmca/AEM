function [] = delFileOutput(Project)
%  DELFILEOUTPUT Function for removing FileOutputs in the Sonnet Project File.
% Check if the project already contains set file output settings.
if isempty(Project(1).FileOutBlock.ArrayOfFileOutputConfigurations) ==1
    
    % If empty, return function
    return
else
    % Set FileOutputConfigurations to an empty list.
    Project(1).FileOutBlock.ArrayOfFileOutputConfigurations = [];
    % Save project
    Project.save();
end
end