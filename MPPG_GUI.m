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

% MPPG Window
guiCtrl = figure('Resize','on','Units','pixels','Position',[200 300 700 500],'Visible','off','MenuBar','none','name','MPPG V2.0','NumberTitle','off','UserData',0);

% Buttons for opening measurement and dose
measOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Measured Dose File','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.05 .89 .4 .1],'callback','ClickedCallback','Callback', {@getMeasFile});
calcOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Calculated Dose File','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0.55 .89 .4 .1],'callback','ClickedCallback','Callback', {@getCalcFile});

% Create file and Status Labels
measFileLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Measurement File: None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .83 .95 .05]);
measStatusLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Measurement Status: None','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .78 .95 .05]);
calcFileLabel = uicontrol('Parent',guiCtrl,'Style','text','String','DICOM-RT DOSE File: None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.6,'Units','normalized','Position',[.02 .73 .95 .05]);
calcStatusLabel = uicontrol('Parent',guiCtrl,'Style','text','String','DICOM Status: None','HorizontalAlignment','left','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[.02 .58 .95 .15]);
offsetLabel = uicontrol('Parent',guiCtrl,'Style','text','String','DICOM Offset: None','HorizontalAlignment','center','FontUnits','normalized','FontSize',.6,'FontWeight','bold','Units','normalized','Position',[.02 .53 .95 .05]);

%%-%% Create Panels for Options
PDDPanel = uibuttongroup('Parent',guiCtrl,'Title','Depth-Dose Normalization Options: ','Units','normalized','Position', [.02 .33 .46 .19]);
profilePanel = uibuttongroup('Parent',guiCtrl,'Title','Profile Normalization Options: ','Units','normalized','Position',[.52 .33 .46 .19]);
gammaPanel = uipanel('Parent',guiCtrl,'Title','Gamma Analysis Options: ','Units','normalized','Position',    [.02 .13 .46 .19]);
OutputPanel = uipanel('Parent',guiCtrl,'Title','Output Options: ','Units','normalized','Position',  [.52 .13 .46 .19]);

% %-% Depth-Dose Normalization Options 
% 
% % Create two radio buttons in PDDPanel
% dmaxButPDD = uicontrol('Style','radiobutton','String','<html>D<sub>max</sub></html>','Units','normalized','Position',[.48 .55 .25 .35],'parent',PDDPanel,'HandleVisibility','off','FontUnits','normalized','FontSize',.6);
% depthButPDD = uicontrol('Style','radiobutton','String','Depth = ','Units','normalized','Position',[.48 .15 .25 .35],'parent',PDDPanel,'HandleVisibility','off','FontUnits','normalized','FontSize',.6);
% 
% % Create some labels
% normToPDD = uicontrol('Parent',PDDPanel,'Style','text','String',sprintf('Normalize Depth Dose Profile To:'),'HorizontalAlignment','left','FontUnits','normalized','FontSize',.35,'Units','normalized','Position',[.05 .3 .41 .6]);
% inCmPDD = uicontrol('Parent',PDDPanel,'Style','text','String','cm','HorizontalAlignment','left','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[.90 .15 .1 .3]);
% normPosPDD = uicontrol('Parent',PDDPanel,'Style','edit','String','10.0','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.73 .13 .15 .35],'Callback',{@getDoseErThresh});
% 
% %-% Profile Normalization Options 
% 
% % Create two radio buttons in PDDPanel
% dmaxButProf = uicontrol('Style','radiobutton','String','<html>D<sub>max</sub></html>','Units','normalized','Position',[.48 .55 .25 .35],'parent',profilePanel,'HandleVisibility','off','FontUnits','normalized','FontSize',.6,'Callback',{@dmaxButProfClick});
% depthButProf = uicontrol('Style','radiobutton','String','Depth = ','Units','normalized','Position',[.48 .15 .25 .35],'parent',profilePanel,'HandleVisibility','off','FontUnits','normalized','FontSize',.6,'Callback',{@depthButProfClick});
% 
% % Create some labels
% normToProf = uicontrol('Parent',profilePanel,'Style','text','String',sprintf('Normalize Depth Dose Profile To:'),'HorizontalAlignment','left','FontUnits','normalized','FontSize',.35,'Units','normalized','Position',[.05 .3 .41 .6]);
% inCmProf = uicontrol('Parent',profilePanel,'Style','text','String','cm','HorizontalAlignment','left','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[.90 .15 .1 .3]);
% normPosProf = uicontrol('Parent',profilePanel,'Style','edit','String','10.0','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.73 .13 .15 .35],'Callback',{@getDoseErThresh});


%-% Gamma Options
doseErLabel = uicontrol('Parent',gammaPanel,'Style','text','String','Dose Diff. (%):','HorizontalAlignment','left','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[.05 .65 .3 .25]);
posErLabel = uicontrol('Parent',gammaPanel,'Style','text','String','DTA (mm):','HorizontalAlignment','left','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[.57 .65 .3 .25]);
NormLabel = uicontrol('Parent',gammaPanel,'Style','text','String','Dose Analysis:','HorizontalAlignment','left','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[.05 .15 .3 .25]);

% Create the button group.
NormButton = uibuttongroup('Parent',gammaPanel,'visible','on','Units','normalized','Position',[.4 .05 .55 .45]);

% Create two radio buttons in the button group.
globalBut = uicontrol('Style','radiobutton','String','Global','Units','normalized','Position',[.05 .05 .44 .9],'parent',NormButton,'HandleVisibility','off','FontUnits','normalized','FontSize',.6);
localBut = uicontrol('Style','radiobutton','String','Local','Units','normalized','Position',[.55 .05 .44 .9],'parent',NormButton,'HandleVisibility','off','FontUnits','normalized','FontSize',.6);

doseErEdit = uicontrol('Parent',gammaPanel,'Style','edit','String','2','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.35 .6 .15 .35],'Callback',{@getDoseErThresh});
posErEdit = uicontrol('Parent',gammaPanel,'Style','edit','String','2','BackgroundColor','w','FontUnits','normalized','FontSize',.5,'Min',0,'Max',1,'Units','normalized','Position',[.80 .6 .15 .35],'Callback',{@getPosErThresh});

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
measData = []; %global
calcData = []; %global
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
    measData = omniproAccessTOmat([measPathName measFileName]);
    
    % Create a measurement data status
    numI = 0; % inline
    numC = 0; % crossline
    numP = 0; % pdd
    numO = 0; % other
    for i = 1:measData.Num   
        if strcmp(measData.BeamData(i).AxisType,'X'); numC = numC + 1;
        elseif strcmp(measData.BeamData(i).AxisType,'Y'); numI = numI + 1;
        elseif strcmp(measData.BeamData(i).AxisType,'Z'); numP = numP + 1;
        else  numO = numO + 1;
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
        mns = measData.BeamData(i).NumPoints; %measured number of samples
        axs = measData.BeamData(i).AxisType;
        dep = measData.BeamData(i).Depth;
        
        %extract 1D profile from 3D calculated dose data
        cd = interp3(cx,cy,cz,calcData,mx,mz,my); %calc'd dose profile
        
        %compute independent variable, in cm
        %Maybe determine if the measurement is diagonal and use indep only in diag case
        indep = zeros(mns,1);
        for k = 2:mns
            %compute distance to next point, general for 3D profiles
            indep(k) = indep(k-1) + sqrt((mx(k)-mx(k-1))^2 + (my(k)-my(k-1))^2 + (mz(k)-mz(k-1))^2);
        end
                    

        %tweak registration, make this optional, or kick out if sh is large
        %maybe register in 3D?
        [regMeas, regCalc, sh] = RegisterData([indep md], [indep cd]);


        %compute gamma
        distThr = sscanf(get(posErEdit,'String'),'%f');
        doseThr = sscanf(get(doseErEdit,'String'),'%f');
        if get(globalBut,'Value')
            globAna = true;
        else
        	globAna = false;
        end
        [gam, distMinGam, doseMinGam] = VerifyData(regMeas, regCalc, distThr, doseThr, globAna, false);

        %summarize results for this test
        if get(makePdf,'Value') == 3
            figure(100+i);
            if (strcmp(axs,'Z'))
                plotTitle = [measFileName ' ' axs];
            else                
                plotTitle = [measFileName ' ' axs ' ' num2str(dep)];
            end
            plotName = measFileName;            
            
            subplot(3,1,1); plot(regMeas(:,1),regMeas(:,2)); hold all;
            subplot(3,1,1); plot(regCalc(:,1),regCalc(:,2)); hold off;
            xlabel('Position (cm)');
            ylabel('Relative Dose');
            legend('meas','calc');
            title(plotTitle);
            
            subplot(3,1,2); plot(regMeas(:,1),gam);
            ylim([0 1.5]);
            xlabel('Position (cm)');
            ylabel('Gamma');
            
            subplot(3,1,3); plot(regMeas(:,1),distMinGam); hold all;
            subplot(3,1,3); plot(regMeas(:,1),doseMinGam); hold off;
            ylim([0 1.5]);
            xlabel('Position (cm)');
            ylabel('AU');
            legend('distMinGam','doseMinGam');
                       
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
                fprintf(fptr,'%s,%s,%s,%s,%s,%s,%s,%s\r\n','Measurement Filename','Calculated Filename','Axis','Depth','Max Gamma','Average Gamma','Std Dev Gamma','Optimum shift (cm)');
            end
            % measured file name, 
            % calculated filename, 
            % max gamma, 
            % registration offset, 
            % dist error at max gamma, 
            % dose error at max gamma, 
            % pdd, cross, or inline, 
            % position of max gamma              
            fprintf(fptr,'%s,%s,%s,%f,%f,%f,%f,%f\r\n',measFileName,doseFileName,axs,dep,max(gam),mean(gam),std(gam),sh);
            fclose(fptr);
        end                
        
    end
    
    %summarize results for all tests
    
    
end

%==============================================
%==============================================

end