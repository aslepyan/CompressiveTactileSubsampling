% This file is to visualize consecutive shifting down-sampling patterns.
close all; clear; clc;
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

nrow = 32; % number of rows; !!
ncol = 32; % number of columns; !!
touchThreshold = 700; % thr value for non touch of sensor; !!

% load data for visualization
dataStorageFolder= 'Subsampling_Data'; % !!
dataFolderName = 'brain'; % !!
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
ind=1;

for modeNum = 1
    idxMode = find(samplingMode==modeNum);

    for msrNum = 64
        idxM = find(M==msrNum);
        fs=data(1,end,1,idxM,idxMode);
        num_frames = floor(fs * save_time);

        for idxWindow=1
            for idxFrame=1:16
                LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
                y=data(2,LL,idxWindow,idxM,idxMode);
                y(y<=touchThreshold)=0;

                % process data for plotting
                rawData = unsamVal*ones(nrow,ncol);
                for msr = 1:msrNum
                    temp = data(2,LL(msr),idxWindow,idxM,idxMode); % 0-1023
                    temp1=data(1,LL(msr),idxWindow,idxM,idxMode); % 0-1023
                    x=floor(temp1/ncol)+1; % rows
                    y=mod(temp1,ncol)+1; % columns
                    rawData(x,y)=temp*(temp>touchThreshold);
                end

                % plot the frame
                imagesc(rawData(1:10,1:10))
                title(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs|%d"),msrNum,idxWindow,idxFrame/fs,idxFrame))
                colormap(new_cmap);
                colorbar;
                clim([bgVal valMax]);
                axis equal;
                drawnow
                pause(0.)

                % save fig
                folder = '..\..\paperFig\figS_samOrd\';
                filePath = fullfile(folder, sprintf('downSamOrd_%d.fig',ind));
                ind=ind+1;
                saveas(gcf, filePath);
            end
        end
    end
end
