%%% traceLinesLoop.m
%%% Calls traceLinesWrapper for every file in the list fileNames.  Returns a cell array
%%% containing the file names, workspace file (saved here for each image), mean run length and speed
%%%
%%% Input Arguments
%%% fileNames = cell array of strings, where each entry is the path to a file to process
%%% modelFile = String containing name of file storing SVM model.  This string was 
%%%      printed out during training.
%%% verbose = 1 to display figures after processing each image and display detailed status 
%%%      updates, and 0 to display no figures and only minimal status updates.  When 1, 
%%%      this will overwrite Figures 1, 2, and 3 in MATLAB.
%%% pThresh = this is a percentile (i.e., in the range [0,100]).  The function
%%%      identifies the pThresh percentile intensity value, and then clamps all 
%%%      pixels above that value, and then linearly rescales the image so that
%%%      the pixels are in the range [0,1].
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
%%% dataOut = cell array containing the file locations and vesicle trafficking values for each image

function dataOut = traceLinesLoop(fileNames,modelFile,verbose,pThresh,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep)

N = length(fileNames);
dataOut = cell(N,6);
if ~exist('pThresh','var') || isempty(pThresh)
    load(modelFile);
    pThresh = model.pThresh;
end
for i = 1:N
    kymoFile = fileNames{i};
    display(['Image ',num2str(i),' out of ',num2str(N),': ',kymoFile]);
    [diagLinesOutC,mergedLines3C,decValsOutC,diagLineProbsC,vertMaskC,rrOut2C,rrSortedC,RfullC] = ...
        traceLinesWrapper(kymoFile,modelFile,verbose,pThresh,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep);
	
	%%% Calculate run lengths and speed for each traced line segment
    runLensC = cellfun(@(x) cellfun(@calcRunLen,x),diagLinesOutC,'uniformoutput',false);
    speedsC = cellfun(@(x) cellfun(@calcSpeed,x),diagLinesOutC,'uniformoutput',false);
    wsFile = [kymoFile(1:end-4),'_workspace_',datestr(now,'yyyy_mm_dd'),'.mat'];
    save(wsFile,'runLensC','speedsC','diagLinesOutC','mergedLines3C','decValsOutC','diagLineProbsC',...
	    'vertMaskC','rrOut2C','rrSortedC','RfullC','fThresh','dThresh','wThresh','vThresh','pThresh','fvThresh','rtThresh');
    
	%%% Calculate the average run length and speed for this animal
    allRunLensM = cell2mat(runLensC(:));
    meanRunLen = mean(allRunLensM(:));
    allSpeedsM = cell2mat(speedsC(:));
    meanSpeed = mean(allSpeedsM(:));
	
	[folder,name,ext] = fileparts(kymoFile);
	dataOut(i,1) = {folder};
	dataOut(i,2) = {[name,ext]};
	dataOut(i,3) = {'unassigned'};
	[folder,name,ext] = fileparts(wsFile);
	dataOut(i,4) = {[name,ext]};
    dataOut(i,5) = {meanRunLen};
    dataOut(i,6) = {meanSpeed};
    
	%%% run this to make MATLAB run faster
    rehash
end
