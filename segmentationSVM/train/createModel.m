%%% createModel.m
%%% Train an SVM for the pixel-by-pixel segmentation using liblinear 
%%%
%%% Input Argument
%%% tdFile = file name pointing to the saved training data
%%%
%%% Output Arguments
%%% model = the trained SVM model
%%% modelFile = file name pointing to the saved model

function [model,modelFile] = createModel(tdFile)

%%% Make sure the tdFile exists, load the training data, and generate the
%%% model's file name
if ~exist('tdFile','var') || ~exist(tdFile,'file')
    error('Error!  tdFile does not exist');
else
    load(tdFile);
end
tdID = strtok(tdFile,'_');
if strcmp(tdID,'trainingData')
    tdID = '';
else
    tdID = [tdID,'_'];
end
modelFile = [tdID,'model_',datestr(now,'yyyy_mm_dd')];

trainingData = td.trainingData;
trainingLabels = td.trainingLabels;
fMin = td.fMin;
fMax = td.fMax;

%%% Scale each column of the training data to [-1,1]
tdScaled = (trainingData - repmat(fMin,size(trainingData,1),1))./repmat(fMax-fMin,size(trainingData,1),1)*2-1;

%%% Use liblinear to find the best value of C and then use it to train the model
bestC = train(trainingLabels,sparse(tdScaled), '-s 0 -C -q');
modelSVM = train(trainingLabels,sparse(tdScaled),['-s 0 -q -c ',num2str(bestC(1))]);

model.fMin = fMin;
model.fMax = fMax;
model.modelSVM = modelSVM;
model.pThresh = td.pThresh;

save(modelFile,'model');

