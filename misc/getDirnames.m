%%% getDirnames.m
%%% Get subdirectory names from the top directory.  If dirMapping is used, 
%%% assume each directory corresponds to a separate groups of animals
function [dirnames,dirMapping] = getDirnames(bigDirname)

if ~exist('bigDirname','var') || isempty(bigDirname)
    error('Error:  invalid directory name');
end

if ischar(bigDirname)
    subDirs = dir(bigDirname);
    dirnames = [];
    for i = 3:length(subDirs)
        if subDirs(i).isdir
            dirnames = [dirnames;{strcat(bigDirname,subDirs(i).name,'\')}];
        end
    end
    dirMapping = [];
else
    dirnames = [];
    dirMapping = [];
    for j = 1:length(bigDirname)
        bigDirname1 = char(bigDirname{j});
        subDirs = dir(bigDirname1);
        for i = 3:length(subDirs)
            if subDirs(i).isdir
                dirnames = [dirnames;{strcat(bigDirname1,subDirs(i).name,'\')}];
                dirMapping = [dirMapping;j];
            end
        end
    end
end