%%% emLoop.m
%%% Wrapper for distribution refinement block.  Independently refines the
%%% distributions of run length and speed, and returns an updated table.

function emT = emLoop(T)

C = table2cell(T);
emC = C;

%%% Identify each animal's corresponding group
dirNums = cell2mat(C(:,3));
dirsToCompare = unique(dirNums);

%%% Determine which column each organization parameter is stored in
varNames = T.Properties.VariableNames;
LInd = find(strcmp('MeanRunLength',varNames));
SInd = find(strcmp('MeanSpeed',varNames));

%%% Perform distribution refinement on each group independently
for i= 1:length(dirsToCompare)
    if nnz(ismember(dirNums,dirsToCompare(i))) > 1
        currDirs = ismember(dirNums,dirsToCompare(i));
        
        Ldirs = currDirs & isfinite(cell2mat(C(:,LInd)));
        oldL = cell2mat(C(Ldirs,LInd));
        
        Sdirs = currDirs & isfinite(cell2mat(C(:,SInd)));
        oldS = cell2mat(C(Sdirs,SInd));
        
        thresh = 0.01;
        [piL,muL,sigmaL,Ls,newL] = emLoop1Var(oldL,thresh);
        [piS,muS,sigmaS,Ss,newS] = emLoop1Var(oldS,thresh);
        
        dataPointsL = newL;
        emC(Ldirs,LInd) = num2cell(dataPointsL);
        
        dataPointsS = newS;
        emC(Sdirs,SInd) = num2cell(dataPointsS);
    end
end

emT = cell2table(emC,'VariableNames',varNames);
