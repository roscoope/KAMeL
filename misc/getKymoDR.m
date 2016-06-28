%%% getKymoDR.m
%%% This function outputs an image with an enhanced dynamic range.
%%%
%%% Input Arguments
%%% kymoFile = can be a filename or an image matrix
%%% pThresh = this is a percentile (i.e., in the range [0,100]).  The function
%%%      identifies the pThresh percentile intensity value, and then clamps all 
%%%      pixels above that value, and then linearly rescales the image so that
%%%      the pixels are in the range [0,1].
%%%
%%% Output Arguments
%%% kymoDR = image (of type double) with enhanced dynamic range

function kymoDR = getKymoDR(kymoFile,pThresh)

if ischar(kymoFile)
    if strcmp(kymoFile(end-3:end),'.csv')
        kB_photoCorr = csvread(kymoFile);
    else
        kB_photoCorr = imread(kymoFile);
    end
else
    kB_photoCorr = kymoFile;
end

if ~exist('pThresh','var') || isempty(pThresh)
    pThresh = 75;
end

kymoDR = kB_photoCorr;
p90 = prctile(kB_photoCorr(:),pThresh);
kymoDR(kymoDR > p90) = p90;
kymoDR1 = linRescale(kymoDR);
kymoDR = kymoDR1;
