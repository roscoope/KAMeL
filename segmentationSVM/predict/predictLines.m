%%% predictLines.m
%%% Wrapper for the SVM for pixel-by-pixel segmentation
%%% 
%%% Input Arguments
%%% model = pre-trained SVM model (not the file name pointing to the model). 
%%% kymoDR = the full image.  This is really only used as a reference to the dimensions of the full image
%%% allFeatures = matrix of features for the whole image at the current rotation
%%% newLine = binary mask image containing only the <theta,rho> line
%%% lineImgF = soft-masking filter (newLine convolved with Gaussian filter)
%%% 
%%% Output Arguments
%%% predMasks = Mask with predicted labels for the image at the line
%%%      specified by newLine
%%% decValsOut = decision values at the pixels near the line specified by newLine

function [predMask,decValsOut] = predictLines(model,kymoDR,allFeatures,newLine,lineImgF)

%%% Soft-mask the full image features
featList = repmat(lineImgF(:),1,size(allFeatures,2)) .* full(allFeatures);

%%% Only perform the prediction on pixels near newLine
newLineD = imdilate(newLine,ones(5));
indsToPred = find(newLineD);

%%% Scale the features
fLScaled = (featList(indsToPred,:) - repmat(model.fMin,size(featList(indsToPred,:),1),1))./repmat(model.fMax-model.fMin,size(featList(indsToPred,:),1),1)*2-1;

%%% Call the liblinear function "predict"
[predLabels,~,decVals] = predict(zeros(size(fLScaled,1),1),sparse(fLScaled),model.modelSVM);

predMask = zeros(size(kymoDR));
predMask(indsToPred) = predLabels;
decValsOut = zeros(size(kymoDR));
decValsOut(indsToPred) = decVals;