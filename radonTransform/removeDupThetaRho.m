%%% removeDupThetaRho.m
%%% Consolidate <theta,rho> pairs that are very similar, as they refer to the 
%%% same line in different blocks

function rrOut = removeDupThetaRho(rrIn,R3)

x = repmat(rrIn(:,1),1,size(rrIn,1));
y = repmat(rrIn(:,2),1,size(rrIn,1));

dists = ((x-x').^2 + (y-y').^2);
dists(logical(triu(ones(size(x))))) = inf;
[vals,inds] = min(dists,[],1);

thresh = 30;
inds(vals > thresh) = [];

tempRR = rrIn;
tempRR(inds,:) = [];

[~,inds] = sort(tempRR(:,2));
tempRR = tempRR(inds,:);
[~,inds] = sort(tempRR(:,1));
tempRR = tempRR(inds,:);
[~,inds] = sort(R3(tempRR(:,1)),'descend');
rrOut = tempRR(inds,:);
