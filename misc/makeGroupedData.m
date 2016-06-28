%%% makeGroupedData.m
%%% Consolidate data by animal group for easier comparisons.
%%%
%%% Input argument
%%% T = table of ungrouped data
%%% 
%%% Output argument
%%% groupedT = table of grouped data.  For every data column in T, groupedT
%%%      has a column corresponding to the mean of that parameter for all
%%%      members in a group, and another column corresponding to the std
%%%      dev of that parameter for all members in a group.

function groupedT = makeGroupedData(T)

C = table2cell(T);
varNames = T.Properties.VariableNames;

dirNums = cell2mat(C(:,3));

uDirNums = unique(dirNums);
groupedC = [];

%%% For each separate group of animals, calculate mean and std dev
for i = 1:length(uDirNums)
    sameDirInds = find(dirNums==uDirNums(i));
    currC = C(sameDirInds,5:end);
    currStats = cell2mat(currC);
    
    %%% If there is only one datapoint for a group, the mean is that value
    %%% and the std dev is 0
    if size(currStats,1) > 1
        meanCells = num2cell(roundToDec(mean(currStats,1),4));
        stdCells = num2cell(roundToDec(std(currStats,1),4));
    else
        meanCells = num2cell(roundToDec(currStats,4));
        stdCells = num2cell(roundToDec(zeros(1,size(currStats,2)),4));
    end
    
    %%% The first time through the loop, initialize the grouped cell array
    if isempty(groupedC)
        groupedC = cell(length(uDirNums),2+2*(size(C,2)-4));
    end
    
    currDir = num2str(uDirNums(i));
    groupedC(i,1) = {currDir};
    groupedC(i,2) = {length(sameDirInds)};
    groupedC(i,3:2:(2*length(meanCells)+3-1)) = meanCells;
    groupedC(i,4:2:(2*length(stdCells)+4-1)) = stdCells;
end

%%% Attach a prefix "M_" and "S_" to the variable names to denote mean and
%%% std dev, respectively.
newVarNamesM = cellfun(@(x) [{strcat('M_',x)},{strcat('S_',x)}],varNames(5:end),'UniformOutput',false);
newVarNames = cell(1,2*length(newVarNamesM));
for i = 1:length(newVarNamesM)
    newVarNames(2*i-1:2*i) = newVarNamesM{i};
end
groupedVarNames = [{'Directory','Num_Animals'},newVarNames];
groupedT = cell2table(groupedC,'VariableNames',groupedVarNames);
