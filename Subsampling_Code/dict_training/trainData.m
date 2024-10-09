% This file is for collection of full raster data used for the training
% dictionary later
%% The full raster training data collection
close all
clear
clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% collect and prune the raw data
% extract the name of folder for each object
dataStorageFolder= 'Subsampling_Data'; % !!
dataNameList = dir(fullfile(uupwd,dataStorageFolder,'*'));
numObject = length(dataNameList)-2;

% sensor params
numSensor = 1024;
msrNum = numSensor;
pressThreshold = 50; % !!

% struct for saving training data for dict
savedTrainData(numObject) = struct('name',[],'data',[]);

for dataNameIdx=1:numObject % !!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % load data
    dataFolderName = dataNameList(dataNameIdx+2).name;
    dataFileName = [dataFolderName, '.mat'];

    dictPath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(dictPath)
    disp('loaded successfully!');

    % extract relevant data for dictionary training
    fullRasterData = [];

    fullRasterIdx = find(M==numSensor); % index of case of full raster in M

    for idxMode = 1 % !!
        fs = data(1,end,1,fullRasterIdx,idxMode);
        numFrame = floor(fs*save_time);

        for idxWindow = 1:numWindow % !!!
            for idxFrame = 1:numFrame
                LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;

                pos = data(1,LL,idxWindow,fullRasterIdx,idxMode); % 0-1023
                if (~all(sort(pos)==0:1023))
                    error('data extraction error!');
                end

                val = data(2,LL,idxWindow,fullRasterIdx,idxMode);

                temp=zeros(numSensor,1); % temp 1d array for storage img val in order
                for posIdx = 1:numSensor
                    temp(pos(posIdx)+1)=val(posIdx);
                end

                temp(temp<=pressThreshold)=0; % !!

                if nnz(temp)>0 %!!
                    fullRasterData = [fullRasterData, temp];
                end
            end
        end
    end

    % save data for each object
    savedTrainData(dataNameIdx).name=dataFolderName;
    savedTrainData(dataNameIdx).data=fullRasterData;
end

% saved trained data
trainDataFolder = 'traningData';
trainDataFileName = 'traningData.mat';
trainDataPath = fullfile(upperpwd, trainDataFolder, trainDataFileName);
save(trainDataPath, "savedTrainData", "numObject");

%% The full raster training data collection (only mid frame in one TSW)
close all
clear
clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% loading relevant data
load ..\archieveData\TSWMat.mat

% collect and prune the raw data
% extract the name of folder for each object
dataStorageFolder= 'Subsampling_Data';
dataNameList = dir(fullfile(uupwd,dataStorageFolder,'*'));
numObject = length(dataNameList)-2;

% total num of sensors
numSensor = 1024;
msrNum=numSensor;
pressThreshold = 50; % !!

% struct for saving training data for dict
savedTrainData(numObject) = struct('name',[],'data',[]);

for dataNameIdx=1:30%1:numObject % !!!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % load data
    dataFolderName = dataNameList(dataNameIdx+2).name;
    dataFileName = [dataFolderName, '.mat'];

    dictPath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
    disp('data loading...');
    load(dictPath)
    disp('loaded successfully!');

    % extract relevant data for dictionary training
    fullRasterData = zeros(numSensor,numWindow);

    fullRasterIdx = find(M==numSensor); % index of case of full raster in M

    k=1;

    for idxMode = 1%1:3 % !!!
        fs = data(1,end,1,fullRasterIdx,idxMode);
        numFrame = floor(fs*save_time);

        idxM = find(M==msrNum);

        for idxWindow = 1:numWindow % !!!
            TSW0=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSW0;
            TSWF=TSWMat(idxWindow,idxM,idxMode,dataNameIdx).TSWF;

            % extract the mid frame to be recovered for each window
            midpnt = round((TSW0+TSWF)/2);

            % store the value of middle frame
            midFrameData = zeros(32);

            for msr = 1:numSensor
                temp = data(2,((midpnt-1)*msrNum)+msr,idxWindow,idxM,idxMode);
                temp1=data(1,((midpnt-1)*msrNum)+msr,idxWindow,idxM,idxMode); % 0-1023
                x=floor(temp1/32)+1; % 1-32
                y=mod(temp1,32)+1; % 1-32
                midFrameData(x,y)=temp*(temp>pressThreshold);
            end

            midFrameData=midFrameData';
            fullRasterData(:,k)=midFrameData(:);
            k=k+1;
        end
    end

    % save data for each object
    savedTrainData(dataNameIdx).name=dataFolderName;
    savedTrainData(dataNameIdx).data=fullRasterData;
end

% saved trained data
trainDataFolder = 'traningData';
trainDataFileName = 'traningData.mat';
trainDataPath = fullfile(upperpwd, trainDataFolder, trainDataFileName);
save(trainDataPath, "savedTrainData", "numObject");

%% Visualization of the extracted frames to be used in dict training
close all;
clear;
clc;

crtpwd = pwd;
upperpwd = fileparts(crtpwd);

load(fullfile(upperpwd, 'traningData\traningData.mat'))

nrow = 32; % !!
ncol = 32; % !!

% plot settings
figure;
cmap = colormap;
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the value -1
valMin = -10;
valMax = 1023;

for dataNameIdx=1%1:numObject %!!
    savedFullRasterData = savedTrainData(dataNameIdx).data;
    numFrameTotal = size(savedFullRasterData,2);
    for i=1:numFrameTotal % !!
        % process the image data for plotting
        img = savedFullRasterData(:,i);
        img = reshape(img,[nrow,ncol])';
        img = imresize(img,1);

        % plot
        imagesc(img)
        title(sprintf(['Frame No. %d'],i))
        colormap(new_cmap);
        colorbar;
        clim([valMin valMax]);
        axis equal;
        drawnow
    end
end
