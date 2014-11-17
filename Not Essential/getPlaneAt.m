function DOSE2D = getPlaneAt(x,y,z,DOSE3D,loc,orient)


if (orient == 'x')
    index = interp1(x,1:length(x),loc);

    if (ceil(index) == floor(index))
        DOSE2D = reshape(DOSE3D(:,index,:),[length(y),length(z)]);
    else
        Plane1 = reshape(DOSE3D(:,floor(index),:),[length(y),length(z)]);
        Plane2 = reshape(DOSE3D(:,ceil(index),:),[length(y),length(z)]);
        DOSE2D = Plane1 + (Plane2 - Plane1)*(index-floor(index));
    end
end


if (orient == 'y')
    index = interp1(y,1:length(y),loc);

    if (ceil(index) == floor(index))
        DOSE2D = reshape(DOSE3D(index,:,:),[length(x),length(z)]);
    else
        Plane1 = reshape(DOSE3D(floor(index),:,:),[length(x),length(z)]);
        Plane2 = reshape(DOSE3D(ceil(index),:,:),[length(x),length(z)]);
        DOSE2D = reshape(Plane1 + (Plane2 - Plane1)*(index-floor(index)),[length(x),length(z)]);
    end
end

if (orient == 'z')
    index = interp1(z,1:length(z),loc);

    if (ceil(index) == floor(index))
        DOSE2D = reshape(DOSE3D(:,:,index),[length(y),length(x)]);
    else
        Plane1 = reshape(DOSE3D(:,:,floor(index)),[length(y),length(x)]);
        Plane2 = reshape(DOSE3D(:,:,ceil(index)),[length(y),length(x)]);
        DOSE2D = reshape(Plane1 + (Plane2 - Plane1)*(index-floor(index)),[length(y),length(x)]);
    end
end