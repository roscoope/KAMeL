%%% mergeLines1.m
%%% This function separates each connected component in each entry of
%%% diagLineProbs into its own potential line
%%% Input Arguments
%%% diagLineProbs = cell array (size is N x 1) where each element is a sparse matrix of a binary 
%%%      mask of all pixels identified as potential line segments along this <theta,rho> line 
%%% rrOut2 = array of size N x 4.  Columns are theta, rho, y-location of seed point,
%%%      and x-location of seed point for each traced line
%%% decVals = cell array (size is N x 1) where each element is a sparse matrix of the decision 
%%%      values of all pixels along this <theta,rho> line 
%%% wThresh = Any line segment shorter than wThresh is ignored
%%% verbose = if this is true, display regular status updates
%%%
%%% Output arguments
%%% newDiagLines = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%%      - epD = dilated mask of the endpoints of the traced line segment (same size as the image, saved as sparse matrix)
%%% allInds = cell array (same size as image) where each element contains the line segments from newDiagLines
%%%      that have an endpoint at that pixel location

function [newDiagLines,allInds] = mergeLines1(diagLineProbs,rrOut2,decVals,wThresh,verbose)

if ~exist('wThresh','var') || isempty(wThresh)
    wThresh = 13;
end

allInds = cell(size(diagLineProbs{1}));
newDiagLines = [];

for k = 1:length(diagLineProbs)
    if verbose && mod(k,300) == 0
        display(['mergeLines1, k=',num2str(k)]);
    end
    currLine = imdilate(full(diagLineProbs{k}),ones(5));
    L = bwlabel(currLine);
    j = round(rrOut2(k,5));
    if j < 1
        j = 1;
    elseif j > size(L,1)
        j = size(L,1);
    end
    i = round(rrOut2(k,6));
    if i < 1
        i = 1;
    elseif i > size(L,2)
        i = size(L,2);
    end
    
    ind = L(j,i);
    
    labels = unique([ind; L(:)],'stable');
    labels(labels==0) = [];
    count = k;
    
    for m = 1:length(labels)
        [r,c] = find(L==labels(m));
        [cMax,cMaxInd] = max(c);
        [cMin,cMinInd] = min(c);
        width = cMax - cMin;
        
        if width > wThresh
            currMask = double(bwmorph(L==labels(m),'thin',3));
            newDiagLines(count).mask = sparse(currMask);
            currDecVals = decVals{k};
            currDecVals(~currMask) = 0;
            newDiagLines(count).decVals = sparse(currDecVals);
            rMax = r(cMaxInd);
            rMin = r(cMinInd);
            ep = zeros(size(currLine));
            ep(rMax,cMax) = 1;
            ep(rMin,cMin) = 1;
            epD = logical(imdilate(ep,ones(3)));
            newDiagLines(count).epD = find(count*epD);
            allInds(epD) = cellfun(@(x) {[x;count]},allInds(epD));
            newDiagLines(count).rr = rrOut2(k,:);
            count = max(length(newDiagLines),length(diagLineProbs))+1;
        end
    end
    if count == k % we didn't find any lines long enough
        newDiagLines(count).mask = sparse(zeros(size(L)));
        newDiagLines(count).decVals = sparse(zeros(size(L)));
        newDiagLines(count).epD = [];
        newDiagLines(count).rr = rrOut2(k,:);
    end
end
