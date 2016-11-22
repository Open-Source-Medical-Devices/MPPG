function MPPG_GUI

% MPPG_GUI
%   Top Level GUI for comparing 1D dose profiles between 
%   water tank measured data and calculated dose data.
%   Used in the MPPG for treatment planning system verification.
%
%   Instructions:
%   i. Measured data should be exported as W2CAD files.
%   ii. Calculated dose should be exported from the treatment plannning system.
%   1. Choose the measured data file.
%   2. Choose the dicom dose file.
%   3. Input gamma calculation parameters.
%   4. Click Run to compare calculated to measured data.

% github.com/open-source-medical-devices/mppg


clear all;
close all;

%Add current directory to matlab search path
if ~isdeployed %if this is not an EXE instance of the program, then add path
    addpath(pwd);
end

% MPPG Window
guiCtrl = figure('Resize','on','Units','pixels','Position',[200 300 700 500],'Visible','off','MenuBar','none','name','MPPG Profile Comparison Tool V2.3','NumberTitle','off','UserData',0);

% Buttons for opening measurement and dose
measOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Measured Dose File','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.05 .89 .4 .1],'callback','ClickedCallback','Callback', {@getMeasFile});
calcOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Calculated Dose File','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0.55 .89 .4 .1],'callback','ClickedCallback','Callback', {@getCalcFile});

% Create file and Status Labels
measFileLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Measurement File: None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .83 .95 .05]);
measStatusLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Measurement Status: None','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .78 .95 .05]);
calcFileLabel = uicontrol('Parent',guiCtrl,'Style','text','String','DICOM-RT DOSE File: None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .73 .95 .05]);
calcStatusLabel = uicontrol('Parent',guiCtrl,'Style','text','String','DICOM Status: None','HorizontalAlignment','left','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[.02 .58 .95 .15]);
offsetLabel = uicontrol('Parent',guiCtrl,'Style','text','String','DICOM Offset: None','HorizontalAlignment','center','FontUnits','normalized','FontSize',.6,'FontWeight','bold','Units','normalized','Position',[.02 .53 .95 .05]);

% Create edit DICOM Offset Button
offsetBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Edit DICOM Offset ...','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0.77 .54 .2 .05],'callback','ClickedCallback','Callback', {@editOffset});

%%-%% Create Panels for Options
NormPanel = uibuttongroup('Parent',guiCtrl,'Title','Depth-Dose Normalization Options: ','Units','normalized','Position', [.02 .33 .42 .19],'SelectionChangeFcn',{@toggleYedit});
NormPanel2 = uibuttongroup('Parent',guiCtrl,'Title','Profile Normalization Options: ','Units','normalized','Position', [.45 .33 .53 .19],'SelectionChangeFcn',{@toggleXZedit});
gammaPanel = uipanel('Parent',guiCtrl,'Title','Gamma Analysis Options: ','Units','normalized','Position',    [.02 .13 .72 .19]);
OutputPanel = uipanel('Parent',guiCtrl,'Title','Output Options: ','Units','normalized','Position',  [.75 .13 .23 .19]);

%-% Depth-Dose Normalization Options 
 
% Create two radio buttons in NormPanel, which will hold the PDD options
dmaxButPDD = uicontrol('Style','radiobutton','String','<html>D<sub>max</sub></html>','Units','normalized','Position',[.45 .57 .24 .35],'parent',NormPanel,'HandleVisibility','off','FontUnits','normalized','FontSize',.45);
depthButPDD = uicontrol('Style','radiobutton','String','Depth (Y)','Units','normalized','Position',[.69 .57 .3 .35],'parent',NormPanel,'HandleVisibility','off','FontUnits','normalized','FontSize',.45);
 
% Create some labels
normToPDD = uicontrol('Parent',NormPanel,'Style','text','String',sprintf('Normalize Depth Dose Profile To:'),'HorizontalAlignment','left','FontUnits','normalized','FontSize',.45,'Units','normalized','Position',[.02 .57 .37 .35]);
DepthYPDD = uicontrol('Parent',NormPanel,'Style','text','String','Depth (Y) =','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .11 .27 .3]);
DepthPosPDD = uicontrol('Parent',NormPanel,'Style','edit','Enable','off','String','10.0','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.33 .10 .24 .35]);
DepthCmPDD = uicontrol('Parent',NormPanel,'Style','text','String','cm','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.6 .11 .2 .3]);

%-% Profile Normalization Options 

% Create two radio buttons in NormPanel2, which will hold the profile options
dmaxButProf = uicontrol('Style','radiobutton','String','<html>D<sub>max</sub></html>','Units','normalized','Position',[.45 .57 .18 .35],'parent',NormPanel2,'HandleVisibility','off','FontUnits','normalized','FontSize',.45);
posButProf = uicontrol('Style','radiobutton','String','Position (X,Z)','Units','normalized','Position',[.65 .57 .33 .35],'parent',NormPanel2,'HandleVisibility','off','FontUnits','normalized','FontSize',.45);
 
% % Create some labels
normToProf = uicontrol('Parent',NormPanel2,'Style','text','String',sprintf('Normalize Inline and Crossline Profiles To:'),'HorizontalAlignment','left','FontUnits','normalized','FontSize',.45,'Units','normalized','Position',[.02 .57 .42 .35]);

CrosslineXProf = uicontrol('Parent',NormPanel2,'Style','text','String','Crossline (X) =','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .09 .30 .3]);
CrosslinePosProf = uicontrol('Parent',NormPanel2,'Style','edit','Enable','off','String','0.0','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.31 .09 .13 .35]);
CrosslineCmProf = uicontrol('Parent',NormPanel2,'Style','text','String','cm','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.46 .09 .08 .3]);

InlineZProf = uicontrol('Parent',NormPanel2,'Style','text','String','Inline (Z) =','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.56 .09 .30 .3]);
InlinePosProf = uicontrol('Parent',NormPanel2,'Style','edit','Enable','off','String','0.0','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.77 .09 .13 .35]);
InlineCmProf = uicontrol('Parent',NormPanel2,'Style','text','String','cm','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.92 .09 .08 .3]);

%-% Gamma Options
doseErLabel = uicontrol('Parent',gammaPanel,'Style','text','String','Dose Diff. (%):','HorizontalAlignment','left','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[.02 .65 .2 .25]);
doseErEdit = uicontrol('Parent',gammaPanel,'Style','edit','String','2','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.23 .6 .12 .35],'Callback',{@getDoseErThresh});
posErLabel = uicontrol('Parent',gammaPanel,'Style','text','String','DTA (mm):','HorizontalAlignment','left','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[.38 .65 .2 .25]);
posErEdit = uicontrol('Parent',gammaPanel,'Style','edit','String','2','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.55 .6 .12 .35],'Callback',{@getPosErThresh});

% Create the button group.
NormLabel = uicontrol('Parent',gammaPanel,'Style','text','String','Dose Analysis:','HorizontalAlignment','left','FontUnits','normalized','FontSize',.65,'Units','normalized','Position',[.02 .15 .3 .25]);
NormButton = uibuttongroup('Parent',gammaPanel,'visible','on','Units','normalized','Position',[.23 .05 .44 .45]);
% Create two radio buttons in the button group.
globalBut = uicontrol('Style','radiobutton','String','Global','Units','normalized','Position',[.05 .05 .44 .9],'parent',NormButton,'HandleVisibility','off','FontUnits','normalized','FontSize',.5);
localBut = uicontrol('Style','radiobutton','String','Local','Units','normalized','Position',[.55 .05 .44 .9],'parent',NormButton,'HandleVisibility','off','FontUnits','normalized','FontSize',.5);

% Create options for thresholds
useThreshold = uicontrol('Parent',gammaPanel,'Style','checkbox','Enable','on','String','Use Threshold?','FontUnits','normalized','FontSize',.5,'Min',0,'Max',3,'Value',0,'Units','normalized','Position',[.71 .6 .28 .35],'Callback',{@toggleThreshold});
thresholdVal = uicontrol('Parent',gammaPanel,'Style','edit','Enable','off','String','10.0','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.78 .14 .12 .35]);
thresholdPct = uicontrol('Parent',gammaPanel,'Style','text','String','%','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.91 .14 .04 .3]);


%-% Checkboxes for Output Options
makeTable = uicontrol('Parent',OutputPanel,'Style','checkbox','Enable','on','String','Create CSV File','FontUnits','normalized','FontSize',.5,'Min',0,'Max',3,'Value',3,'Units','normalized','Position',[.05 .6 .9 .35]);
makePdf = uicontrol('Parent',OutputPanel,'Style','checkbox','Enable','on','String','Create PDF','FontUnits','normalized','FontSize',.5,'Min',0,'Max',3,'Value',3,'Units','normalized','Position',[.05 .15 .9 .35]);

% Run Test Button
testRunBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.8,'Units','normalized','Position',[.1 .02 .8 .1],'callback','ClickedCallback','Callback', {@runTests});

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);
set(guiCtrl,'Visible','on');

measFileName = []; %global, used for output filenames and graph titles
doseFileName = []; %global, used for output filenames and graph titles
dosePathName = []; %global, used for output filenames
measData = []; %global
calcData = []; %global
planData = []; %global
cx = []; cy = []; cz = []; %global

function getMeasFile(source,eventdata)
    
    % Reset name and status
    set(measFileLabel,'String','Measurement File: None Selected');
    set(measStatusLabel,'String','Measurement Status: None');
    
    mpath.measPathName = '.';
    if exist('mpath.mat','file')
        mpath = load('mpath.mat');
        if  mpath.measPathName == 0
             mpath.measPathName = '.';
        end
    end    
    [measFileName measPathName] = uigetfile({'*.ASC';'*.*'},'Select Measured Data','MultiSelect','off',mpath.measPathName );    
    save('mpath.mat','measPathName');

    disp('Parsing W2CAD file...');
    %open and parse the measurement file
    measData = measuredDataTOmat([measPathName measFileName]);
    
    % Create a measurement data status
    numI = 0; % inline
    numC = 0; % crossline
    numP = 0; % pdd
    numO = 0; % other
    for i = 1:measData.Num   
        if strcmp(measData.BeamData(i).AxisType,'X'); numC = numC + 1;
        elseif strcmp(measData.BeamData(i).AxisType,'Y'); numI = numI + 1;
        elseif strcmp(measData.BeamData(i).AxisType,'Z'); numP = numP + 1;
        else numO = numO + 1;
        end
    end
    
    set(measFileLabel,'String',sprintf('Measurement File: %s',measFileName));
    set(measStatusLabel,'String',sprintf('Measurement Status: %d inline, %d crossline, %d depth-dose, and %d other profiles',numI, numC, numP, numO));
end

function getCalcFile(source,eventdata)
    
    % Reset name and status
    set(calcFileLabel,'String','DICOM-RT DOSE File: None Selected');
    set(calcStatusLabel,'String','DICOM Status: None');
    set(offsetLabel,'String', 'DICOM Offset: None');
    
    dpath.dosePathName = '.';
    if exist('dpath.mat','file')
        dpath = load('dpath.mat');  
        if  dpath.dosePathName == 0
             dpath.dosePathName = '.';
        end
    end    
    [doseFileName, dosePathName] = uigetfile({'*.dcm';'*.*'},'Select DICOM-RT DOSE File','MultiSelect','off',dpath.dosePathName);
    save('dpath.mat','dosePathName');
        
    disp('Searching for accompanying DICOM-RT Plan and Structure Set...');
    % Extract plan data and offset from DICOM-RT file 
    [ planData ] = dicomProcessor(dosePathName, doseFileName);

    disp('Opening DICOM-RT Dose...');

    % Extract Dose Grid
    [ cx, cy, cz, calcData ] = dicomDoseTOmat([dosePathName doseFileName], planData.ORIGIN); 
    %offset value represents the offset from the dicom origin to the users chosen isocenter in the plane for the given beam, or other way around
    %prompt the user for the offset values
    
    set(calcFileLabel,'String',sprintf('DICOM-RT DOSE File: %s',doseFileName));
    set(calcStatusLabel,'String',sprintf('DICOM Status: %s',planData.STATUS));
    set(offsetLabel,'String',sprintf('DICOM Offset: (%.3f, %.3f, %.3f)',planData.ORIGIN(1),planData.ORIGIN(2),planData.ORIGIN(3)));
end

function runTests(source,eventdata)
    
    
    
    %loop through each profile in measData
    for i = 1:measData.Num   
        mx = measData.BeamData(i).X; %cm
        my = measData.BeamData(i).Y; %cm
        mz = measData.BeamData(i).Z; %cm
        md = measData.BeamData(i).Value; %measured dose profile
        axs = measData.BeamData(i).AxisType;
        dep = measData.BeamData(i).Depth;
        
%         %extract 1D profile from 3D calculated dose data
%         cd = interp3(cx,cy,cz,calcData,mx,mz,my); %calc'd dose profile
%         
%         %compute independent variable, in cm
%         %Maybe determine if the measurement is diagonal and use indep only in diag case
%         indep = zeros(mns,1);
%         for k = 2:mns
%             %compute distance to next point, general for 3D profiles
%             indep(k) = indep(k-1) + sqrt((mx(k)-mx(k-1))^2 + (my(k)-my(k-1))^2 + (mz(k)-mz(k-1))^2);
%         end

        % Use user preferences to determine normalization location
        if mz(1) ~= mz(end)
            % The depth of the measurement changes, so the profile must
            % have some depth dose component. Normalization based on PDD
            % normalization preferences:
            if get(depthButPDD,'Value')
                normLoc = sscanf(get(DepthPosPDD,'String'),'%f');
            else
                normLoc = 'dmax';
            end
            
            % Set x-label for plots
            norm_dim = 'Y';
            m_xlabel = 'Depth (Y) [cm]';
            
        elseif mx(1) ~= mx(end)
            % The x position of the measurement changes, so the profile must
            % have some crossline profile component. Normalization based
            % on crossline normalization preferences:
            if get(posButProf,'Value')
                normLoc = sscanf(get(CrosslinePosProf,'String'),'%f');
            else
                normLoc = 'dmax';
            end
            
            % Set x-label for plots
            norm_dim = 'X';
            m_xlabel = 'Crossline Position (X) [cm]';
            
        elseif my(1) ~= my(end)
            % The y position of the measurement changes, so the profile must
            % have some inline profile component. Normalization based
            % on inline normalization preferences:
            if get(posButProf,'Value')
                normLoc = sscanf(get(InlinePosProf,'String'),'%f');
            else
                normLoc = 'dmax';
            end
            
            % Set x-label for plots
            norm_dim = 'Z';           
            m_xlabel = 'Inline Position (Z) [cm]';
        end
        
        % Use user preferences to determine threshold choice:
        if get(useThreshold,'Value')
            usrThrs = sscanf(get(thresholdVal,'String'),'%f')/100;
        else
            usrThrs = -1;
        end
           
        [indep, md, cd, cd_ref] = PrepareData(mx, my, mz, md, cx, cy, cz, calcData, normLoc);

        % tweak registration, make this optional, or kick out if sh is large
        % maybe register in 3D?
        [regMeas, regCalc, sh] = RegisterData([indep'  md'], [indep' cd']);


        %compute gamma
        distThr = sscanf(get(posErEdit,'String'),'%f');
        doseThr = sscanf(get(doseErEdit,'String'),'%f');
        if get(globalBut,'Value')
            globAna = true;
        else
        	globAna = false;
        end
        [gam, distMinGam, doseMinGam, gamma_stats] = VerifyData(regMeas, regCalc, distThr, doseThr, globAna, usrThrs, false);

        %summarize results for this test
        if get(makePdf,'Value') == 3
            scrsz = get(0,'ScreenSize');
            figure('Position',[1 + i*20 scrsz(4)/3 scrsz(3)/4 scrsz(4)/2]);            
            
            [~, name, ~] = fileparts(doseFileName);
            plotName = name;  %This will be the name of the pdf that is saved
            name = strrep(name,'_','\_');
            plotTitle = sprintf('%s\n',name);            
            if strcmp(axs,'X');
                plotTitle = sprintf('%sCrossline Profiles at Depth (Y) = %.2f cm, Inline Position (Z) = %.2f cm',plotTitle,mz(1),my(1));
                if strcmp('dmax',normLoc); plotTitle = sprintf('%s\nProfiles normalized at maximum dose location for each profile',plotTitle);
                else plotTitle = sprintf('%s\nProfiles normalized at %s = %.2f cm',plotTitle,norm_dim,normLoc);
                end
            elseif strcmp(axs,'Y')
                plotTitle = sprintf('%sInline Profiles at Depth (Y) = %.2f cm, Crossline Position (X) = %.2f cm',plotTitle,mz(1),mx(1));
                if strcmp('dmax',normLoc); plotTitle = sprintf('%s\nProfiles normalized at maximum dose location for each profile',plotTitle);
                else plotTitle = sprintf('%s\nProfiles normalized at %s = %.2f cm',plotTitle,norm_dim,normLoc);
                end
            elseif strcmp(axs,'Z')
                plotTitle = sprintf('%sDepth-Dose Profiles at Crossline Position (X) = %.2f cm, Inline Position (Z) = %.2f cm',plotTitle,mx(1),my(1));
                if strcmp('dmax',normLoc); plotTitle = sprintf('%s\nProfiles normalized at maximum dose location for each profile',plotTitle);
                else plotTitle = sprintf('%s\nProfiles normalized at %s = %.2f cm',plotTitle,norm_dim,normLoc);
                end
            else 
                plotTitle = sprintf('%sDiagonal Profiles from (%.2f,%.2f,%.2f) to (%.2f,%.2f,%.2f)',plotTitle,mx(1),mz(1),my(1),mx(end),mz(end),my(end));
                if strcmp('dmax',normLoc); plotTitle = sprintf('%s\nProfiles normalized at maximum dose location for each profile',plotTitle);
                else plotTitle = sprintf('%s\nProfiles normalized at %s = %.2f cm',plotTitle,norm_dim,normLoc);
                end
            end                       
            
            dim = [.15 .90 .01 .01];
            str = sprintf('TPS dose at normalization point is %.3f Gy',cd_ref);
            annotation('textbox',dim,'String',str,'FitBoxToText','on','LineStyle','none');
            
            rM_max = max(regMeas(:,1));
            rM_min = min(regMeas(:,1));
            subplot(3,1,1); plot(regMeas(:,1),regMeas(:,2),'b','Linewidth',2); hold all;
            subplot(3,1,1); plot(regCalc(:,1),regCalc(:,2),'r--','Linewidth',2); 
            subplot(3,1,1); plot(regCalc(:,1),usrThrs*ones(size(regCalc(:,1))),'m:','Linewidth',.1)
            hold off;
            xlabel(m_xlabel);
            ylabel('Relative Dose');
            legend('Measured','TPS','Threshold');
            axis([ rM_min rM_max 0 1.15*max( [ max(regCalc(:,2)) max(regMeas(:,2)) ] ) ]);
            title(plotTitle);
            
            subplot(3,1,2); plot(regMeas(:,1),gam,'b','Linewidth',2);
            %ylim([0 1.5]);
            xlabel(m_xlabel);
            ylabel('Gamma');
            text(rM_min+((rM_max-rM_min)/2),1.2,['Pass rate: ' sprintf('%0.1f',gamma_stats(6)) '%'],'BackgroundColor',[.9 .9 .9],'HorizontalAlignment','center');
            axis([ rM_min rM_max 0 1.5 ]);
            
            subplot(3,1,3); plot(regMeas(:,1),distMinGam,'b','Linewidth',2); hold all;
            subplot(3,1,3); plot(regMeas(:,1),doseMinGam,'r--','Linewidth',2); hold off;
            %ylim([0 1.5]);
            xlabel(m_xlabel);
            ylabel('AU');
            legend('distMinGam','doseMinGam');
            axis([ rM_min rM_max 0 1.5 ]);

                       
            if i == 1
                print(gcf, '-dpsc', '-r300', [plotName '.ps']); %save a copy of the image
            else
                print(gcf, '-dpsc', '-append', '-r300', [plotName '.ps']); %save a copy of the image
            end
        end
        
%         figure; plot(indep,cd); hold all;
%         plot(indep,md);
%         title(measData.BeamData(i).DataType);
%         xlabel('position (cm)');  

        %tabular format output
        
        if get(makeTable,'Value') == 3
            outName = 'mppg_out_table.csv';
            if exist(outName,'file') == 2;
                writeHdr = 0;
            else
                writeHdr = 1;
            end
            fptr = fopen(outName,'a');            
            if writeHdr
                fprintf(fptr,'%s,%s,%s,%s,%s,%s,%s,%s,%s\r\n','Measurement Filename','Calculated Filename','Axis','Depth','Max Gamma','Average Gamma','Std Dev Gamma','Passing Rate (%)','Points Above Threshold');
            end
            % measured file name, 
            % calculated filename,
            % scan axis
            % scan depth if applicable
            % max gamma, 
            % mean gamma,
            % std gamma,
            % gamma passing rate
                        
            fprintf(fptr,'%s,%s,%s,%f,%f,%f,%f,%f,%d\r\n',measFileName,doseFileName,axs,dep,gamma_stats(1),gamma_stats(2),gamma_stats(3),gamma_stats(6),gamma_stats(4));
            fclose(fptr);
        end                
        
    end
    
    %summarize results for all tests
    
    
end

function editOffset(source,eventdata)
    % EDITOFFSET Edit DICOM offset and reload DICOM-RT DOSE
    
    set(calcStatusLabel,'String','DICOM Status: None');
    set(offsetLabel,'String', 'DICOM Offset: None');
    
    planData = fncAskForOffset(planData,planData.ORIGIN(1),planData.ORIGIN(2),planData.ORIGIN(3));
    planData.STATUS = 'DICOM offset edited manually by the user.';

    disp('Opening DICOM-RT Dose...');

    % Extract Dose Grid
    [ cx, cy, cz, calcData ] = dicomDoseTOmat([dosePathName doseFileName], planData.ORIGIN); 
    %offset value represents the offset from the dicom origin to the users chosen isocenter in the plane for the given beam, or other way around
    %prompt the user for the offset values
    
    set(calcFileLabel,'String',sprintf('DICOM-RT DOSE File: %s',doseFileName));
    set(calcStatusLabel,'String',sprintf('DICOM Status: %s',planData.STATUS));
    set(offsetLabel,'String',sprintf('DICOM Offset: (%.3f, %.3f, %.3f)',planData.ORIGIN(1),planData.ORIGIN(2),planData.ORIGIN(3)));    

end

function toggleYedit(hObject, eventdata, handles)

    if get(dmaxButPDD,'Value')
        set(DepthPosPDD,'Enable','off');
    else
    	set(DepthPosPDD,'Enable','on');
    end
    
end

function toggleXZedit(hObject, eventdata, handles)
        
    if get(dmaxButProf,'Value')
        set(InlinePosProf,'Enable','off');
        set(CrosslinePosProf,'Enable','off');
    else
        set(InlinePosProf,'Enable','on');
        set(CrosslinePosProf,'Enable','on');
    end
    
end

function toggleThreshold(hObject, eventdata, handles)

    if get(useThreshold,'Value')
        set(thresholdVal,'Enable','on');
    else
    	set(thresholdVal,'Enable','off');
    end
    
end


%==============================================
%==============================================

end