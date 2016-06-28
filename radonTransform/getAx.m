%%% getAx.m
%%% Calculate the inverse Radon transform and the forward Radon
%%% transform+per-projection filter.  This function is based largely on the
%%% following paper:
%%% Aggarwal, Nitin, and W. Clem Karl. "Line detection in images through regularized 
%%%      Hough transform." IEEE transactions on image processing 15.3 (2006): 582-591.

function Ax = getAx(xIn,isTransp)

global kymoW;
global kymoH;
xSize = max(kymoH,kymoW);

%%% Calculate Ax where A is the inverse Radon transform
if strcmp(isTransp,'notransp')
    %%% Take the vector and make it a 2D image
    xSq = reshape(xIn,length(xIn)/180,180);
    AxSqFull = iradon(xSq,0:179,'linear','Ram-Lak',1,xSize);
    if kymoH > kymoW
        wDiff = xSize - kymoW ;
        w = warning('off','all');
        AxSq = AxSqFull(:,(wDiff/2+1):(xSize-wDiff/2));
    else
        hDiff = xSize - kymoH ;
        w = warning('off','all');
        AxSq = AxSqFull((hDiff/2+1):(xSize-hDiff/2),:);
    end
    warning(w);
else % we need A'x
    %%% x is the radon transform of the data y.  Each column represents a different theta 
    %%% and each row represents a different rho.  First, we need to apply the radon 
    %%% transform to x then, we apply the per-projection filter |w| to each column of the result

    %%% Take the vector and make it a 2D image
    xSq = reshape(xIn,kymoH,kymoW);
    xR = radon(xSq,0:179);
    [xN,xM] = size(xR);
    xRc = mat2cell(xR,xN,ones(1,xM));
    
    %%% Per-projection filter
    w = ([0:floor(xN/2),-1*floor(xN/2):-1])';
    aW = abs(w);
    Atx = cellfun(@(x) ifft(aW .* fft(x),xN),xRc,'UniformOutput',false);
    AxSq = cell2mat(Atx);
end

%%% Reshape into a vector
Ax = AxSq(:);