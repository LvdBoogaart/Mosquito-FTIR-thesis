function [imdat,stat] = imagesegmentation_v2(imdat,ImTrackSettings)

%IMAGESEGMENTATION is used to segment an image using various image
%segmentation algorithms.
%Author: Luc van den Boogaart
%
%Algorithms:
%   'imsegkmeans'
%   [L,C] = imagesegmentation(image,'imsegkmeans',ngroups)
%   L = labels
%   C = centers
%
%   'imsegffm'
%   [BW,D] = imagesegmentation(image,'imsegffm')
%   BW = Black & White (binary) image
%   D = geodesic distance map
%
%   'graydiffweight'
%   [W] = imagesegmentation(image,'graydiffweight')
%   W = weightfactors
%
%   'graythresh'
%   [BW, level] = imagesegmentation(image,'graythresh')
%   BW = Black & White (binary) image
%   level = segmentation threshold using Otsu method
%
%   'grayconnected'
%   BW = imagesegmentation(image)
%
%   'adaptthresh'
%   [BW, T] = imagesegmentation(image,'adaptthresh')
%   [BW, T] = imagesegmentation(image,'adaptthresh',sensitivity)
%   BW = Black & White (binary) image
%   T = normalized locally adaptive threshold matrix R = [0,1]
%   sensitivity = factor in R = [0,1]. Higher values give bias to
%   foreground
%
%   'otsuthresh'
%   [BW, T, counts, binlocations] = imagesegmentation(image,'otsuthresh')
%   BW = Black & White (binary) image
%   T = Otsu's method threshold matrix
%   counts = histogram counts
%   binlocations = bin locations returned as numeric array
%
%   'activecontour'
%   BW = imagesegmentation(image,'activecontour')

I = imdat.Imagedat.backgroundremoved;
algorithm = ImTrackSettings.segmentationalgorithm;
addset = ImTrackSettings.additionalsettings;

switch algorithm
    case 'imsegkmeans'
        tic
        if isempty(addset) == true
            ngroups = 3; %default
        else
            ngroups = addset.ngroups;
        end
        [imdat.segmentation.segm_im,Centers] = imsegkmeans(I,ngroups);
        imdat.segmentation.Centers = Centers;
        imdat.segmentation.Time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'imsegffm'
        tic
        mask = false(size(I));
        [max1,i] = max(I);
        [max2,j] = max(max1);
        mask(i(j),j) = true;
        W = graydiffweight(I, mask, 'GrayDifferenceCutoff',round(.25*max2));
        
        thresh = 0.01;
        [imdat.segmentation.segm_im, D] = imsegfmm(W, mask, thresh);
        imdat.segmentation.D = D;
        imdat.segmentation.Time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'graydiffweight'
        tic
        mask = false(size(I));
        [max1,i] = max(I);
        [max2,j] = max(max1);
        mask(i(j),j) = true;
        imdat.segmentation.segm_im = graydiffweight(I, mask, 'GrayDifferenceCutoff',round(.25*max2));
        imdat.segmentation.Time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'graythresh'
        tic
        level = graythresh(I);
        imdat.segmentation.segm_im = imbinarize(I,level);
        imdat.segmentation.Level = level;
        imdat.segmentation.time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'grayconnected'
        tic
        [max1,i] = max(I);
        [max2,j] = max(max1);
        tolerance = addset.tolerance;
        imdat.segmentation.segm_im = grayconnected(I,i(j),j,tolerance);
        imdat.segmentation.time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'adaptthresh'
        tic
        if nargin < 3
            sensitivity = 0.4;
        else
            sensitivity = addset.sensitivity;
        end
        
        T = adaptthresh(I,sensitivity);
        imdat.segmentation.segm_im = imbinarize(I,T);
        imdat.segmentation.T = T;
        imdat.segmentation.Time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'otsuthresh'
        tic
        [counts,x] = imhist(I,64);
        T = otsuthresh(counts);
        imdat.segmentation.segm_im = imbinarize(I,T);
        imdat.segmentation.T = T;
        imdat.segmentation.Counts = counts;
        imdat.segmentation.x = x;
        imdat.segmentation.Time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    case 'activecontour'
        tic
        mask = false(size(I));
        mask(25:end-25,25:end-25) = true;
        imdat.segmentation.segm_im = activecontour(I, mask, 300);
        imdat.segmentation.Time = toc;
        imdat.segmentation.Algorithm = algorithm;
        
    otherwise
        warning('segmentation algorithm unexpected. The following algorithms are accepted: imsegkmeans, imsegffm, graydiffweight, graythresh, grayconnected, adaptthresh, otsuthresh, lazysnapping, activecontour')
end
stat.imagesegmentation = true;
end

