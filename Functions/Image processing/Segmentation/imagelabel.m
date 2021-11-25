function [imdat,stat] = imagelabel(imdat,stat)
I = imdat.segmentation.segm_im;
if isa(I,'logical') == true
    setcase = 'BW';
elseif isa(I,'uint8') == true
    setcase = 'uint8';
end

switch setcase
    case 'BW'
        [imdat.segmentation.BWlabels, imdat.segmentation.numBWlabels] = bwlabel(I);
    case 'uint8'
        error('first segment image')
    otherwise
        warning('unexpected image class')
end
stat.imagelabel = true;
end