function ReturnStruct = omniproAccessTOmat(filename,struct)
% 
% omniproFileStruct = omniproAccessTOmat(filename);
% anotherOmniproFileStruct = omniproAccessTOmat(filename,omniproFileStruct);
% 
% This one takes a file and creates a MATLAB structure with all the data in
% the file. As an option, you can include a structure as an argument to the
% function. The data in the file will be appended to the current 
% structure. In this way, multiple data files can be combined into one 
% grand structure.
% 
% See also
% [ x, y, z, d ] = omniproAccessTOmat(eclipseFileStruct,'OPD', [150 150]);
% [ x, y, z, d ] = omniproAccessTOmat(eclipseFileStruct,'OPP', [150 150],50,'X');
% [ x, y, z, d ] = omniproAccessTOmat(eclipseFileStruct,'OPP', [150 150],50,'Y');
% This one takes your structure and gets whatever data you want out of it 
% using the data type (OPD, OPP), field size, depth and scan direction. 
% 
% Dustin Jacqmin, PhD



fid = fopen(filename,'r');

% Get number of measurements
line = fgetl(fid);
num_meas = sscanf(line, '$NUMS %d');

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
ReturnStruct.BeamData(num_meas).Detector = 0;
ReturnStruct.BeamData(num_meas).BeamType = 0;
ReturnStruct.BeamData(num_meas).FieldSize = [ 0 0 ];
ReturnStruct.BeamData(num_meas).DataType = 0;
ReturnStruct.BeamData(num_meas).AxisType = 0;
ReturnStruct.BeamData(num_meas).NumPoints = 0;
ReturnStruct.BeamData(num_meas).StepSize = 0;
ReturnStruct.BeamData(num_meas).SSD = 0;
ReturnStruct.BeamData(num_meas).Depth = 0;
ReturnStruct.BeamData(num_meas).X = 0;
ReturnStruct.BeamData(num_meas).Y = 0;
ReturnStruct.BeamData(num_meas).Z = 0;
ReturnStruct.BeamData(num_meas).Value = 0;

for i = StartPos:ReturnStruct.Num

    % Scan until $STOM
    line = fgetl(fid);
    while  ~strcmp(sscanf(line, '%s'),'$STOM')
        line = fgetl(fid);
    end
    
    % Scan until $ENOM, filling in data
    line = fgetl(fid);
    count = 1;
    while  ~strcmp(sscanf(line, '%s'),'$ENOM')
        
        if (strcmp(sscanf(line, '%s$1'),'%VERSION')), ReturnStruct.BeamData(i).Version = sscanf(line, '%%VERSION %d'); end
        if (strcmp(sscanf(line, '%s$1'),'%DATE')), ReturnStruct.BeamData(i).Date = sscanf(line, '%%DATE %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%DETY')), ReturnStruct.BeamData(i).Detector = sscanf(line, '%%DETY %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%BMTY')), ReturnStruct.BeamData(i).BeamType = sscanf(line, '%%BMTY %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%FLSZ')), ReturnStruct.BeamData(i).FieldSize = sscanf(line, ['%*s' '%d' '*' '%d'])'; end
        if (strcmp(sscanf(line, '%s$1'),'%TYPE')), ReturnStruct.BeamData(i).DataType = sscanf(line, '%%TYPE %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%AXIS')), ReturnStruct.BeamData(i).AxisType = sscanf(line, '%%AXIS %s'); end
        if (strcmp(sscanf(line, '%s$1'),'%PNTS')) 
            NumPoints = sscanf(line, '%%PNTS %d');
            ReturnStruct.BeamData(i).NumPoints = NumPoints;
            ReturnStruct.BeamData(i).X = zeros(NumPoints,1);
            ReturnStruct.BeamData(i).Y = zeros(NumPoints,1);
            ReturnStruct.BeamData(i).Z = zeros(NumPoints,1);
            ReturnStruct.BeamData(i).Value = zeros(NumPoints,1);
        end
        if (strcmp(sscanf(line, '%s$1'),'%STEP')), ReturnStruct.BeamData(i).StepSize = sscanf(line, '%%STEP %d'); end
        if (strcmp(sscanf(line, '%s$1'),'%SSD')), ReturnStruct.BeamData(i).SSD = sscanf(line, '%%SSD %d'); end
        if (strcmp(sscanf(line, '%s$1'),'%DPTH')), ReturnStruct.BeamData(i).Depth = sscanf(line, '%%DPTH %d'); end

        if length(sscanf(line, ['<' '%f' '%f' '%f' '%f'])) == 4
            data = sscanf(line, ['<' '%f' '%f' '%f' '%f']);
            ReturnStruct.BeamData(i).X(count) = data(1);
            ReturnStruct.BeamData(i).Y(count) = data(2);
            ReturnStruct.BeamData(i).Z(count) = data(3);
            ReturnStruct.BeamData(i).Value(count) = data(4);
            count = count + 1;
        end
        
        line = fgetl(fid);
    end

end