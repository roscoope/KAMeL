%%% findAxonLine.m
%%% This function displays the image in figure(1) and asks the user to
%%% click points along the neurite of interest to be the mask of the axon.
%%%
%%% Input arguments
%%% mpFile = either file name of projection file or a 2D image
%%% diPix = number of pixels by which to dilate the user-selected line for the mask
%%% numLineScans = number of line scans to collect.  This parameter was hardly used 
%%%      and hence not thoroughly tested
%%% imToShow = the image to display to the user, in case the contrast in
%%%      the real image is too low, etc.
%%%
%%% Output arguments
%%% axonMask = the mask image
%%% postEP = the location of the first click of the user
%%% imMask2 = the image that was shown to the user.

function [axonMask,postEP,imMask2] = findAxonLine(mpFile,diPix,numLineScans,imToShow)

if ~exist('numLineScans','var') || isempty(numLineScans)
    numLineScans = 1;
end

%%% Read the input file
if ischar(mpFile)
    imIn = imread(mpFile);
    if size(imIn,3) > 1
        imIn = imIn(:,:,1);
    end
else
    imIn = mpFile;
end

imScaled = linRescale(imIn)*2;

if ~exist('imToShow','var')
    imMask2 = imScaled;
else
    imMask2 = imToShow;
end

%%% Ask the user to click along the nerite of interest.
figure(1);imshow(imMask2);
title('Click points along the neurite of interest and hit ENTER.');

%%% For each new click, display the most-recently generated line segment
%%% for reference
[newX,newY] = ginput(2);
x = [];
y = [];
while ~isempty(newX)
    x = [x; newX];
    y = [y; newY];
    hold on;
    plot([x(end) x(end-1)],[y(end) y(end-1)],'r');
    [newX,newY] = ginput(1);
end

%%% Return cleanly if the user wishes to not select a mask
if isempty(x)
    axonMask = [];
    postEP = [];
    return;
end
x = int32(x);
y = int32(y);

[h,w] = size(imIn);
x(x > w) = w;
x(x < 1) = 1;
y(y > h) = h;
y(y < 1) = 1;

%%% make the userMask within which to look for the neurite.  Connect user clicks
%%% with straight lines.
userMask = zeros(size(imIn));
newLines = cell(length(x)-1,1);
for i = 2:length(x)
    newLine = zeros(size(imIn));
    
    dx = x(i)-x(i-1);
    dy = y(i)-y(i-1);
    
    if abs(dx) > abs(dy)
        if x(i-1) < x(i)
            currX = x(i-1):x(i);
        else
            currX = x(i-1):-1:x(i);
        end
        currY = round((currX - x(i-1)) * dy / dx + y(i-1));
    else
        if y(i-1) < y(i)
            currY = y(i-1):y(i);
        else
            currY = y(i-1):-1:y(i);
        end
        currX = round((currY - y(i-1)) * dx / dy + x(i-1));
    end
    lineInds = sub2ind(size(newLine), currY, currX);
    newLine(lineInds) = 1;
    
    userMask = userMask | newLine;
    newLines(i-1) = {newLine};
end

%%% Dilate the mask to cover the entire width of the neuron.
userMaskD = imdilate(userMask,ones(diPix));

if numLineScans == 1
    axonMask = userMaskD;
else
    axonMask = cell(length(newLines),1);
    for i = 1:length(newLines);
        axonMask(i) = {imdilate(userMask,ones(diPix))};
    end
end

postEP = [y(1);x(1)];