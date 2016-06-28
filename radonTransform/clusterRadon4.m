%%% clusterRadon4.m
%%% Take a Radon transform and return the indices corresponding to the
%%% arrays theta and rho of the peaks in the Radon transform.  Sort the
%%% <theta,rho> pairs by the sum of the Radon transform over all possible
%%% rho (R2full).  Return the number of peaks specified by numPeaks, and
%%% ignore all values of theta that are within tThresh of horizontal lines

function [rp50,tp50] = clusterRadon4(Rin,numPeaks,h,w,theta,rho,R2full,tThresh)

if ~exist('tThresh','var') || isempty(tThresh)
    tThresh = 15;
end

alpha = 0.0001;
R = (1-alpha) * Rin + alpha * repmat((R2full(:))',length(rho),1);
bw = imregionalmax(R);
Rout = R;
Rout(~bw) = 0;
[~,inds] = sort(Rout(:),'descend');
[rPeaks,tPeaks] = ind2sub(size(Rout),inds);

theta=theta(:);
rho=rho(:);
toRemove = find(theta(tPeaks) < 20 | ...
    theta(tPeaks) > 159 | ...
    (theta(tPeaks) > 90-tThresh & theta(tPeaks) < 90+tThresh) | ...
    (theta(tPeaks) > 90-10*(1/round(h/w)) & theta(tPeaks) < 90+10*(1/round(h/w)) & abs(rho(rPeaks)) < (h/2+h/10) & abs(rho(rPeaks)) > (h/2-h/10)));

rPeaks(toRemove) = [];
tPeaks(toRemove) = [];

rp50 = rPeaks(1:min(numPeaks,length(rPeaks)));
tp50 = tPeaks(1:min(numPeaks,length(rPeaks)));
