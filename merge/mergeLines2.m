%%% mergeLines2.m
%%% This combines lines with endpoints that overlap.  It iterates until all
%%% lines with overlapping endpoints are merged.  i.e., if line 1 and line
%%% 5 have overlapping endpoints, and line 5 and line 18 have overlapping
%%% endpoints, then lines 1, 5, and 18 are all considered part of the same
%%% line.  Overlapping endpoint lines are only considered the same if their
%%% corresponding <rho,theta> pairs are similar.
%%%
%%% Input Arguments
%%% newDiagLines = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%%      - epD = dilated mask of the endpoints of the traced line segment (same size as the image, saved as sparse matrix)
%%% allInds = cell array (same size as image) where each element contains the line segments from newDiagLines
%%%      that have an endpoint at that pixel location
%%% rtThresh = Maximum separation of two <theta,rho> pairs for the line segments to be merged
%%% verbose = if this is true, display regular status updates
%%%
%%% Output Arguments
%%% mergedLines = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%% allInds = cell array (same size as image) where each element contains the line segments from newDiagLines
%%%      that have exist at that pixel location

function [mergedLines,allInds] = mergeLines2(newDiagLines,allInds,rtThresh,verbose)

if ~exist('rtThresh','var')
    rtThresh = 10;
end

N=length(newDiagLines);
overlapTable = zeros(N);
oldOverlapTable = zeros(N);
for k = 1:N
    if verbose && mod(k,300) == 0
        display(['mergeLines2, loop1, k=',num2str(k)]);
    end
    inds = newDiagLines(k).epD;
    indsToConsider = cell2mat(allInds(inds));
    
    oIndsToConsider = setdiff(unique(indsToConsider),[0;k]);
    if ~isempty(oIndsToConsider)
        rrs = cell2mat(reshape({newDiagLines(oIndsToConsider).rr},length(oIndsToConsider),1));
        rhos = rrs(:,2);
        thetas = rrs(:,1);
        currRho = newDiagLines(k).rr(2);
        currTheta = newDiagLines(k).rr(1);
        d = sqrt((currRho-rhos).^2 + (currTheta-thetas).^2);
        overlapInds = oIndsToConsider(d<rtThresh);
        
        overlapTable(k,k) = 1;
        overlapTable(k,overlapInds) = 1;
        overlapTable(overlapInds,k) = 1;
    end
    
end

while nnz(overlapTable-oldOverlapTable) > 0
    for k = 1:N
        if verbose && mod(k,300) == 0
            display(['mergeLines2, loop2, k=',num2str(k)]);
        end
        oldOverlapTable = overlapTable;
        overlapInds = setdiff(find(overlapTable(k,:)),k);
        overlapTable(k,k) = 1;
        overlapTable(k,overlapInds) = 1;
        overlapTable(overlapInds,k) = 1;
        
        for m = 1:length(overlapInds)
            crossInds = find(overlapTable(overlapInds(m),:));
            if ~isempty(setdiff(crossInds,k))
                overlapTable(overlapInds,crossInds) = 1;
                overlapTable(crossInds,overlapInds) = 1;
            end
        end
    end
end

newOverlapTable = overlapTable;
mergedLines = []; % this becomes lines whose endpoints overlap
count = 1;
allInds = cell(size(newDiagLines(1).mask));
for k = 1:N
    if verbose && mod(k,300) == 0
        display(['mergeLines2, loop3, k=',num2str(k)]);
    end
    indsToMerge = find(newOverlapTable(k,:));
    if ~isempty(indsToMerge)
        mergeCells = reshape(full([newDiagLines(indsToMerge).mask]),size(allInds,1),size(allInds,2),length(indsToMerge));
        currMerge = sum(mergeCells,3);
        mergedLines(count).mask = sparse(double(logical(currMerge)) * count);
        rrs = cell2mat(reshape({newDiagLines(indsToMerge).rr},length(indsToMerge),1));
        mergedLines(count).rr = mean(rrs,1);
        decVals = reshape(full([newDiagLines(indsToMerge).decVals]),size(allInds,1),size(allInds,2),length(indsToMerge));
        currDecVals = mean(decVals,3);
        mergedLines(count).decVals = sparse(currDecVals);
        allInds(logical(currMerge)) = cellfun(@(x) {[x;count]},allInds(logical(currMerge)));
        count = count + 1;
        newOverlapTable(setdiff(indsToMerge,k),:) = 0;
    end
end
