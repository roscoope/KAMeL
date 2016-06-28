%%% mergeLines3.m
%%% This function merges lines that overlap by a lot. It iterates until all
%%% overlapping lines are merged.  i.e., if line 1 and line 5 overlap, and
%%% line 5 and line 18 overlap, then lines 1, 5, and 18 are all considered
%%% part of the same line.  Overlapping lines are only considered the same
%%% if their corresponding <rho,theta> pairs are similar.  Otherwise, there
%%% could just be a really short line crossing another line.
%%%
%%% Input Arguments
%%% mergedLines = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%% allInds = cell array (same size as image) where each element contains the line segments from newDiagLines
%%%      that have exist at that pixel location
%%% verbose = if this is true, display regular status updates
%%%
%%% Output Arguments
%%% mergedLines3 = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)

function mergedLines3 = mergeLines3(mergedLines,allInds,rtThresh,verbose)

if ~exist('rtThresh','var')
    rtThresh = 5;
end

% now remove lines where most pixels overlap
N = length(mergedLines);
overlapTable = zeros(N);
for k = 1:N
    if verbose && mod(k,300) == 0
        display(['mergeLines3, loop1, k=',num2str(k)]);
    end
    currLine = mergedLines(k).mask;
    currPix = nnz(currLine);
    currRR = mergedLines(k).rr;
    
    inds = find(currLine);
    indsToConsider = cell2mat(allInds(inds));
    oIndsToConsider = setdiff(unique(indsToConsider),[0;k]);
    
    overlapInds = [];
    for m = 1:length(oIndsToConsider)
        newLine = mergedLines(oIndsToConsider(m)).mask;
        overlap = nnz(currLine & newLine);
        newPix = nnz(newLine);
        newRR = mergedLines(oIndsToConsider(m)).rr;
        d = sqrt((currRR(1)-newRR(1))^2+(currRR(2)-newRR(2))^2);
        if (overlap/currPix > 0.25 || overlap/newPix>0.25) && d<rtThresh
            overlapInds = [overlapInds;oIndsToConsider(m)];
        end
    end
    
    overlapTable(k,k) = 1;
    overlapTable(k,overlapInds) = 1;
    overlapTable(overlapInds,k) = 1;
    
end

oldOverlapTable = zeros(N);
while nnz(overlapTable-oldOverlapTable) > 0
    for k = 1:N
        if verbose && mod(k,300) == 0
            display(['mergeLines3, loop2, k=',num2str(k)]);
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
mergedLines2 = []; % this becomes lines whose endpoints overlap
count = 1;
for k = 1:N
    if verbose && mod(k,300) == 0
        display(['mergeLines3, loop3, k=',num2str(k)]);
    end
    indsToMerge = find(newOverlapTable(k,:));
    if ~isempty(indsToMerge)
        mergeCells = reshape(full([mergedLines(indsToMerge).mask]),size(mergedLines(1).mask,1),size(mergedLines(1).mask,2),length(indsToMerge));
        currMerge = sum(mergeCells,3);
        mergedLines2(count).mask = sparse(double(logical(currMerge)) * count);
        rrs = cell2mat(reshape({mergedLines(indsToMerge).rr},length(indsToMerge),1));
        mergedLines2(count).rr = mean(rrs,1);
        decVals = reshape(full([mergedLines(indsToMerge).decVals]),size(allInds,1),size(allInds,2),length(indsToMerge));
        currDecVals = mean(decVals,3);
        mergedLines2(count).decVals = sparse(currDecVals);
        count = count + 1;
        newOverlapTable(setdiff(indsToMerge,k),:) = 0;
    end
end

mergedLines3 = mergedLines2;
