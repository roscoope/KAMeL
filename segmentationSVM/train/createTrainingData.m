%%% createTrainingData.m
%%% Convert the images and lines from a dictionary into a training data
%%% matrix
%%%
%%% Input Arguments
%%% dictionaryFile = file of training dictionary
%%% tdID = prefix of training data output file (or the prefix of the
%%%      dictionary file)
%%% wThresh = any line with width less than wThresh should be considered
%%%      "bad".  this value was 3 for Shunling, and 1/0.109 for David and Shaul
%%% verbose = 1 for frequent status updates
%%%
%%% Output Arguments
%%% td = training data array
%%% tdFile = training data file

function [td,tdFile] = createTrainingData(dictionaryFile,tdID,wThresh,verbose)

%%% Look for the dictionary file and make sure one exists
if ~exist('dictionaryFile','var') || isempty(dictionaryFile)
    dicts = dir([tdID,'dictionary*.mat']);
    dictDates = [dicts.datenum];
    [~,latest] = max(dictDates);
    dictionaryFile = dicts(latest).name;
end
if ~exist(dictionaryFile,'file')
    error('Error!  dictionaryFile does not exist');
else
    load(dictionaryFile);
end

%%% Figure out what to call the output training data
if ~exist('tdID','var')
    tdID = strtok(dictionaryFile,'_');
    if strcmp(tdID,'dictionary')
        tdID = '';
    else
        tdID = [tdID,'_'];
    end
end
tdFile = [tdID,'trainingData_',datestr(now,'yyyy_mm_dd'),'.mat'];

trainingData = [];
trainingLabels = [];

%%% Loop through every image in the training dictionary
for i = 1:length(training_dictionary)
    file=training_dictionary(i).file;
    display(['file ',num2str(i),' out of ',num2str(length(training_dictionary)),': ',file]);
    if exist(file,'file')
        pThresh = training_dictionary(i).pThresh;
        kymoDR = getKymoDR(file,pThresh);
        
        %%% Aggregate traced lines/nonlines if the dictionary has already
        %%% been augmented for retraining
        currLines = training_dictionary(i).lines;
        if isfield(training_dictionary,'lines2')
            currLines2 = training_dictionary(i).lines2;
        else
            currLines2 = [];
        end
        if isfield(training_dictionary,'nonLines')
            currNonLines = training_dictionary(i).nonLines;
        else
            currNonLines = [];
        end
        
        %%% Calculate rho/theta values for each of the lines
        rr = zeros(length(currLines),2);
        for j = 1:length(currLines)
            currMask = full(currLines{j});
            [currRho,currTheta] = getRhoThetaFromMask(currMask);
            rr(j,:) = [round(currTheta),currRho];
        end
        toRemove = isnan(rr(:,1)) | isnan(rr(:,2)) | ~isfinite(rr(:,1)) | ~isfinite(rr(:,2));
        rr(toRemove,:) = [];
        currLines(toRemove) = [];
        
        rr2 = zeros(length(currLines2),2);
        for j = 1:length(currLines2)
            currMask = full(currLines2{j});
            [currRho,currTheta] = getRhoThetaFromMask(currMask);
            rr2(j,:) = [round(currTheta),currRho];
        end
        toRemove = isnan(rr2(:,1)) | isnan(rr2(:,2)) | ~isfinite(rr2(:,1)) | ~isfinite(rr2(:,2));
        rr2(toRemove,:) = [];
        currLines2(toRemove) = [];
        
        rrN = zeros(length(currNonLines),2);
        for j = 1:length(currNonLines)
            currMask = full(currNonLines{j});
            [currRho,currTheta] = getRhoThetaFromMask(currMask);
            rrN(j,:) = [round(currTheta),currRho];
        end
        toRemove = isnan(rrN(:,1)) | isnan(rrN(:,2)) | ~isfinite(rrN(:,1)) | ~isfinite(rrN(:,2));
        rrN(toRemove,:) = [];
        currNonLines(toRemove) = [];
        
        allRr = [rr;rr2;rrN];
        
        %%% Precompute rotated feature images for the necessary theta values
        thetasToTry = unique(allRr(:,1));
        rotatedFeatureImages = cell(size(thetasToTry));
        for j = 1:length(thetasToTry)
            features = getFeaturesRotated(kymoDR,thetasToTry(j));
            rotatedFeatureImages(j) = {sparse(features)};
        end
        
        alLines = [currLines;currLines2;currNonLines];
        numPos = length(currLines)+length(currLines2); %%% the first numPos training examples are positive examples, the rest are negative examples
        
        %%% Loop over all the lines and assemble the training data into a giant matrix
        for j = 1:length(alLines)
            if verbose && mod(j,10) == 0
                display(['line ',num2str(j),' out of ',num2str(length(alLines))]);
            end
            
            %%% Sometimes the training data gets really unwieldy; rehash clears up some space
            if mod(j,100) == 0
                rehash;
            end
            
            currMask = full(alLines{j});
            currMaskD = imdilate(currMask,ones(3));
            currTheta = allRr(j,1);
            currRho = allRr(j,2);
            
            %%% Soft-mask the feature images for the rho,theta line of the current training line
            %%% Don't just use currMask because we want the negative training examples that aren't on the line as well
            newLine = makeLineRadon(kymoDR,currTheta,currRho);
            newLineD = imdilate(newLine,ones(7));
            gf = fspecial('gaussian',50,2);
            lineImgF = imfilter(newLine,gf,'symmetric');
            allFeatures = rotatedFeatureImages{thetasToTry==currTheta};
            featList = repmat(lineImgF(:),1,size(allFeatures,2)) .* full(allFeatures);
            
            [~,c] = find(currMask);
            xDisp = max(c)-min(c);
            if xDisp > wThresh && j <= numPos  %%% This is a positive training line
                fgPixels = find(currMask);
                trainingData = [trainingData;featList(fgPixels,:)];
                trainingLabels = [trainingLabels;ones(size(fgPixels))];
                
                bgPixelsAll = find(newLineD & ~currMaskD);
                bgInds = (randperm(length(bgPixelsAll),min(500,length(bgPixelsAll))))';
                bgPixels = bgPixelsAll(bgInds);
            elseif j>numPos %%% This is a negative training line
                bgPixelsAll = find(newLineD);
                bgInds = (randperm(length(bgPixelsAll),min(500,length(bgPixelsAll))))';
                bgPixels = [find(currMask);bgPixelsAll(bgInds)];
            else %%% This is a negative training line
                bgPixelsAll = find(newLineD);
                bgInds = (randperm(length(bgPixelsAll),min(500,length(bgPixelsAll))))';
                bgPixels = bgPixelsAll(bgInds);
            end
            trainingData = [trainingData;featList(bgPixels,:)];
            trainingLabels = [trainingLabels;zeros(size(bgPixels))];
        end
    end
end

%%% Find the maximum and minimum values for easy scaling of the features later 
fMin = min(trainingData,[],1);
fMax = max(trainingData,[],1);

td.fMin = fMin;
td.fMax = fMax;
td.trainingData = trainingData;
td.trainingLabels = trainingLabels;
td.pThresh = mean([training_dictionary.pThresh]);  %%% use this pThresh for new images during prediction

save(tdFile,'td');

