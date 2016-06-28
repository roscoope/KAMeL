%%% roundToDec.m
%%% Rounds a number numIn to N digits after the decimal point.

function numOut = roundToDec(numIn,N)

numOut = round(numIn.*(10^N))./(10^N);