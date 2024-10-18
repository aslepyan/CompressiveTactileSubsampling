% This file is for the data analysis of the contours/curvatures of the
% deformable objects.
close all; clear all; clc;
crtpwd = pwd;
upperpwd = fileparts(crtpwd);
uupwd = fileparts(upperpwd);

%% loading the collected data
dataStorageFolder= 'Deformation_Data';
dataFolderName = 'balloon'; % !!
dataFileName = [dataFolderName, '.mat'];
recSignalFileName = ['RecSignal1_', dataFolderName, '.mat']; % !!
datapath = fullfile(uupwd, dataStorageFolder, dataFolderName, dataFileName);
recDatapath = fullfile(uupwd, dataStorageFolder, dataFolderName, recSignalFileName);
disp('data loading...');
load(datapath)
load(recDatapath)
disp('data loaded successfully!');

%% params
touchThreshold = 180; % !!
numM = length(M);
modeNum = 2; % !!
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
thrArr=[20,20,50,50,100,100]; % eliminating thr for the low-pass filter
% storage of contour and time points
contourStr(numM,numWindow)=struct('data',[]);
for msrNum = M
    idxM = find(M==msrNum);
    fs=data(1,end,1,idxM,idxMode);
    opt.touchThreshold = thrArr(idxM);
    for iWin=1:numWindow
        TSW0=TSWMat(iWin,idxM).TSW0;
        TSWF=TSWMat(iWin,idxM).TSWF;

        if TSW0==0&&TSWF==0
            continue;
        end

        tempData = [];
        tempTimeArr=linspace(0,(TSWF-TSW0)/fs,TSWF-TSW0+1);
        kk=1;

        frIndArr = savedRcvSg(iWin,idxM,1).recFrameIdx;
        recDataArr = savedRcvSg(iWin,idxM,1).data;
        for idxFrame=TSW0:TSWF
            % use the raw data
            % LL=(idxFrame-1)*msrNum+1:idxFrame*msrNum;
            % x=data(1,LL,iWin,idxM,idxMode);
            % y=data(2,LL,iWin,idxM,idxMode);

            % use the recovered data
            ii=find(frIndArr==idxFrame);
            y=recDataArr(:,ii);
            y=reshape(y',1,[]);
            x=0:1023';

            % for balloon, only consider the radius of tactile image
            isBalloon=true; % set false for objects except balloon!!
            if isBalloon && ~isempty(y)
                recImg=reshape(y,[32,32])';
                recImg(recImg<opt.touchThreshold)=0;
                maxLCol=findMaxLImg(recImg);
                maxLRow=findMaxLImg(recImg');
                r=mean([maxLRow,maxLCol])/2;
                cp=[16,16]; % center point
                recImg=zeros(32);
                for ir=1:32
                    for ic=1:32
                        p=[ir,ic];
                        if norm(p-cp)<r
                            recImg(ir,ic)=1023;
                        end
                    end
                end
                y=recImg(:); % already symmetric
                % imagesc(recImg);
            end

            contourArr = contourFind(x,y,opt);

            timeArr = tempTimeArr(kk)*ones(size(contourArr,1),1);
            kk=kk+1;

            tempData=[tempData;[contourArr,timeArr]];
        end
        tempData = unique(tempData, 'rows', 'stable'); % eliminate repeat points
        contourStr(idxM,iWin).data=tempData;
    end
end

%% visulization (for one specfic M and one specific window)
c1=5e2; % coeff for converting time to vertical space
z_max=15; % max height (in the vertical direction)
for msrNum=[88]%[64,88,128,256,352,512] % !!
    idxM = find(M==msrNum);
    for iWin = 1:3 % !!
        tempData1=contourStr(idxM,iWin).data;
        temp_z = tempData1(:,3)*c1;
        temp_z=temp_z(temp_z<z_max);
        % eliminate some ghosting points; !!
        nL=numel(temp_z);
        tempData=tempData1(1:nL,:);
        % tempData(139,:)=[];
        temp_x = tempData(:,1)-min(tempData(:,1));
        temp_y = tempData(:,2)-min(tempData(:,2));
        temp_z = tempData(:,3)*c1;

        figure("Name", sprintf(['deform shape|',dataFolderName,'_%d.fig'],msrNum));

        % if there are more than 1 layer of points from detection of the
        % deformable object, we will plot the outer layer (hull)
        if ~all(temp_z==temp_z(1))
            % compute and plot the outer surface of consecutive 2 layers of
            % the 3D points
            new_z_ind=0; % index of new z
            pnew_z_ind=0; % index of previous new z
            ini=false;
            for jj=1:numel(temp_z)
                if temp_z(new_z_ind+1)~=temp_z(jj) || jj==numel(temp_z)
                    ppnew_z_ind=pnew_z_ind; % index of previous previous new z
                    pnew_z_ind=new_z_ind;
                    if jj==numel(temp_z)
                        new_z_ind=jj;
                    else
                        new_z_ind=jj-1;
                    end
                    if pnew_z_ind>0
                        % K = convhull(temp_x(ppnew_z_ind+1:new_z_ind), temp_y(ppnew_z_ind+1:new_z_ind), temp_z(ppnew_z_ind+1:new_z_ind), 'Simplify', true);
                        % trisurf(K, temp_x(ppnew_z_ind+1:new_z_ind), temp_y(ppnew_z_ind+1:new_z_ind), temp_z(ppnew_z_ind+1:new_z_ind), 'FaceColor', 'red', 'FaceAlpha', 0.2, 'EdgeColor', 'red', 'EdgeAlpha', 0);
                        % if ~ini
                        % hold on
                        % ini=true;
                        % end
                    end
                end
            end

            % version of as a whole
            K = convhull(temp_x, temp_y, temp_z, 'Simplify', true);
            trisurf(K, temp_x, temp_y, temp_z, 'FaceColor', 'red', 'FaceAlpha', 0.4, 'EdgeColor', 'red', 'EdgeAlpha', 0);
            hold on
        end

        plot3(temp_x,temp_y,temp_z,'.','Color','k','MarkerSize',6);
        hold off;
        title(sprintf([dataFolderName,'|M=%d|Window %d'],msrNum,iWin));
        xlabel('x')
        ylabel('y')
        zlabel('z')

        axis equal;
        % xlim([0 10])
        % ylim([0 10])
        % zlim([0 z_max])
        rotate3d on;

        % save fig
        folder = '..\..\paperFig\fig7\';
        filePath = fullfile(folder, sprintf([dataFolderName,'_%d.fig'],msrNum));
        saveas(gcf, filePath);

        % save data
        folder = '..\..\Deformation_Data\';
        filePath = fullfile(fullfile(folder,dataFolderName), sprintf([dataFolderName,'_%d_.mat'],msrNum));
        save(filePath,"temp_x","temp_y","temp_z");
    end
end

%% paper plot (for one type of projectile)
close all; clear all; clc;
dataFolderName = 'balloon'; % !!
folder = '..\..\Deformation_Data\';
msrNumArr=[88,128,256,352,512]; % !!
c2=1.5; % coeff for find adjustment; !!
dd=[20,20,20,20,20]; % adjust the postion of drawing for each M; !!
posArr=zeros(1,numel(msrNumArr)-1);
for i=1:numel(msrNumArr)-1
    posArr(i+1)=posArr(i)+dd(i);
end
labelArr={};
colorArr=["#0072BD","#D95319","#EDB120","#7E2F8E","#77AC30","#4DBEEE"]; % default color order
ini=false;
max_x=-1;
max_y=-1;

figure("Name", sprintf(['deform shape of ',dataFolderName,'.fig']));
for i=1:length(msrNumArr)
    msrNum = msrNumArr(i);
    load(fullfile(fullfile(folder,dataFolderName), sprintf([dataFolderName,'_%d_.mat'],msrNum)));
    labelArr{i}=sprintf('M=%d',msrNum);
    temp_x = temp_x + posArr(i);
    temp_z = temp_z*c2; % fine adjustment of the vertical heights

    % if there are more than 1 layer of points from detection of the
    % deformable object, we will plot the outer layer (hull)
    if ~all(temp_z==temp_z(1))
        % compute and plot the outer surface of consecutive 2 layers of
        % the 3D points
        new_z_ind=0; % index of new z
        pnew_z_ind=0; % index of previous new z

        for jj=1:numel(temp_z)
            if temp_z(new_z_ind+1)~=temp_z(jj) || jj==numel(temp_z)
                ppnew_z_ind=pnew_z_ind; % index of previous previous new z
                pnew_z_ind=new_z_ind;
                if jj==numel(temp_z)
                    new_z_ind=jj;
                else
                    new_z_ind=jj-1;
                end
                if pnew_z_ind>0
                    % K = convhull(temp_x(ppnew_z_ind+1:new_z_ind), temp_y(ppnew_z_ind+1:new_z_ind), temp_z(ppnew_z_ind+1:new_z_ind), 'Simplify', true);
                    % trisurf(K, temp_x(ppnew_z_ind+1:new_z_ind), temp_y(ppnew_z_ind+1:new_z_ind), temp_z(ppnew_z_ind+1:new_z_ind), 'FaceColor', 'red', 'FaceAlpha', 0.2, 'EdgeColor', 'red', 'EdgeAlpha', 0);
                    % if ~ini
                    %     hold on
                    %     ini=true;
                    % end
                end
            end
        end

        % version of as a whole
        % K = convhull(temp_x, temp_y, temp_z, 'Simplify', true);
        % trisurf(K, temp_x, temp_y, temp_z, 'FaceColor', 'red', 'FaceAlpha', 0.2, 'EdgeColor', 'red', 'EdgeAlpha', 0);
        % if ~ini
        %     hold on
        %     ini=true;
        % end
    end

    plot3(temp_x,temp_y,temp_z,'.','Color',	colorArr(i),'MarkerSize',7);
    if ~ini
        hold on
        ini=true;
    end

    if max_x<max(temp_x)
        max_x=max(temp_x);
    end

    if max_y<max(temp_y)
        max_y=max(temp_y);
    end
end
hold off;
title(sprintf([dataFolderName]));
xlabel('x')
ylabel('y')
zlabel('z')
axis equal;
xlim([-2 max_x+2])
ylim([0 max_y+2]) % !!
% zlim([0 z_max])
rotate3d on;
xticks(posArr+2);
xticklabels(labelArr);

% save fig
folder = '..\..\paperFig\fig7\';
filePath = fullfile(folder, sprintf([dataFolderName,'.fig']));
saveas(gcf, filePath);

%% demo vedio for the balloon
close all; clear all; clc;

v = VideoWriter(['balloon']);
fs = 664.3066; % M = 88
v.FrameRate = fs/16; %16X slower
open(v)

dataFolderName = 'balloon'; % !!
folder = '..\..\Deformation_Data\';
msrNumArr=[88,128,256,352,512]; % !!
c2=1.5; % coeff for find adjustment; !!
dd=[20,20,20,20,20]; % adjust the postion of drawing for each M; !!
posArr=zeros(1,numel(msrNumArr)-1);
for i=1:numel(msrNumArr)-1
    posArr(i+1)=posArr(i)+dd(i);
end
labelArr={};
colorArr=["#0072BD","#D95319","#EDB120","#7E2F8E","#77AC30","#4DBEEE"]; % default color order
ini=false;
max_x=-1;
max_y=-1;

figure("Name", sprintf(['animation of deform shape of ',dataFolderName,'.fig']));
for i=1%1:length(msrNumArr)
    msrNum = msrNumArr(i);
    load(fullfile(fullfile(folder,dataFolderName), sprintf([dataFolderName,'_%d_.mat'],msrNum)));
    labelArr{i}=sprintf('M=%d',msrNum);
    temp_x = temp_x + posArr(i);
    temp_z = temp_z*c2; % fine adjustment of the vertical heights

    % if there are more than 1 layer of points from detection of the
    % deformable object, we will plot the outer layer (hull)
    if ~all(temp_z==temp_z(1))
        % compute and plot the outer surface of consecutive 2 layers of
        % the 3D points
        new_z_ind=0; % index of new z
        pnew_z_ind=0; % index of previous new z

        for jj=1:numel(temp_z)
            if temp_z(new_z_ind+1)~=temp_z(jj) || jj==numel(temp_z)
                ppnew_z_ind=pnew_z_ind; % index of previous previous new z
                pnew_z_ind=new_z_ind;
                if jj==numel(temp_z)
                    new_z_ind=jj;
                else
                    new_z_ind=jj-1;
                end
                if pnew_z_ind>0
                    plot3(temp_x(1:new_z_ind),temp_y(1:new_z_ind),temp_z(1:new_z_ind),'.','Color',	colorArr(i),'MarkerSize',7);
                    title(sprintf([dataFolderName]));
                    xlabel('x')
                    ylabel('y')
                    zlabel('time (A.U.)')
                    axis equal;
                    xlim([-2 30])
                    ylim([0 30]) % !!
                    zlim([0 20])
                    rotate3d on;
                    % xticks(posArr(1)+2);
                    % xticklabels(labelArr(1));
                    drawnow;

                    frame = getframe(gcf);
                    writeVideo(v,frame)
                end
            end
        end
    end
end
for i=1:30
    writeVideo(v,frame)
end
close(v)


%% helper function
function L=findMaxLImg(mat)
L=0;
[nr,~]=size(mat);
for ir=1:nr
    temp=find(mat(ir,:)~=0);
    tempL=0;
    if(~isempty(temp))
        tempL=temp(end)-temp(1)+1;
    end
    if L<tempL
        L=tempL;
    end
end
end