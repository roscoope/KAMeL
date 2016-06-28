%%% showOverlay.m
%%% Displays and returns a 3 color channel image with the binary masks toOverlay1,
%%% toOverlay2, and toOverlay3 overlaid on the original image in the red, 
%%% green, and blue color channels, respectively.  toOverlay2 and toOverlay3
%%% are optional arguments.

function imOverlay = showOverlay(imIn,toOverlay1,toOverlay2,toOverlay3)

maxVal = 2^16-1;

if size(imIn,3) == 1
    r = imIn;
    g = imIn;
    b = imIn;
elseif size(imIn,3) == 3
    r = imIn(:,:,1);
    g = imIn(:,:,2);
    b = imIn(:,:,3);
end

toOverlay1 = logical(toOverlay1);
r(toOverlay1) = maxVal;
g(toOverlay1) = 0;
b(toOverlay1) = 0;
if nargin > 2
    toOverlay2 = logical(toOverlay2);
    r(toOverlay2) = 0;
    g(toOverlay2) = maxVal;
    b(toOverlay2) = 0;
    if nargin >3
        toOverlay3 = logical(toOverlay3);
        r(toOverlay3) = 0;
        g(toOverlay3) = 0;
        b(toOverlay3) = maxVal;
    end
end

imOverlay = cat(3,r,g,b);

if islogical(imOverlay)
    imshow(double(imOverlay));
else
    imshow(imOverlay);
end