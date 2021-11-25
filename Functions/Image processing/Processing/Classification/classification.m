function [imdat,stat] = classification(imdat,Settings,stat)
%CLASSIFICATION is the function used to classify pixel structures. Pixel
%structures are classified either as "Body", "Leg", or "Noise".

%Big box objects can never be classified as noise. If this happenes, adjust
%segmentation thresholds in the Runme.m file. 
warning('off','curvefit:fit:noStartPoint');
if stat.supergrouper == true
    %% Initialize
    c2s = @convertCharsToStrings; %make some more handy function handles
    print_to_console = false;
    
    LBsize = [imdat.processing.tracking.LBox.size];
    rstrct = imdat.processing.tracking.boxrangestrct.LBox;
    LBoxlabels = imdat.processing.labeling.LBoxlabels;
    weights = Settings.weights;
    supergroups = imdat.processing.grouping.supergroups;
    filtlabels = imdat.processing.labeling.filteredlabels;
    Largeboxdat = imdat.processing.tracking.Largeboxdat;
    
    sz = size(supergroups,2); %check
    L = 0; %counts the amount of classified legs
    B = 0; %counts the amount of classified bodies
    U = sz; %counts the amount of unclassified objects
    box = 0; %keeps track of the nth box (for indexing)
    supergroupids = 1:sz; %make a vector of all the group indices
    
    linearitythreshold = 0.05; % 5% this needs to be moved to a settings file
    
    %% Body classify
    %we loop over all objects to find a body object. There does not have to
    %be a body object.
    
    %Two cases would classify as a body: either its an extremely large box,
    %or is is a box with one of the long sides attached to the wall. Using
    %boundingboxes has the complication that a line at a 45 degree angle
    %will also give a large box and with a small actual volume. Therefore a
    %fill factor is used to compensate, taken from the pixel tracking
    %algorithm.
    
    for n = 1:sz
        class(n) = "unclassified";
        targetgroup = supergroups{n};
        
        %Test one: check if the group has a large box in it. If this is the
        %case, the supergrouplabel (which is the same as the index in the
        %group struct) should be equal to one of the LBoxlabels
        
        %If true, possible body group, if false, not a body group
        supergrouplabel = n;
        if ismember(supergrouplabel,LBoxlabels) == true
            nb = sum(LBoxlabels == supergrouplabel);
            index = find(LBoxlabels == supergrouplabel);
            for a = 1:nb
            box = box+1;
            %test: box location
            
            
            xmin = Largeboxdat{index(a)}.xmin; ymin = Largeboxdat{index(a)}.ymin;
            xmax = Largeboxdat{index(a)}.xmax; ymax = Largeboxdat{index(a)}.ymax;
            
            if xmin == 1 || ymin == 1 || xmax == 2000 || ymax == 2000
                %the box is at the boundary. check the following conditions
                if xmin == 1 || xmax == 2000
                    %box is touching left or right side
                    if (xmax - xmin) < (ymax - ymin) && Largeboxdat{index(a)}.fill > 0.6
                        %box is higher than it is wide, and is filled for
                        %more than 70%
                        class(n) = "body";
                        B = B+1;
                        U = U-1;
                        group_id(B) = n;
                        box_id(B) = index(a);
                    end
                    
                elseif ymin == 1 || ymax == 2000
                    %box = touching bottom or top side
                    if (xmax - xmin) > (ymax - ymin) && Largeboxdat{index(a)}.fill > 0.5
                        %box is wider than it is high, and is filled for
                        %more than 60%
                        class(n) = "body";
                        B = B+1;
                        U = U-1;
                        group_id(B) = n;
                        box_id(B) = index(a);
                    end
                    
                end
            elseif Largeboxdat{index(a)}.size*Largeboxdat{index(a)}.fill > 20000
                %check the size and fill ratio
                class(n) = "body";
                B = B+1;
                U = U-1;
                group_id(B) = n;
                box_id(B) = index(a);
            end
            end
        end
    end
    
    %It might happen that two objects get classified as the body. In this
    %case, the smaller box will be reset to "unclassified"
    
    if B>1 %two or more body objects were identified
        objectid = 1:sz; %make an index vector for all objects
        bodygroupid = objectid(class == "body"); %check which objects are classified as "body"
        for a = 1:length(box_id) %run over all objects classified as body
            boxsize(a) = Largeboxdat{box_id(a)}.size; %take the size from the largeboxdat structs
        end
        [~,idmax] = max(boxsize); %find the biggest
        class(setdiff(bodygroupid(idmax),bodygroupid)) = "unclassified"; %set class of all objects except largest to "unclassified"
        Body_id = bodygroupid(idmax);
        Bodybox_id = box_id(idmax);
        imdat.processing.classification.bodyobj.x = Largeboxdat{Bodybox_id}.centroidxy(1);
        imdat.processing.classification.bodyobj.y = Largeboxdat{Bodybox_id}.centroidxy(2);
        B = 1;
    elseif B == 1
        Body_id = group_id(B);
        Bodybox_id = box_id(B);
        imdat.processing.classification.bodyobj.x = Largeboxdat{Bodybox_id}.centroidxy(1);
        imdat.processing.classification.bodyobj.y = Largeboxdat{Bodybox_id}.centroidxy(2);
    end    
    
    %% Leg classify
    %We next loop over all over objects to see if it a leg. First we check
    %all the remaining big boxes 
    for n = 1:sz
        supergrouplabel = n;
        targetgroup = supergroups{supergrouplabel};
        if ismember(supergrouplabel,LBoxlabels) == true && class(n) == "unclassified"
            %% ----------Test 1--------- %%
            %rsquare for straight line (how well does a straight line explain the group?)
            
            model = fittype('a*x+b');
            [~,GOFline] = fit(targetgroup(:,1),targetgroup(:,2),model);%,'start',[targetgroup(1,1),targetgroup(1,2)]);
            if GOFline.rsquare>0.85
                Bflag(1) = 1;
            else
                Bflag(1) = -0.5;
            end
            scores(1) = GOFline.rsquare*Bflag(1);
            
            
            %%%-------------------------%%%
            %% ----------Test 2--------- %%
            %Test two, rsquare for 2nd order polynomial (how well does a quadratic
            %function explain the group?) (would be high for straight lines and
            %feet)
            model = fittype('a*x^2+b*x+c');
            [~,GOFquad] = fit(targetgroup(:,1),targetgroup(:,2),model);%,'start',[targetgroup(1:3,1),targetgroup(1:3,2)]);
            if GOFquad.rsquare>0.85
                Bflag(2) = 1;
            else
                Bflag(2) = -0.5;
            end
            scores(2) = GOFline.rsquare*Bflag(2);
            %%%-------------------------%%%
            %% ---------scoring--------- %%
            if sum(scores) > 0
                class(n) = "leg";
                L = L+1;
                U = U-1;
            end 
            
            if B>=1
            %% Find its location if a body group was identified (usefull later)
            %location is divided into 4 quadrants. Doing so edge cases lie
            %in the stable region of the trig functions, resulting in a
            %more stable algorithm overal. 
                BodyX = Largeboxdat{Bodybox_id}.centroidxy(1);
                BodyY = Largeboxdat{Bodybox_id}.centroidxy(2);
                %First check quadrant (N/E/S/W)
                %a = dy+dx
                %b = dy-dx
                
                %N: a<0 & b<0, E: a>0 & b<0
                %S: a>0 & b>0, W: a<0 & b>0
                
                %check the first and last point of the body group, to take
                %the average position
                
                p1 = targetgroup(1,:); p2 = targetgroup(end,:);
                dx = (p1(1)-BodyX+p2(1)-BodyX)/2;
                dy = (p1(2)-BodyY+p2(2)-BodyY)/2;
                
                a = dy+dx;
                b = dy-dx;
                
                if a<0 && b<0
                    LOC(n) = "N";
                elseif a>0 && b<0
                    LOC(n) = "E";
                elseif a>0 && b>0
                    LOC(n) = "S";
                elseif a<0 && b>0
                    LOC(n) = "W";
                end
                
                imdat.processing.classification.location(n) = LOC(n);
            end
        end
    end
    
    %% Small structures
    %now we have two cases: there was a body object, there was no body
    %object.
    if B>0 
        class_algorithm = "body";
    elseif B == 0
        class_algorithm = "no_body";
    end
    
    switch class_algorithm
        case "body"
            %% Body object orientation and location %%
            %LOCATE THE BODY CENTROID, NEEDED FOR LEG ORIENTATION AND
            %LOCATION RELATIVE TO THE BODY POSITION
            
            centroid = Largeboxdat{Bodybox_id}.centroidxy;
            BodyX = centroid(1);
            BodyY = centroid(2);
                        
            %% small object identification
            smallobjectids = supergroupids(class == "unclassified");
            for n = 1:length(smallobjectids) %only check unclassified objects
                targetgroup = supergroups{smallobjectids(n)};
                i = smallobjectids(n);
                
                %First check quadrant (N/E/S/W)
                %a = dy+dx
                %b = dy-dx
                
                %N: a<0 & b<0, E: a>0 & b<0
                %S: a>0 & b>0, W: a<0 & b>0
                
                %check the first and last point of the body group, to take
                %the average position
                
                p1 = targetgroup(1,:); p2 = targetgroup(end,:);
                dx = (p1(1)-BodyX+p2(1)-BodyX)/2;
                dy = (p1(2)-BodyY+p2(2)-BodyY)/2;
                
                a = dy+dx;
                b = dy-dx;
                
                if a<0 && b<0
                    LOC(n) = "N";
                elseif a>0 && b<0
                    LOC(n) = "E";
                elseif a>0 && b>0
                    LOC(n) = "S";
                elseif a<0 && b>0
                    LOC(n) = "W";
                end
                
                imdat.processing.classification.location(i) = LOC(n);
                %For each of the directions, we rotate the pixel cluster to
                %allign with the x axis, to find the closest and furthest
                %point.
                %R = |cos (theta),-sin (theta)|
                %    |sin (theta), cos (theta)|
                %
                %R is the rotation matrix around the origin [0,0]. So to
                %move the targetgroup about the centroid of the Body, we
                %must translate the targetgroup by the distance of the
                %bodygroup to the origin and back.
                %
                %rotation about [0,0] = ((targetgroup - centroid)*R)
                %rotation about centroid = ((targetgroup - centroid)*R) + centroid
                %
                %We rotate with -theta, because the theta is the angle
                %between the axis to project on and the group. To move the
                %group back to the axis a rotation by -theta is needed.
                
                switch LOC(n)
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

                %Knowing which point is closest and which is furthest, we
                %can draw a line and check the linearity factor as a
                %measure for its direction, is the group facing the body or
                %not?
                
                B_p1 = norm(targetgroup(ID(1),:)-centroid);
                B_p2 = norm(targetgroup(ID(2),:)-centroid);
                p1_p2 = norm(targetgroup(ID(1),:)-targetgroup(ID(2),:));
                
                if abs(1-B_p1./(B_p2+p1_p2)) < linearitythreshold
                    %class is expected to be "leg", but there is still
                    %cases where noise just resembles a leg object.
                    
                    %firstly perfectly placed droplet noise. This noise
                    %will always be circular, so we can try fitting the
                    % noise group to a circle to test for this.
                    SumX = sum([targetgroup(ID(1),1),targetgroup(ID(2),1)]);
                    SumY = sum([targetgroup(ID(1),2),targetgroup(ID(2),2)]);
                    groupsize = 2;
                    
                    %first the centroid is computed, next the distance of the
                    %points to the centroid is calculated. If the std of these
                    %distances is smaller than a threshold value, the points fall
                    %on a circle and can be classified as droplet noise.
                    targetcentroid = [SumX/groupsize,SumY/groupsize];
                    Euclid = sqrt((targetgroup(:,1)-targetcentroid(1)).^2+(targetgroup(:,2)-targetcentroid(2)).^2);
                    
                    if std(Euclid)<10
                        NOISEFLAG(1) = 1;
                    else
                        NOISEFLAG(1) = 0;
                    end
                    
                    %Furthermore a perfectly placed group of random pixels,
                    %such as segmentation artifacts, floats around, these
                    %will not be well described by a line.
                    
                    %We use the same check as in the big box group
                    %rsquare for straight line (how well does a straight line explain the group?)
            
                    model = fittype('a*x+b');
                    [~,GOFline] = fit(targetgroup(:,1),targetgroup(:,2),model);%,'start',[targetgroup(1,1),targetgroup(1,2)]);
                    if GOFline.rsquare>0.85
                        NOISEFLAG(2) = 0;
                    else
                        NOISEFLAG(2) = -0.5;
                    end
                    
                    %If any of the noiseflags were triggered, group is
                    %considered noise.
                    if sum(NOISEFLAG)>0
                        class(i) = "noise";
                    else
                        class(i) = "leg";
                    end
                else
                    class(i) = "noise";
                end
                
            end
            
        case "no_body"
          %In the case no body was found, there will only be leg objects
          %and noise structures.
          
          %We only have to investigate the groups that do not belong to one
          %of the groups that have a big box (they were already classified
          %as leg object).
          
          %What we do have to do is figure out the direction of the legs.
          %There is a number of cases: There are multiple legs in view,
          %there is only one leg in view, there is no leg in view.
          
          if L == 0
              situation = "no_leg";
          elseif L == 1
              situation = "one_leg";
          elseif L>1
              situation = "multiple_legs";
          end
          
          switch situation
%               case "no_leg"
%                   %in this case there is no contact expected, the only case
%                   %would be if a group of densely clustered pixels would
%                   %touch the edge of the screen, indicating a tip of a leg
%                   %crossing into the FOV. There is however, in this single
%                   %frame, not enough information to classify this as a leg.
%                   %
%                   %If this situation arises, the frame will be flagged for
%                   %manual inspection. All structures will be labeled as
%                   %noise.
%                   
%                   smallobjectids = supergroupids(class == "unclassified");
%                   for n = 1:length(smallobjectids) %only check unclassified objects
%                       i = smallobjectids(n);
%                       targetgroup = supergroups(i);
%                       
%                       class(i) = "noise";
%                       
%                       S(1) = sum(targetgroup(:,1)==1); %left FOV bound
%                       S(2) = sum(targetgroup(:,1)==2000); %right FOV bound
%                       S(3) = sum(targetgroup(:,2)==1); %top FOV bound
%                       S(4) = sum(targetgroup(:,2)==2000); %bottom FOV bound
%                       
%                       if sum(S) > 3 %at least 3 points are on the border
%                           imdat.comment = "Check frame manually!";
%                       end
%                   end
%                   
%               case "one_leg"
%                   %in this case, the body is outside of the FOV and only
%                   %one leg is visible. The leg will have a direction and
%                   %the body is expected to be outside the FOV at the
%                   %closest edge in the direction of the group.
%                   
%                   %if any groups fall in between the expected body location
%                   %and the leg, they will be considered part of the leg.
%                   %Any other group will be labeled as noise.
%                   
%                   %Find the direction:
%                   %principal component analysis will be used to find the
%                   %most dominant axis.
%                   leggroupid = supergroupids(class == "leg");
%                   leggroup = supergroups(leggroupid);
%                   
%                   coeff = pca(leggroup);
%                   theta = acos(coeff(1,1));
%                   
%                   if -pi/4 <= theta && pi/4 > theta
%                       wall = "East";
%                   elseif pi/4 <= theta && 3*pi/4 > theta
%                       wall = "South";
%                   elseif (3*pi/4 <= theta && pi > theta) || (-pi<= theta && -3*pi/4 > theta)
%                       wall = "west";
%                   elseif -3*pi/4 <= theta && -pi/4 > theta
%                       wall = "north";
%                   end
%                   
%                   smallobjectids = supergroupids(class == "unclassified");
%                   for n = 1:length(smallobjectids) %only check unclassified objects
%                       i = smallobjectids(n);
%                       targetgroup = supergroups(i);
%                       switch wall
%                           %a part of a leg must be between the leg and the
%                           %wall the leg is facing towards
%                           case "North"
%                               if max(targetgroup(:,2))<min(leggroup(:,2))
%                                   class(n) = "leg";
%                               else
%                                   class(n) = "noise";
%                               end
%                           case "East"
%                               if min(targetgroup(:,1))<max(leggroup(:,1))
%                                   class(n) = "leg";
%                               else
%                                   class(n) = "noise";
%                               end
%                           case "South"
%                               if min(targetgroup(:,2))>max(leggroup(:,2))
%                                   class(n) = "leg";
%                               else
%                                   class(n) = "noise";
%                               end
%                           case "West"
%                               if max(targetgroup(:,1))<min(leggroup(:,1))
%                                   class(n) = "leg";
%                               else
%                                   class(n) = "noise";
%                               end
%                       end
%                   end
%                   
%                   %SOME ISSUES EXPECTED WHEN A LEG IS IN A CORNER GOING
%                   %FROM ONE WALL TO ANOTHER WALL. WILL DEBUG THAT IF I COME
%                   %ACROSS IT
%                   
%               case "multiple_legs"
%                   %Both legs are expected to be directed towards the body,
%                   %which is located outside the FOV.
%                   
%                   %find the angle of both legs, check for the wall where
%                   %they converge.
%                   leggroupids = supergroupids(class == "leg");
%                   for n = 1:length(leggroupids)
%                       leggroupid = leggroupids(n);
%                       leggroup = supergroups(leggroupid);
%                       
%                       coeff{n} = pca(leggroup);
%                       
%                       SumX = sum(targetgroup(:,1));
%                       SumY = sum(targetgroup(:,2));
%                       groupsize = size(targetgroup,1);
%                       targetcentroid{n} = [SumX/groupsize,SumY/groupsize];
%                       
%                   end
%                   
%                   %Make a linear set of equations from the first two legs
%                   A = [coeff{1}(1,1), -coeff{1}(2,1);
%                        coeff{2}(1,1), -coeff{2}(2,1)];
%                   B = [targetcentroid{1}(2)-targetcentroid{1}(1);
%                        targetcentroid{2}(2)-targetcentroid{2}(1)];
%                   intXY = linsolve(A,B);
%                   
%                   if abs(intXY(1))>abs(intXY(2)) %West or east
%                       if intXY(1)<0 %west
%                           wall = "West";
%                       else
%                           wall = "East";
%                       end
%                   else %north or south
%                       if intXY(2) < 0
%                           wall = "North";
%                       else
%                           wall = "South";
%                       end
%                   end
%                   
%                   
% %                   a = size(eq,2);
% %                   i = 1;
% %                   while a>0
% %                       sys = eq(i
% %                   end
          end
          %
    end
    imdat.processing.classification.class = class;
    imdat.processing.classification.nLeg = L;
    imdat.processing.classification.nBody = B;
end
end

function R = rotmat(theta)
    R = [cos(theta), -sin(theta);
         sin(theta),  cos(theta)];  
end

