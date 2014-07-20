function [ x, y, z, dose ] = dicomDoseTOmat(filename, offset)
% Converts a dicom 3D dose file to matlab-usable variables

% Read header and pixel map
info = dicominfo(filename);
I = dicomread(filename);

% Elements in X
cols = double(info.Columns); 

% Elements in Y
rows = double(info.Rows);

% Elemetns in Z
deps = double(info.NumberOfFrames);

% Establish Coordinate System [in cm]
% It was determined by experimentation that at half-pixel shift is needed
% for the AP direction (y direction here), but not for the other dimensions. The reason for
% this isn't clear, but may have to do with the way the TPS makers
% implement their dose grids.
x = (info.ImagePositionPatient(1) + info.PixelSpacing(1)*(0:(cols-1)))/10 - offset(1);% - info.PixelSpacing(1)/2/10; 
y = (info.ImagePositionPatient(2) + info.PixelSpacing(2)*(0:(rows-1)))/10 - offset(2) - info.PixelSpacing(2)/2/10;
z = (info.ImagePositionPatient(3) + info.GridFrameOffsetVector)/10 - offset(3);

% Remove 4th Dimension from Dose Grid
J = reshape(I(:,:,1,:),[rows cols deps]);

% Scale Dose Grid Using Stored Factor
dose = double(J)*info.DoseGridScaling;
