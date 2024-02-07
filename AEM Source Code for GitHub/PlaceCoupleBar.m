function [ArrayXValues, ArrayYValues] = PlaceCoupleBar(x1,y2,side_x, spacing, barthickness, Project)
%  PLACECOUPLEBAR 
delta_y=y2-barthickness;
%x1+2 to give 2um spacing between left side of capacitor and coupling bar
ArrayXValues=[x1+spacing  x1+spacing   side_x   side_x];
ArrayYValues=[y2   delta_y   delta_y   y2];
Project.addMetalPolygonEasy(0,ArrayXValues,ArrayYValues,1);
end