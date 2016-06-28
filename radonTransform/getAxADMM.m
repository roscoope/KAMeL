%%% getAxADMM.m
%%% The system matrix for the ADMM solver.

function Ax = getAxADMM(xIn,isTransp)

rho = 1e2;

temp1 = getAx(xIn,'notransp');
temp2 = getAx(temp1,'transp');
temp3 = temp2 + rho*xIn;
Ax = temp3;

