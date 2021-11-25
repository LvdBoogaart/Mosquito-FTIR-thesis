function [imdat,stat] = objectgrouper(imdat,settings,stat)
%OBJECTGROUPER Summary of this function goes here
%   Detailed explanation goes here
c2s = @convertCharsToStrings; %make some more handy function handles
nBody = imdat.processing.classification.nBody;
nLeg = imdat.processing.classification.nLeg;
print_to_console = true;
warning('off','curvefit:fit:noStartPoint');

if nBody == 1
    
    BodyX = imdat.processing.classification.bodyobj.x;
    BodyY = imdat.processing.classification.bodyobj.y;
    class = imdat.processing.classification.class;
    supergroups = imdat.processing.grouping.supergroups;
    location = imdat.processing.classification.location;
    centroid = [BodyX,BodyY];
    
    
    
    xmat = zeros(3,nLeg*2+1);
    ymat = zeros(3,nLeg*2+1);
    nametab = cell(1,nLeg*2+1);
    k = 0;
    xmat(1,1) = BodyX;
    ymat(1,1) = BodyY;
    nametab{1,1} = "Body";
    
    sz = size(supergroups,2);
    
    for n = 1:sz
        %Make a matrix in the form:
        %|Bx       |L1x1       |L1x2       |...|Lnx1       |Lnx2       |
        %|Bx-Bx    |Bx-L1x1    |Bx-L1x2    |...|Bx-Lnx1    |Bx-Lnx2    |
        %|(Bx-Bx)^2|(Bx-L1x1)^2|(Bx-L1x2)^2|...|(Bx-Lnx1)^2|(Bx-Lnx2)^2|
        %
        if class(n) == "leg"
            k = k+1;
            groupdat{k}.label = n;
            leggroup_id(k) = n;
            LOC = location(n);
            targetgroup = supergroups{n};
            
            p1 = targetgroup(1,:); p2 = targetgroup(end,:);
            dx = (p1(1)-BodyX+p2(1)-BodyX)/2;
            dy = (p1(2)-BodyY+p2(2)-BodyY)/2;
            
            switch LOC
                case "N"
                    %y axis = 0, clockwise positive
                    theta = atan(dx/dy);
                    R = rotmat(-theta);
                    proj = ((targetgroup-centroid)*R)+centroid;
                    
                    %min and max y value
                    [~, minids] = min(proj);
                    [~, maxids] = max(proj);
                    ID(1) = minids(2); %furthest y
                    ID(2) = maxids(2); %closest y
                case "E"
                    %x axis = 0, clockwise positive
                    theta = atan(dy/dx);
                    R = rotmat(-theta);
                    proj = ((targetgroup-centroid)*R)+centroid;
                    
                    %min and max x value
                    [~, minids] = min(proj);
                    [~, maxids] = max(proj);
                    ID(1) = maxids(1); %furthest y
                    ID(2) = minids(1); %closest y
                case "S"
                    %y axis = 0, clockwise positive
                    theta = atan(dx/dy);
                    R = rotmat(-theta);
                    proj = ((targetgroup-centroid)*R)+centroid;
                    
                    %min and max y value
                    [~, minids] = min(proj);
                    [~, maxids] = max(proj);
                    ID(1) = maxids(2); %furthest y
                    ID(2) = minids(2); %closest y
                case "W"
                    %x axis = 0, clockwise positive
                    theta = atan(dy/dx);
                    R = rotmat(-theta);
                    proj = ((targetgroup-centroid)*R)+centroid;
                    
                    %min and max x value
                    [~, minids] = min(proj);
                    [~, maxids] = max(proj);
                    ID(1) = minids(1); %furthest
                    ID(2) = maxids(1); %closest
            end
            
            xmat(1,2*k) = targetgroup(ID(1),1);     %xfar
            xmat(1,2*k+1) = targetgroup(ID(2),1); %xclose
            ymat(1,2*k) = targetgroup(ID(1),2);     %yfar
            ymat(1,2*k+1) = targetgroup(ID(2),2); %yclose
            nametab{1,2*k} = c2s(['Leg',num2str(k),'pfar']);  %nom
            nametab{1,2*k+1} = c2s(['Leg',num2str(k),'pclose']);
            extremes(k,:) = [targetgroup(ID(1),:),targetgroup(ID(2),:)];
        end
    end %prepare matrixes
    
    %subtract the body position from all points, to find dB_P
    xmat(2,:) = xmat(1,:)-xmat(1,1);
    ymat(2,:) = ymat(1,:)-ymat(1,1);
    
    %create a matrix with all euclidean distances
    Euclidmat = sqrt((xmat(1,:)-xmat(1,:)').^2+(ymat(1,:)-ymat(1,:)').^2);
    
    %A leg is in between another leg and the body if the distance from the
    %body's center to the distal point of intermediate leg + the distance
    %from the distal point intermediate to the proximal point of another
    %leg is roughly equal to the distance of the body to the proximal point
    %of that 2nd leg. The distances of the body to all of these points are
    %in the Euclidmat, so we now need to select the right pairs to check.
    
    %We loop through all groups, taking the distance Body to Distal point,
    %called dB_P1, as a basis. (p1 corresponds to the points in the group
    %furthest away to the body, as specified above)
    
    for n = 1:k
        %p2 is closer to body
        dB_P1i = 2*n; %index far dB_P1
        dB_P1 = Euclidmat(dB_P1i,1); %distance Body to far point
        dB_P2 = Euclidmat(1,3:2:k*2+1); %distance Body to proximal point of all other legs
        dP1_P2 = Euclidmat(dB_P1i,3:2:k*2+1); %distance between P1 and all P2's
        
        %when dB_P2 = dB_P1+dP1_P2: (dB_P2./(dB_P1+dP1_P2) approaches 1,
        %meaning the checkmat approaches 0.
        checkmat(n,:) = abs(1-(dB_P2./(dB_P1+dP1_P2))); %check relative difference
        
        %Set a placeholder type "distal" for each leg
        placeholder_type(n) = "distal";
        %Set every group initially as its own parent
        parent(n) = leggroup_id(n);
    end
    
    %Find all cases where dB_P2 = (dB_P1+dP1_P2)+/-threshold
    threshold = 0.02; %set to 2% deviation
    [r,c] = find(checkmat<threshold); %Check the entire matrix
    
    %% Realocate parents
    %Initialize the amount of legs as the amount of supergroups (k)
    NLegs = k; %initialize the amount of leg objects to be made, assuming all point groups are individual legs
    
    %If there was a group found that satisfied the condition, r is not empty
    if isempty(r) == 0 %row is used here because find does not create a c variable when no objects are found that satisfy the condition
        
        %now run the algorithm to identify and classify the intermediate
        %groups:
        %
        %All rows signal an intermediate leg, so we run for size of r
        %The column in checkmat identifies the parent group, the
        %row the child group. So set the parent for the groups in the
        %row as the column.
        %
        for a = 1:length(r)
            R = r(a);
            C = c(a);
            
            placeholder_type(R) = "intermediate";
            parent(R) = leggroup_id(C);
        end
    else
        if print_to_console == true
            disp('No intermediate groups')
        end
    end
    imdat.processing.classification.groupdat = groupdat;
    
    %Interpret data
    groupid = leggroup_id;
    parentgroups = unique(parent);
    
    NLegs = length(parentgroups);
    for n = 1:NLegs
        id = ['Leg ',num2str(n)];
        legobj{n}.id = c2s(id);
        legobj{n}.location = [location{groupid(parent == parentgroups(n))}];
        legobj{n}.groupid = groupid(parent == parentgroups(n))';
        %find out which groups have the same parent
        legobj{n}.grouplabel = placeholder_type(parent == parentgroups(n));
        legobj{n}.pdist = extremes(parent == parentgroups(n),1:2);
        legobj{n}.pprox = extremes(parent == parentgroups(n),3:4); 
        if legobj{n}.pdist(1,1)<legobj{n}.pprox(1,1)
            legobj{n}.direction = "inwards";
        else
            legobj{n}.direction = "outwards";
        end
        
        %quick fix
        pd = legobj{n}.pdist;
        if pd(1)<=500 && pd(2)<=500
        legobj{n}.label = 'LT';
        elseif pd(1)>500 && pd(2)<=500 
            legobj{n}.label = 'RT';
        elseif pd(1)<=500 && pd(2)>500
            legobj{n}.label = 'LB';
        else 
            legobj{n}.label = 'RB';
        end
    end
    
    %output is a leg object, which has all groups inside it
    imdat.processing.classification.legobj = legobj;
    stat.groupclassifier = true;
    
    
else
    %There is no body. SKIP THIS CASE FOR NOW
end
end

function R = rotmat(theta)
R = [cos(theta), -sin(theta);
    sin(theta),  cos(theta)];
end
