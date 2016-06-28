%%% getLineLabels.m
%%% Allow the user to manually click on misclassified lines.  This function
%%% uses Figure 1.
%%%
%%% Input Arguments
%%% currKymoDR = the current kymograph block
%%% allLines = mask image where each pixel belonging to a line has the
%%%      index of that line, so that the indices of the bad ones can be easily
%%%      returned
%%%
%%% Output Arguments
%%% goodLines, badLines = index values of the good and bad lines,
%%%      respectively.  Any lines not identified as "bad" are assumed to be
%%%      good.

function [goodLines,badLines] = getLineLabels(currKymoDR,allLines)

%%% Display the image and the overlaid lines
[h,w]= size(currKymoDR);
if h > w
    figure(1);subplot(1,3,1);imshow(currKymoDR);subplot(1,3,2);showOverlay(currKymoDR,allLines);subplot(1,3,3);imshow(allLines);
else
    figure(1);subplot(3,1,1);imshow(currKymoDR);subplot(3,1,2);showOverlay(currKymoDR,allLines);subplot(3,1,3);imshow(allLines);
end
display('Click on the MISLABELED/BAD red lines');
title('Click on the MISLABELED/BAD red lines');

%%% Use the distance transform to find the nearest line corresponding to
%%% each click the user makes.  Iterate until the user stops click on bad
%%% lines.
[~,idx] = bwdist(allLines);
badLines = [];
[x,y] = ginput;
if ~isempty(x)
    for i = 1:length(x)
        currX = round(x(i));
        currY = round(y(i));
        if currX < 1
            currX = 1;
        elseif currX > w
            currX = w;
        end
        if currY < 1
            currY = 1;
        elseif currY > h
            currY = h;
        end        
        badLines = [badLines;allLines(idx(currY,currX))];
    end
end
badLines = unique(badLines);
allLineLabels = unique(allLines(allLines~=0));
goodLines = setdiff(allLineLabels,badLines);
