%%% mapFilesToTopDir.m
%%% Map files in cell array of strings fileNames to the subdirectories in
%%% bigDirname.
%%%
%%% Input arguments
%%% bigDirname = string of a directory name
%%% fileNames = cell array of strings of filenames to be mapped
%%%
%%% Output arguments
%%% dirNums = array of numerical mappings.  Vector of length(fileNames).
%%% nameFolds = list of subdirectories in bigDirname
%%% if dirNums(i) = j, then fileNames(i) is in the subdirectory nameFolds(j)

function [dirNums,nameFolds] = mapFilesToTopDir(bigDirname,fileNames)

d = dir(bigDirname);
isub = [d(:).isdir]; %# returns logical vector
nameFolds = {d(isub).name}';
nameFolds(ismember(nameFolds,[{'..'},{'.'}])) = [];
nameFolds = strcat(nameFolds,'\');

dn1 = cellfun(@(x) strfind(fileNames,char(x)),nameFolds,'UniformOutput',false);

dn2 = cellfun(@(x) cellfun(@(x) ~isempty(x),x),dn1,'UniformOutput',false);

dn3 = cellfun(@(x,y) x*y,dn2,num2cell((1:length(nameFolds))'),'UniformOutput',false);

dirNums = sum(cell2mat(dn3'),2);