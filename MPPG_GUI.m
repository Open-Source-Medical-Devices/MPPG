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

guiCtrl = figure('Resize','on','Units','pixels','Position',[25 75 500 650],'Visible','off','MenuBar','none','name','MPPG V1.0','NumberTitle','off','UserData',0);
measOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Measured Dose File','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .9 .3 .05],'callback','ClickedCallback','Callback', {@getMeasFile});
calcOpenBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Get Calculated Dose File','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0.5 .9 .3 .05],'callback','ClickedCallback','Callback', {@getCalcFile});
testRunBut = uicontrol('Parent',guiCtrl,'Style','pushbutton','String','Run','FontUnits','normalized','FontSize',.7,'Units','normalized','Position',[0 .0 .5 .05],'callback','ClickedCallback','Callback', {@runTests});

measLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[0 .8 .45 .1]);
calcLabel = uicontrol('Parent',guiCtrl,'Style','text','String','None Selected','HorizontalAlignment','left','FontUnits','normalized','FontSize',.2,'Units','normalized','Position',[.5 .8 .45 .1]);

gammaLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Gamma calculation parameters:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[0 .55 .5 .05]);
doseErLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Dose error threshold (% max):','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .50 .5 .05]);
posErLabel = uicontrol('Parent',guiCtrl,'Style','text','String','Position error threshold (mm):','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[0 .40 .5 .05]);

doseErEdit = uicontrol('Parent',guiCtrl,'Style','edit','String','3','BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.5 .5 .25 .05],'Callback',{@getDoseErThresh});
posErEdit = uicontrol('Parent',guiCtrl,'Style','edit','String','3','BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.5 .4 .25 .05],'Callback',{@getPosErThresh});

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiCtrl,'Color',defaultBackground);

set(guiCtrl,'Visible','on');

measData = []; %global
calcData = []; %global

function getMeasFile(source,eventdata)
    [measFileName measPathName] = uigetfile({'*.ASC';'*.*'},'Select Image','MultiSelect','off');
    set(measLabel,'String',measFileName);
    
    disp('Parsing W2CAD file...');
    %open and parse the measurement file
    measData = omniproAccessTOmat([measPathName measFileName]);
    
end

function getCalcFile(source,eventdata)
    [calcFileName calcPathName] = uigetfile({'*.dcm';'*.*'},'Select Image','MultiSelect','off');
    set(calcLabel,'String',calcFileName);
    
    disp('Opening dicom file...');
    %open dicom file
    info = dicominfo([calcPathName calcFileName]);    
    Y = dicomread(info);
    calcData = squeeze(Y(:,:,1,:));    
    
end

function runTests(source,eventdata)
    
    %loop through each profile in measData
    
        %extract 1D profile from 3D calculated dose data

        %interpolate

        %tweak registration

        %compute gamma

        %summarize results for this test
    
    %summarize results for all tests
    
    
end

%==============================================
%==============================================


%==============================================
%==============================================


end