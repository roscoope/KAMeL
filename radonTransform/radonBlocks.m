%%% radonBlocks.m
%%% Top-level radon transform function.  Calculates the radon transform of the image block by block
%%% 
%%% Input Arguments
%%% kymoDR = image to be analyzed (type double, in range [0,1])
%%% blockSize = size of each block to analyze at a time (default 50)
%%% stepSize = stride between blocks (default 25; we want full overlap)
%%% verbose = 1 to get a regular status updates
%%%
%%% Output Arguments
%%% rrSorted = array of <theta,rho> peaks, sorted by proximity to the dominant velocity.  Columns are theta, 
%%%      rho, y-location of seed point,and x-location of seed point for each traced line.  Duplicate 
%%%      <theta,rho> pairs have been removed.
%%% radonResults = array of <theta,rho> peaks.  Columns are theta, rho, y-location of seed point,
%%%      and x-location of seed point for each traced line.  These are listed as identified from each block.
%%% Rfull = Radon transform of kymoDR

function [rrSorted,radonResults,Rfull] = radonBlocks(kymoDR,blockSize,stepSize,verbose)

[h,w] = size(kymoDR);

%%% Calculate Radon transform of kymoDR as the solution to an inverse problem.
%%% To use MATLAB's lsqr solver, we need to unfortunately declare the height
%%% and width of the kymograph as global variables, which we first clear.
kymo = kymoDR;
clear kymoH;
clear kymoW;
global kymoW;
global kymoH;

%%% The code requires the kymograph have an even number of rows and columns,
%%% so we pad as necessary
if mod(size(kymo,1),2) ~= 0
    kymo = [kymo; mean(kymo(:))*ones(1,size(kymo,2))];
end
kymoH = size(kymo,1);
if mod(size(kymo,2),2) ~= 0
    kymo = [kymo mean(kymo(:))*ones(kymoH,1)];
end
kymoW = size(kymo,2);
%%% Actually calculate the transform.  Run this using "evalc" to eliminate the output from MATLAB
[~,~,rho,~,~,Rfull] = evalc('probRadonSetup(kymo,[],[],15*(1/round(h/w)));');
%%% Sum the Radon transform over all possible values of rho to find the dominant speed.  Also
%%% combine the +theta and -theta values because the speed in both directions has a similar peak
R2full = sum(Rfull(:,91:end)+Rfull(:,90:-1:1));
R3full = [R2full(end:-1:1), R2full]';

radonResults = [];
R2 = zeros(90,1);
jArray = 1:stepSize:h;
if jArray(end)-jArray(end-1) < blockSize
    jArray = sort([jArray h-blockSize+1]);
    jArray(jArray < 1) = [];
end

%%% Loop over all blocks and calculate the Radon transform for each one
i = 0;
for jCount = 1:length(jArray)
    j = jArray(jCount);
    if verbose
        display(horzcat('j = ',num2str(j),' and i = ',num2str(i)));
    end
    for i = 1:stepSize:w
	
		%%% Radon transform setup
        kymo = kymoDR(j:min(j+blockSize-1,h),i:min(i+blockSize-1,w));
        clear kymoH;
        clear kymoW;
        global kymoW;
        global kymoH;
        if mod(size(kymo,1),2) ~= 0
            kymo = [kymo; mean(kymo(:))*ones(1,size(kymo,2))];
        end
        kymoH = size(kymo,1);
        if mod(size(kymo,2),2) ~= 0
            kymo = [kymo mean(kymo(:))*ones(kymoH,1)];
        end
        kymoW = size(kymo,2);
        if kymoH > 2 && kymoW > 2
			%%% Radon transform that also identifies the indices of the <theta,rho> values associated 
			%%% with the peaks in the transform domain
            [~,theta,rho,thetaPeaks,rPeaks,R] = evalc('probRadonSetup(kymo,20,R3full);');
            
            allTheta = theta(thetaPeaks);
            allRho = rho(rPeaks);
            
			%%% Geometrically transform the peaks so theta and rho refer to the entire image
            deltaY = h/2 - (j + kymoH/2);
            deltaX = w/2 - (i + kymoW/2);
            [thetaOut,rhoOut] = convertPeaks(allTheta,allRho,deltaY,deltaX);
            
            radonResults = [radonResults; thetaOut, rhoOut, j*ones(size(thetaOut)), i*ones(size(thetaOut))];
            
            R2 = R2 + sum(R(:,91:end)+R(:,90:-1:1),1)';
        end
    end
end

%%% Remove duplicate <theta,rho> pairs and prioritize based on the dominant velocity
R2masked = R2;
R2masked(theta < 20 | theta > 159 | (theta > 90-5*(1/round(h/w)) & theta < 90+5*(1/round(h/w)))) = 0;
R3 = [R2masked(end:-1:1);R2masked];
alpha = 0.001;
rrOut = removeDupThetaRho(radonResults,R3);
allTheta = rrOut(:,1);
allRho = rrOut(:,2);
shiftedRho = round(allRho)-min(rho);
if min(shiftedRho) < 1
    shiftedRho(shiftedRho<1) = 1;
end
priorities = alpha * R3(allTheta) + (1-alpha)* Rfull(sub2ind(size(Rfull),shiftedRho,allTheta));
[~,inds] = sort(priorities,'descend');
rrSorted = rrOut(inds,:);
