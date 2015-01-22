function ReturnStruct = measuredDataTOmat(filename,struct)
% 
% measuredStruct = measuredDataTOmat(filename);
% appendedMeasuredStruct = measuredDataTOmat(filename,measuredStruct);
% 
% Determine if the measured data is in W2CAD or ASCII format, then handle
% accordingly.
%
% Dustin Jacqmin, PhD


% Determine file type based on first line:
fid = fopen(filename,'r');
line = fgetl(fid);
fclose(fid);

if (strcmp(sscanf(line, '%s$1'),'$NUMS'))
    % We have a W2CAD file
    if nargin == 2;
        ReturnStruct = w2cadTOmat(filename,struct);
    else
        ReturnStruct = w2cadTOmat(filename);
    end
elseif (strcmp(sscanf(line, '%s$1'),':MSR'))
    % We have an ASCII file
    if nargin == 2;
        ReturnStruct = asciiTOmat(filename,struct);
    else
        ReturnStruct = asciiTOmat(filename);
    end
else
    ReturnStruct = [];
end