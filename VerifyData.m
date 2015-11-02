function [gam, distMinGam, doseMinGam, gamma_stats ] = VerifyData(regMeas, regCalc, distThr, doseThr, globAna, usrThrs, plotOn)
% vOut = VerifyData(regMeas, regCalc, plotOn, distThr, doseThr)
%   Perform 1D gamma evaluation
%
%   Input:
%       regMeas - col 1 = position (cm), col 2 = measurements
%       regCalc - col 1 = position (cm), col 2 = calculated dose values
%       distThr - Gamma calc distance threshold in mm
%       doseThr - Gamma calc dose threshold in %
%       globAna - Global vs. Local dose difference analysis
%       usrThrs - User specified lower threshold for counting gamma results 
%       plotOn - Plot flag to be verbose with plotting
%
%   Output:
%       gam - 1D gamma calculation result
%       distMinGam - DTA component of gamma
%       doseMinGam - Dose difference component of gamma
%       gamma_stats - an array with [ gamma_max gamma_mean gamma_std
%       aboveTh aboveThPass passRt]
%
%
%   Reference:
%       D.A. Low and J.F. Dempsey. Evaluation of the gamma dose distribution
%       comparison method. Medical Physics, 30(5):2455–2464, 2003.
%
%   by Jeremy Bredfeldt, 2014
%   github.com/open-source-medical-devices/mppg   
    
    %distThr = 3; %mm
    %doseThr = 0.03; %Should be percent Gray
    doseThr = doseThr/100; %Convert from percent to decimal
    
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
        %figure;
        %imagesc(rEThr);
        %colorbar;

    end
    
    %Compute dose error
    Drm = repmat(regMeas(:,2),1,len);
    
    %figure;
    %imagesc(Drm);
    
    Drc = repmat(regCalc(:,2)',len,1);
    
    %figure;
    %imagesc(Drc);
    if (globAna)
        dE = ((Drm-Drc)/1).^2;
    else
        dE = ((Drm-Drc) ./ Drm).^2;
    end
    
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
    
%     if plotOn
%         %%%%%Debug
%         figure;
%         plot(regMeas(:,1),regMeas(:,2)); hold all;
%         plot(regCalc(:,1),regCalc(:,2));
%         plot(regMeas(:,1),gam);
        %get distance error at minimum gamma
        Ic = 1:len; %make column index array
        I = sub2ind(size(rm),Ir,Ic); %convert to linear indices
        distMinGam = sqrt(rEThr(I)); %distance error at minimum gamma position
%         plot(regMeas(:,1),distMinGam);

        %get dose error at minimum gamma
        doseMinGam = sqrt(dEThr(I)); %dose error at minimum gamma position
%         plot(regMeas(:,1),doseMinGam); hold off;
        %get distance to minimum dose difference
        [mDose IMDr] = min(dE);
%         legend('meas','calc','gam','distMinGam','doseMinGam');
%         xlabel('cm');
%         ylabel('AU');
        
%         set(gcf,'PaperPositionMode','auto');
%         print(gcf, '-dpdf', '-append', '-painters', '-r300', 'MPPG_Output_Figures.pdf'); %save a copy of the image
%     end
    
    % Compute the gamma statistics
    aboveTh = 0;
    aboveThPass = 0;
    gamma_max = 0;
    gamma_sum = 0;
    gamma_sum_2 = 0;
    zero_flag = 1;
    
    for i = 1:length(gam)
        
%         if regCalc(i,2) <= 0 && zero_flag
%             zero_flag = 0;
%             h = msgbox('Calculated dose values that are less than or equal to zero were found in this profile. These points will be excluded from the gamma analysis.');
%             waitfor(h)
%         end          
        
        if regMeas(i,2) >= usrThrs && regCalc(i,2) > 0
            
            % Update maximum gamma
            if gam(i) > gamma_max, gamma_max = gam(i); end
            
            % Update mean and std stats
            gamma_sum = gamma_sum + gam(i);
            gamma_sum_2 = gamma_sum_2 + gam(i)*gam(i);
            
            % Update counts
            aboveTh = aboveTh + 1;
            if gam(i) <= 1
                aboveThPass = aboveThPass + 1;
            end
            
        end    
    end
    
    gamma_mean = gamma_sum/aboveTh;
    gamma_std = sqrt(gamma_sum_2/aboveTh - gamma_sum*gamma_sum/aboveTh/aboveTh);
    passRt = aboveThPass/aboveTh*100;
    gamma_stats = [ gamma_max gamma_mean gamma_std aboveTh aboveThPass passRt];
    
    %figure;
    %plot(regMeas(:,1),regMeas(:,2)); hold all;
    %plot(regCalc(:,1),regCalc(:,2));
    %plot(regMeas(:,1),100*regMeas(:,2)-regCalc(:,2))./regMeas(:,2);
    %plot(regMeas(:,1),gam);
    %ylim([0 1.5]);
    %legend('Meas','Calc','DTE','Dose Dif','Gamma');
    %hold off;
        
end