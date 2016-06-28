%%% updateDictForRetrain.m
%%% Augment the training dictionary for retraining the SVM
%%%
%%% Input Arguments
%%% dictionaryFile = file containing the original training dictionary
%%% modelFile = file pointing to the existing model
%%% toRetrainManual = 0 to identify misclassified lines automatically, 1 to
%%%      identify them with user input
%%% verbose = 1 for regular status updates
%%% wThresh = Minimum distance (in pixels) a vesicle must travel in order to be considered a line
%%% vThresh = Potential line segments are ignored if more than vThresh of their pixels are 
%%%      part of the vertical mask
%%% fvThresh = Connect segments predicted simultaneous on the same <theta,rho> line if they are 
%%%      are fewer than 10 pixels apart and more than vThresh pixels fall on the vertical mask
%%% fThresh = Maximum fraction of overlap a new line segment can have with the existing line traces; 
%%%      any line segments with an overlap above fThresh are ignored
%%% dThresh = Minimum average value of the decision values of pixels in a line segment; any line 
%%%      segments with an average decision value below dThresh are ignored
%%% rtThresh = Maximum separation of two <theta,rho> pairs for the line segments to be merged
%%% hStep = Vertical size of blocks to run KAMeL on; to run on entire image at once (can be slow), 
%%%      set hStep to be larger than the height of the largest image in the dataset
%%% wStep = Horizontal size of blocks to run KAMeL on; to run on entire image at once (can be slow), 
%%%      set wStep to be larger than the width of the largest image in the dataset
%%%
%%% Output Argument
%%% dFileOut = filename of new dictionary

function dFileOut = updateDictForRetrain(dictionaryFile,modelFile,toRetrainManual,verbose,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep)

dFileOut = [dictionaryFile(1:end-4),'_2.mat'];

load(dictionaryFile);
N = length(training_dictionary);

for i = 1:N
    kymoFile = training_dictionary(i).file;
    if exist(kymoFile,'file') %%% Avoid issues with deleted image files
        display(['Image ',num2str(i),' out of ',num2str(N),': ',kymoFile]);
        pThresh = training_dictionary(i).pThresh;
        
        %%% Effectively run KAMeL for this single image
        diagLinesOutC = traceLinesWrapper(kymoFile,modelFile,verbose,pThresh,wThresh,vThresh,fvThresh,fThresh,dThresh,rtThresh,hStep,wStep);
        
        %%% Do some prep if the augmentation is going to be automatic
        if ~toRetrainManual
            allTDLines = training_dictionary(i).lines;
            tdLines = sum(cell2mat(reshape(cellfun(@full,allTDLines,'uniformoutput',false),1,1,length(allTDLines))),3);
            tdLinesD = imdilate(full(tdLines),ones(3));
        end
        
        %%% Iterate over every block into which the image was divided
        kymoDR = getKymoDR(kymoFile,pThresh);
        [h,w] = size(kymoDR);
        fullImg = zeros(h,w);
        hArray = 1:hStep:h;
        wArray = 1:wStep:w;
        for j = 1:size(diagLinesOutC,1)
            for k = 1:size(diagLinesOutC,2)
                currH = hArray(j);
                currW = wArray(k);
                currKymoDR = kymoDR(currH:min(currH+hStep-1,h),currW:min(currW+wStep-1,w));
                diagLinesOut = diagLinesOutC{j,k};
                if ~isempty(diagLinesOut)
                    
                    %%% If any lines were identified, continue...
                    allLines = max(cell2mat(reshape(cellfun(@full,diagLinesOut,'uniformoutput',false),1,1,size(diagLinesOut,1))),[],3);
                    
                    if toRetrainManual %%% Allow user to select bad lines
                        [goodLines,badLines] = getLineLabels(currKymoDR,allLines);
                    else
                        %%% Iterate over all identified lines.  If they
                        %%% overlap sufficiently with lines in the training
                        %%% dictionary, then assume they were correctly
                        %%% identified
                        currTdLines = tdLinesD(currH:min(currH+hStep-1,h),currW:min(currW+wStep-1,w));
                        goodLines =[];
                        badLines = [];
                        for count = 1:size(diagLinesOut,1)
                            currLine = diagLinesOut{count};
                            if nnz(currLine & currTdLines) / nnz(currLine) > 0.25
                                goodLines = [goodLines;count];
                            else
                                badLines = [badLines;count];
                            end
                        end
                    end
                    
                    %%% Since each of the "good" and "bad" lines were
                    %%% identified on blocks of the image, extend each of
                    %%% the masks to fill the entire image
                    goodLineArray = cell(length(goodLines),1);
                    for lineCount = 1:length(goodLines)
                        fullImg2 = fullImg;
                        fullImg2(currH:min(currH+hStep-1,h),currW:min(currW+wStep-1,w)) = diagLinesOut{goodLines(lineCount)};
                        goodLineArray(lineCount) = {sparse(fullImg2)};
                    end
                    badLineArray = cell(length(badLines),1);
                    for lineCount = 1:length(badLines)
                        fullImg2 = fullImg;
                        fullImg2(currH:min(currH+hStep-1,h),currW:min(currW+wStep-1,w)) = diagLinesOut{badLines(lineCount)};
                        badLineArray(lineCount) = {sparse(fullImg2)};
                    end
                    
                    %%% Augment the training dictionary
                    if isfield(training_dictionary,'lines2')
                        training_dictionary(i).lines2 = [training_dictionary(i).lines2;goodLineArray];
                        training_dictionary(i).nonLines = [training_dictionary(i).nonLines;badLineArray];
                    else
                        training_dictionary(i).lines2 = goodLineArray;
                        training_dictionary(i).nonLines = badLineArray;
                    end
                    
                    %%% Save regularly
                    save(dFileOut,'training_dictionary');
                end
            end
        end
    end
end

