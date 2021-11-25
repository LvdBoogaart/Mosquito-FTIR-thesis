%Driver script for data analysis Mosquito Thesis project
% Author: Luc van den Boogaart

time.tstart = tic;
%% Set operating mode
run runtype.m

%% Load and apply settings
run Initialize.m
ImTrackSettings = overwrite_default_settings(settings);

%% Load data
[im_datastore,imdat,background] = read_data_v06(day,runno,camera,drive,frames,'usesampledata',usesampledata,'altfolder',altfolder);

%% Image preprocessing
%_create datastore & data struct_

if mode.preprocessing == true
    
%_Downsample to uint 8_
[imdat,background8b] = downsample16to8b(im_datastore,imdat,background);

%_filtered background_
imdat = backgroundsubtractv3(settings,imdat,'filtersetting','single');

%_apply threshold_
imdat = applythreshold(settings,imdat);

end

%% Image segmentation
%_segement the image using estimated thresholds_%
nframes = frames(2)-frames(1)+1;

if mode.segmentation == true
time.tsegment = tic;
    for i = 1:nframes
        [imdat{i},stat{i}] = imagesegmentation_v2(imdat{i},ImTrackSettings); %segment images
        [imdat{i},stat{i}] = imagelabel(imdat{i},stat{i}); %Create BW Label
        clc
        disp('Image segmentation')
        disp(['Image ',num2str(i),' of ',num2str(nframes)])
        toc
    end
    
disp(newline+"segmentation time elapsed:")
toc(time.tsegment)
disp(newline+"Total time elapsed:")
toc(time.tstart)
end

%% Image processing
%_perform tracking, labeling and grouping operations_%

if mode.processing == true
    time.tprocessing = tic;
for i = 1:nframes
    [imdat{i},stat{i}] = boxtrack(imdat{i},ImTrackSettings,stat{i}); %Boundingboxtracking
    [imdat{i},stat{i}] = unfoldtrackdat(imdat{i},'all',stat{i}); %unfolding csm lists all boxes
    [imdat{i},stat{i}] = unfoldtrackdat(imdat{i},'LBox',stat{i}); %unfolding csm lists large boxes (subset of all boxes)
    [imdat{i},stat{i}] = scancenters(imdat{i},ImTrackSettings,stat{i}); %Euclid and DBScan
    [imdat{i},stat{i}] = removedoubles(imdat{i},stat{i}); %Filter out centers that lie inside the large Boxes
    [imdat{i},stat{i}] = correctlabels(imdat{i},stat{i}); %correct label if LBox is mislabeled as noise
    [imdat{i},stat{i}] = pixeltrackerv2(imdat{i},ImTrackSettings,stat{i}); %find xy location of pixels inside boxes and label pixels
    [imdat{i},stat{i}] = datareorganise(imdat{i},stat{i}); %move around some data to make the struct reflect the folder structure
    [imdat{i},stat{i}] = supergrouper(imdat{i},stat{i}); %advanced grouping
    
    clc
    disp('Image processing')
    disp(['Image ',num2str(i),' of ',num2str(nframes)])
    toc
    imdat{i}.identifier = "imagetracker struct";
end

disp(newline+"Processing time elapsed:")
toc(time.tprocessing)
disp(newline+"Total time elapsed:")
toc(time.tstart)
end


%% Classification
%_classify pixel clusters as legs, body or noise_%
if mode.classification == true
time.tclass = tic;
for i = 1:nframes
    [imdat{i},stat{i}] = classification(imdat{i},settings,stat{i});
    [imdat{i},stat{i}] = objectgrouper(imdat{i},settings,stat{i});
    clc
    disp('Image classification algorithm')
    disp(['Image ',num2str(i),' of ',num2str(nframes)])
    toc
    

end
disp(newline+"Classification time elapsed:")
toc(time.tclass)
disp(newline+"Total time elapsed:")
toc(time.tstart)
end
%% Fitting
%_fit splines to the legs_%

if mode.fitting == true   
time.tfitting = tic;
for i = 1:nframes
    [imdat{i},stat{i}] = spline_fit(imdat{i},stat{i});
    clc
    disp('spline fit algorithm')
    disp(['Image ',num2str(i),' of ',num2str(nframes)])
    toc
end
disp(newline+"Fitting time elapsed:")
toc(time.tfitting)
disp(newline+"Total time elapsed:")
toc(time.tstart)
end


%% sampling 
%plot figure for analysis
time.tsampling = tic;
if mode.sampling == true   
    for i = 1:nframes
        
        figureplotter_v3('Newfig',imdat{i}.Imagedat.raw,imdat{i},'Spline',[]);

        %Find offset curves and project points on
        offset = 1.4; %width of the leg
        imdat{i} = Get_Bounds(imdat{i},offset);
        
        %bresenham line interpolation of 
        imdat{i}.sampling.brescurves.cb = bresenhamv2(imdat{i}.sampling,'serial','0');
        imdat{i}.sampling.brescurves.cb1 = bresenhamv2(imdat{i}.sampling,'serial','1');
        imdat{i}.sampling.brescurves.cb2 = bresenhamv2(imdat{i}.sampling,'serial','2');
        imdat{i}.sampling.brescurves.cbp = bresenhamv2(imdat{i}.sampling.c1,imdat{i}.sampling.c2,'parallel');
        
        %group the pixels
        %This part is by far the most time-consuming. Can possibly be sped
        %up by finding an alternative for inpolygon using masks. Tricky
        %though. 
        imdat{i}.sampling.framedat = grouppixels(imdat{i}.sampling.brescurves);
        
        clc
        disp('sampling algorithm')
        disp(['Image ',num2str(i),' of ',num2str(nframes)])
        toc 

        close(gcf())
    end
    disp(newline+"sampling time elapsed:")
    toc(time.tsampling)       
    disp(newline+"Total time elapsed:")
    toc(time.tstart)
end

%% Analysis
if mode.analysis == true
    time.tanalysis = tic;
    for i = 1:nframes
        tic
        imdat{i} = cellmasks(settings,imdat{i},imdat{i}.sampling.framedat,imdat{i}.sampling.brescurves);
        clc
        disp('cell masks')
        disp(['Image ',num2str(i),' of ',num2str(nframes)])
        toc
    end
    
  
    %subtract backgrounds
    imdat = backgroundsubtractv3(settings,imdat,'filtersetting','double','output','int8','fieldname','filtered','gausspass',2,'noisethreshold',5);
    
 
    for i = 1:nframes
        tic
        imdat{i} = extract_grays(settings,imdat{i},'imfromimdat','raw');
        imdat{i} = extract_grays(settings,imdat{i},'imfromimdat','filtered');
        clc
        disp('Extract grays')
        disp(['Image ',num2str(i),' of ',num2str(nframes)])
        toc
    end
disp(newline+"analysis time elapsed:")
toc(time.tanalysis)       
disp(newline+"Total time elapsed:")
toc(time.tstart)        
end


%% Visualization
frames = [30];
if mode.plotting == true
    for i = frames

%         %segmented
%         figureplotter_v3('Newfig',[],imdat{i},'Boxes',[],'color','r');
%         figureplotter_v3('Overlay',imdat{i},'Centers',[],'Labeled',[],'Legend',[]);
%         figureplotter_v3('Overlay',imdat{i},'Mask');
%         title(['segmented, frame ',num2str(i)]);
        
        %raw
        figureplotter_v3('Newfig',imdat{i}.Imagedat.raw);
        figureplotter_v3('Overlay',imdat{i},'Boxes',[],'color','r');
        figureplotter_v3('Overlay',imdat{i},'Centers',[],'Labeled',[],'Legend',[]);
        figureplotter_v3('Overlay',imdat{i},'Mask');
        figureplotter_v3('Overlay',imdat{i},'Spline',[]);
        title(['raw, frame ',num2str(i)])
        
        %threshold curves
        plotprofiles(i,'raw')
        plotprofiles(i,'filtered')
        drawnow

    end
end

%% Contact area
for n = 1:nframes
    imdat{n} = contact_area(imdat{n},'threshold',5,'padding',2,'leg','RB');
    contactarea(n) = imdat{n}.analysis.contactarea.RB;
end
figure()
plot(1:nframes,contactarea)
xlabel('t [ms]')
xticks([0 20 40 60 80 100 120 140 160])
xticklabels({'0' '40' '80' '120' '160' '200' '240' '280' '320'})
ylabel('contact area [µm^2]')
title('Contact area over time, right hind leg')
hold on
wn = 0.05;
filtered = lowpass(contactarea,wn);
plot(1:nframes,filtered)
%%

animate_series(imdat,[1:150],contactarea,'t_pause',0.05,'set','filtered','scaled');