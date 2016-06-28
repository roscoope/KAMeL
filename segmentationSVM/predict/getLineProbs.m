%%% getLineProbs.m
%%% This is the top-level segmentation function.  It finds the seed point,
%%% calls the SVM, and does some preliminary morphological image processing
%%% to remove very small components that could not possibly be lines.
%%%
%%% Input Arguments
%%% im = full image
%%% radonResults = array of <theta,rho> peaks, sorted by proximity to the dominant velocity.  Columns are theta, 
%%%      rho, y-location of seed point,and x-location of seed point for each traced line.  Duplicate 
%%%      <theta,rho> pairs have been removed.
%%% blockSize = size of blocks used when performing the Radon transform
%%% model = pre-trained SVM model (not the file name pointing to the model).  Matlab thinks this input 
%%%      argument is unused because it is called using evalc to supress output
%%% wThresh = Minimum distance (in pixels) a vesicle must travel in order to be considered a line
%%% dThresh (optional, largely unused) = Pixels with a decision value about dThresh are considered "foreground." 
%%%      By default, the SVM classifies pixels with a decision value above 0 as "foreground"
%%% vThresh = Potential line segments are ignored if more than vThresh of their pixels are 
%%%      part of the vertical mask
%%% fvThresh = Connect segments predicted simultaneous on the same <theta,rho> line if they are 
%%%      are fewer than 10 pixels apart and more than vThresh pixels fall on the vertical mask
%%% verbose = 1 to get a regular status updates
%%%
%%% Output Arguments
%%% vertMask = vertical mask of kymograph
%%% diagLineProbs = cell array (size is N x 1) where each element is a sparse matrix of a binary 
%%%      mask of all pixels identified as potential line segments along this <theta,rho> line 
%%% rrOut = array of size N x 4.  Columns are theta, rho, y-location of seed point,
%%%      and x-location of seed point for each traced line
%%% decValsOut = cell array (size is N x 1) where each element is a sparse matrix of the decision 
%%%      values of all pixels along this <theta,rho> line 

function [vertMask, diagLineProbs, rrOut,decValsOut] = getLineProbs(im,radonResults,blockSize,model,wThresh,dThresh,vThresh,fvThresh,verbose)

%%% Turn off warnings for now
warning('off','MATLAB:griddedInterpolant:MeshgridEval2DWarnId');

if ~exist('wThresh','var') || isempty(wThresh)
    wThresh = 10;
end
if ~exist('vThresh','var') || isempty(vThresh)
    vThresh = 0.5;
end
if ~exist('fvThresh','var') || isempty(fvThresh)
    fvThresh = 0.5;
end

%%% Generate vertical mask of kymograph
vertMask = getStationaryEvents(im);

%%% Precompute rotated features for all thetas that need to be tested
thetasToTry = unique(radonResults(:,1));
rotatedFeatureImages = cell(size(thetasToTry));
for i = 1:length(thetasToTry)
    features = getFeaturesRotated(im,thetasToTry(i));
    rotatedFeatureImages(i) = {sparse(features)};
end

%%% For each <theta,rho> pair, segment the pixels on that line
lineCount = 0;
diagLineProbs = cell(size(radonResults,1),1);
decValsOut = cell(size(radonResults,1),1);
rrOut = zeros(size(radonResults,1),6);
for peakCount = 1:length(diagLineProbs)
    
    %%% Get the seed point for later use
    currTheta = (radonResults(peakCount,1));
    currRho = (radonResults(peakCount,2));
    [rSeed,cSeed,imDiag,newLine,lineImgF] = getSeed(im,currTheta,currRho,radonResults(peakCount,3),radonResults(peakCount,4),blockSize);
    
    %%% If there are no visible pixels on the <theta,rho> line, there's no need to continue
    if nnz(imDiag) > 0 && nnz(~isfinite(imDiag)) == 0
        
        %%% Call the SVM wrapper using evalc to supress all the output from liblinear
        [~,probs1,decVals] = evalc('predictLines(model,im,rotatedFeatureImages{thetasToTry==currTheta},newLine,lineImgF)');
        
        %%% Enable additional thresholding on the decision values if desired
        if exist('dThresh','var') && ~isempty(dThresh)
            probs1 = decVals > dThresh & decVals ~=0;
        end
        
        %%% If any foreground pixels were identified, continue with morphological processing
        if nnz(probs1) > 0
            
            %%% Dilate to connect nearby foreground pixels
            L = bwlabel(imdilate(probs1,ones(5)));
            
            %%% Remove any line segments that are shorter than wThresh
            indsToRemove = find(arrayfun(@(x) calcRunLen(L==x),(1:max(L(:)))')<wThresh);
            L(ismember(L,indsToRemove)) = 0;
            
            %%% Remove any line segments that overlap too much with the
            %%% vertical mask, as they are probably just mislabeled
            %%% stationary vesicles
            indsToRemove = find(arrayfun(@(x) nnz(L==x & vertMask)/nnz(L==x),(1:max(L(:)))')>vThresh);
            L(ismember(L,indsToRemove)) = 0;
            
            %%% Thin result to return to the original thickness of the mask
            probs = double(bwmorph(L,'thin',3));
            
            %%% If there are still foreground pixels, continue...
            if nnz(probs) > 0
                L = bwlabel(probs);
                
                %%% Consider each connected component individually 
                for j = 1:max(L(:))
                    im1 = L==j;
                    [~,c1] = find(im1);
                    
                    %%% If the connected component is within 10 pixels of
                    %%% another component, and they are separated mainly by
                    %%% vertical mask, then they are the same vesicle
                    %%% traveling across stationary vesicles. 
                    for k = j+1:max(L(:))
                        im2 = L==k;
                        [~,c2] = find(im2);
                        linePair = false(size(probs1));
                        [currRho,currTheta] = getRhoThetaFromMask(probs1);
                        lineImg= makeLineRadon(linePair,currTheta,currRho);
                        if max(c1) < min(c2)
                            linePair(:,max(c1):min(c2)) = lineImg(:,max(c1):min(c2));
                        else
                            linePair(:,max(c2):min(c1)) = lineImg(:,max(c2):min(c1));
                        end
                        if nnz(linePair) > 1
                            [~,c] = find(linePair);
                            fracVert = nnz(vertMask & linePair)/nnz(linePair);
                            
                            %%% Connect them with a single-pixel-wide line
                            if fracVert > fvThresh && max(c)-min(c) < 10;
                                probs = probs | linePair;
                            end
                        end
                    end
                end
                lineCount = lineCount + 1;
                
                %%% Save the mask, the decision values, and the corresponding <theta,rho> information for later use
                diagLineProbs(lineCount) = {sparse(double(probs))};
                decValsOut(lineCount) = {sparse(decVals)};
                rrOut(lineCount,:) = [radonResults(peakCount,:),rSeed,cSeed];
            end
        end
    end
    if verbose && mod(peakCount,100) == 0
        display([num2str(peakCount),' out of ',num2str(length(diagLineProbs)),' peaks']);
    end    
end
diagLineProbs = diagLineProbs(1:lineCount);
decValsOut = decValsOut(1:lineCount);
rrOut = rrOut(1:lineCount,:);

%%% Turn warnings on again
warning('on','MATLAB:griddedInterpolant:MeshgridEval2DWarnId');


