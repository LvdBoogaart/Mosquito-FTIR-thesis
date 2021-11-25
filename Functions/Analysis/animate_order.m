function animate_order(frame,leg)
%ANIMATE_ORDER Summary of this function goes here
%   Detailed explanation goes here
imdat = evalin('base','imdat');
IMDAT = imdat{frame};

%top figure
raw = IMDAT.Imagedat.raw;
backgroundfilt = IMDAT.Imagedat.backgroundremoved;
querypoints = IMDAT.analysis.qpt{leg};


for n = length(x)
subplot(2,1,1) = imshow(raw);

subplot(2,1,2) = 
drawnow
pause(0.05)
end

