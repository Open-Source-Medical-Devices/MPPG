function DOSE1D = getProfileAt(x,y,z,DOSE3D,loc1,loc2,orient)


if (orient == 'x')
    DOSE1D = interp3(x,y,z,DOSE3D,x,loc1*ones(size(x)),loc2*ones(size(x)));
end


if (orient == 'y')
    DOSE1D = interp3(x,y,z,DOSE3D,loc1*ones(size(y)),y,loc2*ones(size(y)));
end

if (orient == 'z')
    DOSE1D = interp3(x,y,z,DOSE3D,loc1*ones(size(z)),loc2*ones(size(z)),z);
end