function figureplotter_v3(varargin)

%% REWRITE HELP SECTION
%%
%FIGUREPLOTTER Author: Luc van den Boogaart
%
%   figureplotter_v3(type,...,object,...,namepair)
%
%   Types: (Newfig,image) Overlay
%   'Newfig' creates a new figure, this requires a base image to be supplied
%   figureplotter_v2('Newfig',figure,...)
%
%   'Overlay' overlays the operation on the current figure (note that the
%   figure size needs to be similar to the overlay figure size
%   figureplotter_v3('Overlay',object)
%
%
%   Object: Boxes, Centers, Spline
%   'Boxes' plots the bounding boxes around pixel clusters on a figure
%   figureplotter_v3('Newfig',figure,'Boxes',Boundingboxes)
%       or
%   figureplotter_v3('Overlay','Boxes',Boundingboxes)
%       or
%   figureplotter_v3(type,...,'Boxes',Boundingboxes,Namepairs...
%       Namepairs:
%       'color','...': all plot colors are accepted
%       'LineWidth',...: specifies border thickness
%
%   'Centers' plots the centerpoints of the bounding boxes around pixel
%   clusters on a figure
%   figureplotter_v3('Newfig',figure,'Centers',Centerpoints)
%       or
%   figureplotter_v3('Overlay','Centers',Centerpoints)
%       or
%   figureplotter_v3(type,...,'Boxes',Boundingboxes,Namepairs)
%       Namepairs:
%       'Labeled',grouplabels: color centerpoints based on label number
%       'Markersize',...: Sets centerpoint size
%       'Markertype','...': Sets marker shape ('+','*','filled'... etc)
%       'color','...': All colors are accepted
%
%   'Mask' groups and colours the pixels inside the large bounding boxes.
%   Mask only works when all Namepairs are provided, like:
%   figureplotter_v2('Overlay','Mask',pixelmasksarray,'Grouplabel',...
%       grouplabelvector,'Pixlabel',maskpixellabels,'Boxcoords',...
%       boundingboxvectormatrix')
%
%   Example
%   figureplotter_v3('Newfig',image1,'Boxes',unfilteredboxes)
%   figureplotter_v3('Overlay','Boxes',filteredboxes,'color','r')
%   figureplotter_v3('Overlay','Centers',Centerpoints,'Labeled',Labels,'Markersize',3)




args = varargin;
nargs = nargin;
type = args{1};

switch type
    case 'Newfig'
        if nargs>2
            data = args{3};
        end
    case 'Overlay'
        data = args{2};
end

if nargs>2 && data.identifier == "imagetracker struct"
    dataflag = true;
else
    dataflag = false;
end

switch type
    case 'Newfig'
        figure()
        if isempty(args{2}) == false
            image = args{2};
        else
            image = data.segmentation.segm_im;
        end
        
        imshow(image)
        hold on
        
        if dataflag == true && nargs>3
            objectflagn = 4;
        elseif (dataflag == false && nargs>2)            
            objectflagn = 3;
        elseif nargs == 2 || (dataflag == true && nargs == 3)
            objectflagn = 99;
        end
    case 'Overlay'
        if dataflag == true
            objectflagn = 3;
        elseif dataflag == false
            objectflagn = 2;
        end
    otherwise
        warning('Specify figure type')
end



if nargs > objectflagn
    objectflag = args{objectflagn};
    objectarg = args{objectflagn+1};
    if nargs>objectflagn+1
        remargs = args(objectflagn+2:end);
        nremargs = nargs-(objectflagn+1);
    else
        nremargs = 0;
    end
elseif objectflagn == 99
    objectflag = 'skip';
else
    objectflag = args{objectflagn};
end

switch objectflag
    case 'Showimg'
        %Room to add title, axes, create a imagesc, etc.
    case 'Boxes'
        if dataflag == true && isempty(objectarg) == true
            BoundingBoxes = data.processing.tracking.LBox;
        else
            BoundingBoxes = objectarg;
        end
        
        if nremargs == 0 %no additional name pairs
            for a = 1:size(BoundingBoxes,2)
                rectangle('Position',BoundingBoxes(a).BoundingBox,'Edgecolor','g','LineWidth',1)
                hold on
            end
            
        elseif nremargs > 0 && rem(nremargs,2) == 0 %additional namepairs
            %standard settings
            color = 'g';
            width = 1;
            for f = 1:nremargs/2
                flag = remargs{2*f-1};
                switch flag
                    case 'color'
                        color = remargs{2*f};
                    case 'LineWidth'
                        width = remargs{2*f};
                    otherwise
                        warning('unexpected namepair received')
                end
            end
            for a = 1:size(BoundingBoxes,2)
                rectangle('Position',BoundingBoxes(a).BoundingBox,'Edgecolor',color,'LineWidth',width)
                hold on
            end
            
        elseif nremargs > 1 && rem(nremargs,2) ~= 0
            error('incomplete namepair supplied')
        end
    case 'Centers'
        if dataflag == true && isempty(objectarg) == true
            Centers = data.processing.tracking.centroids.filtered;
        else
            Centers = objectarg;
        end
        
        if nremargs == 0 %No namepairs
            scatter(Centers(:,1),Centers(:,2))
            
        elseif nremargs > 0 && rem(nremargs,2) == 0 %additional namepairs
            %standard settings
            color = 'g';
            sz = 10;
            shape = 'filled';
            Labeled = false;
            plotlegend = false;
            %check namepair input
            for f = 1:nremargs/2
                flag = remargs{2*f-1};
                switch flag
                    case 'color'
                        color = remargs{2*f};
                    case 'Markersize'
                        sz = remargs{2*f};
                    case 'Markertype'
                        shape = remargs{2*f};
                    case 'Labeled'
                        if dataflag == true
                            Labels = data.processing.labeling.filteredlabels;
                        else
                            Labels = remargs{2*f};
                        end
                        Labeled = true;
                    case 'Legend'
                        plotlegend = true;
                        if dataflag == true && isempty(remargs{2*f}) == true
                            legendcell = data.processing.classification.class;
                        else
                            legendcell = remargs{2*f};
                        end
                    otherwise
                        warning('unexpected name pair received')
                end
            end
            
            %Plot centerpoints
            if Labeled == true
                %Labeled
                ngroups = max(Labels);
                index = 1:1:length(Labels);
                for n = 1:ngroups
                    ii{n} = index(Labels==n);
                    scatter(Centers(ii{n},1),Centers(ii{n},2),sz,shape)
                end
                if plotlegend == true
                    legend(legendcell,'AutoUpdate','off')
                end
                
            else
                %Unlabeled
                scatter(Centers(:,1),Centers(:,2),sz,color,'Markertype',shape)
            end
        elseif nremargs > 1 && rem(nremargs,2) ~= 0
            error('incomplete namepair supplied')
        end
    case 'Spline'
        if dataflag == true && isempty(objectarg) == true
            legobjs = data.fitting.legobj;
            sz = size(legobjs,2);
            for n = 1:sz
                Spline = legobjs{n}.spline;
                fnplt(Spline)
                hold on
            end
        else
            Spline = objectarg;
            fnplt(Spline)
            hold on
        end
        
%% Needs revision
    case 'Mask'
        if dataflag == true
            Masks = data.processing.tracking.Largeboxdat;
        else
            Masks = objectarg;
        end
        
        switch dataflag
            case true
                Grouplabeled = true;
                Grouplabels = data.processing.labeling.LBoxlabels;
                Pixlabeled = true;

                
            case false
                if nremargs == 0
                    warning('No labeling provided')
                elseif nremargs > 0 && rem(nremargs,2) == 0
                    for f = 1:nremargs/2
                        flag = remargs{2*f-1};
                        switch flag
                            case 'Grouplabel'
                                Grouplabeled = true;
                                
                                Grouplabels = remargs{2*f};
                                
                            case 'Pixlabel'
                                Pixlabeled = true;
                                globalxy = remargs{2*f};
                            case 'Boxcoords'
                                Coordinatesgiven = true;
                                BoxCoords = remargs{2*f};
                            otherwise
                                warning('unexpected name pair received')
                        end
                    end
                else
                    error('incomplete namepair received')
                end
            otherwise
                error('For a brief moment it seems as if all sound numbs. In front of you, code-spacetime slowly starts to tear appart. You feel your stomach twisting and knotting while your mind tries to comprehend the breaking appart of the laws that govern this universe. Reaching out from the abyss, that somehow seems to engulf this mortal realm from the inside out, is a new logic state from a hyperplane of truth and falsity. You feel it slowly clutching your soul, trying to split any foundation of binary thought. Roll a DC25 Wisdom saving throw.')
        end
        
        
        if Grouplabeled == true && Pixlabeled == true
            sz = size(Masks,2);
            defaultcolorslist = defaultcolors;
            
            groupflag = data.processing.tracking.Largeboxflag;
            for n=1:sz
                if groupflag(n) ~= 0
                    Mask = Masks{n}.globalxy;
                    locallabel = Masks{n}.locallabel;
                    ax = gca();
                    Truemask = Mask(locallabel~=-1,:);
                    scattercolor = [defaultcolorslist{Grouplabels(n)}];
                    scatter(ax, Truemask(:,1),(Truemask(:,2)),...
                        10,'filled','MarkerFaceColor',scattercolor)
                end
            end
        else
            error('Labeling incomplete, type help figureplotter_v2 for additional information')
        end
    case 'skip'
        %no further action taken
    otherwise
        warning('unexpected visualization type supplied')
end
end

%% Default colors list, for plotting purposes
function list = defaultcolors
list = {[0, 0.4470, 0.7410]
    [0.8500, 0.3250, 0.0980]
    [0.9290, 0.6940, 0.1250]
    [0.4940, 0.1840, 0.5560]
    [0.4660, 0.6740, 0.1880]
    [0.3010, 0.7450, 0.9330]
    [0.6350, 0.0780, 0.1840]};
end

%% Changelog
%Version 3
%Changed the input system to take in Imagetracker output struct as base
%single data input.

%% KNOWN BUGS:
%Scatter marker shape not fully implemented