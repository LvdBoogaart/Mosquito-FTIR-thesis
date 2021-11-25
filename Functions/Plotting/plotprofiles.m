function plotprofiles(framenumber,name)
%PLOTPROFILES Summary of this function goes here
%   Detailed explanation goes here
imdat = evalin('base','imdat');
analysis = imdat{framenumber}.analysis.(name);

S = size(analysis.qpt,2);

figure()
for n = 1:S
    x = (1:1:size(analysis.qpt{n},1))/size(analysis.qpt{n},1);
    
    
    
    yraw = double(cell2mat(analysis.ypt{n}));
    ymean = cell2mat(analysis.mean_ypt{n});
    ymax = double(cell2mat(analysis.max_ypt{n}));
    
    direction = imdat{framenumber}.processing.classification.legobj{n}.direction;
    if direction == "inwards"
        yraw = flip(yraw);
        ymean = flip(ymean);
        ymax = flip(ymax);
    end
    
    subplot(S,1,n)
    hold on
    plot(x,yraw,'LineWidth',0.5)
    plot(x,ymean,'LineWidth',1.5)
    plot(x,ymax,'LineWidth',0.5)
    xlabel('s')
    xticks([0,1])
    xticklabels({'body','end'});
    ylabel('gray')
    
    %subplot(S,1,n), plot(x,yraw,x,ymean,x,ymax,'LineWidth',[0.5,1,0.5])
    title(['intesity profiles leg ',num2str(n),' set: ',name])
    
end

legend('raw','mean','smoothingwindow')

