%auto_selector_string
drivelist = getdrives;
currentfolder = pwd;
flag = false; %Stop searching directories when the Events folder is found

regularstring = 'Mosquito_adhesion_thesis_RAW_20210325_20210402_LvdB';

a=1;
while a<=size(drivelist,2) && flag == false
    cd(drivelist{a})
    if isfolder(regularstring)==1
        %find the xlsx file: go down one layer, grab the events.xlsx
        drivename = pwd;
        addpath([drivename,regularstring]);
        eventtable = readtable('Events.xlsx');
        cd(currentfolder)
        flag = true;
    elseif isfile('Events.xlsx')==1
        eventtable = readtable('Events.xlsx');
        cd(currentfolder)
        flag = true;
    else
        warning(['no events folder found in ',drivelist{a}])
        cd(currentfolder)
    end
    a = a+1;
end
clear flag
%%
day = eventtable.day{setno};
runno = eventtable.runno(setno);
drive = drivename;
camera = eventtable.camera{setno};
frames = [eventtable.frameStart(setno), eventtable.frameEnd(setno)];
comment = eventtable.comment{setno};
framerate = eventtable.framerate{setno};


% Compile creates a folder path string
altfolder = [drive,'Mosquito_adhesion_thesis_RAW_20210325_20210402_LvdB\2021_',day,'_Mosquito_Adhesion_Thesis\Run',num2str(runno),'\',camera];

% Create rundat 
rundat.day = day;
rundat.run = runno;
rundat.drive = drive;
rundat.camera = camera;
rundat.frames = frames;
rundat.comment = comment;
rundat.framerate = framerate;

