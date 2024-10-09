% This file is for the data analysis of the contours/curvatures of the
% deformable objects.
close all; clear all; clc;
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

%% loading the collected data
dataStorageFolder= 'Deformation_Data';
dataFolderName = 'tape'; % !!
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
interTSW = 0.1; % !!
% threshold of maximal duration of a TSW of bouncing; unit: s
maxTSW = 0.2; % !!
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
        %!!!
        myii=round(0.3*fs);
        for idxFrame=myii:numFrame
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

%% extract the contour and time
% storage of contour and time points
contourStr(numM,numWindow)=struct('data',[]);
for msrNum = M
    idxM = find(M==msrNum);
    fs=data(1,end,1,idxM,idxMode);
    for iWin=1:numWindow
        TSW0=TSWMat(iWin,idxM).TSW0;
        TSWF=TSWMat(iWin,idxM).TSWF;

        if TSW0==0&&TSWF==0
            continue;
        end

        tempData = [];
        tempTimeArr=linspace(0,(TSWF-TSW0)/fs,TSWF-TSW0+1);
        kk=1;
        for idxFrame=TSW0:TSWF
            LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
            x=data(1,LL,iWin,idxM,idxMode);
            y=data(2,LL,iWin,idxM,idxMode);
            opt.touchThreshold = touchThreshold;
            contourArr = contourFind(x,y,opt);

            timeArr = tempTimeArr(kk)*ones(size(contourArr,1),1);
            kk=kk+1;

            tempData=[tempData;[contourArr,timeArr]];
        end
        contourStr(idxM,iWin).data=tempData;
    end
end

%% visulization
close all;
msrNum = 88;
idxM = find(M==msrNum);
tempData=contourStr(idxM,1).data;

title(sprintf('Measurement Level: %d',msrNum))

% if there are more than 1 layer detection of the deformable object
if ~all(tempData(:,3)==tempData(1,3))
    % Compute the convex hull of the 3D points
    K = convhull(tempData(:,1), tempData(:,2), tempData(:,3),'Simplify',true);
    % Plot the outer surface (convex hull)
    trisurf(K, tempData(:,1), tempData(:,2), tempData(:,3), 'FaceColor', 'red', 'FaceAlpha', 0.4,'EdgeColor','red','EdgeAlpha', 0.36);
    hold on
end

plot3(tempData(:,1),tempData(:,2),tempData(:,3),'.','Color','k','MarkerSize',12);
xlabel('x')
ylabel('y')
zlabel('t')

xlim([1 32])
ylim([1 32])
hold off
% xlim([min(tempData(:,1)),max(tempData(:,1))])
% ylim([min(tempData(:,2)),max(tempData(:,2))])
% zlim([0,1e-2])

%% paper plot
figure("Name","deform shape");
msrNumArr=[88,128,256,352,512];
dd=20; % adjust the postion of drawing for each M; !!
posArr=0:dd:(length(msrNumArr)-1)*dd;
labelArr={};
hold on;
for i=1:length(msrNumArr)
    msrNum = msrNumArr(i);
    idxM = find(M==msrNum);
    tempData=contourStr(idxM,1).data;
    labelArr{i}=sprintf('M=%d',msrNum);
    temp_x = tempData(:,1)-min(tempData(:,1))+posArr(i);
    temp_y = tempData(:,2)-min(tempData(:,2));
    temp_z = tempData(:,3);

    % if there are more than 1 layer detection of the deformable object
    if ~all(temp_z==tempData(1,3))
        % Compute the convex hull of the 3D points
        K = convhull(temp_x, temp_y, temp_z, 'Simplify', true);
        % Plot the outer surface (convex hull)
        trisurf(K, temp_x, temp_y, temp_z, 'FaceColor', 'red', 'FaceAlpha', 0.4, 'EdgeColor', 'red', 'EdgeAlpha', 0.36);
    end

    plot3(temp_x,temp_y,temp_z,'.','Color','k','MarkerSize',6);
end
hold off;
title(sprintf([dataFolderName]));
% title(dataFolderName)
xlabel('x')
ylabel('y')
zlabel('t (s)')
xlim([-dd length(msrNumArr)*dd])
ylim([0 10]) % !!
offset=2; % !!
xticks(posArr+offset);
xticklabels(labelArr);
set(gca, 'Position', [0.15, 0.1, 0.8, 0.4]);
view(3);

% save fig
folder = '..\..\paperFig\fig7\';
filePath = fullfile(folder, sprintf([dataFolderName,'.fig']));
saveas(gcf, filePath);
