function [NumCapKID] = NumCap(y1, y2, spacing, thickness);
%  NUMCAP %This function calculates the maximum number of whole intedigitated capacitor 
% fingers for an LEKID within a given space.
% 
% 
y_total=(y2-y1);
NumCapKID=floor(y_total/(spacing+thickness));
end