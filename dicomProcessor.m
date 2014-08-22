function [ doseData ] = dicomProcessor(dosedir, dosefile)
    % DICOMPROCESSOR Accepts a directory and DICOM DOSE filename and determines
    % if the associated DICOM-RT PLAN and RT STRUCT are in the same
    % directory. If so, the DICOM offset for use in MPPG_GUI is determined.
    % A structure is returned. At this time, only the DICOM offset is sent
    % back, but this could be used to send addtional plan information.
    
    % Dustin Jacqmin, 2014

    %%%% Open DICOM-RT DOSE and check type %%%%
    ddcm = dicominfo([ dosedir dosefile ]);

    if ~strcmp(ddcm.Modality,'RTDOSE')
        disp('Warning: File selected is not a DICOM-RT DOSE file.');
        h = msgbox('Warning: File selected is not a DICOM-RT DOSE file.');
        doseData.STATUS = 'File selected is not a DICOM-RT DOSE file. Please try again';
        return;
    end

    % Get TPS and enter into status:
    doseData.STATUS = sprintf('DICOM-RT DOSE is from %s.', ddcm.Manufacturer);
    
    %%%% Search the directory for the accompanying DICOM-RT PLAN %%%%
    % Save current folder and change directory to DICOM-RT DOSE directory
    currentFolder = pwd;
    cd(dosedir);                

    %%%%%% SPLIT 1: Does DICOM-RT DOSE have a Reference RT Plan Sequence? %%%%%%
    planFound = false;
    
    try
        % Get Reference RT Plan Sequence
        RRPS = ddcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;

        % Create a DICOM file list. Cycle through the DICOM files to check for PLAN
        % files. If it is a plan file, check to see if the Reference RT Plan Sequence
        % from the dose file matches the SOP Instance UID in the plan file. If it
        % does, you have a pair.

        files = dir('*.dcm');

        for i = 1:length(files)
            pdcm = dicominfo(files(i).name);
            if strcmp(pdcm.Modality,'RTPLAN')
                SIUP = pdcm.SOPInstanceUID;
                if strcmp(RRPS,SIUP)
                    planFound = true;
                    break;
                end
            end
        end
    catch
         doseData.STATUS = sprintf('%s DICOM-RT DOSE does not have the "ReferencedRTPlanSequence" attribute, possibly because it was exported without a DICOM-RT PLAN.', doseData.STATUS);
    end

    %%% At this point, the code will diverge many ways depending on the
    %%% treatment planning system and whether a PLAN was found. This will
    %%% be handled with local functions for clarity.
    
    %%%%%% SPLIT 2: Plan Found vs. No Plan found %%%%%%
    if (planFound)
        doseData.STATUS = sprintf('%s Accompanying DICOM-RT PLAN was found.', doseData.STATUS);
        doseData = fncPlanFound(doseData,pdcm);
    else
        doseData.STATUS = sprintf('%s Accompanying DICOM-RT PLAN was not found.', doseData.STATUS);
        doseData = fncAskForOffset(doseData);
    end
    
    % Finally, CD back to original directory
    cd(currentFolder);
end
    
function doseData = fncPlanFound(doseData,pdcm)
    % FNCPLANFOUND This function handles the case for when the DICOM-RT
    % DOSE has an accompnaying DICOM-RT PLAN. 
    
    % The next step is trying to find the DICOM offset. The first place we
    % will look is in the DICOM-RT PLAN. 
    
    %%%%%% SPLIT 3: RT PLAN HAS ATTRIBUTE CALLED "DoseReferenceSequence" %%%%%%
    try
       
        foundORIGIN = false;

        % Search over all POIs in the Plan Dose Reference Sequence
        for i = 1:length(fieldnames(pdcm.DoseReferenceSequence))

            itemName = ['Item_' num2str(round(i))];

            % Check to see if this one is called ORIGIN
            if strcmp(pdcm.DoseReferenceSequence.(itemName).DoseReferenceDescription,'ORIGIN')

                % This one is called ORIGIN. Extract the location in DICOM
                % coordinates for the offset
                plan_origin = pdcm.DoseReferenceSequence.(itemName).DoseReferencePointCoordinates/10; % convert to cm
                foundORIGIN = true;
                break
            end

        end
        
        %%%%%% SPLIT 4: Was a POI called ORIGIN found in the DoseReferenceSequence? %%%%%%
        if (foundORIGIN)
            
            % Our search is over and we can return the DICOM offset from
            % DICOM-RT PLAN
            doseData.ORIGIN = plan_origin;
            doseData.STATUS = sprintf('%s A POI called "ORIGIN" was found in the DICOM-RT PLAN DoseReferenceSequence. This will be used as the DICOM offset.', doseData.STATUS);            
        else
            % The seach of DoseReferenceSequence did not turn up a point
            % called "ORIGIN". Let's continue with a search for a structure
            % set.
            doseData.STATUS = sprintf('%s A POI called "ORIGIN" was not found in the DICOM-RT PLAN.', doseData.STATUS);
            doseData = fncSearchStructureSet(doseData,pdcm);
        end        
        
    catch
        % If we get here, it is likely that the DICOM-RT PLAN does not have
        % an attribute called DoseReferenceSequence. This is the case with
        % Pinnacle3 plans, and perhaps other TPS. Let's continue with a 
        % search for a structure set.
        doseData.STATUS = sprintf('%s A POI called "ORIGIN" was not found in the DICOM-RT PLAN.', doseData.STATUS);
        doseData = fncSearchStructureSet(doseData,pdcm);

    end
    
end

function doseData = fncSearchStructureSet(doseData,pdcm)

    %%%%%% SPLIT 5: Does DICOM-RT PLAN have a "pdcm.ReferencedStructureSetSequence"? %%%%%%
    structuresFound = false;
    
    try
        % Get Reference RT Plan Sequence
        RSSS = pdcm.ReferencedStructureSetSequence.Item_1.ReferencedSOPInstanceUID;

        % Create a DICOM file list. Cycle through the DICOM files to check
        % for STRUCT files. If it is a structure set file, check to see if 
        % the ReferencedStructureSetSequence ID from the PLAN file matches 
        % the SOP Instance UID in the structure set file. If it does, you 
        % have a pair.

        files = dir('*.dcm');

        for i = 1:length(files)
            sdcm = dicominfo(files(i).name);
            if strcmp(sdcm.Modality,'RTSTRUCT')
                SIUP = sdcm.SOPInstanceUID;
                if strcmp(RSSS,SIUP)
                    structuresFound = true;
                    break;
                end
            end
        end
    catch
         doseData.STATUS = sprintf('%s DICOM-RT PLAN does not have the "ReferencedStructureSetSequence" attribute, possibly because it was exported without a DICOM-RT STRUCT.', doseData.STATUS);
    end
    
    %%%%%% SPLIT 6: Structure set found? %%%%%%
    if (structuresFound)
        doseData.STATUS = sprintf('%s Accompanying DICOM-RT STRUCT was found.', doseData.STATUS);
        doseData = fncStructuresFound(doseData,sdcm);
    else
        doseData.STATUS = sprintf('%s Accompanying DICOM-RT STRUCT was not found.', doseData.STATUS);
        doseData = fncAskForOffset(doseData);
    end

end

function doseData = fncStructuresFound(doseData,sdcm)

    % We've reached the end of our search. The last step is searching the
    % structure set for a POI called ORIGIN. If none is found, we'll ask
    % the user for an offset.
    
    %%%%%% SPLIT 7: RT STRUCT HAS ATTRIBUTE CALLED "StructureSetROISequence" & "ROIContourSequence"  %%%%%%
    try

        foundORIGIN = false;

        % Search over all items in the StructureSetROISequence

        for i = 1:length(fieldnames(sdcm.StructureSetROISequence))

            itemName = ['Item_' num2str(round(i))];

            % Check to see if this one is called ORIGIN
            if strcmp(sdcm.StructureSetROISequence.(itemName).ROIName,'ORIGIN')

                % This one is called ORIGIN. Get the "ROI Number"
                roiNum = sdcm.StructureSetROISequence.(itemName).ROINumber;

                % Search the ROIContourSequence for an ROI with the same
                % ReferencedROINumber

                for j = 1:length(fieldnames(sdcm.ROIContourSequence))

                    itemName = ['Item_' num2str(round(i))];

                    % Check to see if this one has same ROINumber
                    if sdcm.ROIContourSequence.(itemName).ReferencedROINumber == roiNum

                        % Now we've found our DICOM offset. It's burried
                        % here:
                        struct_origin = sdcm.ROIContourSequence.(itemName).ContourSequence.Item_1.ContourData/10; % convert to cm
                        foundORIGIN = true;
                        break
                    end
                end
            end

            if (foundORIGIN); break; end;
        end
        
        %%%%%% SPLIT 4: Was a POI called ORIGIN found in the DoseReferenceSequence? %%%%%%
        if (foundORIGIN)
            
            % Our search is over and we can return the DICOM offset from
            % DICOM-RT PLAN
            doseData.ORIGIN = struct_origin;
            doseData.STATUS = sprintf('%s A POI called "ORIGIN" was found in the DICOM-RT STRUCT StructureSetROISequence. This will be used as the DICOM offset.', doseData.STATUS);            
        else
            % The seach of DoseReferenceSequence did not turn up a point
            % called "ORIGIN". Let's continue with a search for a structure
            % set.
            doseData.STATUS = sprintf('%s A POI called "ORIGIN" was not found in the DICOM-RT STRUCT.', doseData.STATUS);
            doseData = fncAskForOffset(doseData);
        end        

    catch
    	doseData.STATUS = sprintf('%s A POI called "ORIGIN" was not found in the DICOM-RT STRUCT.', doseData.STATUS);
        doseData = fncAskForOffset(doseData);
    end

end
