% visualization of recovered img
close all
clear
clc

crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% extract the names of data files
dataStorageFolder= 'robot_data'; % !!
dataNameList = dir(fullfile(uupwd,'data',dataStorageFolder,'*'));
dataNameList = dataNameList(3:end);

% load("..\archieveData\footIndConv.mat") % !!

numObject=length(dataNameList);

nrow = 32; % number of rows; !!
ncol = 32; % number of columns; !!
numSensor = nrow*ncol;
pressThreshold = 00; % !!; for manikin, 1 - 120; 2 - 450;  for robot, soft - 10; 1 - 520, 2 - 300

% plot settings
figure;
cmap = colormap; % get the current colormap 
new_cmap = [0 0 0; cmap]; % define the new colormap with black for the negative value
valMin = -20; % negative value assigned to the unsampled pixels
valMax = 1024; % max value of measurement values
modeName = ["Down-Sampling","Random Sampling","Binary Sampling"]; % name of the subsampling method

disp('Data visualization process initiated...');
for dataNameIdx=7%1:numObject % !!
    fprintf('Object No.%d/%d\n',dataNameIdx,numObject);

    % loading the subsampling and recovered data
    dataFolderName = dataNameList(dataNameIdx).name;
    dataFileName = [dataFolderName, '.mat'];
    recSignalFileName = ['RecSignal1_', dataFolderName, '.mat']; % !!
    datapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, dataFileName);
    recDatapath = fullfile(uupwd, 'data', dataStorageFolder, dataFolderName, recSignalFileName);
    disp('data loading...');
    load(datapath)
    load(recDatapath)
    disp('data loaded successfully!');

    numMode = numel(samplingMode);
    numM = numel(M);

    for modeNum = samplingMode %!!
        idxMode = find(samplingMode==modeNum);

        for msrNum = M %!!
            if msrNum==numSensor
                continue;
            end

            idxM = find(M==msrNum);
            fs = data(1,end,1,idxM,idxMode);
            numFrame = floor(fs*save_time);

            %v = VideoWriter(dataNameList(dataNameIdx).name); % Uncomment for video
            %v.FrameRate = fs/400; %400X slower % Uncomment for video
            %open(v) % Uncomment for video

            for idxWindow = 1:numWindow % !!
                xHis = savedRcvSg(idxWindow,idxM,idxMode).data;
                xHisIdx = 1;

                for i=savedRcvSg(idxWindow,idxM,idxMode).recFrameIdx'
                    % prepare subsampling data
                    rawData = valMin*ones(nrow,ncol);

                    for msr = 1:msrNum
                        temp = data(2,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode);

                        temp1=data(1,((i-1)*msrNum)+msr,idxWindow,idxM,idxMode); % 0-1023
                        % temp1=footIndConv(temp1+1)-1; % !! for foot ind conversion
                        x=floor(temp1/ncol)+1; % row ind
                        y=mod(temp1,ncol)+1; % col ind

                        rawData(x,y)=temp*(temp>pressThreshold);
                    end

                    % change position or orientation
                    newP=[0,0];
                    rawData = circshift(rawData,newP);

                    % prepare recovered data
                    recData = reshape(xHis(:,xHisIdx),[ncol,nrow])';
                    recData(recData<=0)=0;
                    xHisIdx = xHisIdx+1;

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
                    recData1=recData;
                    recData1(recData1<=100)=0;
                    imagesc(recData1)
                    colorbar;
                    clim([valMin valMax]);
                    % clim([-5 max(recData1,[],'all')]);
                    title('Recovered Data');
                    axis equal;

                    sgtitle(sprintf(strcat(modeName(modeNum), "|msrNum %d|Window %d|%0.5fs"),msrNum,idxWindow,i/fs))

                    drawnow

                    %frame = getframe(gcf); % Uncomment for video
                    %writeVideo(v,frame) % Uncomment for video
                end
            end
        end
    end
end
%close(v) % Uncomment for video


disp('visualization finish!');
