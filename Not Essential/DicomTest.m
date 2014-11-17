%Test dicom read
%clear all;
%close all;
%clc;

calc_f_path = 'E:\\Google Drive\\Medical_Physics\\MPPG\\20140206_MPPG_Calc\\6mv\\';
calc_f_file = '6MV_5.4.dcm';
disp('Reading dicom info...');
info = dicominfo([calc_f_path calc_f_file]);
disp('Reading dicom file...');
Y = dicomread(info);
X = squeeze(Y(:,:,1,:));

%%
%Display some data
for i = 1:1
    figure(1);
    imagesc(X(:,:,95));
    caxis([0 16000]);
    pause(0.5);
end
%%
%Slices at larger numbers are more superior

%Now try to get depth dose from center of beam for small MLC field

%These values are in the beam frame, where isocenter is 0,0,0
origX = -25.732; %cm, neg is patient's right
origY = -74.723 + 35; %cm, neg is posterior, isocenter is at -35
origZ = -32.164; %cm, neg is superior

res = 0.4; %cm/pixel


%interogation point in beam frame (0,0,0 is isocenter) (SSD = 90)
desX = 0.0; %cm
desY = 0.0;
desZ = 0.0;

%Get size of array
[numPixX numPixY numPixZ] = size(X);

%Get interogation point in image frame
%The image frame has 0,0,0 at most right, post, sup
pixX = round((desX - origX)/res);
pixY = numPixY - round((desY - origY)/res);
pixSurY = numPixY - round((desY - origY + 10.5)/res); %water surface in image frame
pixZ = numPixZ - round((desZ - origZ)/res);

figure(2);
OnAxPdd = squeeze(squeeze(X(pixSurY:end,pixX,pixZ)));
OnAxPdd = double(OnAxPdd)/max(double(OnAxPdd));
PddIndep = linspace(0,length(OnAxPdd)*res,length(OnAxPdd));
%interpolate
interpFac = 10;
PddIndepInt = linspace(0,length(OnAxPdd)*res,length(OnAxPdd)*interpFac);
OnAxPddInt = spline(PddIndep, OnAxPdd, PddIndepInt);

plot(PddIndep,OnAxPdd); hold all;
plot(PddIndepInt,OnAxPddInt);


%measurement file
meas_f_path = 'E:\\Google Drive\\Medical_Physics\\MPPG\\MPPG_BasicPhotonFields-2014-01-17\\';
meas_f_file = '20131223_MPPG_Meas_Data.xlsx';
meas_arr = xlsread([meas_f_path meas_f_file], 1, 'D10:D3009');
pos_arr = xlsread([meas_f_path meas_f_file], 1, 'A10:A3009');
meas_arr = meas_arr/max(meas_arr);

figure(2);
plot(pos_arr,meas_arr);
%title('Measured PDD');
legend('Calc','Fit','Meas');
hold off;
