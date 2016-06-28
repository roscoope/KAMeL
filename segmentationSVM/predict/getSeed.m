%%% getSeed.m
%%% Identify the seed point (the brightest point on the <theta,rho> line).
%%% 
%%% Input Arguments
%%% im = the full image 
%%% currTheta, currRho = parameters defining the current line of interest
%%% j,i = y- and x-position of the top left corner of the block that this <theta,rho> pair 
%%%      was identified with respect to the entire image
%%% blockSize = size of the block in which the <theta,rho> pair was found
%%% 
%%% Output Arguments
%%% rSeed,cSeed = y- and x-position of the identified seed point
%%% imDiag = full image after soft-masking along <theta,rho> line
%%% newLine = binary mask image containing only the <theta,rho> line
%%% lineImgF = soft-masking filter (newLine convolved with Gaussian filter)

function [rSeed,cSeed,imDiag,newLine,lineImgF] = getSeed(im,currTheta,currRho,j,i,blockSize)

%%% Allow user to input a mask image directly instead, or find the seed in
%%% the entire image
if exist('currRho','var') && length(currRho) == 1
    newLine = makeLineRadon(im,currTheta,currRho);
elseif exist('currTheta','var') && length(currTheta) > 1
    newLine = currTheta;
else
    newLine = ones(size(im));
end
sigma = 2;
gf = fspecial('gaussian',50,sigma);
lineImgF = conv2(newLine,gf,'same');
imDiag = linRescale(lineImgF .* im);

[h,w] = size(im);
imSmall = imDiag(j:min(j+blockSize-1,h),i:min(i+blockSize-1,w));
[~,indSeed] = max(imSmall(:));
[rSeed1,cSeed1] = ind2sub(size(imSmall),indSeed(1));  %%% this should be the initial seed!
%%% Transform it with respect to the entire image.
rSeed = rSeed1 + j - 1;
cSeed = cSeed1 + i - 1;

