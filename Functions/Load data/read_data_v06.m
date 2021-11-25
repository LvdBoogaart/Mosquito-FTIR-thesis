function [datastore,imdat,background] = read_data_v06(day,run,camera,drive,frames,varargin)
%READ_DATA_V05 Reads the folder from the drive, and imports the files into
%a image data store and a meta data struct. Also extracts one background
%image for background substraction.
%Author: Luc van den Boogaart
%Email: lucvdboogaart@gmail.com

c2s = @convertCharsToStrings;

nargs = nargin;
n = 1;
a = 1;
sampledataflag = false;
usealtfolder = false;
if nargs > 5
    while n<=size(varargin,2)
        objectflag{a} = varargin{n};
        object{a} = varargin{n+1};
        a = a+1;
        n = n+2;
    end 
end

for n = 1:size(objectflag,2)
    flag = objectflag{n};
switch flag
    case 'usesampledata'
        sampledataflag = object{n};
    case 'altfolder'
        altfolder = object{n};
        if isempty(altfolder)==false
            usealtfolder = true;
        end
end
end

%% Folder management
%Compile string for target folder

%Store current working folder string
currentfolder = pwd;
if usealtfolder == false
if sampledataflag == false
    folderpath = compile(day,run,camera,drive);
    
    %Set working folder to target folder
    cd(folderpath)
else
    folderpath = [currentfolder,'\sampledata'];
    
    %Set working folder to target folder
    cd(folderpath)
end
else
    folderpath = altfolder;
    cd(folderpath)
end

%Be aware that manually specifying an altfolder is very error prone. Make
%sure to specify the folder that links to the set of images as specified in
%the selection code

%% Initialize extraction
%Load folder and contents
List = dir(folderpath);
n = frames(2)-frames(1);

if n >= 100
    %initialize process indicator
    frac = floor(n/100);
    p = 1;
    processtype = 'large';
else
    frac = floor(100/n);
    p = frac;
    processtype = 'small';
end

%Get filename of topfile in the folder
name = List(3).name;    %This has to be 3, 1 and 2 are . and .. entries for unknown reasons

%% Set regular expression for extraction
%File names are regular expressions and can be accessed using the regexp
%function.
expression = '(?<date>\d+_\d+_\d+)_(?<run>\w*N\d)_(?<camera>[A-Z0-9]+)_(?<number>\d+)(?<filetype>\W\w+)';
filedat = regexp(name,expression,'names');
start_n = str2double(filedat.number)+frames(1);

%% Make datastore (access handle for the workspace from any working folder)
tic
disp('start read')
disp('0% done')
ds = imageDatastore(folderpath);
datastore = subset(ds,frames(1)+2:frames(2)+2);
disp('datastore initialized')
toc


%% Make data struct (containing meta data for image files)
tic
Tstart = tic;

for n = 1:n+1
    number = start_n;
    if number < 10000
        readstring = [filedat.date,'_',filedat.run,'_',filedat.camera,'_0',num2str(number),filedat.filetype];
    else
        readstring = [filedat.date,'_',filedat.run,'_',filedat.camera,'_',num2str(number),filedat.filetype];
    end
    
    %Storing meta data from string
    imdat{n,1}.Imagedat.camera = filedat.camera;
    imdat{n,1}.Imagedat.date = filedat.date;
    imdat{n,1}.Imagedat.run = filedat.run;
    imdat{n,1}.Imagedat.name = readstring;
    imdat{n,1}.Imagedat.number = number;
    imdat{n,1}.Imagedat.string = c2s(readstring);
    
    p = progresstrack(n,frac,p,processtype,Tstart);
    
    start_n = start_n+1;

end

clc
toc;
Ttotal = toc(Tstart)
disp('read_data_v05.m')
disp('100% done')

%% Save background image
background = ds.Files{1};

%% Return working folder
cd(currentfolder)
end

function folderpath = compile(day,run,camera,drive)
% Compile creates a folder path string
folderpath = [drive,'\Mosquito_adhesion_thesis_RAW_20210325_20210402_LvdB\2021_',day,'_Mosquito_Adhesion_Thesis\Run',num2str(run),'\',camera];
end

function p = progresstrack(n,frac,p,processtype,Tstart)
%Showing process
switch processtype
    case 'large'
        if rem(n,frac)==0
            clc
            toc;
            Ttotal = toc(Tstart)
            disp('read_data_v05.m')
            disp([num2str(p),'% done'])
            p = p+1;
            tic;
        end
    case 'small'
        clc
        toc;
        Ttotal = toc(Tstart)
        disp('read_data_v05.m')
        disp([num2str(p),'% done'])
        p = p+frac;
        tic;
end
end
