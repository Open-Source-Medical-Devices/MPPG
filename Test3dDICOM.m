clear all;
close all;

% Test out the reading and processesing of a Dicom File

filename = '15x15_UO_000_ISO_000.dcm';
filename = '../15x15_Dose_OFFSET_1p22_-65p29_-233p00.dcm';

[ dcm_x, dcm_y, dcm_z, dcm_dose ] = dicomDoseTOmat(filename, [ 1.22 -65.29 233.0 ]/10);

% I want a plane at: x = 0, y = 0 and z = 0
xloc = 0;
yloc = 5;
zloc = 0;

figure(1)

subplot(1,3,1);
DOSE2D = getPlaneAt(dcm_x,dcm_y,dcm_z,dcm_dose,xloc,'x');
imagesc(dcm_z,dcm_y,DOSE2D)

subplot(1,3,2);
DOSE2D = getPlaneAt(dcm_x,dcm_y,dcm_z,dcm_dose,yloc,'y');
imagesc(dcm_z,dcm_x,DOSE2D)

subplot(1,3,3);
DOSE2D = getPlaneAt(dcm_x,dcm_y,dcm_z,dcm_dose,zloc,'z');
imagesc(dcm_z,dcm_y,DOSE2D)

%% Test out the reading and processing of Acsii files from OmniPro

% Read one file from OmniPro and Create Structure
filename = 'P06_Open_OPD_2.ASC';
omniproStruct = omniproAccessTOmat(filename);

% Read another file and add to previous structure
filename = 'P06_Open_OPP.ASC';
omniproStruct = omniproAccessTOmat(filename,omniproStruct);

figure(2);
% Read Jeni's file from OmniPro and Create Structure
filename = 'P06OPN_WISC.ASC';
omniproStruct2 = omniproAccessTOmat(filename);

% Get OPD (Open field PDD) for 10x10 field (100 mm by 100 mm)
[ x, y, z, d ] = getOmniproAccessData(omniproStruct2,'OPD', [100 100]);
plot(z,d,'r')
hold off;

%% Let's try to compare some measured profiles and some Eclipse data

% I want a plane at: x = 0, y = 0 and z = 0
xloc = 0; % cm
yloc = 20; % cm
zloc = 0; % cm

figure(3)

% Starting with X, let's do a crossline profile 
subplot(1,3,1);

% Get Eclipse Profile
DOSE1D = getProfileAt(dcm_x,dcm_y,dcm_z,dcm_dose,yloc,zloc,'x');
DOSE1D = convertTOrelative(dcm_x,DOSE1D,0);

% Get Omnipro Data
[ x, y, z, d ] = getOmniproAccessData(omniproStruct,'OPP', [150 150],10*yloc,'X');

plot(dcm_x,DOSE1D,'k',x/10,d,':b')

% Next is Y, Let's do the PDD
subplot(1,3,2);

% Get Eclipse Profile
DOSE1D = getProfileAt(dcm_x,dcm_y,dcm_z,dcm_dose,xloc,zloc,'y');
DOSE1D = convertTOrelative(dcm_y,DOSE1D,'max');

% Get Omnipro Data
[ x, y, z, d ] = getOmniproAccessData(omniproStruct,'OPD', [150 150]);

plot(dcm_y,DOSE1D,'k',z/10,d,':b')

% Finally Z, let's get the inline profile

subplot(1,3,3);

% Get Eclipse Profile
DOSE1D = getProfileAt(dcm_x,dcm_y,dcm_z,dcm_dose,xloc,yloc,'z');
DOSE1D = convertTOrelative(dcm_z,DOSE1D,0);

% Get Omnipro Data
[ x, y, z, d ] = getOmniproAccessData(omniproStruct,'OPP', [150 150],50,'Y');

plot(dcm_z,DOSE1D,'k',y/10,d,':b')
