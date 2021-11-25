function [imdat,stat] = correctlabels(imdat,stat)
%CORRECTLABELS Checks for mislabeled boxes: dbscan can mislabel centerpoint
%of large boxes as noise, due to distance to closest labeled point being 
%above the threshold value. In case this happens, LBox label are corrected

if stat.LBox == 1
    ROIidx = [imdat.processing.tracking.LBox.FnBoxidx];
    Labelvec = imdat.processing.tracking.centroids.alllabels;
    nLB = imdat.processing.tracking.nLB;
    Euclid = imdat.processing.tracking.Euclidmat;
    
    %% Label boxes
    %find labels of ROI boxes
    ROIgrouplabel = Labelvec(ROIidx);
    iix = 1:length(Labelvec);
    
    
    updatevec = Labelvec;

    
    %if numel(ROIgrouplabel(ROIgrouplabel == -1))>1
        %multiple mislabeled bois
        
    
    for n = 1:nLB
        goodLabels = (updatevec~=-1);
        subsetidx = iix(goodLabels);
        if ROIgrouplabel(n) == -1

            [minval,minidx] = min(Euclid(subsetidx,ROIidx(n)));
            if minval<300
            ROIgrouplabel(n) = updatevec(subsetidx(minidx));
            else
                ROIgrouplabel(n) = max(updatevec)+1;
            end
            updatevec(ROIidx(n)) = ROIgrouplabel(n);
        end
    end
    
    %Save data into boxdat struct
    imdat.processing.tracking.centroids.LBoxlabels = ROIgrouplabel;
    imdat.processing.tracking.centroids.uniquelabels = unique(updatevec(updatevec~=-1));
    stat.correctlabels = true;
else
    imdat.processing.tracking.centroids.lboxLabels = [];
    stat.correctlabels = false;
end
end
