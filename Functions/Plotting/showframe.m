function showframe(framenumber)
%SHOWIMAGE Summary of this function goes here
%   Detailed explanation goes here

imdat = evalin('base','imdat');
settings = evalin('base','settings');
for n = 1:length(framenumber)
IMDAT = imdat{framenumber(n)};
Imagedat = IMDAT.Imagedat;
I = Imagedat.raw;
segm_im = IMDAT.segmentation.segm_im;
backgroundremoved = Imagedat.backgroundremoved;

figure()
a = subplot(2,2,1); imshow(I); title('raw'); pbaspect([1 1 1]); 
b = subplot(2,2,2); imagesc(I); title('raw scaled'); pbaspect([1 1 1]); colorbar; axis off
c = subplot(2,2,3);  imshow(segm_im); title(['segmented: grainsize = ',num2str(settings.grainsize),' threshold = ',num2str(settings.noisethreshold)]); pbaspect([1 1 1]);
d = subplot(2,2,4);  imagesc(backgroundremoved); title('backgroundremoved scaled'); pbaspect([1 1 1]); colorbar; axis off
set(a,'Position',[.1 .55 .4 .4])
set(b,'Position',[.5 .55 .4 .4])
set(c,'Position',[.1  .05 .4 .4])
set(d,'Position',[.5  .05 .4 .4])

drawnow
end
end

