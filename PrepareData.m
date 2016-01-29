function [indep, md, cd, cd_ref] = PrepareData(mx, my, mz, md, cx, cy, cz, calcData, normLoc)

% Step 1: Evaluate the calculated dose grid to determine if the measure
% profile fits inside

% Default: Calculated dose grid is large enough
minx = false;
maxx = false;
miny = false;
maxy = false;
minz = false;
maxz = false;

% Check: Calculated dose grid is larger than measured for all boundaries
if ( mx(1) < cx(1) ); minx = true; end
if ( mx(end) > cx(end) ); maxx = true; end
if ( mz(1) < cy(1) ); miny = true; end
if ( mz(end) > cy(end) ); maxy = true; end
if ( my(1) < cz(1) ); minz = true; end
if ( my(end) > cz(end) ); maxz = true; end

% If the measured dose extends outside calculated dose for any dimension,
% warn the user
if ( minx || maxx || miny || maxy || minz || maxz )
    str = sprintf('Calculated dose grid does not fully encompass measured dose profile:\n');

    indx = [ 1 length(mx) ];
    indy = [ 1 length(my) ];
    indz = [ 1 length(mz) ];
  
   if (minx)
       str = sprintf('%s\nCrossline Minimum: Measured = %.2f, Calculated = %.2f',str,mx(1),cx(1));
       ind = 1;
       while ( mx(ind) < cx(1) ); ind = ind + 1; end
       indx(1) = ind;
   end
   if (maxx)
       str = sprintf('%s\nCrossline Maximum: Measured = %.2f, Calculated = %.2f',str,mx(end),cx(end));
       ind = length(mx);
       while ( mx(ind) > cx(end) ); ind = ind - 1; end
       indx(2) = ind;
   end
   if (miny)
       str = sprintf('%s\nDepth Minimum: Measured = %.2f, Calculated = %.2f',str,mz(1),cy(1)); 
       ind = 1;
       while ( mz(ind) < cy(1) ); ind = ind + 1; end
       indz(1) = ind;
   end
   if (maxy)
       str = sprintf('%s\nDepth Maximum: Measured = %.2f, Calculated = %.2f',str,mz(end),cy(end));
       ind = length(mz);
       while ( mz(ind) > cy(end) ); ind = ind - 1; end
       indz(2) = ind;
   end
   if (minz)
       str = sprintf('%s\nInline Minimum: Measured = %.2f, Calculated = %.2f',str,my(1),cz(1));
        ind = 1;
        while ( my(ind) < cz(1) ); ind = ind + 1; end
        indy(1) = ind;
   end
   if (maxz); str = sprintf('%s\nInline Maximum: Measured = %.2f, Calculated = %.2f',str,my(end),cz(end));
        ind = length(my);
        while ( my(ind) > cz(end) ); ind = ind - 1; end
        indy(2) = ind;
   end
   
   % Shrink measured dose parameters
    index_range = max([ indx(1) indy(1) indz(1) ]):min([ indx(end) indy(end) indz(end) ]);
    mx = mx(index_range);
    my = my(index_range);
    mz = mz(index_range);
    md = md(index_range);
    h = msgbox(sprintf('%s\n\nMeasured dose profile has been truncated to allow interpolation of calculated dose data. The full measured profile will not be analyzed. This can be resolved by making the calculation dose grid larger.',str));

    waitfor(h)

   
    
end

% Step 2: Determine what measured dimension to use for independent
% variable:

if (mz(1) ~= mz(end)); idm = mz; 
elseif mx(1) ~= mx(end); idm = mx; 
elseif my(1) ~= my(end); idm = my; 
end

%Check if any points of the measured data are at same location
%Get rid of any measured points that are at repeat locations, this will
%crash interpolation
not_rep_pts = [true; (idm(1:end-1)-idm(2:end)) ~= 0]; %not repeated points
idm = idm(not_rep_pts); %remove repeats in the sample positions
md = md(not_rep_pts); %remove repeats in measured data

% Step 3: Resample for gamma analysis

% Resample indep with the same range but a finer spacing
SAMP_PER_CM = 50; % samples per cm
idm_range = abs(idm(end)-idm(1));
PTS = floor(SAMP_PER_CM*idm_range); %number of samples
indep = linspace(idm(1),idm(end),PTS);

% Resample md with new indep
md = interp1(idm, md, indep, 'PCHIP');

% Resample calculated dose with new indep
cd = interp3(cx,cy,cz,calcData,linspace(mx(1),mx(end),PTS),linspace(mz(1),mz(end),PTS),linspace(my(1),my(end),PTS),'*cubic');

% Step 4: Apply normalization preferences:
if strcmp(normLoc,'dmax')
    md = md/max(md);
    cd_ref = max(cd);
    cd = cd/max(cd);
else
    md = md / max(md);
    cd_ref = interp1(indep,cd,normLoc);
    cd = (cd / interp1(indep,cd,normLoc)) * interp1(indep,md,normLoc);
end
