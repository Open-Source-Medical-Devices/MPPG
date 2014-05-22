%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% renamer.m
%
% This tool:
% 1. Identifies all DICOM-RT DOSE and PLAN files in a directory
% 2. Matches them based on data stored in the DICOM files
% 3. Renames them with more descriptive names
%
% Dustin Jacqmin, PhD 2014
% https://github.com/Open-Source-Medical-Devices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get current working directory, so we can return here at the end:
currentFolder = pwd;

%% User input

% Perform search in this directory
directory = '.'; % './Renaming tool';

% Change filename (0) or copy to new filename (1)
copy2new = 0;

cd(directory);
%% Identify DICOM-RT DOSE and PLAN files in directory

% Identify DICOM TYPE and store in 'files'
files = dir('*.dcm');
for i = 1:length(files)
    dcm = dicominfo(files(i).name);
    
    str = sprintf('\n%s is a %s',files(i).name, dcm.Modality);
    disp(str);
    files(i).Modality = dcm.Modality;
    
     if strcmp(dcm.Modality,'RTDOSE')
%          str = sprintf('%s is %s','dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID', dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID);
%          disp(str);
         files(i).ID = dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
         
     elseif strcmp(dcm.Modality,'RTPLAN')
%          str = sprintf('%s is %s','dcm.SOPInstanceUID', dcm.SOPInstanceUID);
%          disp(str); 
         files(i).ID = dcm.SOPInstanceUID;
     end 
      
end

% Match PLAN and DOSE
for i = 1:length(files)
    
    if strcmp(files(i).Modality,'RTDOSE')
        thisID = files(i).ID;
         
        for j = 1:length(files)
            if j ~= i
                thatID = files(j).ID;
                if strcmp(thisID,thatID)
                    files(i).partnerID = j;
                    files(j).partnerID = i;
                end
            end
        end
    end
end

% Extract Plan characteristics from RT PLAN 
for i = 1:length(files)
    
    dcm = dicominfo(files(i).name);
    
    if strcmp(files(i).Modality,'RTPLAN')
        files(i).PlanName = dcm.RTPlanName;
        files(i).MachineName = dcm.BeamSequence.Item_1.TreatmentMachineName;
        files(i).BeamName = dcm.BeamSequence.Item_1.BeamName;
        files(i).BeamType = dcm.BeamSequence.Item_1.BeamType;
        files(i).RadiationType = dcm.BeamSequence.Item_1.RadiationType;
        files(i).Energy = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.NominalBeamEnergy;
        files(i).X1 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(1);
        files(i).X2 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(2);
        files(i).Y1 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(1);
        files(i).Y2 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(2);
        files(i).GantryAngle = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.GantryAngle;
        files(i).IsocenterPosition = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.IsocenterPosition;
        
        files(i).Filename = sprintf('%s_%s_%s_%s-%s_%s.dcm','RTPLAN',files(i).PlanName, files(i).MachineName, num2str(files(i).Energy), files(i).RadiationType, files(i).BeamName);
        pID = files(i).partnerID;
        files(pID).Filename = sprintf('%s_%s_%s_%s-%s_%s.dcm','RTDOSE',files(i).PlanName, files(i).MachineName, num2str(files(i).Energy), files(i).RadiationType, files(i).BeamName);
        
    end 
end

% Change filenames
for i = 1:length(files)
    if strcmp(files(i).Modality,'RTPLAN')
        pID = files(i).partnerID;
        if copy2new == 1
            copyfile(files(i).name, files(i).Filename);
            copyfile(files(pID).name, files(pID).Filename);
        else
            movefile(files(i).name, files(i).Filename);
            movefile(files(pID).name, files(pID).Filename);
        end
    end
end

    
%% Finally, return to the starting folder
cd(currentFolder);
