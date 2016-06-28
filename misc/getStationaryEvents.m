%%% getStationaryEvents.m
%%% This function takes the kymograph and outputs the vertical line mask 
%%% using various types of filtering.

function vertMask = getStationaryEvents(kymoIn)

KA_blockh = 10;
KA_vertsmooth = 1/100*ones(10);

im_vertmed = medfilt2(kymoIn,[KA_blockh*3,1],'symmetric');
im_filt = imfilter(im_vertmed,KA_vertsmooth,'symmetric');
im_backsub = im_vertmed - im_filt;
vertMask = logical(im2bw(im_vertmed+im_backsub,graythresh(im_vertmed+im_backsub)));
