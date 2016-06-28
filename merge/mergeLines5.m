%%% mergeLines5.m
%%% This function removes any lines that are just too short, based on
%%% a user-specified threshold
%%%
%%% Input Arguments
%%% mergedLines = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)
%%% wThresh = Any line segment shorter than wThresh is ignored
%%%
%%% Output Arguments
%%% mergedLines3 = struct array of lines containing the following fields:
%%%      - mask = binary mask of the pixels in the line (same size as the image, saved as sparse matrix)
%%%      - rr = [theta,rho,y-location of seed point,x-location of seed point]
%%%      - decVals = decision values of all pixels near the line (same size as the image, saved as sparse matrix)

function mergedLines3 = mergeLines5(mergedLines2,wThresh)

% remove short lines
N = length(mergedLines2);
mergedLines3 = mergedLines2;
count = 1;
while count < N
    currLine = mergedLines3(count).mask;
    [r,c] = find(currLine);
    if isempty(r) || (max(c) - min(c) < wThresh)
        mergedLines3(count) = [];
    else
        count = count + 1;
    end
    N = length(mergedLines3);
end
