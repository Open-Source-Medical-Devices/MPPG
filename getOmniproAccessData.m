function [x, y, z, d] = getOmniproAccessData(struct,type,fs,depth,axis)
%getEclipseData   Get a data set from an Eclipse data structure.
%   struct = Structure containing Eclipse data.
%   type = Open Profile (OPP) or Open PDD (OPD)
%   fs = Field size in a 2-element vector (e.g. [10 10])
%   depth = For OPP, this is depth
%   axis = For OPP, this is the scan axis
%
%   A request for an OPD should have 3 arguments, a request for an OPP
%   should have all 5.

x = 0; y = 0; z = 0; d = 0;

if strcmp(type,'OPD')

    % The data stored in W2CAD files is stored in mm. Convert input (cm) to
    % mm
    fs = fs*10;
    
    for i = 1:struct.Num
    
        % Check DataType and FieldSize
        if ~strcmp(type,struct.BeamData(i).DataType), continue; end;
        if struct.BeamData(i).FieldSize(1) ~= fs(1) || struct.BeamData(i).FieldSize(2) ~= fs(2), continue; end;

        x = struct.BeamData(i).X;
        y = struct.BeamData(i).Y;
        z = struct.BeamData(i).Z;
        d = struct.BeamData(i).Value;
        break;
           
    end
        
end

if strcmp(type,'OPP')
    
    % The data stored in W2CAD files is stored in mm. Convert input to cm
    fs = fs*10;
    depth = depth*10;

    for i = 1:struct.Num
    
        % Check DataType and FieldSize
        if ~strcmp(type,struct.BeamData(i).DataType), continue; end;
        if struct.BeamData(i).FieldSize(1) ~= fs(1) || struct.BeamData(i).FieldSize(2) ~= fs(2), continue; end;
        if struct.BeamData(i).Depth ~= depth, continue; end;
        if ~strcmp(axis,struct.BeamData(i).AxisType), continue; end;

        x = struct.BeamData(i).X;
        y = struct.BeamData(i).Y;
        z = struct.BeamData(i).Z;
        d = struct.BeamData(i).Value;
        break;

           
    end
        
end

% Convert output to cm
x = x/10;
y = y/10;
z = z/10;
        
    


