% This file is for the visulization of subsampled data
clear;

% params
touchThreshold = 10; % thr for the tactile noise
sensorType = 3; % 1-square; 2-insole; 3-glove
dataStorageFolder= 'glove_data';
dataFolderName = 'catch3';

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);
addpath("..\utils\")

% load data for visualization
dataFileName = [dataFolderName, '.mat'];
fullpath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
disp('data loading...');
load(fullpath)
disp('loaded successfully!');

% plot settings
figure;
cmap = colormap; % get the current colormap
new_cmap = [1 1 1; 0 0 0; cmap]; % define the new colormap with black for unsampled pixels and white for the background
bgVal = -10; % value assigned to the background
unsamVal = -5; % value assigned to the unsampled pixels
valMax = 1024; % max value of measurement values
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"]; % name of the subsampling method

for modeNum = samplingMode
    idxMode = find(samplingMode==modeNum);

    for msrNum = M
        idxM = find(M==msrNum);
        fs=data(1,end,1,idxM,idxMode);
        num_frames = floor(fs * save_time);

        for idxWindow=1:numWindow
            for idxFrame=1:num_frames
                LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
                y=data(2,LL,idxWindow,idxM,idxMode);
                y(y<=touchThreshold)=0;
                if sum(y~=0)<=0
                    continue;
                end

                % process data for plotting
                rawData = unsamVal*ones(32);
                for msr = 1:msrNum
                    temp = data(2,LL(msr),idxWindow,idxM,idxMode); % 0-1023
                    temp1=data(1,LL(msr),idxWindow,idxM,idxMode); % 0-1023
                    x=floor(temp1/32)+1; % rows
                    y=mod(temp1,32)+1; % columns
                    rawData(x,y)=temp*(temp>touchThreshold);
                end

                % convert the image to match specific type of sensor
                if sensorType==2
                    rawData = insoleConv(rawData);
                elseif sensorType==3
                    rawData = gloveConv(rawData);
                end

                % plot the frame
                imagesc(rawData)
                title(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs|%d"),msrNum,idxWindow,idxFrame/fs,idxFrame))
                colormap(new_cmap);
                colorbar;
                clim([bgVal valMax]);
                axis equal;
                drawnow
                pause(0.)
            end
        end
    end
end
