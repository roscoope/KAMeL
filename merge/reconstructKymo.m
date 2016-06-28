%%% reconstructKymo.m
%%% Removes line segments that have low average decision values or overlap too
%%% much with existing lines
%%%
%%% Input Arguments
%%% mergedLines3 = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%% vertMask = vertical mask of kymograph
%%% fThresh = Maximum fraction of overlap a new line segment can have with the existing line traces; 
%%%      any line segments with an overlap above fThresh are ignored
%%% dThresh = Minimum average value of the decision values of pixels in a line segment; any line 
%%%      segments with an average decision value below dThresh are ignored
%%% 
%%% Output Arguments
%%% diagLinesOut = cell array where each element is a sparse matrix of a binary, thinned 
%%%      mask of a single line segment

function diagLinesOut = reconstructKymo(mergedLines3,vertMask,fThresh,dThresh)
if ~isempty(mergedLines3)
    allLines = reshape({mergedLines3.mask},length(mergedLines3),1);
    imChecked = vertMask;
    diagLinesOut = cell(size(allLines,1),1);
    lineCount = 0;
    for i = 1:length(allLines)
        newLine = allLines{i}>0;
        fracSeen = nnz(imChecked & newLine) / nnz(newLine);
        newDecVals = mergedLines3(i).decVals;
        meanDecVal = mean(full(newDecVals(newLine)));
        if fracSeen < fThresh && meanDecVal > dThresh
            lineCount = lineCount + 1;
            diagLinesOut(lineCount) = {bwmorph(full(newLine),'thin',inf)*lineCount};
            imChecked = imChecked + newLine;
        end
    end
    diagLinesOut = diagLinesOut(1:lineCount,:);
else
    diagLinesOut = [];
end