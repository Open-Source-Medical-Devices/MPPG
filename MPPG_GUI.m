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

guiCtrl = figure('Resize','on','Units','pixels','Position',[100 300 500 300],'Visible','off','MenuBar','none','name','MPPG V1.0','NumberTitle','off','UserData',0);
measOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Measured Dose File','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0 .9 .4 .1],'callback','ClickedCallback','Callback', {@getMeasFile});
calcOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Calculated Dose File','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0.5 .9 .4 .1],'callback','ClickedCallback','Callback', {@getCalcFile});
testRunBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.9,'Units','normalized','Position',[0 .0 .5 .1],'callback','ClickedCallback','Callback', {@runTests});

measLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .8 .45 .1]);
calcLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.5 .8 .45 .1]);

gammaLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Gamma calculation parameters:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0 .65 .5 .1]);
doseErLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Dose error threshold (% max):','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .49 .5 .1]);
posErLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Position error threshold (mm):','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .39 .5 .1]);

doseErEdit = uicontrol('Parent',guiCtrl,'Style','edit','String','3','BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.5 .5 .25 .1],'Callback',{@getDoseErThresh});
posErEdit = uicontrol('Parent',guiCtrl,'Style','edit','String','3','BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.5 .39 .25 .1],'Callback',{@getPosErThresh});

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);

set(guiCtrl,'Visible','on');

measData = []; %global
calcData = []; %global
cx = []; cy = []; cz = []; %global

function getMeasFile(source,eventdata)
    [measFileName measPathName] = uigetfile({'*.ASC';'*.*'},'Select Image','MultiSelect','off');    
    
    disp('Parsing W2CAD file...');
    %open and parse the measurement file
    measData = omniproAccessTOmat([measPathName measFileName]);
    
    set(measLabel,'String',measFileName);
end

function getCalcFile(source,eventdata)
    [calcFileName calcPathName] = uigetfile({'*.dcm';'*.*'},'Select Image','MultiSelect','off');
        
    disp('Opening dicom file...');
    %open dicom file    
    [ cx, cy, cz, calcData ] = dicomDoseTOmat([calcPathName calcFileName], [0 -25 0]); %should not have to hard code this, need to FIX\
    %offset value represents the offset from the dicom origin to the users chosen isocenter in the plane for the given beam, or other way around
    %prompt the user for the offset values
    
    set(calcLabel,'String',calcFileName);
end

function runTests(source,eventdata)
    
    %loop through each profile in measData
    for i = 1:measData.Num   
        mx = measData.BeamData(i).X/10; %convert to cm
        my = measData.BeamData(i).Y/10; %convert to cm
        mz = measData.BeamData(i).Z/10; %convert to cm
        md = measData.BeamData(i).Value; %measured dose profile
        mns = measData.BeamData(i).NumPoints; %measured number of samples
         
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
        vOut = VerifyData(regMeas, regCalc, distThr, doseThr, 1);

        %summarize results for this test
        
%         figure; plot(indep,cd); hold all;
%         plot(indep,md);
%         title(measData.BeamData(i).DataType);
%         xlabel('position (cm)');  

        %tabular format output
        
        %pdfs of the graphs from matlab
        
        %way to flip through output graphs
        
    end
    
    %summarize results for all tests
    
    
end

%==============================================
%==============================================

end