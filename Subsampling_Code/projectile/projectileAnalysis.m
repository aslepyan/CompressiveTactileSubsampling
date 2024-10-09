%% This file is for analyzing the experiment of projectiles.
close all; clear all; clc;
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

%% loading the collected data
dataStorageFolder= 'Projectile_Data';
dataFolderName = 'projectileBall_3dcube_form'; % !!
dataFileName = [dataFolderName, '.mat'];
fullpath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
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
plot(M,sum(numF,2)./numW,'-k.');
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
plot(M,plotDeltaArr,'-k.');
xlabel('Measurement Level');
ylabel('average difference of force');

