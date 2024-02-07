function [all_Resonances, all_QFactors, all_Filenames] = EndResonators(Resonance, QFactor, Filename, action)
%  ENDRESONATORS Records the resonant frequencies, Qc Factors and .son Filenames of all the 
% completed MKID structures automated by AEM.
persistent End_Resonances
persistent End_QFactors
persistent End_Filenames
if isempty(End_Resonances)
    
    End_Resonances = [];
    End_QFactors = [];
    End_Filenames = [];
end
switch lower(action)
    case "new"
        End_Resonances = [];
        End_QFactors = [];
        End_Filenames = [];
        all_Resonances = End_Resonances;
        all_QFactors = End_QFactors;
        all_Filenames = End_Filenames;
    case "add"
        End_Resonances = [End_Resonances  Resonance];
        End_QFactors = [End_QFactors  QFactor];
        End_Filenames = [End_Filenames  Filename];
        all_Resonances = End_Resonances;
        all_QFactors = End_QFactors;
        all_Filenames = End_Filenames;
    case "get"
        
        all_Resonances = End_Resonances;
        all_QFactors = End_QFactors;
        all_Filenames = End_Filenames;
    otherwise
        error("This is an invalid input");
end
       
end