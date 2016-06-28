%%% getLinesKymo.m
%%% Allow the user to click on lines in the image iteratively.  For every line, 
%%% the user clicks on each end point once, and then hits "enter."  After selecting 
%%% all of the lines in the image, the user hits "enter" again.  The user should 
%%% select ALL lines, since any that are not selected will be labeled as background 
%%% during the augmentation of the dataset and retraining of the image.
%%% 
%%% Input Arguments
%%% kymo = input image
%%% 
%%% Output Argument
%%% lines = cell array of binary masks.  Each entry is lines is a sparse
%%%      matrix the size of the input kymo with support only where the user
%%%      clicked

function lines = getLinesKymo(kymo)

axonMask = findAxonLine(kymo,1,[],kymo);
imToShow = kymo;

lines = [];

while nnz(axonMask) > 0
    imToShow = showOverlay(imToShow,axonMask);
    lines = [lines;{sparse(double(axonMask(:,:,1)))}];
    axonMask = findAxonLine(kymo,1,[],imToShow);
end