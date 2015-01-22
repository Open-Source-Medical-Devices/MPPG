function ReturnStruct = asciiTOmat(filename,struct)
% 
% ReturnStruct = asciiTOmat(filename,struct)
% 
% This one takes a file and creates a MATLAB structure with all the data in
% the file. As an option, you can include a structure as an argument to the
% function. The data in the file will be appended to the current 
% structure. In this way, multiple data files can be combined into one 
% grand structure.
% 
% Dustin Jacqmin, PhD

fid = fopen(filename,'r');

% Get number of measurements
line = fgetl(fid);
num_meas = sscanf(line, ':MSR %d');

if nargin == 2;
    ReturnStruct = struct;
    StartPos = ReturnStruct.Num + 1;
    ReturnStruct.Num = num_meas + ReturnStruct.Num;
else
    ReturnStruct.Num = num_meas;
    StartPos = 1;
end
    
% Pre-allocation
ReturnStruct.BeamData(num_meas).Version = 0;
ReturnStruct.BeamData(num_meas).Date = 0;
ReturnStruct.BeamData(num_meas).BeamType = 0;
ReturnStruct.BeamData(num_meas).BeamEnergy = 0;
ReturnStruct.BeamData(num_meas).FieldSize = [ 0 0 ];
ReturnStruct.BeamData(num_meas).DataType = 0;
ReturnStruct.BeamData(num_meas).NumPoints = 0;
ReturnStruct.BeamData(num_meas).SSD = 0;
ReturnStruct.BeamData(num_meas).Depth = 0;
ReturnStruct.BeamData(num_meas).StartPos = 0;
ReturnStruct.BeamData(num_meas).EndPos = 0;
ReturnStruct.BeamData(num_meas).X = 0;
ReturnStruct.BeamData(num_meas).Y = 0;
ReturnStruct.BeamData(num_meas).Z = 0;
ReturnStruct.BeamData(num_meas).Value = 0;

for i = StartPos:ReturnStruct.Num

    % Scan until $STOM
    line = fgetl(fid);
    while  ~strcmp(sscanf(line, '%s$1'),'%VNR')
        line = fgetl(fid);
    end
    
    % Scan untils $ENOM, filling in data
    count = 1;
    while  ~strcmp(sscanf(line, '%s$1'),':EOM')
        
        if (strcmp(sscanf(line, '%s$1'),'%VNR')), ReturnStruct.BeamData(i).Version = sscanf(line, '%%VNR %f'); end
        if (strcmp(sscanf(line, '%s$1'),'%DAT')), ReturnStruct.BeamData(i).Date = sscanf(line, '%%DAT %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%BMT')), ReturnStruct.BeamData(i).BeamType = sscanf(line, '%%BMT %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%BMT')), ReturnStruct.BeamData(i).BeamEnergy = sscanf(line,'%%BMT %*s %f'); end
        if (strcmp(sscanf(line, '%s$1'),'%FSZ')), ReturnStruct.BeamData(i).FieldSize = sscanf(line, ['%*s' '%d' '*' '%d'])'/10; end %cm
        if (strcmp(sscanf(line, '%s$1'),'%SCN')), ReturnStruct.BeamData(i).DataType = sscanf(line, '%%SCN %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%PTS')) 
            NumPoints = sscanf(line, '%%PTS %d');
            ReturnStruct.BeamData(i).NumPoints = NumPoints;
            ReturnStruct.BeamData(i).X = zeros(NumPoints,1);
            ReturnStruct.BeamData(i).Y = zeros(NumPoints,1);
            ReturnStruct.BeamData(i).Z = zeros(NumPoints,1);
            ReturnStruct.BeamData(i).Value = zeros(NumPoints,1);
        end
        if (strcmp(sscanf(line, '%s$1'),'%SSD')), ReturnStruct.BeamData(i).SSD = sscanf(line, '%%SSD %d')/10; end %cm
        if (strcmp(sscanf(line, '%s$1'),'%STS')), ReturnStruct.BeamData(i).StartPos = sscanf(line, '%%STS %f %f %f')/10; end %cm
        if (strcmp(sscanf(line, '%s$1'),'%EDS')), ReturnStruct.BeamData(i).EndPos = sscanf(line, '%%EDS %f %f %f')/10; end %cm
        
        if length(sscanf(line, ['=' '%f' '%f' '%f' '%f'])) == 4
            data = sscanf(line, ['=' '%f' '%f' '%f' '%f']);
            ReturnStruct.BeamData(i).X(count) = data(2)/10; %cm
            ReturnStruct.BeamData(i).Y(count) = -data(1)/10; %cm
            ReturnStruct.BeamData(i).Z(count) = data(3)/10; %cm
            ReturnStruct.BeamData(i).Value(count) = data(4);
            count = count + 1;
        end
        
        line = fgetl(fid);
    end

    % Assign axis type and depth based on beam data
    ReturnStruct.BeamData(i).AxisType = '';
    if max(ReturnStruct.BeamData(i).X) - min(ReturnStruct.BeamData(i).X) > .1
        ReturnStruct.BeamData(i).AxisType = sprintf('%sX',ReturnStruct.BeamData(i).AxisType);
    end
    if max(ReturnStruct.BeamData(i).Y) - min(ReturnStruct.BeamData(i).Y) > .1
        ReturnStruct.BeamData(i).AxisType = sprintf('%sY',ReturnStruct.BeamData(i).AxisType);
    end
    if max(ReturnStruct.BeamData(i).Z) - min(ReturnStruct.BeamData(i).Z) > .1
        ReturnStruct.BeamData(i).AxisType = sprintf('%sZ',ReturnStruct.BeamData(i).AxisType);
    end
    
    if strcmp(ReturnStruct.BeamData(i).AxisType,'X') || strcmp(ReturnStruct.BeamData(i).AxisType,'Y')
        ReturnStruct.BeamData(i).Depth = ReturnStruct.BeamData(i).Z(1);
    end
    
end

fclose(fid);