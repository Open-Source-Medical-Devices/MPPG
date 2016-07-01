function doseData = fncAskForOffset(doseData,x0,y0,z0)
    % FNCASKFOROFFSET In the event the DICOM offset cannot be found
    % automatically, the function will ask the user to enter one manually.
    % The user may specify x0, y0, z0 for the input boxes.
    
    if nargin == 4
        % Assume x0,y0,z0 are all doubles:
        TF = false;

        if isempty(x0); TF = true; end
        if isempty(y0); TF = true; end
        if isempty(z0); TF = true; end        
        if ~isa(x0,'double'); TF = true; end
        if ~isa(y0,'double'); TF = true; end
        if ~isa(z0,'double'); TF = true; end
        
        if (TF)
            x0 = 0;
            y0 = 0;
            z0 = 0;
        end
    else
        x0 = 0;
        y0 = 0;
        z0 = 0;
    end    
    
    % Establish global variables:
    offsetCtrl = [];
    xOffsetEdit = [];
    yOffsetEdit = [];
    zOffsetEdit = [];
    
    x = [];
    y = [];
    z = [];

    % Assume offset is invalid
    invalidOffset = true;
    
    % While the offset is invalid: Open a window and wait until the user
    % enters values and closes the window. Check to see if the values are
    % valid. If so, continue. If not, try again.
    while(invalidOffset)
        openOffsetWindow(x0,y0,z0);
        waitfor(offsetCtrl);
                
        invalidOffset = isInvalidOffset();
        
    end
    
    % Return the dicom offset as a value called ORIGIN in the doseData
    % structure
    doseData.ORIGIN = [x y z];
    doseData.STATUS = sprintf('%s Offset entered manually by the user.', doseData.STATUS);
    
    function openOffsetWindow(x0,y0,z0)
    
        %%% Create a window for DICOM offset entry
        offsetCtrl = figure('Resize','off','Units','pixels','Position',[100 300 300 200],'Visible','off','MenuBar','none','name','Enter DICOM Offset...','NumberTitle','off','UserData',0);

        xOffsetEdit = uicontrol('Parent',offsetCtrl,'Style','edit','String','0','FontUnits','normalized','FontSize',.4,'BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.12 .35 .2 .2]);
        yOffsetEdit = uicontrol('Parent',offsetCtrl,'Style','edit','String','0','FontUnits','normalized','FontSize',.4,'BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.44 .35 .2 .2]);
        zOffsetEdit = uicontrol('Parent',offsetCtrl,'Style','edit','String','0','FontUnits','normalized','FontSize',.4,'BackgroundColor','w','Min',0,'Max',1,'Units','normalized','Position',[.76 .35 .2 .2]);

        xLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','X:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.03 .33 .08 .2]);
        yLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','Y:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.35 .33 .08 .2]);
        zLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','Z:','FontUnits','normalized','FontSize',.5,'Units','normalized','Position',[.67 .33 .08 .2]);

        requestLabel = uicontrol('Parent',offsetCtrl,'Style','text','String','Please enter the DICOM offset location in [cm]:','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.1 .7 .8 .2]);

        okBut = uicontrol('Parent',offsetCtrl,'Style','pushbutton','String','Submit DICOM Offset','FontUnits','normalized','FontSize',.4,'Units','normalized','Position',[.1 .05 .8 .2],'Callback', {@getOffsetVals});

        defaultBackground = get(0,'defaultUicontrolBackgroundColor');
        set(offsetCtrl,'Color',defaultBackground);    

        set(xOffsetEdit,'String',sprintf('%.2f',x0));
        %set(yOffsetEdit,'String',sprintf('%.2f',y0));
        set(yOffsetEdit,'String',sprintf('%.2f',-25.06));
        set(zOffsetEdit,'String',sprintf('%.2f',z0));           
        set(offsetCtrl,'Visible','on');
        
    end
    
    function getOffsetVals(source,eventdata)
        
       x = sscanf(get(xOffsetEdit,'String'),'%f');
       y = sscanf(get(yOffsetEdit,'String'),'%f');
       z = sscanf(get(zOffsetEdit,'String'),'%f');
              
       close(offsetCtrl)
           
    end

    function TF = isInvalidOffset()
        % ISINVALIDOFFSET This function checks the x, y and z values
        % returned from getOffsetVals to determine if any of them are
        % invalid doubles, which cannot be used.
        
        % Assume they are all doubles:
        TF = false;
        
        if isempty(x); TF = true; end
        if isempty(y); TF = true; end
        if isempty(z); TF = true; end        
        if ~isa(x,'double'); TF = true; end
        if ~isa(y,'double'); TF = true; end
        if ~isa(z,'double'); TF = true; end
            
        if (TF)
            h = msgbox(sprintf('One or more entered values could not be converted to numbers. Please try again:\n\n x = %f, y = %f, z = %f',x,y,z));
            waitfor(h);
        end
    end

end