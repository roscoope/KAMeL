function KAMeL(varargin)

addpath('em')
addpath('merge')
addpath('misc')
addpath('radonTransform')
addpath('segmentationSVM\')
addpath('segmentationSVM\predict\')
addpath('segmentationSVM\train')

%%% First argument must be mode:  either 'train' or 'predict'
%%% Second argument is dirList
%%% Third argument is path to liblinear

nargin = length(varargin);
if nargin < 3
    error('Error:  Not enough input arguments.');
elseif mod(nargin,2) == 0
    error('Error:  Mismatched input arguments.');
end

%%% First argument must be mode:  either 'train' or 'predict'
if strcmp(varargin{1},'train')
    mode = 1;
elseif strcmp(varargin{1},'predict')
    mode = 2;
else
    error('Error!  Invalid mode selected');
end

%%% Second argument is dirList
dirList = varargin{2};
if isempty(dirList) || ~iscellstr(dirList)
    error('Error:  Invalid directory list.');
end
for i = 1:length(dirList)
    currDir = dirList{i};
    if ~strcmp(currDir(end),'\') && ~strcmp(currDir(end),'/')
        currDir = [currDir, '/'];
    end
    dirList(i) = {currDir};
end

%%% Third argument is path to liblinear
pathToLiblinear = varargin{3};
if ~exist(pathToLiblinear,'dir')
    error('Error!  The path to liblinear does not exist');
elseif isempty(strfind(lower(pathToLiblinear),'matlab'))
    error('Error!  Make sure you include the path to the MATLAB files in liblinear')
end
addpath(pathToLiblinear)

%%% Default Argument Values
dictID = '';
addToDictionary = 1;
retrainManual = 0;
fileOut = '';
modelFile = '';
toEM = true;
fileExt = '*.tif';
verbose = false;
hStep = 300;
wStep = 500;
pThresh = [];
wThresh = 10;
vThresh = 0.5;
dThresh = -1;
fvThresh = 0.5;
fThresh = 0.75;
rtThresh = 5;
%%% Assign user-defined parameter values
for i = 4:2:nargin
    currStr = varargin{i};
    currVal = varargin{i+1};
    eval([currStr,' = currVal;']);
end

if mode == 1 %%% We are in training mode
    if strcmp(dictID,'')
        error('Error!  Please enter a dictID');
    end
    
    %%% dictionary creation (involves user input)
    dictionaryFile = createDictionary(dirList,fileExt,dictID,addToDictionary);
    
    %%% Training data and model creation are automatic
    display('Creating training data...')
    [~,tdFile] = createTrainingData(dictionaryFile,dictID,wThresh,verbose);
    display('Training SVM...')
    [~,modelFile1] = createModel(tdFile);

    %%% Retraining the SVM (can be automatic or manual)
    display('Retraining SVM...');
    modelFile = retrainSVM(dictionaryFile,dictID,modelFile1,retrainManual,verbose,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep);
    if ~strcmp(modelFile(end-3:end),'.mat')
        modelFile = [modelFile,'.mat'];
    end
    
    %%% Tell the user where the model is saved for future reference
    display(['Model saved in: ',modelFile]);
elseif mode == 2  %%% Prediction Mode
    if strcmp(modelFile,'')
        error('Error!  Please enter a modelFile');
    elseif ~exist(modelFile,'file')
        error('Error!  Please enter a modelFile that exists');
    end
    if strcmp(fileOut,'')
        error('Error!  Please enter an output file name (fileOut)');
    end
    
    %%% Do the line tracing
    fileNames = getInfNestedFileNames(dirList,fileExt);
    C = traceLinesLoop(fileNames,modelFile,verbose,pThresh,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep);
    
    %%% Assign dirNums
    if length(dirList) == 1
        [dirNums,~] = mapFilesToTopDir(dirList{1},fileNames);
        if isempty(dirNums)
            dirNums = ones(size(fileNames));
        end
    else
        dirInds = cellfun(@(y) find(cellfun(@(x) ~isempty(x),strfind(fileNames,y))),dirList,'uniformoutput',false);
        dirNums = zeros(size(fileNames));
        for j = 1:length(dirList)
            dirNums(dirInds{j}) = j;
        end
    end
    C(:,3) = num2cell(dirNums);
    varNames = {'Directory','DataFile','DirNum','WorkspaceFile','MeanRunLength','MeanSpeed'};
    T = cell2table(C,'VariableNames',varNames);
    
    %%% Apply EM and write out the data
    if ~isempty(T)
        %%% Apply Distribution Refinement
        if toEM
            emT = emLoop(T);
        else
            emT = T;
        end
        
        %%% Create a grouped file for easy comparison of populations
        groupedT = makeGroupedData(emT);
        
        %%% Write out the files
        writetable(emT,[fileOut,'.csv']);
        writetable(groupedT,[fileOut,'_grouped.csv']);
    end
end
