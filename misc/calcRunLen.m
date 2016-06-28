%%% calcRunLen.m
%%% Returns the x-displacement of diagLine, which is a mask of a single line segment

function runLen = calcRunLen(diagLine)
[r,c] = find(diagLine);
runLen = max(c) - min(c);
