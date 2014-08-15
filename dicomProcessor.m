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

function doseData = fncAskForOffset(doseData)
    % FNCASKFOROFFSET In the even the DICOM offset cannot be found
    % automatically, the function will ask the user to enter one manually.
    
    % Establish global variables:
    offsetCtrl = [];
    xOffsetEdit = [];
    yOffsetEdit = [];
    zOffsetEdit = [];
    
    x = [];
    y = [];
    z = [];

    % Assume offset is invalid
    invalidOffset = true;
    
    % While the offset is invalid: Open a window and wait until the user
    % enters values and closes the window. Check to see if the values are
    % valid. If so, continue. If not, try again.
    while(invalidOffset)
        openOffsetWindow();
        waitfor(offsetCtrl);
                
        invalidOffset = isInvalidOffset();
        
    end
    
    % Return the dicom offset as a value called ORIGIN in the doseData
    % structure
    doseData.ORIGIN = [x y z];
    doseData.STATUS = sprintf('%s Offset entered manually by the user.', doseData.STATUS);
    
    function openOffsetWindow()
    
        %%% Create a window for DICOM offset entry
        offsetCtrl = figure('Resize','off','Units','pixels','Position',[100 300 300 200],'Visible','off','MenuBar','none','name','Enter DICOM Offset...','NumberTitle','off','UserData',0);

        xOffsetEdit = uicontrol('Parent',offsetCtrl,'Style','edit','String','0','FontUnits','normalized','FontSize',.4,'BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.12 .35 .2 .2]);
        yOffsetEdit = uicontrol('Parent',offsetCtrl,'Style','edit','String','0','FontUnits','normalized','FontSize',.4,'BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.44 .35 .2 .2]);
        zOffsetEdit = uicontrol('Parent',offsetCtrl,'Style','edit','String','0','FontUnits','normalized','FontSize',.4,'BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.76 .35 .2 .2]);

        xLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','X:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.03 .33 .08 .2]);
        yLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','Y:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.35 .33 .08 .2]);
        zLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','Z:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.67 .33 .08 .2]);

        requestLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','Please enter the DICOM offset location in [cm]:','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.1 .7 .8 .2]);

        okBut = uicontrol('Parent',offsetCtrl,'Style','pushbutton','String','Submit DICOM Offset','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.1 .05 .8 .2],'Callback', {@getOffsetVals});

        defaultBackground = get(0,'defaultUicontrolBackgroundColor');
        set(offsetCtrl,'Color',defaultBackground);    

        set(xOffsetEdit,'String','0');
        set(yOffsetEdit,'String','0');
        set(zOffsetEdit,'String','0');           
        set(offsetCtrl,'Visible','on');
        
    end
    
    function getOffsetVals(source,eventdata)
        
       x = sscanf(get(xOffsetEdit,'String'),'%f');
       y = sscanf(get(yOffsetEdit,'String'),'%f');
       z = sscanf(get(zOffsetEdit,'String'),'%f');
              
       close(offsetCtrl)
           
    end

    function TF = isInvalidOffset()
        % ISINVALIDOFFSET This function checks the x, y and z values
        % returned from getOffsetVals to determine if any of them are
        % invalid doubles, which cannot be used.
        
        % Assume they are all doubles:
        TF = false;
        
        if isempty(x); TF = true; end
        if isempty(y); TF = true; end
        if isempty(z); TF = true; end        
        if ~isa(x,'double'); TF = true; end
        if ~isa(y,'double'); TF = true; end
        if ~isa(z,'double'); TF = true; end
            
        if (TF)
            h = msgbox(sprintf('One or more entered values could not be converted to numbers. Please try again:\n\n x = %f, y = %f, z = %f',x,y,z));
            waitfor(h);
        end
    end

end
