%%% getInfNestedFileNames.m
%%% Recursively search for all files within a directory
%%% Example usage:  fileNames = getInfNestedFileNames({'../images/'},'*.tif',[],'bad');
%%%
%%% Input arguments
%%% bigDirnames = cell array of strings, where each string is another directory to analyze
%%% gExt = string to search for within the directories
%%% searchForFiles (optional) = flag to search for files (true) or directories (false)
%%% strToIgnore (optional) = string to ignore when compiling the output
%%%
%%% Output argument
%%% fileNames = cell array of strings, where each string is another file.
%%%      Each string in fileNames begins with a string found in bigDirnames

function fileNames = getInfNestedFileNames(bigDirnames,gExt,searchForFiles,strToIgnore)

if ~exist('searchForFiles','var') || isempty(searchForFiles)
    searchForFiles = true;
else
    if ~searchForFiles
        if gExt(end) ~= '\'
            gExt = [gExt,'\'];
        end
    end
end

if ~exist('strToIgnore','var') || isempty(strToIgnore)
    strToIgnore = [];
end

fileNames = [];

%%% Loop over all directories in bigDirnames
for dirCount = 1:length(bigDirnames)
    currBigDir = char(bigDirnames{dirCount});
    fnNew = [];
    d = dir(strcat(currBigDir,gExt));

    %%% Add the files in the current directory
    for i = 1:length(d)
        if (((~d(i).isdir) && searchForFiles) || (d(i).isdir && ~searchForFiles)) && isempty(strfind(d(i).name,strToIgnore))
            [pathstr,~,~] = fileparts(d(i).name);
            if ~isempty(pathstr) && pathstr(end) ~= '\'
                pathstr = [pathstr, '\'];
            end
            fnNew = [fnNew;{strcat(currBigDir,pathstr,d(i).name)}];
        end
    end
    fileNames = [fileNames;fnNew];
    
    %%% Recursively search each subdirectory within the current directory
    dirnames = getDirnames(currBigDir);
    for j = 1:length(dirnames)
        currBigDir = dirnames(j);
        fnNew = getInfNestedFileNames(currBigDir,gExt,searchForFiles,strToIgnore);
        fileNames = [fileNames;fnNew];
    end
    
end