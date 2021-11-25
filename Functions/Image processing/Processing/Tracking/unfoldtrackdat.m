function [imdat,stat] = unfoldtrackdat(imdat,type,stat)

switch type
    case 'all'
        fieldname = 'allBox';
    case 'LBox'
        fieldname = 'LBox';
    otherwise
        error('invalide type supplied')
end

Boxes = imdat.processing.tracking.(fieldname);
nBoxes = size(Boxes,2);

if nBoxes>0

            Concatenated = [Boxes.BoundingBox];
            B1 = Concatenated(1:4:end);
            B2 = Concatenated(2:4:end);
            B3 = Concatenated(3:4:end);
            B4 = Concatenated(4:4:end);
            
            imdat.processing.tracking.centroids.(type) = [(B1+B3/2)',(B2+B4/2)'];
            
            for n = 1:nBoxes
                imdat.processing.tracking.boxrangestrct.(type).xrange(n,:) = [B1(n)'+0.5,B1(n)'+0.5+B3(n)'];
                imdat.processing.tracking.boxrangestrct.(type).yrange(n,:) = [B2(n)'+0.5,B2(n)'+0.5+B4(n)'];
            end

    switch type
        case 'LBox'
            stat.unfoldtrackdatLBox = true;
        case 'all'
            stat.unfoldtrackdatFnBox = true;
    end

    
    %In case empty data needs to be passed through the algorithm
else
    imdat.processing.tracking.centroids.(type) = [];
    imdat.processing.tracking.boxrangestrct.(type) = struct([]);
    switch type
        case 'LBox'
            stat.unfoldtrackdatLBox = false;
        case 'all'
            stat.unfoldtrackdatFnBox = false;
    end
end
end
