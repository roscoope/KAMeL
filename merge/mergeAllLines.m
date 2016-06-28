%%% mergeAllLines.mask
%%% Takes line segments identified by SVM and merges or separates them as necessary.
%%%
%%% Input Arguments
%%% diagLineProbs = cell array (size is N x 1) where each element is a sparse matrix of a binary 
%%%      mask of all pixels identified as potential line segments along this <theta,rho> line 
%%% rrOut2 = array of size N x 4.  Columns are theta, rho, y-location of seed point,
%%%      and x-location of seed point for each traced line
%%% decVals = cell array (size is N x 1) where each element is a sparse matrix of the decision 
%%%      values of all pixels along this <theta,rho> line 
%%% wThresh = Any line segment shorter than wThresh is ignored
%%% rtThresh = Maximum separation of two <theta,rho> pairs for the line segments to be merged
%%% verbose = if this is true, display regular status updates
%%%
%%% Output Arguments
%%% mergedLines3 = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)

function mergedLines3 = mergeAllLines(diagLineProbs,rrOut2,decVals,wThresh,rtThresh,verbose)

if ~exist('wThresh','var') || isempty(wThresh)
    wThresh = 13;
end
wThresh1 = wThresh * 5/13;

[newDiagLines,~] = mergeLines1(diagLineProbs,rrOut2,decVals,wThresh1,verbose);
allInds2 = cell(size(newDiagLines(1).mask));
for i = 1:length(newDiagLines)
    currMask = newDiagLines(i).mask;
    allInds2(logical(currMask)) = cellfun(@(x) {[x;i]},allInds2(logical(currMask)));
end
mergedLines2 = mergeLines3(newDiagLines,allInds2,rtThresh,verbose);

allInds1 = cell(size(mergedLines2(1).mask));
for i = 1:length(mergedLines2)
    currMask = mergedLines2(i).mask;
    
    [r,c] = find(currMask);
    [cMin,cMinInd] = min(c);
    [cMax,cMaxInd] = max(c);
    rMax = r(cMaxInd);
    rMin = r(cMinInd);
    ep = zeros(size(currMask));
    ep(rMax,cMax) = 1;
    ep(rMin,cMin) = 1;
    epD = logical(imdilate(ep,ones(3)));
    mergedLines2(i).epD = find(i*epD);
    allInds1(epD) = cellfun(@(x) {[x;i]},allInds1(epD));
end
[mergedLines,~] = mergeLines2(mergedLines2,allInds1,rtThresh,verbose);
mergedLines3 = mergeLines5(mergedLines,wThresh);