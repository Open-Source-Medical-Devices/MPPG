function renamer_GUI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% renamer_GUI.m
%
% This tool:
% 1. Identifies all DICOM-RT DOSE and PLAN files in a directory
% 2. Matches them based on data stored in the DICOM files
% 3. Renames them with more descriptive names
% 4. Allows all this to be done using a convenient GUI
%
% Dustin Jacqmin, PhD & Jeremy Bredfeldt, 2014
% https://github.com/Open-Source-Medical-Devices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;

% Get current working directory, so we can return here at the end:
currentFolder = pwd;

%% Create the GUI

% Create a window
guiCtrl = figure('Resize','on','Units','pixels','Position',[100 300 500 300],'Visible','off','MenuBar','none','name','DICOM Renamer','NumberTitle','off','UserData',0);

dirLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Select a directory containing DICOM files to be renamed:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.02 .88 .8 .1]);
dirBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Select Directory','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.05 .8 .4 .1],'callback','ClickedCallback','Callback', {@countDICOM});
dirDisplay = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[.05 .57 .90 .2]);
countDisplay = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.05 .47 .90 .1]);

boxPanel = uipanel('Parent',guiCtrl,'Title','Include These In Filename','Units','normalized','Position',[.05 .19 .9 .3]);

boxLastName = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Last Name','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.05 .7 .2 .25]);
boxFirstName = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','First Name','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.05 .4 .2 .25]);
boxMRN = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','MRN','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.05 .1 .2 .25]);
boxPlanName = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Plan Name','Min',0,'Max',3,'Value',3,'Units','normalized','Position',[.2833 .7 .2 .25]);
boxMachineName = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Machine Name','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.2833 .4 .2 .25]);
boxBeamName = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Beam Name','Min',0,'Max',3,'Value',3,'Units','normalized','Position',[.2833 .1 .2 .25]);
boxBeamType = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Beam Type','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.5166 .7 .2 .25]);
boxRadiationType = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Radiation Type','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.5166 .4 .2 .25]);
boxEnergy = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Beam Energy','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.5166 .1 .2 .25]);
boxGantryAngle = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Gantry Angle','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.75 .7 .2 .25]);
boxBeamModifier = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Beam Modifier','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.75 .4 .2 .25]);
boxMLC = uicontrol('Parent',boxPanel,'Style','checkbox','Enable','on','String','Has MLC?','Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.75 .1 .2 .25]);

renameBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','Enable','off','String','Rename Files','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.05 .05 0.9 .1],'callback','ClickedCallback','Callback', {@runRenamer});

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiCtrl,'Visible','on');

renamerPathName = [];

    function countDICOM(source,eventdata)
        
        set(dirDisplay,'String','Loading: Please wait ...');
        set(countDisplay,'String','');
        
        % Return to previous directory if possible
        rpath.renamerPathSave = '.';
        if exist('rpath.mat','file')
            rpath = load('rpath.mat');  
            if  rpath.renamerPathSave == 0
                 rpath.renamerPathSave = '.';
            end
        end
        
        % Have user select directory
        [renamerPathName] = uigetdir(rpath.renamerPathSave,'Select Directory Containing DICOM files');
        
        % Check for valid directory
        if ischar(renamerPathName) 
            if isdir(renamerPathName)
                               
                % Save the directory above this one as the last directory      
                renamerPathSave = sprintf('%s%s', renamerPathName, '\..');
                save('rpath.mat','renamerPathSave');

                % Set the directory name in the GUI
                set(dirDisplay,'String',renamerPathName);

                % Perform a count of the files:
                numPLAN = 0;
                numDOSE = 0;
                numSTRUCT = 0;
                
                % Change directory:
                cd(renamerPathName);                

                files = dir('*.dcm');

                for i = 1:length(files)
                    dcm = dicominfo(files(i).name);
                    
                    if strcmp(dcm.Modality,'RTDOSE')
                        numDOSE = numDOSE + 1;
                    elseif strcmp(dcm.Modality,'RTPLAN')
                        numPLAN = numPLAN + 1;
                    elseif strcmp(dcm.Modality,'RTSTRUCT')
                        numSTRUCT = numSTRUCT + 1;
                    end
                end

                % Display the count
                set(countDisplay,'String',sprintf('Directory contains %d RTSTRUCT, %d RTPLAN and %d RTDOSE',numSTRUCT,numPLAN,numDOSE));
                
                % Enable Button:
                set(renameBut,'Enable','on');

                
                % Change directory to original:
                cd(currentFolder);
                
            else
            	% Warn the user
                set(dirDisplay,'String','Not a valid directory');
                set(countDisplay,'String','');
                set(renameBut,'Enable','off');
            end
        else

            % Warn the user
            set(dirDisplay,'String','Not a valid directory');
            set(countDisplay,'String','');
            set(renameBut,'Enable','off');
        end
        
    end

    function runRenamer(source,eventdata)
        
        cd(renamerPathName);
        
        set(renameBut,'String','Renaming In Progress: Please Wait ...');
        set(renameBut,'Enable','off');
        
        drawnow update;
        
        includeLastName = 0; % Patient Last Name
        includeFirstName = 0; % Patient First Name
        includeMRN = 0; % Patient MRN
        includePlanName = 0; % Water Phantom, etc.
        includeMachineName = 0; % Varian 21iX 703, etc.
        includeBeamName = 0; % 10x10, C-shape, Test 5.7, etc.
        includeBeamType = 0; % STATIC, STEP-AND-SHOOT, etc.
        includeRadiationType = 0; % PHOTON, ELECTRON, etc.
        includeEnergy = 0; % 6MV, 12MeV, etc.
        includeGantryAngle = 0; % 0deg, 180deg
        includeBeamModifier = 0; % OPEN, STANDARD-45-OUT, ??-60-IN, etc.
        includeMLC = 0; % MLCs, NOMLCs
        
        %%%% Get checkbox values %%%%
        if (get(boxLastName,'Value') == 3); includeLastName = 1; end
        if (get(boxFirstName,'Value') == 3); includeFirstName = 1; end
        if (get(boxMRN,'Value') == 3); includeMRN = 1; end
        if (get(boxPlanName,'Value') == 3); includePlanName = 1; end
        if (get(boxMachineName,'Value') == 3); includeMachineName = 1; end
        if (get(boxBeamName,'Value') == 3); includeBeamName = 1; end
        if (get(boxBeamType,'Value') == 3); includeBeamType = 1; end
        if (get(boxRadiationType,'Value') == 3); includeRadiationType = 1; end
        if (get(boxEnergy,'Value') == 3); includeEnergy = 1; end
        if (get(boxGantryAngle,'Value') == 3); includeGantryAngle = 1; end
        if (get(boxBeamModifier,'Value') == 3); includeBeamModifier = 1; end
        if (get(boxMLC,'Value') == 3); includeMLC = 1; end
    
        %%%% Overwrite current names to a random sequence of numbers %%%% 
        % This prevents issues associated with running this program twice in a row

        % Identify DICOM TYPE and store in 'files'
        files = dir('*.dcm');
        base = round(1000000*now);
        for i = 1:length(files)
            dcm = dicominfo(files(i).name);
            movefile(files(i).name, sprintf('%s_%d.dcm', dcm.Modality, base + i));
        end
        
        %%%% Identify DICOM-RT DOSE and PLAN files in directory %%%%
        % Identify DICOM TYPE and store in 'files'
        files = dir('*.dcm');
        for i = 1:length(files)
            dcm = dicominfo(files(i).name);
            
            files(i).Modality = dcm.Modality;
            
            % THE RTDOSE file has a 'ReferencedRTPlanSequence' identifier that
            % contains the SOPInstanceUID for the appropriate corresponding RTPLAN
            % file. We will store these and use them to identify pairs.
            
            % THE RTPLAN file has a 'ReferencedStructureSetSequence' identifier that
            % contains the SOPInstanceUID for the appropriate corresponding
            % RTSTRUCT file. We will store these and use them to identify pairs.
                        
            if strcmp(dcm.Modality,'RTDOSE')
                try
                    files(i).pID = dcm.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
                catch 
                    files(i).pID = -1;
                end
            elseif strcmp(dcm.Modality,'RTPLAN')
                files(i).pID = dcm.SOPInstanceUID;
                try
                    files(i).sID = dcm.ReferencedStructureSetSequence.Item_1.ReferencedSOPInstanceUID;
                catch
                    files(i).sID = -1;
                end
            elseif strcmp(dcm.Modality,'RTSTRUCT')
                files(i).sID = dcm.SOPInstanceUID;
            end 
              
        end
        
        %%%% Match RTPLAN and RTDOSE based on IDs %%%%
        for i = 1:length(files)
            
            % Match each RTDOSE with an RTPLAN file
            if strcmp(files(i).Modality,'RTDOSE')
                thisID = files(i).pID;
                 
                for j = 1:length(files)
                    if j ~= i
                        thatID = files(j).pID;
                        %check if id's are the same, and that the partner is an RTPLAN
                        if strcmp(thisID,thatID) && strcmp(files(j).Modality,'RTPLAN')
                            files(i).partner_pID = j;
                            %set the RTPlans partners
                            files(j).partner_pID = i;
                        end
                    end
                end
            end
        end
        
        %%%% Match RTSTRUCT and RTPLAN based on IDs %%%%
        for i = 1:length(files)
            
        % Match each RTPLAN with an RTSTRUCT file
            if strcmp(files(i).Modality,'RTPLAN')
                thisID = files(i).sID;
                 
                for j = 1:length(files)
                    if j ~= i
                        thatID = files(j).sID;
                        % check if id's are the same, and that the partner
                        % is an RTSTRUCT
                        if strcmp(thisID,thatID) && strcmp(files(j).Modality,'RTSTRUCT')
                            files(i).partner_sID = j;
                            %set the RTPlans partners
                            files(j).partner_sID = i;
                        end
                    end
                end
            end
        end
        
        
        %%%% Go through DOSE files and create new filenames %%%%
        for i = 1:length(files)
            if strcmp(files(i).Modality,'RTDOSE')
                if files(i).pID == -1
                    % There is no plan for this RT-DOSE File. Give generic
                    % name
                    files(i).Filename = sprintf('RTDOSE_NOPLAN_%d',i);
                else
                    
                    % Get beam number from DICOM RT DOSE
                    dcmDose = dicominfo(files(i).name);
                    try
                        files(i).beamNum = dcmDose.ReferencedRTPlanSequence.Item_1.ReferencedFractionGroupSequence.Item_1.ReferencedBeamSequence.Item_1.ReferencedBeamNumber;
                    catch
                        files(i).beamNum = 0;
                    end
                        
                    % Open DICOM RT PLAN for this DICOM RT DOSE file
                    pID = files(i).partner_pID;
                    dcmPlan = dicominfo(files(pID).name);

                    % Gather parameters from DICOM-RT PLAN that don't
                    % require beam number
                    files(i).TPS = dcmPlan.Manufacturer;
                    try
                        files(i).PlanName = dcmPlan.RTPlanLabel;
                    catch
                        files(i).PlanName = dcmPlan.RTPlanName;
                    end
                    try
                        files(i).LastName = dcmPlan.PatientName.FamilyName;
                    catch
                        files(i).LastName = '';
                    end
                    try
                        files(i).FirstName = dcmPlan.PatientName.GivenName;
                    catch
                        files(i).FirstName = '';
                    end
                    files(i).MRN = dcmPlan.PatientID;
                    files(i).Time = dcmPlan.RTPlanTime;
                    
                    % Begin constructing filename
                    file_rtdose = 'RTDOSE';
                    if includeLastName == 1
                        file_rtdose = sprintf('%s_%s',file_rtdose, files(i).LastName);
                    end
                    if includeFirstName == 1
                        file_rtdose = sprintf('%s_%s',file_rtdose, files(i).FirstName);
                    end
                    if includeMRN == 1
                        file_rtdose = sprintf('%s_%s',file_rtdose, files(i).MRN);
                    end
                    if includePlanName == 1
                        file_rtdose = sprintf('%s_%s',file_rtdose, files(i).PlanName);
                    end

                    % In an earlier version, it was assumed that the beam number in the
                    % DICOM RT DOSE corresponded to the same item number in the DICOM
                    % RT PLAN BeamSequence. This turns out not to be true if beams are
                    % deleted during the planning process. The true corresponding field
                    % is plan.BeamSequence.BeamNumber. We will need to search for this:

                    for j = 1:length(fieldnames(dcmPlan.BeamSequence))
                        itemName = ['Item_' num2str(round(j))];

                        % Hello. Is this the beam you're looking for?
                        if dcmPlan.BeamSequence.(itemName).BeamNumber == files(i).beamNum

                            files(i).MachineName = dcmPlan.BeamSequence.(itemName).TreatmentMachineName;
                            files(i).BeamName = dcmPlan.BeamSequence.(itemName).BeamName;
                            files(i).BeamType = dcmPlan.BeamSequence.(itemName).BeamType;
                            files(i).RadiationType = dcmPlan.BeamSequence.(itemName).RadiationType;
                            files(i).Energy = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.NominalBeamEnergy;
                            files(i).X1 = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(1);
                            files(i).X2 = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions(2);
                            files(i).Y1 = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(1);
                            files(i).Y2 = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(2);
                            files(i).GantryAngle = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.GantryAngle;
                            files(i).IsocenterPosition = dcmPlan.BeamSequence.(itemName).ControlPointSequence.Item_1.IsocenterPosition;
                            if dcmPlan.BeamSequence.(itemName).NumberOfWedges > 0
                                files(i).BeamModifier = sprintf('%s-%s',dcmPlan.BeamSequence.(itemName).WedgeSequence.Item_1.WedgeType, dcmPlan.BeamSequence.(itemName).WedgeSequence.Item_1.WedgeID);
                            else
                                files(i).BeamModifier = 'OPEN';
                            end
                            try
                                files(i).MLC = dcmPlan.BeamSequence.(itemName).BeamLimitingDeviceSequence.Item_3.RTBeamLimitingDeviceType;
                            catch exception
                                files(i).MLC = 'NO-MLC';
                            end

                            if includeMachineName == 1
                                file_rtdose = sprintf('%s_%s',file_rtdose, files(i).MachineName);
                            end
                            % Create the new file names for RTPLAN and RTDOSE
                            if includeBeamName == 1
                                file_rtdose = sprintf('%s_%s',file_rtdose, files(i).BeamName);
                            end       
                            if includeBeamType == 1
                                file_rtdose = sprintf('%s_%s',file_rtdose, files(i).BeamType);
                            end
                            if includeRadiationType == 1
                                file_rtdose = sprintf('%s_%s',file_rtdose, files(i).RadiationType);
                            end
                            if includeEnergy == 1
                                if strcmp(files(i).RadiationType,'PHOTON')
                                    file_rtdose = sprintf('%s_%sMV',file_rtdose, num2str(files(i).Energy));
                                elseif strcmp(files(i).RadiationType,'ELECTRON')
                                    file_rtdose = sprintf('%s_%sMeV',file_rtdose, num2str(files(i).Energy));
                                end        
                            end
                            if includeGantryAngle == 1
                                file_rtdose = sprintf('%s_%sdeg',file_rtdose, num2str(files(i).GantryAngle));
                            end
                            if includeBeamModifier == 1
                                file_rtdose = sprintf('%s_%s',file_rtdose, files(i).BeamModifier);
                            end
                            if includeMLC == 1
                                file_rtdose = sprintf('%s_%s',file_rtdose, files(i).MLC);
                            end
                            
                        end
                        
                        % Remove slashes:
                        file_rtdose(regexp(file_rtdose,'[\,/]')) = [];
                        files(i).Filename = file_rtdose;
                    end
                end
            end    
        end
        
        %%%% Go through RTPLAN files and create new filenames %%%
        for i = 1:length(files)
            if strcmp(files(i).Modality,'RTPLAN')
        
                dcmPlan = dicominfo(files(i).name);
                
                files(i).TPS = dcmPlan.Manufacturer;
                try
                    files(i).PlanName = dcmPlan.RTPlanLabel;
                catch
                    files(i).PlanName = dcmPlan.RTPlanName;
                end
                try
                    files(i).LastName = dcmPlan.PatientName.FamilyName;
                catch
                    files(i).LastName = '';
                end
                try
                    files(i).FirstName = dcmPlan.PatientName.GivenName;
                catch
                    files(i).FirstName = '';
                end
                files(i).MRN = dcmPlan.PatientID;
                files(i).Time = dcmPlan.RTPlanTime;
                
                file_rtplan = 'RTPLAN';
                if includeLastName == 1
                    file_rtplan = sprintf('%s_%s',file_rtplan, files(i).LastName);
                end
                if includeFirstName == 1
                    file_rtplan = sprintf('%s_%s',file_rtplan, files(i).FirstName);
                end
                if includeMRN == 1
                    file_rtplan = sprintf('%s_%s',file_rtplan, files(i).MRN);
                end
                
                % Force RTPLAN to include Plan Name
                file_rtplan = sprintf('%s_%s',file_rtplan, files(i).PlanName);
                
                % Remove slashes:
                file_rtplan(regexp(file_rtplan,'[\,/]')) = [];
                files(i).Filename = file_rtplan;
            end
        end
        
        %%%% Go through RTSTRUCT files and create new filenames %%%
        for i = 1:length(files)
            if strcmp(files(i).Modality,'RTSTRUCT')
        
                % Is there a plan for this RTSTRUCT?
                sID = files(i).partner_sID;
                if isempty(sID)
                    % There is no plan for this RTSTRUCT
                    files(i).Filename = sprintf('RTSTRUCT_NOPLAN_%d',i);
                else
                   
                    % Open the RTPLAN for this RTSTRUCT
                    dcmPlan = dicominfo(files(sID).name);                

                    files(i).TPS = dcmPlan.Manufacturer;
                    if strcmp(files(i).TPS,'Varian Medical Systems')
                        files(i).PlanName = dcmPlan.RTPlanLabel;
                    else
                        files(i).PlanName = dcmPlan.RTPlanName;
                    end
                    try
                        files(i).LastName = dcmPlan.PatientName.FamilyName;
                    catch
                        files(i).LastName = '';
                    end
                    try
                        files(i).FirstName = dcmPlan.PatientName.GivenName;
                    catch
                        files(i).FirstName = '';
                    end
                    files(i).MRN = dcmPlan.PatientID;
                    files(i).Time = dcmPlan.RTPlanTime;

                    file_rtplan = 'RTSTRUCT';
                    if includeLastName == 1
                        file_rtplan = sprintf('%s_%s',file_rtplan, files(i).LastName);
                    end
                    if includeFirstName == 1
                        file_rtplan = sprintf('%s_%s',file_rtplan, files(i).FirstName);
                    end
                    if includeMRN == 1
                        file_rtplan = sprintf('%s_%s',file_rtplan, files(i).MRN);
                    end

                    % Force RTPLAN to include Plan Name
                    file_rtplan = sprintf('%s_%s',file_rtplan, files(i).PlanName);

                    files(i).Filename = file_rtplan;
                end
            end
        end
                
        %%%% Diagnostics %%%%
        % It is possible that a renaming scheme will result in duplicate
        % names. Let's check for this and warn the user so that we don't
        % accidentally overwrite files.
        
        % Possibility 1: Two exports from same plan. Append export time.
        for i = 1:length(files)
        	if strcmp(files(i).Modality,'RTPLAN') || strcmp(files(i).Modality,'RTSTRUCT')
                for j = 1:length(files)
                    if i ~= j
                        if strcmp(files(i).Filename,files(j).Filename)

                            h = msgbox('Under the selected renaming parameters, some of the DICOM-RT STRUCT, PLAN and DOSE files would have duplicate names. This has been resolved by appending a time-stamp to the filenames.');
                            waitfor(h);


                            for k = 1:length(files)
                                files(k).Filename = sprintf('%s_%s',files(k).Filename, files(k).Time);
                            end 

                        end
                    end
                end
            end
        end
       
        % Possibility 2: Two different beams have the same name. Append
        % beam number.
        for i = 1:length(files)
            if strcmp(files(i).Modality,'RTDOSE')
                for j = 1:length(files)
                    if i ~= j
                        if strcmp(files(i).Filename,files(j).Filename)

                            h = msgbox('Under the selected renaming parameters, some of the DICOM-RT DOSE files would have duplicate names. This has been resolved by appending the beam number to the filenames.');
                            waitfor(h);
                            
                            for k = 1:length(files)
                                if strcmp(files(k).Modality,'RTDOSE')
                                    files(k).Filename = sprintf('%s_%d',files(k).Filename, files(k).beamNum);
                                end
                            end 
                        end
                    end
                end
            end
        end
                
        %%%% Rename the files %%%%
        for i = 1:length(files)
            movefile(files(i).name, sprintf('%s.dcm',files(i).Filename));
        end
        
        % Change directory to original:
        cd(currentFolder);
        set(renameBut,'String','Rename Files');
        set(renameBut,'Enable','on');

        h = msgbox('Renaming of DICOM files was successful.');
        waitfor(h);

    end
    
end