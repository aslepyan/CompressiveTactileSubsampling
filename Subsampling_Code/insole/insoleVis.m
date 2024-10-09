% This file is for the visualization of insole images
close all
clear
clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% extract the names of data files
dataStorageFolder= 'insole_data'; % !!
dataNameList = dir(fullfile(uupwd,dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

load("..\archieveData\footIndConv.mat")

numObject=length(dataNameList);

nrow = 64; % number of rows; !!
ncol = 16; % number of columns; !!
numSensor = nrow*ncol;
pressThreshold = 60; % !!

% params for the low-pass filtering
% alphaArr = ones(numel(M),1); % no filtering
alphaArr = [0.5,0.2,0.25,0.4]; % !!

% plot settings
figure;
cmap = colormap; % get the current colormap
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMin = -20; % negative value assigned to the unsampled pixels
valMax = 1024; % max value of measurement values
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"]; % name of the subsampling method

disp('Data visualization process initiated...');
for dataNameIdx=1:numObject % !!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the subsampling and recovered data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    recSignalFileName = ['RecSignal1_', dataFolderName, '.mat']; % !!
    datapath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
    recDatapath = fullfile(uupwd, dataStorageFolder, dataFolderName, recSignalFileName);
    disp('data loading...');
    load(datapath)
    load(recDatapath)
    disp('data loaded successfully!');

    numMode = numel(samplingMode);
    numM = numel(M);

    for modeNum = samplingMode %!!
        idxMode = find(samplingMode==modeNum);

        for msrNum = 512%M %!!
            if msrNum==numSensor
                continue;
            end

            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            for idxWindow = 1:numWindow % !!
                xHis = savedRcvSg(idxWindow,idxM,idxMode).data;
                xHisIdx = 1;

                % params for the low-pass filtering
                alpha = alphaArr(idxM);
                pimg = zeros(nrow,ncol); % last rec img
                firstLPF=1; % is first img?

                for i=savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx'
                    % prepare subsampling data
                    rawData = valMin*ones(nrow,ncol);

                    for msr = 1:msrNum
                        temp = data(2,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode);

                        temp1=data(1,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode); % 0-1023
                        temp1=footIndConv(temp1+1)-1; % !! for foot ind conversion
                        x=floor(temp1/ncol)+1; % row ind
                        y=mod(temp1,ncol)+1; % col ind

                        rawData(x,y)=temp*(temp>pressThreshold);
                    end

                    % change position or orientation
                    newP=[0,0];
                    rawData = circshift(rawData,newP);

                    % prepare recovered data
                    recData = reshape(xHis(:,xHisIdx),[ncol,nrow])';
                    recData(recData<=pressThreshold)=0;
                    xHisIdx = xHisIdx+1;

                    % low-pass filter
                    if firstLPF
                        recData=alpha*recData;
                        firstLPF=0;
                    else
                        recData=pimg+alpha*(recData-pimg);
                    end
                    pimg=recData;

                    %plot subsampling data
                    subplot(1,2,1);
                    imagesc(rawData)
                    colormap(new_cmap);
                    colorbar;
                    clim([valMin valMax]);
                    title('Raw Data');
                    axis equal;

                    % plot recovered data
                    subplot(1,2,2);
                    imagesc(recData)
                    colormap(new_cmap);
                    colorbar;
                    clim([valMin valMax]);
                    title('Recovered Data');
                    axis equal;

                    sgtitle(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs"),msrNum,idxWindow,i/fs))

                    drawnow
                end
            end
        end
    end
end

disp('visualization finish!');
