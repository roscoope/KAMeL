%%% regularlizedHough.m
%%% Use ADMM with L1 regularization to solve the system y = Ax where A is the
%%% Radon transform matrix

function [x,cost,c1,c2] = regularlizedHough(y,rhoRes)

maxIter = 3;
weightRho = 1e2;

z = zeros(rhoRes*180,1);
u = zeros(rhoRes*180,1);

options = optimoptions('lsqlin','Display','off');
param.verbose = 0;
numIter = 1;

while numIter < maxIter
    v = z-u;
    % min ||C*x-d||_2 s.t. Ax <= b
    alpha3 = 1;
    alpha0 = 1;
    d = (getAx(y,'transp') + weightRho*v);
    x = lsqr(@getAxADMM,d);

	%%% Soft thresholding for L1 regularization
    alpha2 = 10;
    kappa = alpha2 / weightRho;
    v = x + u;
    z(v > kappa) = v(v > kappa) - kappa;
    z(v < -1*kappa) = v(v < -1*kappa) + kappa;
    z(abs(v) <= kappa) = 0;
    
    u = u + x - z;
    
    cost(numIter) = alpha0/2*(norm(y-getAx(x,'notransp'),2))^2 + alpha3*norm(x,1);
    c1(numIter) = 1/2*(norm(y-getAx(x,'notransp'),2))^2 ;
    c2(numIter) = norm(x,1);
    
    numIter = numIter + 1;
end


