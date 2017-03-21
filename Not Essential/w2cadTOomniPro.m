%function nullOut = w2cadTOomniPro(filename)

[measFileName measPathName] = uigetfile({'*.ASC';'*.*'},'Select Measured Data','MultiSelect','off');    
filename = [measPathName measFileName];

nullOut = 0;

[pathstr,name,ext] = fileparts(filename);

outFilename = name;
outFilepath = pathstr;

% Open the w2cad file using the w2cadTOmat() function
% This will extract the information stored in the file into MATLAB
inStruct = w2cadTOmat(filename);

% Create the output file:
fid = fopen([outFilepath '/' outFilename '_processed.asc'],'w');

% Write the number of measurements in the file
fprintf(fid,':MSR \t%d\t # No. of measurement in file\n',inStruct.Num);

% Write the rest of the header
fprintf(fid,':SYS BDS 0 # Beam Data Scanner System\n');

% Loop over measurements
for i=1:inStruct.Num
    
    % Header text
    fprintf(fid,'#\n# RFA300 ASCII Measurement Dump ( BDS format )\n#\n');
    fprintf(fid,'# Measurement number  \t%d\n',i');
    fprintf(fid,'#\n');
    
    % Version number
    fprintf(fid,'%%VNR 1.0\n');

    % Mode
    fprintf(fid,'%%MOD \tRAT \n');
    
    % Type
    fprintf(fid,'%%MOD \tSCN \n');
    
    % Scan Type
    if strcmp(inStruct.BeamData(i).DataType,'OPD')
        fprintf(fid,'%%SCN \tDPT \n');
    elseif strcmp(inStruct.BeamData(i).DataType,'OPP')
        fprintf(fid,'%%SCN \tPRO \n');
    else
        fprintf(fid,'%%SCN \tDIA \n');
    end
    
    % Detector Type
    if strcmp(inStruct.BeamData(i).Detector,'CHA')
        fprintf(fid,'%%FLD \tION \n');
    else
        fprintf(fid,'%%FLD \tSEM \n');
    end
    
    % Date and time
    fprintf(fid,'%%DAT \t01-01-1900 \n');
    fprintf(fid,'%%TIM \t00:00:00 \n');

    % Field Size
    fprintf(fid,'%%FSZ \t%d\t%d\n',inStruct.BeamData(i).FieldSize(1)*10, inStruct.BeamData(i).FieldSize(2)*10);
    
    % Radiation Type (w2cad does not have beam energy, so false value used
    % here
    fprintf(fid,'%%BMT \t%s\t    1.0\n',inStruct.BeamData(i).BeamType);
    
    % SSD
    fprintf(fid,'%%SSD \t%d\n',inStruct.BeamData(i).SSD*10);

    % Build-up
    fprintf(fid,'%%BUP \t0\n');
    
    % Beam Reference Distance
    fprintf(fid,'%%BRD \t1000\n');
    
    % Shape (-1 is undefined)
    fprintf(fid,'%%FSH \t-1\n');
    
    % Accessory number
    fprintf(fid,'%%ASC \t0\n');
    
    % Wedge angle
    fprintf(fid,'%%WEG \t0\n');
    
    % Gantry Angle
    fprintf(fid,'%%GPO \t0\n');

    % Collimator Angle
    fprintf(fid,'%%CPO \t0\n');
    
    % Measurement Type
    if strcmp(inStruct.BeamData(i).DataType,'OPD')
        fprintf(fid,'%%MEA \t1\n');
    elseif strcmp(inStruct.BeamData(i).DataType,'OPP')
        fprintf(fid,'%%MEA \t2\n');
    else
        fprintf(fid,'%%MEA \t-1\n');
    end
    
    % Profile Depth
    if strcmp(inStruct.BeamData(i).DataType,'OPD')
        fprintf(fid,'%%PRD \t0\n');
    elseif strcmp(inStruct.BeamData(i).DataType,'OPP')
        fprintf(fid,'%%PRD \t%d\n',inStruct.BeamData(i).Depth*10);
    else
        fprintf(fid,'%%PRD \t0\n');
    end
    
    % Number of Points
    fprintf(fid,'%%PTS \t%d\n',inStruct.BeamData(i).NumPoints);
    
    % Comment
    fprintf(fid,'! Generated with w2cadTOomniPro.m\n');
    fprintf(fid,'! Filename: %s\n',[name ext]);
    
    % Start and End Position
    end_pos = inStruct.BeamData(i).NumPoints;
    fprintf(fid,'%%STS \t%7s\t%7s\t%7s # Start Scan values in mm ( X , Y , Z )\n', ... 
        sprintf('%.1f',-10*inStruct.BeamData(i).Y(1)), ...
        sprintf('%.1f',10*inStruct.BeamData(i).X(1)), ...
        sprintf('%.1f',10*inStruct.BeamData(i).Z(1)));
    fprintf(fid,'%%EDS \t%7s\t%7s\t%7s # Start End values in mm ( X , Y , Z )\n', ...
        sprintf('%.1f',-10*inStruct.BeamData(i).Y(end_pos)), ...
        sprintf('%.1f',10*inStruct.BeamData(i).X(end_pos)), ...
        sprintf('%.1f',10*inStruct.BeamData(i).Z(end_pos)));

    % Data Points
    fprintf(fid,'#\n');
    fprintf(fid,'#\t  X      Y      Z     Dose\n');
    fprintf(fid,'#\n');
    valueMax = max(inStruct.BeamData(i).Value);
    for j=1:end_pos
        fprintf(fid,'= \t%7s\t%7s\t%7s\t%7s\n', ...
            sprintf('%.1f',-10*inStruct.BeamData(i).Y(j)), ...
            sprintf('%.1f',10*inStruct.BeamData(i).X(j)), ...
            sprintf('%.1f',10*inStruct.BeamData(i).Z(j)), ...
            sprintf('%.1f',inStruct.BeamData(i).Value(j)/valueMax*100));        
    end
    
    fprintf(fid,':EOM  # End of Measurement\n');
    
end


fclose(fid);