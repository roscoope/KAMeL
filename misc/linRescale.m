%%% linRescale.m
%%% This function takes an input image, vIn, and regardless of its type,
%%% converts it to a double and linearly rescales its itensities to be 
%%% in the range [0,1]

function vOut = linRescale(vIn)

v = double(vIn);

minV = min(v(:));
maxV = max(v(:));

if maxV==minV
    vOut = vIn;
    vOut(vOut > 1) = 1;
    vOut(vOut < 0) = 0;
else
    vOut = (v-minV)/(maxV-minV);
end