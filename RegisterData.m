function [regMeas regCalc sh_cm] = RegisterData(meas, calc)

% [regMeas regCalc sh] = RegisterData(meas, calc)
%   Normalizes, interpolates and registers 1D measured and calculated data
%
%   Input:
%       meas - col 1 = position (cm), col 2 = measurements
%       calc - col 1 = position (cm), col 2 = calculated dose values
%
%   Output:
%       regMeas - measured data after normalization, registration and interpolation
%       regCalc - measured data after normalization, registration and interpolation
%       sh - number of cm to shift, following interpolation, needed for registration
%
%   by Jeremy Bredfeldt, 2014
%   github.com/open-source-medical-devices/mppg
    
    %normalize, *** this should be fixed with a proper cal factor
    meas(:,2) = meas(:,2)/max(meas(:,2));
    calc(:,2) = calc(:,2)/max(calc(:,2));
    
    %match up the resolution by interpolation
    %calcInt = interp1(calc(:,1), calc(:,2), meas(:,1),'PCHIP');
    
    %ideal sample rate
    sr = 50; %samples per cm (judgement call)
    dist = meas(1,1) - meas(end,1); %total distance in cm
    ns = sr*abs(dist); %number of samples
    intIndep = linspace(meas(1,1),meas(end,1),ns)'; %interpolated independent var
    
    %interpolate measured data
    measInt = interp1(meas(:,1), meas(:,2), intIndep, 'PCHIP');
    
    %interoplate calc data
    calcInt = interp1(calc(:,1), calc(:,2), intIndep, 'PCHIP');
    
    
    try % to use xcorr
 
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
        
    catch  
        
        % Tell user about exception
        % disp('RegisterData function error: It is possible that xcorr() threw an exception because the Signal Processing Toolbox is not installed in this version of MATLAB');
        % disp('Proceeding without automated registration');
        
        % Return unshifted data
        regMeas = [ intIndep measInt ];
        regCalc = [ intIndep calcInt ];
        sh = 0;
        
    end
    
    
    
    %convert shift to cm
    sh_cm = sh/sr;
end