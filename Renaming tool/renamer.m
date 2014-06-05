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
clear all;

% Get current working directory, so we can return here at the end:
currentFolder = pwd;

%% User input

% Perform search in this directory
directory = '.'; % './Renaming tool';

% Develop the filename by including (1) or excluding (0) these parameters
includePlanName = 1; % Water Phantom, etc.
includeMachineName = 0; % Varian 21iX 703, etc.
includeBeamName = 1; % 10x10, C-shape, Test 5.7, etc.
includeBeamType = 1; % STATIC, STEP-AND-SHOOT, etc.
includeRadiationType = 1; % PHOTON, ELECTRON, etc.
includeEnergy = 1; % 6MV, 12MeV, etc.
includeGantryAngle = 0; % 0deg, 180deg
includeBeamModifier = 1; % OPEN, STANDARD-45-OUT, ??-60-IN, etc.
includeMLC = 1; % MLCs, NOMLCs

cd(directory);

%% Overwrite current names to a random sequence of numbers 
% This prevents issues associated with running this program twice in a row

% Identify DICOM TYPE and store in 'files'
files = dir('*.dcm');
base = round(100000*rand);
for i = 1:length(files)
    dcm = dicominfo(files(i).name);
    
    movefile(files(i).name, sprintf('%s_%d.dcm', dcm.Modality, base + i));
          
end
%% Identify DICOM-RT DOSE and PLAN files in directory

% Identify DICOM TYPE and store in 'files'
files = dir('*.dcm');
for i = 1:length(files)
    dcm = dicominfo(files(i).name);
    
%     str = sprintf('\n%s is a %s',files(i).name, dcm.Modality);
    files(i).Modality = dcm.Modality;
    
    % THE RTDOSE file has a 'ReferencedRTPlanSequence' identifier that
    % contains the SOPInstanceUID for the appropriate corresponding RTPLAN
    % file. We will store these and use them to identify pairs.
    if strcmp(dcm.Modality,'RTDOSE')
%         str = sprintf('%s is %s','dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID', dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID);
%         disp(str);
        files(i).ID = dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
    elseif strcmp(dcm.Modality,'RTPLAN')
%          str = sprintf('%s is %s','dcm.SOPInstanceUID', dcm.SOPInstanceUID);
%          disp(str); 
        files(i).ID = dcm.SOPInstanceUID;
    end 
      
end

%% Match RTPLAN and RTDOSE based on IDs
for i = 1:length(files)
    
    %Match each RTDOSE with an RTPLAN file
    if strcmp(files(i).Modality,'RTDOSE')
        thisID = files(i).ID;
         
        for j = 1:length(files)
            if j ~= i
                thatID = files(j).ID;
                %check if id's are the same, and that the partner is an RTPLAN
                if strcmp(thisID,thatID) && strcmp(files(j).Modality,'RTPLAN')
                    files(i).partnerID = j;
                    %set the RTPlans partners
                    files(j).partnerID = i;
                end
            end
        end
    end
end

%% Go through dose files and rename them according to their beam names
for i = 1:length(files)
    if strcmp(files(i).Modality,'RTDOSE')
        %Get beam number
        dcmDose = dicominfo(files(i).name);
        beamNum = dcmDose.ReferencedRTPlanSequence.Item_1.ReferencedFractionGroupSequence.Item_1.ReferencedBeamSequence.Item_1.ReferencedBeamNumber;
        pID = files(i).partnerID;
        dcmPlan = dicominfo(files(pID).name);
        %next lines are a bit tricky, using "dynamic field name" technique (itemName)
        itemName = ['Item_' num2str(round(beamNum))];        
        beamName = dcmPlan.BeamSequence.(itemName).BeamName;
        files(i).Filename = ['RTDOSE_' beamName '.dcm'];
        movefile(files(i).name, files(i).Filename);
    end
end

% %% Extract Plan characteristics from RTPLAN 
% for i = 1:length(files)
%     
%     dcm = dicominfo(files(i).name);
%     
%     if strcmp(files(i).Modality,'RTPLAN')
%         files(i).PlanName = dcm.RTPlanName;
%         files(i).MachineName = dcm.BeamSequence.Item_1.TreatmentMachineName;
%         files(i).BeamName = dcm.BeamSequence.Item_1.BeamName;
%         files(i).BeamType = dcm.BeamSequence.Item_1.BeamType;
%         files(i).RadiationType = dcm.BeamSequence.Item_1.RadiationType;
%         files(i).Energy = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.NominalBeamEnergy;
%         files(i).X1 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(1);
%         files(i).X2 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(2);
%         files(i).Y1 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(1);
%         files(i).Y2 = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(2);
%         files(i).GantryAngle = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.GantryAngle;
%         files(i).IsocenterPosition = dcm.BeamSequence.Item_1.ControlPointSequence.Item_1.IsocenterPosition;
%         if dcm.BeamSequence.Item_1.NumberOfWedges > 0
%             files(i).BeamModifier = sprintf('%s-%s',dcm.BeamSequence.Item_1.WedgeSequence.Item_1.WedgeType, dcm.BeamSequence.Item_1.WedgeSequence.Item_1.WedgeID);
%         else
%             files(i).BeamModifier = 'OPEN';
%         end
%         try
%             files(i).MLC = dcm.BeamSequence.Item_1.BeamLimitingDeviceSequence.Item_3.RTBeamLimitingDeviceType;
%         catch exception
%             files(i).MLC = 'NO-MLC';
%         end
%         
%         % Create the new file names for RTPLAN and RTDOSE
%         file_rtplan = 'RTPLAN';
%         file_rtdose = 'RTDOSE';
%         if includePlanName == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).PlanName);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).PlanName);
%         end
%         if includeMachineName == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).MachineName);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).MachineName);
%         end
%         if includeBeamName == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).BeamName);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).BeamName);
%         end       
%         if includeBeamType == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).BeamType);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).BeamType);
%         end
%         if includeRadiationType == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).RadiationType);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).RadiationType);
%         end
%         if includeEnergy == 1
%             if strcmp(files(i).RadiationType,'PHOTON')
%                 file_rtplan = sprintf('%s_%sMV',file_rtplan, num2str(files(i).Energy));
%                 file_rtdose = sprintf('%s_%sMV',file_rtdose, num2str(files(i).Energy));
%             elseif strcmp(files(i).RadiationType,'ELECTRON')
%                 file_rtplan = sprintf('%s_%sMeV',file_rtplan, num2str(files(i).Energy));
%                 file_rtdose = sprintf('%s_%sMeV',file_rtdose, num2str(files(i).Energy));
%             end        
%         end
%         if includeGantryAngle == 1
%             file_rtplan = sprintf('%s_%sdeg',file_rtplan, num2str(files(i).GantryAngle));
%             file_rtdose = sprintf('%s_%sdeg',file_rtdose, num2str(files(i).GantryAngle));
%         end
%         if includeBeamModifier == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).BeamModifier);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).BeamModifier);
%         end
%         if includeMLC == 1
%             file_rtplan = sprintf('%s_%s',file_rtplan, files(i).MLC);
%             file_rtdose = sprintf('%s_%s',file_rtdose, files(i).MLC);
%         end
%                 
%         files(i).Filename = sprintf('%s.dcm',file_rtplan);
%         pID = files(i).partnerID;
%         files(pID).Filename = sprintf('%s.dcm',file_rtdose);
%     end 
% end
% 
% %% Change filenames
% for i = 1:length(files)
%     if strcmp(files(i).Modality,'RTPLAN')
%         pID = files(i).partnerID;
%         movefile(files(i).name, files(i).Filename);
%         movefile(files(pID).name, files(pID).Filename);
%    end
% end

    
%% Finally, return to the starting folder
cd(currentFolder);
