%%% emLoop1Var.m
%%% Implement expectation-maximization as a mixture of Gaussians model.
%%%
%%% Input variables:
%%% Lobs is a vector of the observed organization parameter.
%%% Thresh is the covergence threshold.
%%%
%%% Output variables:
%%% Ls = all possible values of the hidden organization parameter
%%% piL = P(Lhidden) 
%%%     = distribution over the true, hidden organization parameter.
%%%     Vector of length(Ls)
%%% muL = mean of each Gaussian distribution
%%%     Vector of length(Ls)
%%% sigmaL = std dev of each Gaussian distribution
%%%     Vector of length(Ls)
%%% Lhidden = true hidden organization parameter values
%%%     Vector of length(Lobs)
%%%
%%% Assume that P(Lobs|Lhidden = Ls(j)) ~ N(muL(j),sigmaL(j))

function [piL,muL,sigmaL,Ls,Lhidden] = emLoop1Var(Lobs,thresh)

N = length(Lobs);

%%% Divide the parameter space into C classes
C = 50;
Ls = (linspace(min(Lobs)*0.5,max(Lobs)*1.1,C))';
errsL = Lobs;

%%% Initialize distribution parameters
%%% piL = P(Lhidden) is initialized as the frequency of Lobs
%%% muL = mean of each Gaussian distribution
%%% sigmaL = std dev of each Gaussian distribution
[counts,bins] = histc(Lobs,Ls);
initPiL = counts/length(Lobs)+0.001;
piL = initPiL/sum(initPiL);
initMuL = zeros(C,1);
for i = 1:C
    initMuL(i) = mean(errsL(bins==i));
end
muL = initMuL;
muL(isnan(muL) ) = mean(errsL);
initSigmaL = zeros(C,1);
for i = 1:C
    initSigmaL(i) = std(errsL(bins==i));
end
sigmaL = initSigmaL;
sigmaL(isnan(sigmaL) | sigmaL==0) = std(errsL);
Lhidden = Lobs;

count = 0;
notConverged = true;
if ~exist('thresh','var')
    thresh = 0.001;
end
sumCondProbL = ones(size(sigmaL));

while notConverged
    count = count + 1;
    
    %%% Remove bins of Ls that are no longer viable random variables
    LsToRemove = find(sigmaL==0 | sumCondProbL==0);
    Ls(LsToRemove) = [];
    piL(LsToRemove) = [];
    piL = piL / sum(piL);
    muL(LsToRemove) = [];
    sigmaL(LsToRemove) = [];
    C = length(Ls);
    
    oldPiL = piL;
    
    %%% Calculate conditional probability P(Lhidden|Lobs) using Bayes' rule
    gMatrixL = zeros(C,N);
    normMatrixL = zeros(C,N);
    for j = 1:C
        if sigmaL(j) ~= 0  %%% if sigmaL(j) == 0, we no longer have a random variable
            for i = 1:N
                gMatrixL(j,i) = normpdf(errsL(i),muL(j),sigmaL(j));
                normMatrixL(j,i) = gMatrixL(j,i)*piL(j);
            end
        end
    end
    
    pZgivenX_L = normMatrixL ./ repmat(sum(normMatrixL,1),C,1);  % size is C,N
    
    %%% Update piL, muL, sigmaL
    sumCondProbL = sum(pZgivenX_L,2);
    piL = 1/N * sumCondProbL;
    muL = sum(pZgivenX_L.*repmat(errsL',C,1),2) ./ sumCondProbL;
    sigmaL = sqrt(sum(pZgivenX_L.*(repmat(errsL',C,1)-repmat(muL,1,N)).^2,2) ./ sumCondProbL);
    
    %%% Update our best guess for the hidden parameter values
    Lhidden = (sum(pZgivenX_L .* repmat(Ls,1,N)))';
    
    %%% Calculate the difference in the distributions
    cm1L = norm(oldPiL-piL,2);
    currConvMetric = cm1L;
    
    %%% Stop looping, either we have converged or we have gone beyond the acceptable number of iterations
    if currConvMetric < thresh || count > 100
        notConverged = false;
    end
end

