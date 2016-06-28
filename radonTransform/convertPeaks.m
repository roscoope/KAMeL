%%% convertPeaks.m
%%% Geometrically transforms the <theta,rho> pairs, located at deltaY and 
%%% deltaX, so the results are the <theta,rho> pairs for a full image

function [thetaOut,rhoOut] = convertPeaks(theta,rho,deltaY,deltaX)

thetaOut = theta;
rhoOut = zeros(size(rho));

for i = 1:length(theta)
    currTheta = theta(i);
    currRho = rho(i);
    newRho = currRho + deltaY*sind(currTheta)-deltaX*cosd(currTheta);
    rhoOut(i) = newRho;
end
    
    