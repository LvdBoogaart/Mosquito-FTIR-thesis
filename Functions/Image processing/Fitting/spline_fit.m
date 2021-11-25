function [imdat,stat] = spline_fit(imdat,stat)
if stat.groupclassifier == true
    supergroups = imdat.processing.grouping.supergroups;
    classdat = imdat.processing.classification;
    
    NLegs = size(classdat.legobj,2); %amount of legs = amount of splines to be created
    a = 1:size(supergroups,2); %amount of groups in picture
    
    bodyanchorweight = 15;
    footanchorweight = 100;
    extraknotanchorweight = 15;
    kneeanchorweight = 20;
    
    %Find PCA of the body group
    ID = a(classdat.class == "body");
    pts = supergroups{ID}; %points of the body group
    PCAmat = pts; %principal components analysis
    coeff = pca(PCAmat);
    theta = acos(coeff(1,1));   %angle in rad
    
    %group average
    np = size(pts,1);
    pAVG = mean(pts);
    pmeansub = pts-pAVG.*ones(np,1); %mean substracted data
    pneg = (pmeansub(:,1)<0)*-1;
    ppos = (pmeansub(:,1)>0);
    signvec = pneg+ppos;
    
    unitvec = coeff(:,1);
    proj = (pmeansub.*unitvec');
    [M,id] = max(signvec'.*vecnorm(proj'));
    
    classdat.bodyobj.coeff = coeff;
    classdat.bodyobj.XKnotID = id;
    
    
    
    for n = 1:NLegs
        L = classdat.legobj{n};
        disp(['leg ',num2str(n)])
        %select points for the splinefitting
        points = supergroups(L.groupid);
        imdat.fitting.legobj{n}.legpts = points;
        
        Bx = classdat.bodyobj.x;
        By = classdat.bodyobj.y;
        ind = 1;
        knot = 1;
        x = [];
        y = [];
        
        
        for m = 1:size(points,2)
            x = vertcat(x,points{m}(:,1));
            Xl(m) = x(1);
            Xr(m) = x(end);
            y = vertcat(y,points{m}(:,2));
            Yl(m) = y(1);
            Yr(m) = y(end);
            ind = length(x)+1;
        end
        
        %Rotate body group with principal axis to the x axis, take the max
        %and min x. %add if principal axis is in line with the investigated
        %group.
        
        %Check if x proximal is smaller or greater than center, or just add
        %and sort by x.
        %L.
        
        %location of group:
        if sum(L.location == 'W')>0
            LOC = 'W';
        elseif sum(L.location == 'E')>0
            LOC = 'E';
        elseif sum(L.location == 'S') == length(L.location)
            LOC = 'S';
        elseif sum(L.location == 'N') == length(L.location)
            LOC = 'N';
        else
            warning('unexpected result')
        end
        
        centroid = [Bx,By];
        
        switch LOC
            case 'W'
                %Body coordinates, position: last
                %If principal axis is towards leg group, add extra knot
                
                if theta<0 %counterclockwise rotation, principal axis in line with Legs on left side
                    targetgroup = pts;
                    %x axis = 0, clockwise positive
                    R = rotmat(-theta);
                    proj = ((targetgroup-centroid)*R)+centroid; %allign to x axis
                    
                    %min and max x value
                    [~, minids] = min(proj);
                    ID(1) = minids(1); %furthest
                    extraknot = targetgroup(ID,:);
                    
                    %fit x and y
                    splinegroupx = vertcat(x,extraknot(1),Bx);
                    splinegroupy = vertcat(y,extraknot(2),By);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = footanchorweight; weights(end) = bodyanchorweight; 
                    weights(end-1) = extraknotanchorweight; weights(end-2) = kneeanchorweight;
                else
                    %fit x and y
                    splinegroupx = vertcat(x,Bx);
                    splinegroupy = vertcat(y,By);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = footanchorweight; weights(end) = footanchorweight;
                    weights(end-1) = kneeanchorweight;
                end
                
            case 'E'
                %Body coordinates first
                if theta>0
                    targetgroup = pts;
                    %x axis = 0, clockwise positive
                    R = rotmat(theta);
                    proj = ((targetgroup-centroid)*R)+centroid; %allign to x axis
                    
                    %min and max x value
                    [~, maxids] = max(proj);
                    ID(1) = maxids(1); 
                    extraknot = targetgroup(ID,:);
                    
                    %fit x and y
                    splinegroupx = vertcat(Bx,extraknot(1),x);
                    splinegroupy = vertcat(By,extraknot(2),y);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = bodyanchorweight; weights(end) = footanchorweight; 
                    weights(2) = extraknotanchorweight; weights(3) = kneeanchorweight;
                else
                    %fit x and y
                    splinegroupx = vertcat(Bx,x);
                    splinegroupy = vertcat(By,y);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = bodyanchorweight; weights(end) = footanchorweight;
                    weights(2) = kneeanchorweight;
                end
           
            case 'S'
                if theta<0
                    targetgroup = pts;
                    %y axis = 0, clockwise positive
                    R = rotmat(-theta);
                    proj = ((targetgroup-centroid)*R)+centroid; %allign to x axis
                    
                    %min and max x value
                    [~, maxids] = max(proj);
                    ID(1) = maxids(2); 
                    extraknot = targetgroup(ID,:);
                    
                    %fit x and y
                    splinegroupx = vertcat(Bx,extraknot(1),x);
                    splinegroupy = vertcat(By,extraknot(2),y);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = bodyanchorweight; weights(end) = footanchorweight; 
                    weights(2) = extraknotanchorweight; weights(3) = kneeanchorweight;
                else
                    %fit x and y
                    splinegroupx = vertcat(Bx,x);
                    splinegroupy = vertcat(By,y);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = bodyanchorweight; weights(end) = footanchorweight;
                    weights(2) = kneeanchorweight;
                end
            case 'N'
                if theta>0
                    targetgroup = pts;
                    %y axis = 0, clockwise positive
                    R = rotmat(theta);
                    proj = ((targetgroup-centroid)*R)+centroid; %allign to x axis
                    
                    %min and max x value
                    [~, minids] = min(proj);
                    ID(1) = minids(2); 
                    extraknot = targetgroup(ID,:);
                    
                    %fit x and y
                    splinegroupx = vertcat(x,extraknot(1),Bx);
                    splinegroupy = vertcat(y,extraknot(2),By);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = footanchorweight; weights(end) = bodyanchorweight; 
                    weights(end-1) = extraknotanchorweight; weights(end-2) = kneeanchorweight;
                else
                    %fit x and y
                    splinegroupx = vertcat(x,Bx);
                    splinegroupy = vertcat(y,By);
                    
                    %set anchors
                    weights = ones(length(splinegroupx),1);
                    weights(1) = footanchorweight; weights(end) = bodyanchorweight;
                    weights(end-1) = kneeanchorweight;
                end
        end
        
        
        sp3 = spap2(3,3,splinegroupx,splinegroupy,weights);
        sp4 = spap2(4,4,splinegroupx,splinegroupy,weights);
        
        L1 = approxSplineLength(sp3);
        L2 = approxSplineLength(sp4);
        
        if 1.005*L1<L2
            spline = sp3;
        else
            spline = sp4;
        end
        
        imdat.fitting.legobj{n}.points = [splinegroupx,splinegroupy];
        imdat.fitting.legobj{n}.spline = spline;
    end
    stat.spline_fit = true;
else
    stat.spline_fit=false;
    classdat = [];
end
end

function R = rotmat(theta)
R = [cos(theta), -sin(theta);
    sin(theta),  cos(theta)];
end