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

guiCtrl = figure('Resize','on','Units','pixels','Position',[100 300 500 300],'Visible','off','MenuBar','none','name','MPPG V1.1','NumberTitle','off','UserData',0);
measOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Measured Dose File','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0 .9 .4 .1],'callback','ClickedCallback','Callback', {@getMeasFile});
calcOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Calculated Dose File','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0.5 .9 .4 .1],'callback','ClickedCallback','Callback', {@getCalcFile});
testRunBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.9,'Units','normalized','Position',[0 .0 .5 .1],'callback','ClickedCallback','Callback', {@runTests});

measLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .8 .45 .1]);
calcLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.5 .8 .45 .1]);

gammaLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Gamma calculation parameters:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0 .65 .5 .1]);
doseErLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Dose error threshold (% max):','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .49 .5 .1]);
posErLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Position error threshold (mm):','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .39 .5 .1]);

doseErEdit = uicontrol('Parent',guiCtrl,'Style','edit','String','2','BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.5 .5 .25 .1],'Callback',{@getDoseErThresh});
posErEdit = uicontrol('Parent',guiCtrl,'Style','edit','String','2','BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.5 .39 .25 .1],'Callback',{@getPosErThresh});

% panel to contain output checkboxes
guiPanel = uipanel('Parent',guiCtrl,'Title','Select Output Options: ','Units','normalized','Position',[0 .15 1 .2]);

% checkbox to generate a summary table
makeTable = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','on','String','Table Out','Min',0,'Max',3,'Value',3,'Units','normalized','Position',[.0 .8 .8 .25]);

% checkbox to generate a pdf of the figures
makePdf = uicontrol('Parent',guiPanel,'Style','checkbox','Enable','on','String','PDF Out','Min',0,'Max',3,'Value',3,'Units','normalized','Position',[.0 .5 .8 .25]);

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);

set(guiCtrl,'Visible','on');

measFileName = []; %global, used for output filenames and graph titles
doseFileName = []; %global, used for output filenames and graph titles
measData = []; %global
calcData = []; %global
cx = []; cy = []; cz = []; %global

function getMeasFile(source,eventdata)
    mpath.measPathName = '.';
    if exist('mpath.mat','file')
        mpath = load('mpath.mat');
    end
    [measFileName measPathName] = uigetfile({'*.ASC';'*.*'},'Select Measured Data','MultiSelect','off',mpath.measPathName );    
    save('mpath.mat','measPathName');

    disp('Parsing W2CAD file...');
    %open and parse the measurement file
    measData = omniproAccessTOmat([measPathName measFileName]);
    
    set(measLabel,'String',measFileName);
end

function getCalcFile(source,eventdata)
    dpath.dosePathName = '.';
    if exist('dpath.mat','file')
        dpath = load('dpath.mat');  
        if  dpath.dosePathName == 0
             dpath.dosePathName = '.';
        end
    end    
    [doseFileName, dosePathName] = uigetfile({'*.dcm';'*.*'},'Select DICOM-RT DOSE File','MultiSelect','off',dpath.dosePathName);
    save('dpath.mat','dosePathName');
    
    ppath.planPathName = '.';
    if exist('ppath.mat','file')
        ppath = load('ppath.mat');
        if  ppath.planPathName == 0
             ppath.planPathName = '.';
        end        
    end  
    [planFileName, planPathName] = uigetfile({'*.dcm';'*.*'},'Select DICOM-RT PLAN File','MultiSelect','off',ppath.planPathName);
    save('ppath.mat','planPathName');

    disp('Opening DICOM-RT DOSE and PLAN files...');
%    % Extract plan data and offset from DICOM-RT file 
%    [ offset, planData ] = dicomPlanProcessor([dosePathName doseFileName],[planPathName planFileName]);

    % Extract Dose Grid
    [ cx, cy, cz, calcData ] = dicomDoseTOmat([dosePathName doseFileName], [0 -30.09 0]); %should not have to hard code this, need to FIX\
    %offset value represents the offset from the dicom origin to the users chosen isocenter in the plane for the given beam, or other way around
    %prompt the user for the offset values
    
    set(calcLabel,'String',doseFileName);
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
        [regMeas regCalc sh] = RegisterData([indep md], [indep cd]);


        %compute gamma
        distThr = sscanf(get(posErEdit,'String'),'%f');
        doseThr = sscanf(get(doseErEdit,'String'),'%f');
        [gam, distMinGam, doseMinGam] = VerifyData(regMeas, regCalc, distThr, doseThr, 0);

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