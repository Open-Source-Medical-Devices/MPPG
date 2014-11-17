%CompareScanToCalc.m

%Compares water tank scan measurements to treatment planning dose calculations.
%Input: 1. Scanned measurments, 2. Dose calc files
%Output: Gamma


%Calculated dose file
%In Pinnacle, the dose is stored in a binary file.
% The file has no header. And only 32 bit floats.
% Need to know dose grid parameters from dose page in Planning window, to read these files.

%dose grid resolutions (cm/sample)
dg_xr = 0.4; 
dg_yr = 0.4;
dg_zr = 0.4;

%dose grid number of samples
dg_xns = 76;
dg_yns = 94;
dg_zns = 75;
dg_tns = dg_xns*dg_yns*dg_zns; %total number of samples


%dose grid origin in cm
dg_xo = -15.495;
dg_yo = -10.840;
dg_zo = -14.518;

%read calculated dose file
calc_f_path = 'E:\\Google Drive\\Medical_Physics\\MPPG\\MPPG_BasicPhotonFields-2014-01-17\\MPPG_BasicPhotonFields\\';
calc_f_file = 'plan.Trial.binary.042';
fid = fopen([calc_f_path calc_f_file]);
calc_list = fread(fid, dg_tns, 'float32','b'); %read into a 1D array
calc_arr = reshape(calc_list,dg_xns,dg_yns,dg_zns);

figure(1);
imagesc(squeeze(calc_arr(:,:,39)));

%measurement file
meas_f_path = 'E:\\Google Drive\\Medical_Physics\\MPPG\\MPPG_BasicPhotonFields-2014-01-17\\';
meas_f_file = '20131223_MPPG_Meas_Data.xlsx';
meas_arr = xlsread([meas_f_path meas_f_file], 1, 'D10:D3009');

figure(2);
plot(meas_arr);
title('Measured PDD');

figure(3);
plot(squeeze(squeeze(calc_arr(40,:,39))));
title('Calc PDD');


%To do:
%Figure out which dose calc file is which
%Resample data sets to match eachother
%Potentially need to shift calc data
%Register the data sets
%Compute gamma
%Design structure for looping through all data


