function [imdat,stat] = supergrouper(imdat,stat)
%function [supergroups,stat] = supergrouper(filtCenters,xypix,coordinates,filtLabels,pixlabel,LBoxLabels,flag,stat)

%We have a list of all labels (unique Centerlabels) that indicate supergroups
%We then check all the mask labels and add the pixels to the super groups
%Within the LBoxes we only add those pixels that are not considered noise
if stat.LBox == true
    %tracking data
    centroids = imdat.processing.tracking.centroids;
    flag = imdat.processing.tracking.Largeboxflag;
    
    %label data
    labels = imdat.processing.labeling;
    Largeboxdat = imdat.processing.labeling.Largeboxdat;
    

    %find all unique labels except 
    Supergrouplabels = labels.uniquelabels;
    
    %make new groups, use the previously indicated labels
    for i = 1:length(Supergrouplabels)
        SGL = Supergrouplabels(i);
        
        %Make super groups
        Supergroup = centroids.filtered(labels.filteredlabels == SGL,:);
        flaggedLBoxlabels = labels.LBoxlabels.*flag'; %flag sets body id to 0 to skip (if present as a box greater than threshold)
        
        %Add the pixels (from pixeltrackerv2) to the correct groups
        %(skipping the group containing the body)
        for n = 1:length(flaggedLBoxlabels)
            ML = flaggedLBoxlabels(n);
            if ML == SGL
                filtboxpixels = Largeboxdat{n}.globalxy(Largeboxdat{n}.locallabel~=-1,:); %apply local label to global pixels
                Supergroup = floor([Supergroup;filtboxpixels]);
            end
        end
        supergroups = sortrows(Supergroup);
        imdat.processing.grouping.supergroups{SGL} = supergroups;
    end
 
    stat.supergrouper = true;
else
    stat.supergrouper = false;
    imdat.processing.grouping.supergroups = [];
end
end
