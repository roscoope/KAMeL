%%% probRadonSetup.m
%%% Calculate the Radon transform as the solution to an inverse problem
%%% 
%%% Input Arguments
%%% kymo = input image
%%% numPeaks = number of peaks to identify in the Radon transform
%%% R2full = sum of full image's Radon transform over all values of rho. Used in prioritizing the peaks.
%%% tThresh = values of theta that are within tThresh of horizontal lines are ignored
%%%
%%% Output Arguments
%%% theta = array of all possible theta (always 0:179)
%%% rho = array of all possible rho values
%%% thetaPeaks = array of the indices of theta corresponding to the peaks in the Radon transform
%%% rhoPeaks = array of the indices of rho corresponding to the peaks in the Radon transform.  This 
%%%      array is the same size as thetaPeaks.
%%% R = Radon transform of kymo

function [theta,rho,thetaPeaks,rPeaks,R] = probRadonSetup(kymo,numPeaks,R2full,tThresh)

addpath('miscMT\');
[h,w] = size(kymo);
im1 = linRescale(kymo);

%%% Solve for Radon transform as solution to inverse problem with L1 regularization
thetaInit = (0:179)';
[~,rhoInit] = radon(im1,thetaInit);
[Rv,~,~,~] = regularlizedHough(im1(:),length(rhoInit));
R = reshape(abs(Rv),length(Rv)/180,180);
blockSize = 1;
theta = thetaInit(1:blockSize:end);
rho = rhoInit(1:blockSize:end);

%%% Cluster the peaks to give as few duplicates as possible
if ~exist('numPeaks','var') ||  isempty(numPeaks)
    numPeaks = 30; % was 100 for full kymographs, this is for blocks of kymographs
end
if ~exist('R2full','var') || isempty(R2full)
    R2full = ones(size(theta));
end
if ~exist('tThresh','var')
    tThresh = [];
end
[rPeaks,thetaPeaks] = clusterRadon4(R,numPeaks,h,w,theta,rho,R2full,tThresh);