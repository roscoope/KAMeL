%%% createDictionary.m
%%% User-interface function for annotating kymographs.  Uses Figure 1 of
%%% MATLAB.  For every line, the user clicks on each end point once, and
%%% then hits "enter."  After selecting all of the lines in the image, the
%%% user hits "enter" again.  The user should select ALL lines, since any
%%% that are not selected will be labeled as background during the
%%% augmentation of the dataset and retraining of the image.
%%% 
%%% Input Arguments
%%% dirList = list of directories to search for kymographs (cell array of strings)
%%% fileExt = extension of kymograph files for which to search (string)
%%% dictID = prefix of output dictionary file
%%% addToDictionary = 0 to create new dictionary, or 1 to add training examples to old 
%%%      dictionary, if a dictionary matching dictID already exists
%%%
%%% Output Argument
%%% dictionaryFile = new dictionary file

function dictionaryFile = createDictionary(dirList,fileExt,dictID,addToDictionary)

%%% Randomize the list of images in the data set
trainingKymoList1 = getInfNestedFileNames(dirList,fileExt);
inds = randperm(length(trainingKymoList1),length(trainingKymoList1));
trainingKymoList = trainingKymoList1(inds);

%%% If requested, try to find an existing dictionary that matches dictID
dicts = dir([dictID,'dictionary*.mat']);
if addToDictionary && ~isempty(dicts)
    dictDates = [dicts.datenum];
    [~,latest] = max(dictDates);
    dictionaryFileName = dicts(latest).name;
    [path,name,ext] = fileparts(dictID);
    dictionaryFile = [path,'\',dictionaryFileName];
    load(dictionaryFile);
    training_dictionary = training_dictionary(:);
    count = length(training_dictionary);
else
    training_dictionary = [];
    count = 0;
end

dictionaryFile = [dictID,'dictionary_',datestr(now,'yyyy_mm_dd'),'.mat'];
prevPThresh = 75;
toAddMoreImages = 0;
j = 1;
N = length(trainingKymoList);
while j <= length(trainingKymoList) && toAddMoreImages~=2
    file=trainingKymoList{j};
    if isempty(training_dictionary) || nnz(strcmp({training_dictionary.file},file)) == 0
        try
            close(1);
        catch
        end
        kymoDR = getKymoDR(file,prevPThresh);
        figure(1);imshow(kymoDR);
        display(' ');
        display(['The training dictionary has ',num2str(count),' files.']);
        display(['There are ',num2str(N-j),' files left in this dataset']);
        display(['The current file is ',file]);
        
        %%% Ask the user if they want to add this image or not, or if they
        %%% want to stop adding images altogether
        toAddMoreImages = input('Add this image to training dictionary? (0 = yes, 1 = no, 2 = stop adding files) ');
        if toAddMoreImages==0
            
            %%% If the user wants to add this image, first ask user to
            %%% select pThresh (dynamic range enhancement parameter)
            pThresh = selectDRparam(file,prevPThresh);
            prevPThresh = pThresh;
            kymoDR = getKymoDR(file,pThresh);
            
            %%% Ask user to select lines in kymograph
            lines = getLinesKymo(kymoDR);
            lines = cellfun(@(x) imresize(full(x),size(kymoDR)),lines,'uniformOutput',false);
            
            %%% Add these lines to the training dictionary and save it
            %%% immediately to avoid losing the meticulously inputted data
            count = count + 1;
            training_dictionary(count,1).lines=lines;
            training_dictionary(count,1).file=file;
            training_dictionary(count,1).pThresh = pThresh;
            save(dictionaryFile,'training_dictionary');
        end
    end
    j = j+1;
end


