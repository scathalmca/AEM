function [Counter] = SimCounter(action)
%  SIMCOUNTER Counts number of simulations performed by Sonnet.
persistent count
if isempty(count)
    count = 0;
end
switch lower(action)
    case "new"
        count = 0;
        Counter = count;
    case "sim"
        count = count +1; 
        Counter = count;
    case "get"
        Counter = count;
    otherwise 
        error("This is an invalid input");
end
       
end