function [offset, planData ] = dicomPlanProcessor(dosefile, planfile)

% Open DICOM-RT DOSE and check type
ddcm = dicominfo(dosefile);

if ~strcmp(ddcm.Modality,'RTDOSE')
    disp('Warning: File selected for DICOM DOSE is not a DICOM DOSE file.');
end

% Get Reference RT Plan Sequence
RRPS = ddcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;

planData = 0;

% Open DICOM-RT PLAN and check type
pdcm = dicominfo(planfile);

if ~strcmp(ddcm.Modality,'RTPLAN')
    disp('Warning: File selected for DICOM PLAN is not a DICOM PLAN file.');
end

% Get SOP Instance UID
SIU = pdcm.SOPInstanceUID;

if ~strcmp(RRPS,SIU)
    disp('Warning: The selected DICOM DOSE and PLAN files may not be from the same exported plan.')
end

% Get beam number for DICOM-RT DOSE
beamNum = ddcm.ReferencedRTPlanSequence.Item_1.ReferencedFractionGroupSequence.Item_1.ReferencedBeamSequence.Item_1.ReferencedBeamNumber;

% Look for point of interest called "ORIGIN"
foundORIGIN = false;

% Search over all POIs in the Plan Dose Reference Sequence
for i = 1:length(fieldnames(pdcm.DoseReferenceSequence))
    
    itemName = ['Item_' num2str(round(i))];
    
    % Check to see if this one is called ORIGIN
    if strcmp(pdcm.DoseReferenceSequence.(itemName).DoseReferenceDescription,'ORIGIN')
        
        % This one is called ORIGIN. Extract the location in DICOM
        % coordinates for the offset
        offset = pdcm.DoseReferenceSequence.(itemName).DoseReferencePointCoordinates/10; % convert to cm
        foundORIGIN = true;
        break
    end
    
end

% Check to see if the ORIGIN was found.
if foundORIGIN
    disp('A POI called ORIGIN was found. We will assume that this is the scanning tank origin and use it for the dicom offset.');
else
    disp('A POI called ORIGIN was not found. DICOM coordinate offset is defaulting to [ 0, -30.09, 0 ]');
    offset = [ 0 -30.09 0 ];
end

% Get isocenter location. We are not using it now, but may in the future.
itemName = ['Item_' num2str(round(beamNum))]; 
isocenter = pdcm.BeamSequence.(itemName).ControlPointSequence.Item_1.IsocenterPosition;

% A placeholder for extracted plan data.
planData = 0;
