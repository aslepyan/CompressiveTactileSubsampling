%% This file is for analyzing the experiment of projectiles.
clear
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

%% loading the collected data
dataStorageFolder= 'Projectile_Data';
dataFolderName = 'projectileBall_3dcube_form'; % !!
dataFileName = [dataFolderName, '.mat'];
fullpath = fullfile(uupwd,'data', dataStorageFolder, dataFolderName, dataFileName);
disp('data loading...');
load(fullpath)
disp('data loaded successfully!');

%% params
touchThreshold = 180; % !!
numM = length(M);
modeNum = 3; % !!
idxMode = find(samplingMode==modeNum);

%% extracting the bouncing frames
% threshold of duration between two consecutive TSWs; unit: s
interTSW = 0.05;
% threshold of maximal duration of a TSW of bouncing; unit: s
maxTSW = 0.15;
% struct for storage of the start and the end frame indices of the 1st
% entire bouncing TSW for each window. If the data is invalid, then the
% TSW0=TSWF=0.
TSWMat(numWindow,numM)=struct("TSW0",[],"TSWF",[]);
for msrNum = M
    idxM = find(M==msrNum);
    fs = data(1,end,1,idxM,idxMode);
    numFrame = floor(fs*save_time);
    for iWin=1:numWindow
        nTouch=0;
        TSW0=0;
        TSWF=0;
        for idxFrame=1:numFrame
            LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
            y=data(2,LL,iWin,idxM,idxMode);
            y(y<=touchThreshold)=0;
            if all(y==0)
                continue;
            end

            if nTouch==0
                TSW0=idxFrame;
                idxFrameHis = TSW0;
                nTouch=1;
            end

            if (idxFrame-idxFrameHis)/fs>interTSW
                TSWF=idxFrameHis;
                break;
            end

            idxFrameHis=idxFrame;
            TSWF=idxFrame;
        end
        if (TSWF-TSW0)/fs>maxTSW
            TSW0=0;
            TSWF=0;
        end
        TSWMat(iWin,idxM).TSW0=TSW0;
        TSWMat(iWin,idxM).TSWF=TSWF;
    end
end

%% number of frames with non-zero touch and max val
% array of number of frames with non-zero touch for each window and each
% measurement level
numF = zeros(numM,numWindow);
% array of touch with max pixel-wise force for each window and each
% measurement level
maxF = zeros(numM,numWindow);
for msrNum = M
    idxM = find(M==msrNum);
    for iWin=1:numWindow
        TSW0=TSWMat(iWin,idxM).TSW0;
        TSWF=TSWMat(iWin,idxM).TSWF;
        if TSW0==0&&TSWF==0
            % case when current window of current measurement level is
            % invalid
            numF(idxM,iWin)=-1;
            maxF(idxM,iWin)=-1;
            continue;
        end
        nnon0=0;
        tempMax = 0;
        for idxFrame=TSW0:TSWF
            LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
            y=data(2,LL,iWin,idxM,idxMode);
            y(y<=touchThreshold)=0;

            % number of frames with non-zero touch
            if ~all(y==0)
                nnon0=nnon0+1;
            end

            % max pixel-wise force
            if max(y)>tempMax
                tempMax=max(y);
            end
        end
        numF(idxM,iWin)=nnon0;
        maxF(idxM,iWin)=tempMax;
    end
end

% calculating the num of valid win for each measurement level
numW = numWindow*ones(numM,1);
for msrNum = M
    idxM = find(M==msrNum);
    for iWin=1:numWindow
        val = numF(idxM,iWin);
        if val==-1
            numF(idxM,iWin)=0;
            maxF(idxM,iWin)=0;
            numW(idxM)=numW(idxM)-1;
        end
    end
end

figure(1)
plot([M,1024],[sum(numF,2)./numW;2/5],'-k.'); % 2 frames out of 5 windows in the FR case
xlabel('Measurement Level');
ylabel('Number of frames with nonzero touch');

% save fig


figure(2)
plot(M,sum(maxF,2)./numW,'-k.');
xlabel('Measurement Level');
ylabel('Maximal force');

%% resolution/difference of force between two consecutive frames
% array of difference max pixel-wise force for each window and each
% measurement level
deltaArr = cell(numM,numWindow);
% threshold for examining the difference of forces between two consecutive
% frames.
deltafTd = 1; % !!
for msrNum = M
    idxM = find(M==msrNum);
    for iWin=1:numWindow
        TSW0=TSWMat(iWin,idxM).TSW0;
        TSWF=TSWMat(iWin,idxM).TSWF;
        if TSW0==0&&TSWF==0
            continue;
        end
        tempDeltaArr = [];
        for idxFrame=TSW0:TSWF
            LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
            y=data(2,LL,iWin,idxM,idxMode);
            y(y<=touchThreshold)=0;

            if idxFrame==TSW0
                ymaxp=max(y);
                tempDeltaArr=ymaxp;
                continue;
            end

            ymax=max(y);
            tempDelta=abs(ymax-ymaxp);
            if tempDelta>deltafTd
                tempDeltaArr=[tempDeltaArr tempDelta];
            end
            ymaxp=ymax;

            if idxFrame==TSWF
                tempDeltaArr=[tempDeltaArr ymax];
            end
        end
        deltaArr{idxM,iWin}=tempDeltaArr;
    end
end

plotDeltaArr = zeros(numM,1);
for msrNum = M
    idxM = find(M==msrNum);
    tempDeltaArr = [];
    for iWin=1:numWindow
        tempDeltaArr = [tempDeltaArr deltaArr{idxM,iWin}];
    end
    plotDeltaArr(idxM)=mean(tempDeltaArr);
end

figure(3)
plot([M,1024],[plotDeltaArr;1023],'-k.'); % 1023 in the FR case
xlabel('Measurement Level');
ylabel('average difference of force');

%% Maximal force over time for the bouncing tennis ball
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

% collect and prune the raw data
% extract the name of folder for each object
dataStorageFolder= 'Projectile_Data';

% main loop
% load data
dataFolderName = 'projectileBall_3dcube_form'; % !!
dataFileName = [dataFolderName, '.mat'];
fullpath = fullfile(uupwd, 'data',dataStorageFolder, dataFolderName, dataFileName);
disp('data loading...');
load(fullpath)
disp('loaded successfully!');

numM = length(M);
numMode = length(samplingMode);
numTestWindow = numWindow; % !!!
% 1st index is for time or force; 2nd is for the measurement level; 3rd is
% for the measurement mode; 4th is for the object.
forceStr = cell(2,numM,numMode);

for modeNum = samplingMode % !!!
    idxMode = find(samplingMode==modeNum);

    for msrNum = M % !!!
        idxM = find(M==msrNum);

        fs=data(1,end,1,idxM,idxMode);
        num_frames = floor(fs * save_time);

        forceHis=zeros(numTestWindow,num_frames);
        timeHis=repmat(0:1/fs:save_time-1/fs, numTestWindow, 1);

        for idxWindow=1:numTestWindow
            for i=1:num_frames
                LL=(i-1)*msrNum+1:i*msrNum;
                temp=data(2,LL,idxWindow,idxM,idxMode);
                temp=temp.*(temp>180); %!!

                forceHis(idxWindow,i)=max(temp);
            end
        end

        forceStr{1,idxM,idxMode}=timeHis;
        forceStr{2,idxM,idxMode}=forceHis;
    end
end

%% plotting
figure("Name","force-time plot of projectile");
for iMode=1
    for iM=1%[5,8,12,17,19] % !!
        timeHis=forceStr{1,iM,iMode};
        forceHis=forceStr{2,iM,iMode};
        for idxWindow=2%1:numTestWindow % !!
            force = forceHis(idxWindow,:);
            fprintf('%d\n',sum(force~=0));
            plot(timeHis(idxWindow,:),force,'.-',MarkerSize=10,DisplayName=sprintf('Measurement Level: %d|Win: %d',M(iM),idxWindow));
            legend('Location', 'southoutside');
            xlabel('time (s)');
            ylabel('force (A.U.)');
            legend('Location', 'eastoutside');

            folder = '..\..\paperFig\fig6';
            filePath = fullfile(folder, sprintf('time-force_%d.fig',M(iM)));
            saveas(gcf, filePath);

            disp('');
        end
    end
end
