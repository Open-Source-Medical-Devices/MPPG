function MPPG_Check
%MPPG_Check.m
%This script compares measured and calculated MPPG data for all tests.
%The tests need to be summarized in an XL spreadsheet according to the format outlined below
clear all;
close all;

%path and file name to spread sheet that describe each test
[meas_f_file,meas_f_path,FilterIndex] = uigetfile('*.xlsx','Choose test summary spreadsheet');
meas_f_full = [meas_f_path meas_f_file];
[~,~,measTable] = xlsread(meas_f_full, 1); %1 indicates which page of the XL workbook the summary data is in
cd(meas_f_path);

mD = measTable(3:end,:); %remove header row
[numTests numCols] = size(mD);

%plot flag, tells subroutines to plot or not
plotOn = 0;

%Which columns hold what data in summary table
testIndex = 1;  %test number
testID = 2;     %name of the test (string)
enID = 3;       %energy and wedge ID (string)
subTestID = 4;  %PDD or Cross beam (string)
mPageID = 10;    %Measured data XL workbook page
mDepRID = 11;    %Measured data dependent variable (nC)
mIndepRID = 12;  %Measured data independent variable (position)
depthID = 5;    %Depth (for cross beam measurements)
cPathID = 14;    %Path to calculated dicom file (Pinnacle output)
cFnameID = 15;   %Name of calculated dicom file (Pinnacle output)
mPathID = 8;   %Path to measured data XL file
mFnameID = 9;  %Name of measured data XL file
cOrigXID = 16;  %Calculated dose grid origin offset (Lat)
cOrigYID = 17;  %Calculated dose grid origin offset (Sup-Inf)
cOrigZID = 18;  %Calculated dose grid origin offset (Axial)
cOrigResID = 19;%Dose grid resolution
xOffsetID = 6;%X offset (Lat, 0,0 is center of beam) in cm
zOffsetID = 7;%Z offset (Sup-Inf, 0,0 is center of beam) in cm
measUnitsID = 13;%Units on measurement independent variable (cm or mm)

%Loop through all verification tests
for v = 4

    %Run verification
    measData = GetMeasData(mD{v,mPathID}, mD{v,mFnameID}, mD{v,mPageID},...
        mD{v,mDepRID}, mD{v,mIndepRID}, plotOn, ...
        mD{v,testID}, mD{v,enID}, mD{v,subTestID}, ...
        mD{v,depthID}, mD{v,measUnitsID});

    calcData = GetCalcData(mD{v,cPathID}, mD{v,cFnameID}, mD{v,cOrigXID},...
        mD{v,cOrigYID}, mD{v,cOrigZID}, mD{v,cOrigResID}, plotOn, ...
        mD{v,testID}, mD{v,enID}, mD{v,subTestID}, ...
        mD{v,depthID}, mD{v,xOffsetID}, mD{v,zOffsetID});
    [regMeas regCalc sh] = RegisterData(measData, calcData);
    %display how far we needed to shift to get best correlation, should be same for all beams?
    disp(['num pixels to shift ' mD{v,subTestID} ': ' num2str(sh)]);

    %perform gamma evaluation
    vOut = VerifyData(regMeas, regCalc, plotOn);
        
    if strcmp('PDD',mD(v,3))
        %display PDDs
        figure;
        plot(regMeas(:,1), regMeas(:,2),'LineWidth',3); hold all;
        plot(regCalc(:,1), regCalc(:,2),'--','LineWidth',3);
        ylim([0 1.25]);
        xlabel('Depth (cm)');
        ylabel('Normalized dose');        
        title(['PDD ' num2str(mD{v,enID}) ' MV']);        
        
        %display gamma
        %figure;
        plot(regMeas(:,1),vOut,'*-','LineWidth',3);
        ylim([0 1.25]);
        xlabel('Depth (cm)','FontSize',15);
        ylabel('Gamma & Normalized Dose','FontSize',15);
        %title(['PDD Gamma ' num2str(mD{v,enID}) ' MV']);
        legend('Measured', 'Calculated', 'Gamma'); hold off;
        %WriteSummary(vOut);
    elseif strcmp('Inline',mD(v,3)) || strcmp('Cross',mD(v,3))

        figure;
        plot(regMeas(:,1), regMeas(:,2),'LineWidth',3); hold all;
        plot(regCalc(:,1), regCalc(:,2),'--','LineWidth',3);
        ylim([0 1.5]);
        xlabel('Position (cm)');
        ylabel('Normalized dose','FontSize',15);
        %legend('Measured', 'Calculated');
        %title(['Cross ' num2str(mD{v,enID}) ' MV @ ' num2str(mD{v,depthID}) ' cm']);   
        
        %display gamma
        %figure;
        plot(regMeas(:,1),vOut,'*-','LineWidth',3);
        ylim([0 1.5]);
        xlabel('Position (cm)','FontSize',15);
        ylabel('Gamma & Normalized Dose','FontSize',15);
        %title(['Cross Gamma ' num2str(mD{v,enID}) ' MV @ ' num2str(mD{v,depthID}) ' cm']); 
        legend('Measured', 'Calculated', 'Gamma');
    end
    xlim([-10 -7]);
        
end

%==============================================
%==============================================
function measData = GetMeasData(path, fname, page, depR, indepR, plotOn, test, en, sub, depth, units)
    dep = xlsread([path fname], page, depR); %dependent var
    indep = xlsread([path fname], page, indepR);
    k = 1; %assume units are cm
    if strcmp(units,'mm')
        k = 0.1; %if units are mm, convert to cm
    end
    measData = [indep.*k dep];
    
    if plotOn
        figure;
        plot(indep,dep);
        if strcmp('PDD',sub)
            ttl = ['Measured ' test ' ' num2str(en) 'MV ' sub ' ' num2str(depth) ' cm depth'];
        else
            ttl = ['Measured ' test ' ' num2str(en) 'MV ' sub ' ' num2str(depth) ' cm depth'];
        end
        title(ttl);
    end
end

%==============================================
%==============================================
function calcData = GetCalcData(path, fname, origX, origY, origZ, res, plotOn, test, en, sub, depth, xOff, zOff)
    
    info = dicominfo([path fname]);    
    Y = dicomread(info);
    X = squeeze(Y(:,:,1,:));
    
    %Get size of array
    [numPixX numPixY numPixZ] = size(X);

    %Get interogation point in image frame
    %The image frame has 0,0,0 at most right, post, sup
    if strcmp(sub,'PDD')
        pixX = round((-origX+xOff)/res);
        pixSurY = 1; %water surface in image frame
        pixZ = numPixZ - round((-origZ+zOff)/res); 
        calcDep = squeeze(squeeze(X(pixSurY:end,pixX,pixZ)));
        calcIndep = linspace(0,length(calcDep)*res,length(calcDep)); %in cm
    elseif strcmp(sub,'Inline') || strcmp(sub,'Cross')
        pixX = round((-origX)/res);
        pixY = round(depth/res) + 0; %water surface in image frame
        pixZ = numPixZ - round(-origZ/res);         
        if strcmp(sub,'Inline')
            calcDep = squeeze(squeeze(X(pixY,pixX,:))); %Get inline data               
        elseif strcmp(sub,'Cross')    
            calcDep = squeeze(squeeze(X(pixY,:,pixZ))); %Get cross data
        end
        calcIndep = linspace(-length(calcDep)*res/2,length(calcDep)*res/2,length(calcDep)); %in cm  
    end
    calcDep = info.DoseGridScaling*double(calcDep); %convert to dose in Gy

    if plotOn     
        figure;
        plot(calcIndep,calcDep); hold all;
        ttl = ['Calculated ' test ' ' num2str(en) 'MV ' sub];
        title(ttl);        
    end
    if isrow(calcDep)
        calcDep = calcDep';
    end
    calcData = [calcIndep' calcDep]; %return the calculated independent and dependent variables
end

%==============================================
%==============================================
function [regMeas regCalc sh] = RegisterData(meas, calc)
    
    %normalize, *** this should be fixed with a proper cal factor
    meas(:,2) = meas(:,2)/max(meas(:,2));
    calc(:,2) = calc(:,2)/max(calc(:,2));
    
    %match up the resolution by interpolation
    calcInt = interp1(calc(:,1), calc(:,2), meas(:,1),'PCHIP');
    
    %ideal sample rate
    sr = 200; %samples per cm
    dist = meas(1,1) - meas(end,1); %total distance in cm
    ns = sr*abs(dist); %number of samples
    intIndep = linspace(meas(1,1),meas(end,1),ns)'; %interpolated independent var
    
    %interpolate measured data
    measInt = interp1(meas(:,1), meas(:,2), intIndep, 'PCHIP');
    
    %interoplate calc data
    calcInt = interp1(calc(:,1), calc(:,2), intIndep, 'PCHIP');
    
    %cross correlate
    [c,lags] = xcorr(measInt, calcInt, 4*sr);
    
    %determine the peak correlation offset
    [~,i] = max(c);
    sh = lags(i); %number of pixels to shift (and direction)
    
    %shift one of the curves to match the other, *** this shouldn't be necessary
    calcIntShft = circshift(calcInt,sh); %shift     
    
    %get rid of shifted pixels on end
    regMeas = [intIndep(1:end-abs(sh)) measInt(1:end-abs(sh))];
    regCalc = [intIndep(1:end-abs(sh)) calcIntShft(1:end-abs(sh))];
    
end

%==============================================
%==============================================
function vOut = VerifyData(regMeas, regCalc, plotOn)
    %Perform gamma evaluation
    
    distThr = 3; %mm
    doseThr = 0.03; %Should be percent Gray    
    
    %Compute distance error (in mm)
    len = length(regMeas(:,1));
    rm = repmat(10*regMeas(:,1),1,len); %convert to mm
    
    %figure;
    %imagesc(rm);
    
    rc = repmat(10*regCalc(:,1)',len,1); %convert to mm
    
    %figure;
    %imagesc(rc);
    
    rE = (rm-rc).^2;
    
    %figure;
    %imagesc(rE);
    
    rEThr = rE./(distThr.^2);
    if plotOn
        figure;
        imagesc(rEThr);
        colorbar;

    end
    
    %Compute dose error
    Drm = repmat(regMeas(:,2),1,len);
    
    %figure;
    %imagesc(Drm);
    
    Drc = repmat(regCalc(:,2)',len,1);
    
    %figure;
    %imagesc(Drc);
    
    dE = (Drm-Drc).^2;
    
    %figure;
    %imagesc(dE);
    
    dEThr = dE./((doseThr).^2);    
    if plotOn
        %figure;
        %imagesc(dEThr);
        %colorbar;        
    end
    
    gam2 = rEThr + dEThr;
    
    %figure;
    %imagesc(gam2);
    
    %take min down columns to get gamma as a function of position
    [gam Ir] = min(gam2); %Ir is the row index where the min gamma was found
    gam = sqrt(gam);
    
    %%%%%Debug
    figure;
    plot(regMeas(:,1),regMeas(:,2)); hold all;
    plot(regCalc(:,1),regCalc(:,2));
    plot(regMeas(:,1),gam);
    %get distance error at minimum gamma
    Ic = 1:len; %make column index array
    I = sub2ind(size(rm),Ir,Ic); %convert to linear indices
    distMinGam = sqrt(rEThr(I)); %distance error at minimum gamma position
    plot(regMeas(:,1),distMinGam);
    
    %get dose error at minimum gamma
    doseMinGam = sqrt(dEThr(I)); %dose error at minimum gamma position
    plot(regMeas(:,1),doseMinGam); hold off;
    %get distance to minimum dose difference
    [mDose IMDr] = min(dE);
    legend('meas','calc','gam','distMinGam','doseMinGam');
    
    
    %figure;
    %plot(regMeas(:,1),regMeas(:,2)); hold all;
    %plot(regCalc(:,1),regCalc(:,2));
    %plot(regMeas(:,1),100*regMeas(:,2)-regCalc(:,2))./regMeas(:,2);
    %plot(regMeas(:,1),gam);
    %ylim([0 1.5]);
    %legend('Meas','Calc','DTE','Dose Dif','Gamma');
    %hold off;
        
    vOut = gam;
end

end