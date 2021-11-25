%Runtype script, used by the driver to select the operating mode

switch Operatingmode
    case 'standard'
        %True
        mode.segmentation = true;
        mode.preprocessing = true;
        mode.processing = true;
        mode.classification = true;
        mode.fitting = true;
        mode.sampling = true;
        mode.plotting = true;
        mode.analysis = true;        
        %False        
    case 'plotting'
        %True
        mode.plotting = true;
        mode.analysis = true;       
        %False
        mode.segmentation = false;
        mode.preprocessing = false;
        mode.classification = false;
        mode.fitting = false;
        mode.sampling = false;
        mode.processing = false;
    case 'segmentation'
        %True
        mode.segmentation = true;
        mode.preprocessing = true;
        %False
        mode.classification = false;
        mode.fitting = false;
        mode.sampling = false;
        mode.plotting = false;
        mode.analysis = false;
        mode.processing = false;
    case 'load_data'
        %True
        %False
        mode.segmentation = false;
        mode.preprocessing = false;
        mode.classification = false;
        mode.fitting = false;
        mode.sampling = false;
        mode.plotting = false;
        mode.analysis = false;
        mode.processing = false;
    otherwise
        error('unknown Operatingmode requested')
end