function [imdat,background8b] = downsample16to8b(im_ds,imdat,background)
%DOWNSAMPLE16TO8B Function used to downsample images from 16 bit to 8 bit

S = size(im_ds.Files);
background8b = uint8(imread(background));
for n = 1:S(1)
    tic
    I = imread(im_ds.Files{n});
    imdat{n}.Imagedat.raw = uint8(I);  
    imdat{n}.Imagedat.background = background8b;
    clc, clear I
    disp('downsample16to8b.m')
    disp(['n = ',num2str(n),' of ',num2str(S(1))])
    toc
end


end

