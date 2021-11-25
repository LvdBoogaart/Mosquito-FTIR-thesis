function [imdat] = extract_grays(settings,imdat,varargin)
%figure out the input
nvargs = size(varargin,2);
a = 1;
resolution = settings.resolution;
while a<=nvargs
    object = varargin{a};
    objectclass = class(object);
    switch objectclass
        case 'char'
            setting = object;
            switch setting
                case 'fieldname'
                    fieldname_value = varargin{a+1};
                    a = a+2;
                case 'imfromimdat'
                    imfromimdat_value = varargin{a+1};
                    switch imfromimdat_value
                        case {'segmented','segm_im','Segmented'}
                            image = imdat.segmentation.segm_im;
                        otherwise
                            if isfield(imdat.Imagedat,imfromimdat_value) == 1
                                image = imdat.Imagedat.(imfromimdat_value);
                            end
                    end
                    a = a+2;
                case {'debug','display_samplepoints'}
                    debug = true;
                    a = a+1;
                case {'t_pause','pause_duration'}
                   pause_duration = varargin{a+1};
                    a = a+2; 
            end                    
        case {'matlab.ui.Figure','matlab.graphics.axis.Axes'}
            image = getimage(object);
            imclass = class(image);
            a = a+1;
        case {'uint8','uint16','int8','int16'}
            image = object;
            imclass = class(image);
            a = a+1;
    end
    
end
if exist('display_samplepoints','var') == 1
        figureplotter_v3('Newfig',imdat.Imagedat.raw,imdat,'Spline',[])
        figureplotter_v3('Overlay',imdat,'Boxes',[],'color','r');
end

if exist('image','var') == 0
    warning('No target image was specified, raw image was used')
    image = imdat.Imagedat.raw;
end

if exist('fieldname_value','var') == 0
    if exist('imfromimdat_value') == 1
        warning(['no target fieldname specified, data stored as imdat.analysis.',imfromimdat_value])
        fieldname_value = imfromimdat_value;
    else
        warning(['no target fieldname specified, data stored as imdat.analysis.default'])
        fieldname_value = 'default';
    end
end   
%algorithm
nLegs = imdat.sampling.nLegs;
for n = 1:nLegs
    groups = imdat.analysis.legobj{n}.groups; 
    qcells = imdat.analysis.legobj{n}.qcells;
    for m = 1:size(groups.parent,2)
        if isempty(groups.children{m}) == false

            QP{n}.parents(m,:) = groups.parent{m}(1,:);
            QP{n}.children{m,1} = IDtoXY(groups.children{m}(:,1),resolution);
            %Extracting things from the image maxtrix does not work use xy,
            %but row column. Which means everything needs to be flipped
            %thanks matlab for being convoluted like this
            QP{n}.avgint{m,1} = sum(diag(image(QP{n}.children{m}(:,2),QP{n}.children{m}(:,1))))/size(QP{n}.children{m},1);
            QP{n}.raw{m,1} = image(QP{n}.parents(m,2),QP{n}.parents(m,1));
            QP{n}.max{m,1} = max(diag(image(QP{n}.children{m}(:,2),QP{n}.children{m}(:,1))));
        end
        
        %Debugging
        if exist('debug','var') == 1
            %if display option is toggled
            scatter(QP{n}.parents(m,1),QP{n}.parents(m,2),'filled')
            scatter(QP{n}.children{m}(:,1),QP{n}.children{m}(:,2))
            drawnow limitrate
            avgi = sum(diag(image(QP{n}.children{m}(:,1),QP{n}.children{m}(:,2))))/size(QP{n}.children{m},1);
            locali = image(QP{n}.parents(m,1),QP{n}.parents(m,2));
            maxi = max(diag(image(QP{n}.children{m}(:,1),QP{n}.children{m}(:,2))));
            
            disp(['average intensity = ',num2str(avgi)])
            disp(['local intesity = ',num2str(locali)])
            disp(['max intensity = ',num2str(maxi)])
            
            if exist('pause_duration','var') == 1
                pause(pause_duration)
            else
                disp('Hit any key to continue')
                pause()
                clc
            end
        end

    end
    imdat.analysis.(fieldname_value).qpt{n} = QP{n}.parents;
    imdat.analysis.(fieldname_value).mean_ypt{n} = QP{n}.avgint;
    imdat.analysis.(fieldname_value).ypt{n} = QP{n}.raw;
    imdat.analysis.(fieldname_value).max_ypt{n} = QP{n}.max;
end
end

