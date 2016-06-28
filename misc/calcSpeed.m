%%% calcSpeed.m
%%% Returns the speed (x-displacement divided by y-displacement) of 
%%% diagLine, which is a mask of a single line segment

function speed = calcSpeed(diagLine)
[r,c] = find(diagLine);
speed = (max(c) - min(c))/(max(r)-min(r));
