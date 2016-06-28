%%% retrainSVM.m
%%% Wrapper to retrain the SVM for pixel-by-pixel segmentation.  First, we
%%% augment the training dictionary (this is slow because we run KAMeL on every 
%%% image in the dictionary_, then we generate new training data, and
%%% finally we train the SVM again.
%%% 
%%% Input Arguments
%%% dictionaryFile = file containing the original training dictionary
%%% dictID = prefix string identifying the dictionary
%%% modelFile = file pointing to the existing model
%%% toRetrainManual = 0 to identify misclassified lines automatically, 1 to
%%%      identify them with user input
%%% verbose = 1 for regular status updates
%%% wThresh = Minimum distance (in pixels) a vesicle must travel in order to be considered a line
%%% vThresh = Potential line segments are ignored if more than vThresh of their pixels are 
%%%      part of the vertical mask
%%% fvThresh = Connect segments predicted simultaneous on the same <theta,rho> line if they are 
%%%      are fewer than 10 pixels apart and more than vThresh pixels fall on the vertical mask
%%% fThresh = Maximum fraction of overlap a new line segment can have with the existing line traces; 
%%%      any line segments with an overlap above fThresh are ignored
%%% dThresh = Minimum average value of the decision values of pixels in a line segment; any line 
%%%      segments with an average decision value below dThresh are ignored
%%% rtThresh = Maximum separation of two <theta,rho> pairs for the line segments to be merged
%%% hStep = Vertical size of blocks to run KAMeL on; to run on entire image at once (can be slow), 
%%%      set hStep to be larger than the height of the largest image in the dataset
%%% wStep = Horizontal size of blocks to run KAMeL on; to run on entire image at once (can be slow), 
%%%      set wStep to be larger than the width of the largest image in the dataset
%%%
%%% Output Argument
%%% modelFile = file pointing to the SVM model

function modelFile = retrainSVM(dictionaryFile,dictID,modelFile,toRetrainManual,verbose,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep)

display('Run KAMeL on each image in the training dictionary...')
dFileOut = updateDictForRetrain(dictionaryFile,modelFile,toRetrainManual,verbose,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep);
display('Creating new training data...')
[~,tdFile] = createTrainingData(dFileOut,dictID,wThresh,verbose);
display('Training the SVM with augmented data...');
[~,modelFile] = createModel(tdFile);
