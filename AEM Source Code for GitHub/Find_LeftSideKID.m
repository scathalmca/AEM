function [XCoords, YCoords] = Find_LeftSideKID(Project, x1, x2, y1, y2)
%  FIND_LEFTSIDEKID 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is used to find the coordinates of the vertical polygon that forms the 
% left side of the MKID geometry provided by the user in AEM.
% This is achieved by scanning through points from the bottom of the box in
% which the MKID sits in the ground plane until the function detects a
% polygon in Sonnet.
% The "scan" of points starts at x1 and scans in the right direction to find
% the first polygon (i.e. the left side of the MKID IDC).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin forloop from the bottom of the box in the ground plane (y2)
for j = y2-1 : -1 : y1+1
    % Start scanning left until a polygon is detected
    for i=x1+1 : 1: x2-1
        % Check to see if a polygon exists that point (i,j,0)
        answer=Project.findPolygonUsingPoint(i, j, 0);
        if isempty(answer)~=1 
            % If answer is not empty, a polygon exists at those coordinates
            XCoords=answer.XCoordinateValues;
            YCoords=answer.YCoordinateValues;
            % Finding X Coords
            XCoords = [XCoords{2}  XCoords{3}  XCoords{4}  XCoords{5}];
            XCoords =[min(XCoords)  max(XCoords)  max(XCoords)  min(XCoords)];
            % Finding Y Coords
            YCoords = [YCoords{2}  YCoords{3}  YCoords{4}  YCoords{5}];
            YCoords =[min(YCoords)  min(YCoords)  max(YCoords)  max(YCoords)];
            break
        end
    end
    % Continue looping through y and x directions until a polygon is found
    if isempty(answer)~=1
        break
        
    end
end
end