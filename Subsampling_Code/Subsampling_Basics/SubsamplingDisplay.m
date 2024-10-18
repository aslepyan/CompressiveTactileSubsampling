% This file is for the visulization of raw data
close all; clear; clc;
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);    

nrow = 32; % number of rows; !!
ncol = 32; % number of columns; !!
touchThreshold = 180; % thr value for non touch of sensor; !!

% load data for visualization
dataStorageFolder= 'Deformation_Data'; % !!
dataFolderName = 'balloon_FR'; % !!
dataFileName = [dataFolderName, '.mat'];
fullpath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
disp('data loading...');
load(fullpath)
disp('loaded successfully!');

load("..\archieveData\footIndConv.mat") % !!

% plot settings
figure;
cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMin = -20; % negative value assigned to the unsampled pixels
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
                if sum(y~=0)<=0 % !!
                    continue;
                end

                % process data for plotting
                rawData = valMin*ones(nrow,ncol);
                for msr = 1:msrNum
                    temp = data(2,LL(msr),idxWindow,idxM,idxMode); % 0-1023
                    temp1=data(1,LL(msr),idxWindow,idxM,idxMode); % 0-1023
                    % temp1=footIndConv(temp1+1)-1; % !!
                    x=floor(temp1/ncol)+1; % rows
                    y=mod(temp1,ncol)+1; % columns
                    rawData(x,y)=temp*(temp>touchThreshold);
                end

                % plot the frame
                imagesc(rawData)
                title(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs|%d"),msrNum,idxWindow,idxFrame/fs,idxFrame))
                colormap(new_cmap);
                colorbar;
                clim([valMin valMax]);
                axis equal;
                drawnow
                % pause(0.2)
            end
        end
    end
end
