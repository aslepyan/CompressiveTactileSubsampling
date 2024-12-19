% visualization of recovered img
clear

% params
pressThreshold = 60; % for manikin, 1 - 120, 2 - 450; for robot, soft - 10; 1 - 520, 2 - 300
sensorType = 2; % 1-square; 2-insole; 3-glove
recMethod = 1; % 1-ksvd; 2-interp; 3-DCT; 4-Haar
dataStorageFolder= 'insole_data';
dataFolderName = 'foot';

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);
addpath("..\utils\")

% loading the subsampling and recovered data
dataFileName = [dataFolderName, '.mat'];
if recMethod==1
    recSignalFileName = ['RecSignal1_', dataFolderName, '.mat'];
elseif recMethod==2
    recSignalFileName = ['interpRcv1_', dataFolderName, '.mat'];
elseif recMethod==3
    recSignalFileName = ['RecSignal_dct_', dataFolderName, '.mat'];
elseif recMethod==4
    recSignalFileName = ['RecSignal_haar_', dataFolderName, '.mat'];
end
datapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
recDatapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
disp('data loading...');
load(datapath)
load(recDatapath)
disp('data loaded successfully!');

numSensor = 1024;
numMode = numel(samplingMode);
numM = numel(M);
% low-pass filtering
alphaArr = ones(1,20);
if sensorType==2
    alphaArr = [0.5,0.2,0.25,0.4];
end

% plot settings
figure;
cmap = colormap; % get the current colormap
new_cmap = [1 1 1; 0 0 0; cmap]; % define the new colormap with black for unsampled pixels and white for the background
bgVal = -10; % value assigned to the background
unsamVal = -5; % value assigned to the unsampled pixels
valMin = -10; % negative value assigned to the unsampled pixels
valMax = 1024; % max value of measurement values
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"]; % name of the subsampling method

for modeNum = samplingMode
    idxMode = find(samplingMode==modeNum);

    for msrNum = 512%M
        if msrNum==numSensor
            continue;
        end

        idxM = find(M==msrNum);
        fs = data(1,end,1,idxM,idxMode);
        numFrame = floor(fs*save_time);

        for idxWindow = 1:numWindow
            xHis = savedRcvSg(idxWindow,idxM,idxMode).data;
            xHisIdx = 1;

            % params for the low-pass filtering
            alpha = alphaArr(idxM);
            pimg = zeros(32); % last rec img
            if sensorType==2
                pimg = zeros(64,16);
            end
            firstLPF=true; % is first img?

            for i=savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx'
                % prepare subsampling data
                rawData = unsamVal*ones(32);
                for msr = 1:msrNum
                    temp = data(2,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode);
                    temp1=data(1,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode); % 0-1023
                    x=floor(temp1/32)+1; % row ind
                    y=mod(temp1,32)+1; % col ind
                    rawData(x,y)=temp*(temp>pressThreshold);
                end

                % prepare recovered data
                recData = reshape(xHis(:,xHisIdx),[32,32])';
                recData(recData<=20)=0;
                xHisIdx = xHisIdx+1;

                % low-pass filter
                if firstLPF
                    recData=alpha*recData;
                    firstLPF=false;
                else
                    recData=pimg+alpha*(recData-pimg);
                end
                pimg=recData;

                % convert the image to match specific type of sensor
                if sensorType==2
                    rawData = insoleConv(rawData);
                    recData = reshape(recData',[16,64])';
                elseif sensorType==3
                    rawData = gloveConv(rawData);
                    recData = gloveConv(recData);
                end

                % plot subsampling data
                subplot(1,2,1);
                imagesc(rawData)
                colormap(new_cmap);
                colorbar;
                clim([bgVal valMax]);
                title('Raw Data');
                axis equal;

                % plot recovered data
                subplot(1,2,2);
                imagesc(recData)
                colormap(new_cmap);
                colorbar;
                clim([bgVal valMax]);
                title('Recovered Data');
                axis equal;

                sgtitle(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs"),msrNum,idxWindow,i/fs))
                drawnow
            end
        end
    end
end
