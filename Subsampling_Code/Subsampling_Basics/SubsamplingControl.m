% Extract, measure and save data by using three subsampling algorithms.
% Note: 1. Check whether the sub-sampling arduino code upload to the
% arduino board.
% 2. First, run the matlab file; then touch the sensor to begin.
% 3. Update the variables "samplingMode", "save_time", "numWindow", "M" and
% the ones reponsible for the saved file and folder.
% 4. If we change the arduino code, before we use this matlab file. First,
% uncommend the time printing syntax and then calculate the time per frame
% by using command window. Last, comment the printing syntax of time in the
% arduino code.
close all; clear; clc;

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% basic params
global M save_time data numWindow samplingMode numSensor numWindowTotal idxWindowTotal;
numSensor = 1024;
samplingMode = [3]; % 1-downsampling; 2-random sampling; 3-binary sampling; 4-sum sampling !!
numSamplingMode = length(samplingMode);
save_time = 2; % duration of one window; s, !!
numWindow = 1; % num of window, !!
MNumFrameProd = 2e5; % threshold total num of msr sensors per window (2s is 2e5)

% array of num of measured sensors per frame, !!
% M = [42,48,49,56,64,66,77,88,96,112,121,128,160,176,192,224,256,352,512,1024,];
% M = [42,48,49,56,64,66,77,88,96,112,121,128,160,176,192,224,256,352,512,];
% M = [64,66,77,88,96,112,121,128,160,176,192,224,256,352,512,];
% M = [64,128,256,512];
M=88;
% M = [64,88,128,256,352,512];

numM = length(M); % num of diff cases of num of measured sensors per frame

numWindowTotal = numSamplingMode*numM*numWindow;
idxWindowTotal = 1;

% Initialization of an array for storage of data for the current object
% Dim 1: Store the corresponding coord and data (pressure) value
% The range of data(1,) are 0-1023.
% Dim 2: For each measured sensor in one frame and for each frame in one
% window
% Dim 3: For each window under idxM and idxMode
% Dim 4: For each case with a specific num of measured sensors per frame
% Dim 5: For each sampling mode
% Note: For each idxM and idxMode, the num of measured sensors and the num
% of frames per window are different, so we need to indicate them.
% Therefore, data(1,end,1,idxM,idxMode) specifies sampling rate (fs).
data=zeros(2, MNumFrameProd, numWindow, numM, numSamplingMode);

% main loop (order: mode-->M-->window (from outer loop to inner loop))
for idxMode = 1:length(samplingMode)
    modeNum = samplingMode(idxMode);

    if modeNum==3
        binarySampling();
    elseif modeNum==1
        downSamplingShift();
    elseif modeNum==2
        randomSampling();
    elseif modeNum==4
        sumSam();
    end
end

% save the subsampled data
dataStorageFolder= 'Deformation_Data'; % !!
dataFolderName = 'zz'; % !!
dataFileName = [dataFolderName, '.mat'];
dataFolderPath = fullfile(uupwd, dataStorageFolder, dataFolderName);
dataFilePath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);

disp('saving...');

% create folder and file, save data in the file.
if exist(dataFolderPath, 'dir')
    disp('Warning: folder has been already created!');
    save(dataFilePath, "data", "samplingMode", "M","save_time","numWindow",'-v7.3');
    disp('saved!');
else
    mkdir(dataFolderPath);
    save(dataFilePath, "data", "samplingMode", "M","save_time","numWindow",'-v7.3');
    disp('saved!');
end
