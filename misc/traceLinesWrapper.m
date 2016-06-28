%%% traceLinesWrapper.m
%%% Since traceLines.m is slow, this function breaks the input image file into chunks
%%% and runs traceLines on each block individually.
%%%
%%% Input Arguments (very similar to traceLines.m)
%%% kymoFile = string containing the name of the file to analyze
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
%%% Output Arguments (Same as traceLines.m, but each output is a cell array, and each entry in 
%%% each cell array corresponds to the value of that output for that corresponding block.  The 
%%% output arguments are copied here from traceLines for reference)
%%% 
%%% diagLinesOut = cell array where each element is a sparse matrix of a binary, thinned 
%%%      mask of a single line segment
%%% mergedLines3 = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%% decVals = cell array (size is N x 1) where each element is a sparse matrix of the decision 
%%%      values of all pixels along this <theta,rho> line 
%%% diagLineProbs = cell array (size is N x 1) where each element is a sparse matrix of a binary 
%%%      mask of all pixels identified as potential line segments along this <theta,rho> line 
%%% vertMask = vertical mask of kymograph
%%% rrOut2 = array of size N x 4.  Columns are theta, rho, y-location of seed point,
%%%      and x-location of seed point for each traced line
%%% rrSorted = array of all <theta,rho> peaks, sorted by proximity to the dominant velocity.  Columns are theta, 
%%%      rho, y-location of seed point,and x-location of seed point for each traced line
%%% Rfull = previously computed Radon transform of kymoDR

function [diagLinesOutC,mergedLines3C,decValsOutC,diagLineProbsC,vertMaskC,rrOut2C,rrSortedC,RfullC] = ...
    traceLinesWrapper(kymoFile,modelFile,verbose,pThresh,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep)

kymoDR = getKymoDR(kymoFile,pThresh);
[kymoDrH,kymoDrW] = size(kymoDR);
kymoDRC = mat2cell(kymoDR,[hStep*ones(floor(kymoDrH/hStep),1);mod(kymoDrH,hStep)],...
    [wStep*ones(floor(kymoDrW/wStep),1);mod(kymoDrW,wStep)]);
[diagLinesOutC,mergedLines3C,decValsOutC,diagLineProbsC,vertMaskC,rrOut2C,rrSortedC,RfullC] ...
    = cellfun(@(x) traceLines(x,modelFile,verbose,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh),kymoDRC,'uniformoutput',false);
rehash
