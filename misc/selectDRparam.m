%%% selectDRparam.m
%%% Asks the user to select the pThresh parameter for the image in kymoFile.
%%% This function loops until the user selects -999 as pThresh.  If the user
%%% selects an invalid pThresh (i.e., a number outside the range [0,100]), it 
%%% ignores the value and asks again.  This function uses Figure 1 in MATLAB.

function pThresh = selectDRparam(kymoFile,initPThresh)

try
    close(1)
catch
end

if exist('initPThresh','var')
    keepTrying = initPThresh;
else
    keepTrying = 75;
end
while keepTrying ~= -999
    if keepTrying >=0 && keepTrying <= 100
        pThresh = keepTrying;
    end
    kymoDR = getKymoDR(kymoFile,pThresh);
    figure(1);imshow(kymoDR);
    keepTrying = input(['Current pThresh = ',num2str(pThresh),'.  Enter a new pThresh or -999 to stop. ']);
end
