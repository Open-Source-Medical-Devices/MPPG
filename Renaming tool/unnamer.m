%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% unnamer.m
%
% This tool:
% 1. Renames all .dcm files using a sequence of numbers
%
% Dustin Jacqmin, PhD 2014
% https://github.com/Open-Source-Medical-Devices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;

% Get current working directory, so we can return here at the end:
currentFolder = pwd;

%% User input

% Perform search in this directory
directory = '.'; % './Renaming tool';

cd(directory);

%% Rename files

% Identify DICOM TYPE and store in 'files'
files = dir('*.dcm');
for i = 1:length(files)
    
    movefile(files(i).name, sprintf('%d.dcm',i));
          
end
    
%% Finally, return to the starting folder
cd(currentFolder);
