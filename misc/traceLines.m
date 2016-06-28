%%% traceLines.m
%%% Traces the lines in the image kymoDR.  Returns a lot of intermediate information
%%% for debugging purposes.
%%%
%%% Input Arguments
%%% kymoDR = image to trace (of type double, in range [0,1])
%%% modelFile = String containing name of file storing SVM model.  This string was 
%%%      printed out during training.
%%% verbose = 1 to display figures after processing each image and display detailed status 
%%%      updates, and 0 to display no figures and only minimal status updates.  When 1, 
%%%      this will overwrite Figures 1, 2, and 3 in MATLAB.
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
%%% Rfull (optional) = previously computed Radon transform of kymoDR
%%% rrSorted (optional) = array of size N x 4.  Columns are theta, rho, y-location of seed point,
%%%      and x-location of seed point for each traced line
%%% 
%%% Output Arguments
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

function [diagLinesOut,mergedLines3,decValsOut,diagLineProbs,vertMask,rrOut2,rrSorted,Rfull] = ...
    traceLines(kymoDR,modelFile,verbose,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,Rfull,rrSorted)

%%% block-by-block Radon transform
blockSize = 50;
stepSize = 25;
if ~exist('rrSorted','var') || isempty(rrSorted)
    display('Calculating Radon Transform...');
    [rrSorted,~,Rfull] = radonBlocks(kymoDR,blockSize,stepSize,verbose);
end

%%% Segmentation SVM
display('Segmentation SVM...')
load(modelFile)
[vertMask, diagLineProbs, rrOut2, decValsOut] = getLineProbs(linRescale(kymoDR),rrSorted,blockSize,model,wThresh,[],vThresh,fvThresh,verbose);

%%% Line merging
display('Merging lines...')
mergedLines3 = mergeAllLines(diagLineProbs,rrOut2,decValsOut,wThresh*1.3,rtThresh,verbose);
diagLinesOut = reconstructKymo(mergedLines3,vertMask,fThresh,dThresh);

%%% If desired, output several plots to show the various stages of the analysis
if verbose
    allLines = sum(cell2mat(cellfun(@full,reshape(diagLineProbs,1,1,length(diagLineProbs)),'UniformOutput',false)),3);
    figure(1);subplot(1,2,1);imshow(kymoDR);subplot(1,2,2);showOverlay(kymoDR,allLines);title('diagLineProbs')
    if ~isempty(diagLinesOut)
        allLines = sum(cell2mat(reshape(cellfun(@full,{mergedLines3.mask},'uniformoutput',false),1,1,length(mergedLines3))),3);
        figure(2);subplot(1,2,1);imshow(kymoDR);subplot(1,2,2);showOverlay(kymoDR,allLines);title('mergedLines')
        allLines = sum(cell2mat(reshape(diagLinesOut,1,1,size(diagLinesOut,1))),3);
        figure(3);subplot(1,2,1);imshow(kymoDR);subplot(1,2,2);showOverlay(kymoDR,allLines);title('diagLinesOut')
    end
end
